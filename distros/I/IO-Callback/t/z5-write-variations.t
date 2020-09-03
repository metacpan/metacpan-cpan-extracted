# IO::Callback 1.08 t/z5-write-variations.t
# Try many combinations of write operations on an IO::Callback, checking that each
# gives exactly the same results as Perl does for a real file.

use strict;
use warnings;

use Test::More;

BEGIN {
    # On some systems this test can take hours, I suspect sync on file
    # close.
    if ($ENV{EXTENDED_TESTING}) {
        plan 'no_plan';
    }
    else {
        plan skip_all => 'EXTENDED_TESTING environment variable not set';
    }

}

require Test::NoWarnings;
our $test_nowarnings_hook = $SIG{__WARN__};
$SIG{__WARN__} = sub {
    my $warning = shift;
    return if $] < 5.008 and $warning =~ /Use of uninitialized value in scalar assignment/;
    $test_nowarnings_hook->($warning);
};

use IO::Callback;
use IO::Handle;
use File::Temp qw/tempdir/;
use Fcntl 'SEEK_CUR';
use File::Slurp;
use Fatal qw/open close/;

our $test_write_dest;
our %tell_result_sequence;
our $failure_message;
our $test_srccode;

our $tmpfile = tempdir(CLEANUP => 1) . "/testfile";

our $tests_started_at = time();

our $use_syswrite;
foreach $use_syswrite (0, 1) {
    my @writecode = build_write_code($use_syswrite);
    foreach my $writecode1 (@writecode) {
        foreach my $writecode2 (@writecode) {
            run_test($writecode1, $writecode2);
        }
    }
}

Test::NoWarnings::had_no_warnings();
done_testing();

sub run_test {
    my (@writecode) = @_;

    $test_srccode = join "::", map {$_->{SrcCode}} @writecode;

    $. = 999999;
    my $fh = IO::Callback->new('>', \&writesub);
    local $test_write_dest = '';
    do_test_writes($fh, 1, map {$_->{CodeRef}} @writecode);
    my $got = $test_write_dest;

    if ($failure_message) {
        fail("$test_srccode test bailed: iocode write: $failure_message");
        undef $failure_message;
        return;
    }

    # Check that the results are correct by applying the same sequence of
    # writes to a real file and comparing.
    $. = 999999;
    $fh = IO::Callback->new('>', \&writesub);
    open my $ref_fh, ">", $tmpfile;
    do_test_writes($ref_fh, 0,  map {$_->{CodeRef}} @writecode);
    close $ref_fh;
    my $want = read_file $tmpfile;

    if ($failure_message) {
        fail("$test_srccode test bailed: real write: $failure_message");
        undef $failure_message;
        return;
    }

    is( $got, $want, "$test_srccode data matched real file results" );
    is( $tell_result_sequence{1}, $tell_result_sequence{0},
               "$test_srccode tell() values matched real file results" );
}

sub systell {
    my $ret = sysseek($_[0], 0, SEEK_CUR);
    return 0 if $ret eq "0 but true";
    return $ret;
}

sub do_test_writes {
    my ($fh, $is_io_coderef, @coderefs) = @_;

    # tell() won't work on the real file if I've used syswrite on it, use sysseek to emulate it in that case.
    my $mytell = $use_syswrite && ! $is_io_coderef ? \&systell : sub { tell $_[0] };

    my @tell = ($mytell->($fh));
    foreach my $code (@coderefs) {
        $code->($fh);
        push @tell, $mytell->($fh);
    }
    $tell_result_sequence{$is_io_coderef} = join ",", @tell;
}

sub writesub {
    $test_write_dest .= $_[0];
}

sub build_write_code {
    my ($use_syswrite) = @_;

    my @writecode;

    if ($use_syswrite) {
        my $writecall_template = <<'ENDCODE';
            my $wrote = eval { __WRITECALL__ };
            if ($@) {
                $failure_message = "died within test: $@";
            } elsif (not defined $wrote) {
                $failure_message = "syswrite returned undef";
            }
ENDCODE
        my @write_src_code = (
            'syswrite $fh, ""',
            'syswrite $fh, "", 0',
            'syswrite $fh, "", 0, 0',
            'syswrite $fh, "123456", 0, 5',
            'syswrite $fh, "0"',
            'syswrite $fh, "abcdefg"',
            'syswrite $fh, "ABCDEFG", 2',
            'syswrite $fh, "qwertyz", 2, 2',
            'syswrite $fh, "QWERTYZ", 0, 2',
            'syswrite $fh, "QWERTYZ", 0, -2',
            'syswrite $fh, "fobabz8", 2, -4',
        );
        foreach my $short_code (@write_src_code) {
            my $long_code = $writecall_template;
            $long_code =~ s/__WRITECALL__/$short_code/;
            push @writecode, {
                SrcCode     => $short_code,
                FullSrcCode => $long_code,
            };
        }
    } else {
        my @src_code;
        my @printf_argsets = (
            q{''},
            q{'%s', ''},
            q{'%s', 'foo'},
            q{'%s', 0},
            q{0},
        );
        foreach my $as (@printf_argsets) {
            push @src_code, "printf \$fh $as", "\$fh->printf($as)";
        }
        my @print_argsets = (
            q{''},
            q{'', ''},
            q{0},
            q{0, 0},
            q{'foo', '', 'bar'},
        );
        foreach my $ors ('undef', "''", 0, "'foo'") {
            foreach my $ofs ('undef', "''", 0, "'bar'") {
                my $prefix = "local \$\\=$ors; local \$,=$ofs;";
                foreach my $as (@print_argsets) {
                    push @src_code, "$prefix print \$fh $as", "$prefix \$fh->print($as)";
                }
            }
        }
        @writecode = map { {SrcCode => $_} } @src_code;
    }

    foreach my $wc (@writecode) {
        $wc->{FullSrcCode} ||= $wc->{SrcCode};
        my $src = "sub { my \$fh = shift; $wc->{FullSrcCode} }";
        $wc->{CodeRef} = eval $src;
        die "eval [$src]: $@" if $@;
    }

    return @writecode;
}

