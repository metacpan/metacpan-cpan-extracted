#!perl

use 5.010;
use strict;
use warnings;

use File::chdir;
use File::Path qw(remove_tree);
use File::Slurper qw(read_text write_text);
use File::Temp qw(tempdir);
use File::Write::Rotate;
use Monkey::Patch::Action qw(patch_package);

use Test::Exception;
use Test::Warnings qw(:no_end_test warnings);
use Test::More 0.98;

$ENV{TZ} = "UTC";

my $dir = tempdir(CLEANUP=>1);
$CWD = $dir;

test_filehandle_cache(
    label => "basic",
    new_params => [dir=>$dir, prefix=>"a"],
    code => sub {
        my ($writer) = @_;
        delete_all_files();
        $writer->("[1]");
        is(scalar read_text("a"), "[1]");
        $writer->("[2]", "[3]");
        is(scalar read_text("a"), "[1][2][3]");
    }
);

test_filehandle_cache(
    label => "binmode ':utf8'",
    new_params => [dir=>$dir, prefix=>"a",
                   binmode => ':utf8'],
    code => sub {
        my ($writer) = @_;
        delete_all_files();
        my $text = "\x{263a}";
        utf8::upgrade($text);
        my @warnings = warnings {
            use warnings;
            $writer->($text);
        };
        ok(!(grep { $_ =~ /wide character/i } @warnings),
           "no 'Wide character in ...' warning");
        is(scalar read_text("a"), $text, "file contents");
    }
);

test_filehandle_cache(
    label => "rotate by size",
    new_params => [dir=>$dir, prefix=>"a", size=>3],
    code => sub {
        my ($writer, $get_fwr) = @_;
        delete_all_files();
        is(($get_fwr->()->_file_path())[1], "", "period");
        $writer->("[1]");
        is(scalar read_text("a"), "[1]");
        $writer->("[2]", "[3]");
        is(scalar read_text("a"), "[2][3]");
        is(scalar read_text("a.1"), "[1]");
    }
);

# just testing at some non-negligible size
test_filehandle_cache(
    label => "rotate by size = 20Kb",
    new_params => [dir=>$dir, prefix=>"a", size=>20*1000],
    code => sub {
        my ($writer, $get_fwr) = @_;
        delete_all_files();
        my $msg = "x" x 100;
        for (1..200) { $writer->($msg) }
        is( (-s 'a')  , 20000, 'first file exists and has 20Kb so far');
        is( (-e 'a.1'), undef, 'rotate files does not exists yet' );
        note('printing one more message to force rotation bondaries');
        $writer->($msg);
        is( (-s 'a')  ,   100, 'new file exists and has 100 bytes');
        is( (-s 'a.1'), 20000, 'rotate file exists and has 20Kb');
	my $orig_size = (-s 'a.1');
        test_gzip($get_fwr->(), ['a.1']);
        # sane value
        my $comp_size = 0;
        $comp_size = (-s 'a.1.gz');

	if (defined($comp_size)) {
            cmp_ok($comp_size, '<', $orig_size, 'compressed file size is smaller than before compression');
        } else {
            fail("there is no compressed a.1, cannot compare sizes");
        }
    }
);

test_filehandle_cache(
    label => "rotate by period, daily",
    new_params => [dir=>$dir, prefix=>"a", period=>"daily"],
    code => sub {
        my ($writer, $get_fwr) = @_;
        delete_all_files();
        my $ph;
        $ph = set_time_to(1356090474); # 2012-12-21 @UTC
        is(($get_fwr->()->_file_path())[1], "2012-12-21", "period");
        $writer->("[1]");
        is(scalar read_text("a.2012-12-21"), "[1]", 'got expected content in the file (1)');
        $writer->("[2]", "[3]");
        is(scalar read_text("a.2012-12-21"), "[1][2][3]", 'got expected content in the file (2)');
        $ph = set_time_to(1356090474 + 86400); # 2012-12-22 @UTC
        $writer->("[4]");
        is(scalar read_text("a.2012-12-22"), "[4]", 'got expected content in the file (3)');
        #list_files();
        test_gzip($get_fwr->(), ['a.2012-12-21']);
    }
);

test_filehandle_cache(
    label => "rotate by period, monthly",
    new_params => [dir=>$dir,
                   prefix=>"a", period=>"monthly"],
    code => sub {
        my ($writer, $get_fwr) = @_;
        delete_all_files();
        my $ph;
        $ph = set_time_to(1356090474); # 2012-12-21 @UTC
        is(($get_fwr->()->_file_path())[1], "2012-12", "period");
        $writer->("[1]");
        is(scalar read_text("a.2012-12"), "[1]");
        $writer->("[2]", "[3]");
        is(scalar read_text("a.2012-12"), "[1][2][3]");

        $ph = set_time_to(1356090474 + 31*86400); # 2013-01-21 @UTC
        $writer->("[4]");
        is(scalar read_text("a.2013-01"), "[4]");
        test_gzip($get_fwr->(), ['a.2012-12']);
    }
);

test_filehandle_cache(
    label => "rotate by period, yearly",
    new_params => [dir=>$dir,
                   prefix=>"a", period=>"year"],
    code => sub {
        my ($writer, $get_fwr) = @_;
        delete_all_files();
        my $ph;
        $ph = set_time_to(1356090474); # 2012-12-21 @UTC
        is(($get_fwr->()->_file_path())[1], "2012", "period");
        $writer->("[1]");
        is(scalar read_text("a.2012"), "[1]");
        $writer->("[2]", "[3]");
        is(scalar read_text("a.2012"), "[1][2][3]");

        $ph = set_time_to(1356090474 + 31*86400); # 2013-01-21 @UTC
        $writer->("[4]");
        is(scalar read_text("a.2013"), "[4]");
        test_gzip($get_fwr->(), ['a.2012']);
    }
);

test_filehandle_cache(
    label => "rotate by period + size, suffix",
    new_params => [dir=>$dir, prefix=>"a", suffix=>".log",
                   size=>3, period=>"daily"],
    code => sub {
        my ($writer, $get_fwr) = @_;
        delete_all_files();
        my $ph;
        $ph = set_time_to(1356090474); # 2012-12-21 @UTC
        is(($get_fwr->()->_file_path())[1], "2012-12-21", "period");
        $writer->("[1]");
        is(scalar read_text("a.2012-12-21.log"), "[1]");
        $writer->("[2]", "[3]");
        is(scalar read_text("a.2012-12-21.log"), "[2][3]");
        is(scalar read_text("a.2012-12-21.log.1"), "[1]");
        $writer->("[4]");
        is(scalar read_text("a.2012-12-21.log"), "[4]");
        is(scalar read_text("a.2012-12-21.log.1"), "[2][3]");
        is(scalar read_text("a.2012-12-21.log.2"), "[1]");

        $ph = set_time_to(1356090474 + 86400); # 2012-12-22 @UTC
        $writer->("[5]");
        is(scalar read_text("a.2012-12-22.log"), "[5]");
        test_gzip($get_fwr->(), ['a.2012-12-21.log', 'a.2012-12-21.log.1', 'a.2012-12-21.log.2']);
    }
);

test_filehandle_cache(
    label => "two writers, one rotates",
    new_params => [dir=>$dir, prefix=>"a"],
    code => sub {
        my ($writer, $get_fwr1) = @_;
        delete_all_files();
        my $fwr2 = File::Write::Rotate->new(dir=>$dir, prefix=>"a", size=>3);
        $writer->("[1.1]");
        is(scalar read_text("a"), "[1.1]");
        $fwr2->write("[2.1]");
        is(scalar read_text("a"), "[2.1]");
        is(scalar read_text("a.1"), "[1.1]");
        $writer->("[1.2]");
        is(scalar read_text("a"), "[2.1][1.2]");
        is(scalar read_text("a.1"), "[1.1]");
        test_gzip($get_fwr1->(), ['a.1']);
    }
);

# if FWR only rotates after second write(), then there will be cases where the
# file won't get rotated at all.
subtest "rotate on first write()" => sub {
    delete_all_files();
    write_text("$dir/a", "123");
    my $fwr = File::Write::Rotate->new(dir=>$dir, prefix=>"a", size=>3);
    $fwr->write("[1]");
    is(scalar read_text("a"), "[1]");
    is(scalar read_text("a.1"), "123");
    test_gzip($fwr, ['a.1']);
};

{
    my @got_messages = ();
    test_filehandle_cache(
        label => "hook_before_write basic",
        new_params => [dir=>$dir, prefix=>"a", hook_before_write => sub {
            my ($fwr, $msgs, $fh) = @_;
            push @got_messages, [@$msgs];
            ok((-e $fwr->lock_file_path), "lock file exists");
            print $fh "hook_before_write";
        }],
        code => sub {
            my ($writer) = @_;
            delete_all_files();
            @got_messages = ();
            $writer->("a", "b");
            is_deeply(\@got_messages, [["a", "b"]], "hook messages OK");
            is_deeply(get_file_contents(), {"a" => "hook_before_writeab"}, "content OK");
        }
    );
}

subtest "buffer (success), hook_before_write" => sub {
    delete_all_files();
    my $fwr = File::Write::Rotate->new(dir=>$dir, prefix=>"a", buffer_size=>2);
    $fwr->{hook_before_write} = sub { die };

    lives_ok { $fwr->write("[1]") } "first message to buffer";
    lives_ok { $fwr->write("[2]") } "second message to buffer";
    ok((! -e $fwr->lock_file_path), "should be unlocked");

    undef $fwr->{hook_before_write};

    $fwr->write("[3]");

    is(scalar read_text("a"), "[1][2][3]", "buffered messages gets logged");
    $fwr->write("[4]");
    is(scalar read_text("a"), "[1][2][3][4]", "buffered is emptied");
    ok((! -e $fwr->lock_file_path), "should be unlocked");
};

subtest "buffer (failed, full), buffer_size attribute" => sub {
    delete_all_files();
    my $fwr = File::Write::Rotate->new(dir=>$dir, prefix=>"a");
    $fwr->buffer_size(2);
    is($fwr->buffer_size, 2, 'buffer_size()');

    local $fwr->{hook_before_write} = sub { die };

    lives_ok  { $fwr->write("[1]") } "first message to buffer";
    ok((! -e $fwr->lock_file_path), "should be unlocked");
    lives_ok  { $fwr->write("[2]") } "second message to buffer";
    ok((! -e $fwr->lock_file_path), "should be unlocked");
    throws_ok { $fwr->write("[3]") } qr/\Q[1][2][3]\E/, "buffer is full";
    ok((! -e $fwr->lock_file_path), "should be unlocked");
};

subtest "hook_after_create" => sub {
    delete_all_files();
    my $fwr = File::Write::Rotate->new(
        dir=>$dir, prefix=>"a",
        hook_after_create => sub {
            my ($self) = @_;
            my $fh = $self->handle;
            print $fh "header\n";
        },
    );
    $fwr->write("[1]");
    is(scalar read_text("a"), "header\n[1]");
};

test_filehandle_cache(
    label => "rotate by period, daily + histories",
    new_params => [dir=>$dir, prefix=>"a", period=>"daily", histories=>2],
    code => sub {
        my ($writer) = @_;
        delete_all_files();
        my $ph;
        my $time_base = 1356090474; # 2012-12-21 @UTC
        my $DAY = 3600 * 24;
        $ph = set_time_to($time_base);
        $writer->("[1]");
        is_deeply(get_file_contents(), {"a.2012-12-21" => "[1]"}, "current file only");
        $ph = set_time_to($time_base + 1 * $DAY);
        $writer->("[2]");
        is_deeply(get_file_contents(), {"a.2012-12-21" => "[1]", "a.2012-12-22" => "[2]"}, "1 history");
        $ph = set_time_to($time_base + 2 * $DAY);
        $writer->("[3]");
        is_deeply(get_file_contents(), {"a.2012-12-21" => "[1]", "a.2012-12-22" => "[2]", "a.2012-12-23" => "[3]"},
                  "2 histories");
        $ph = set_time_to($time_base + 3 * $DAY);
        $writer->("[4]");
        is_deeply(get_file_contents(), {"a.2012-12-22" => "[2]", "a.2012-12-23" => "[3]", "a.2012-12-24" => "[4]"},
                  "2 histories (deleted)");
    }
);


test_filehandle_cache(
    label => "rotate by size + histories",
    new_params => [dir=>$dir, prefix=>"a", size=>3, histories=>2],
    code => sub {
        my ($writer) = @_;
        delete_all_files();
        $writer->("[1]");
        is_deeply(get_file_contents(), {"a" => "[1]"}, "current file only");
        $writer->("[2]", "[3]");
        is_deeply(get_file_contents(), {"a" => "[2][3]", "a.1" => "[1]"}, "1 history (rotated)");
        $writer->("[4][5]");
        is_deeply(get_file_contents(), {"a" => "[4][5]", "a.1" => "[2][3]", "a.2" => "[1]"},
                  "2 histories (rotated)");
        $writer->("[6]");
        is_deeply(get_file_contents(), {"a" => "[6]", "a.1" => "[4][5]", "a.2" => "[2][3]"},
                  "2 histories (rotated and deleted)");
    }
);

test_filehandle_cache(
    label => "rotate by size + period + histories",
    new_params => [dir=>$dir, prefix=>"a", period=>"daily", size=>3, histories=>3],
    code => sub {
        my ($writer) = @_;
        delete_all_files();
        my $ph;
        my $time_base = 1356090474; # 2012-12-21 @UTC
        my $DAY = 3600 * 24;
        $ph = set_time_to($time_base);
        $writer->("[1]");
        is_deeply(get_file_contents(), {"a.2012-12-21" => "[1]"});
        $writer->("[2]");
        is_deeply(get_file_contents(), {"a.2012-12-21.1" => "[1]", "a.2012-12-21" => "[2]"});
        $ph = set_time_to($time_base + 1 * $DAY);
        $writer->("[3]");
        is_deeply(get_file_contents(), {"a.2012-12-21.1" => "[1]", "a.2012-12-21" => "[2]", "a.2012-12-22" => "[3]"});
        $writer->("[4]");
        is_deeply(get_file_contents(),
                  {"a.2012-12-21.1" => "[1]", "a.2012-12-21" => "[2]", "a.2012-12-22.1" => "[3]", "a.2012-12-22" => "[4]"},
                  "rotate 2012-12-22 but NOT 2012-12-21");
        $writer->("[5]");
        is_deeply(get_file_contents(),
                  {"a.2012-12-21" => "[2]", "a.2012-12-22.2" => "[3]", "a.2012-12-22.1" => "[4]", "a.2012-12-22" => "[5]"},
                  "delete [1] as a result of rotating at 2012-12-22");
        $ph = set_time_to($time_base + 2 * $DAY);
        $writer->("[6]");
        is_deeply(get_file_contents(),
                  {"a.2012-12-22.2" => "[3]", "a.2012-12-22.1" => "[4]", "a.2012-12-22" => "[5]", "a.2012-12-23" => "[6]"},
                  "delete [2] as a result of entering the new period");
        $writer->("[7");
        is_deeply(get_file_contents(),
                  {"a.2012-12-22.1" => "[4]", "a.2012-12-22" => "[5]", "a.2012-12-23.1" => "[6]", "a.2012-12-23" => "[7"});
        $writer->("]");
        is_deeply(get_file_contents(),
                  {"a.2012-12-22.1" => "[4]", "a.2012-12-22" => "[5]", "a.2012-12-23.1" => "[6]", "a.2012-12-23" => "[7]"},
                  "not rotating because it's within the size limite");
    }
);

DONE_TESTING:
done_testing;

if (Test::More->builder->is_passing) {
    $CWD = "/";
} else {
    diag "there are failing tests, not deleting test data dir $dir";
}

sub delete_all_files {
    # remove all files first
    opendir my($dh), ".";
    while (my $e = readdir($dh)) {
        next if $e eq '.' || $e eq '..';
        remove_tree($e);
    }
}

sub get_files {
    opendir my $dh, ".";
    return [grep {$_ ne '.' && $_ ne '..'} readdir $dh];
}

sub list_files {
    diag explain get_files();
}

sub get_file_contents {
    my $files = get_files();
    return { map { $_ => scalar read_text($_) } @$files };
}

our $Time;
sub _time() { $Time }

sub set_time_to {
    $Time = shift;
    my $ph = patch_package("File::Write::Rotate", 'time', 'replace', \&_time);
    return $ph;
}

sub test_gzip {

    my $fwr = shift;
    my $files_ref = shift;
    my @sizes;

    for my $filename(@{$files_ref}) {
        push(@sizes, (-s $filename));
    }

    my $ret = $fwr->compress;
    ok($ret, 'compress method returns true') or return;

    my $counter = 0;
    for my $filename(@{$files_ref}) {
        my $orig_size = $sizes[$counter];
        $counter++;
        my $new_file = $filename . '.gz';
        ok( (-s $new_file), "rotated file $filename was compressed to $new_file"); #1
        ok(!(-e $filename), "original $filename is deleted"); #2
    }
}

sub test_filehandle_cache {
    my (%args) = @_;
    my $label_base = $args{label};
    my $new_params_ref = $args{new_params};
    my $code = $args{code};
    subtest "Filehandle cached: $label_base", sub {
        my $fwr = File::Write::Rotate->new(@$new_params_ref);
        my $get_fwr = sub { $fwr };
        my $writer = sub {
            $fwr->write(@_);
            ok((! -e $fwr->lock_file_path), "should be unlocked");
        };
        $code->($writer, $get_fwr);
    };
    subtest "Filehandle not cached: $label_base", sub {
        my $get_fwr = sub { File::Write::Rotate->new(@$new_params_ref) };
        my $writer = sub {
            my $fwr = $get_fwr->();
            $fwr->write(@_);
            ok((! -e $fwr->lock_file_path), "should be unlocked");
        };
        $code->($writer, $get_fwr);
    };
}
