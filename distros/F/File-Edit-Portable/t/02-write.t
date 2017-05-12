#!perl
use 5.006;
use strict;
use warnings;

use Fcntl qw(:flock);
use File::Copy;
use File::Edit::Portable;
use File::Tempdir;
use Mock::Sub;
use Test::More;

my $tempdir = File::Tempdir->new;
my $tdir = $tempdir->name;
my $bdir = 't/base';

my $unix = "$bdir/unix.txt";
my $win = "$bdir/win.txt";
my $copy = "$tdir/test.txt";

{
    my $rw = File::Edit::Portable->new;

    eval { $rw->write; };
    like ($@, qr/file/, "write() croaks if no file is found");

    my @file = $rw->read($unix);

    eval { $rw->write; };
    like ($@, qr/contents/, "write() croaks if no contents are passed in");
}
{
    my $rw = File::Edit::Portable->new;

    my @file = $rw->read($unix);

    for (@file){
        /([\n\x{0B}\f\r\x{85}]{1,2}|[{utf8}2028-{utf8}2029]]{1,2})/;
        is ($1, undef, "no EOLs present after read");
    }

    for (qw(a b c d e)){
        push @file, $_;
    }

    $rw->write(copy => $copy, contents => \@file);

    my $eor = $rw->recsep($copy, 'hex');

    is ($eor, '\0a', "unix line endings were replaced properly" );
}
{
    my $rw = File::Edit::Portable->new;

    my @file = $rw->read($win);

    for (@file){
        /([\n\x{0B}\f\r\x{85}]{1,2}|[{utf8}2028-{utf8}2029]]{1,2})/;
        is ($1, undef, "no EOLs present after read");
    }

    for (qw(a b c d e)){
        push @file, $_;
    }

    $rw->write(copy => $copy, contents => \@file);

    my $eor = $rw->recsep($copy, 'hex');

    is ($eor, '\0d\0a', "win line endings were replaced properly" );
}
{
    my $rw = File::Edit::Portable->new;

    my $file = $unix;
    my $copy = "$tdir/write_fh.txt";

    my $fh = $rw->read($file);
    my @read_contents = $rw->read($file);

    $rw->write(copy => $copy, contents => $fh);

    my @write_contents = $rw->read($copy);

    my $i = 0;
    for (@read_contents){
        chomp;
        is($write_contents[$i], $_, "written line is ok when write() takes a file handle as contents");
        $i++;
    }
}
{
    my $rw = File::Edit::Portable->new;
    my $mock = Mock::Sub->new;

    my $file = $unix;
    my $copy = "$tdir/write_fh.txt";

    my $fh = $rw->read($file);

    my $recsep_sub = $mock->mock('File::Edit::Portable::recsep', return_value => 1);
    $rw->{files}{$file}{is_read} = 0;
    $rw->{files}{$file}{recsep} = 'blah';
    $rw->write(copy => $copy, contents => $fh);
 
    is($recsep_sub->called_count, 1, "recsep() is called if ! is_read");
}
{
    my $rw = File::Edit::Portable->new;
    my $mock = Mock::Sub->new;

    my $file = $unix;
    my $copy = "$tdir/write_fh.txt";

    my $fh = $rw->read($file);

    my $recsep_sub = $mock->mock('File::Edit::Portable::recsep', return_value => 1);

    $rw->{files}{$file}{recsep} = 'blah';
    $rw->write(copy => $copy, contents => $fh);

    is($recsep_sub->called_count, 0, "recsep() isn't called if is_read set");
}
SKIP: {

    skip "win32 test, but not on windows", 1 unless $^O eq 'MSWin32';

    my $rw = File::Edit::Portable->new;

    my $fh = $rw->read($unix);

    $rw->write(copy => $copy, contents => $fh, recsep => $rw->platform_recsep);

    my $eor = $rw->recsep($copy, 'hex');

    is ($eor, '\0d\0a', "platform_recsep() w/ no parameters can be used as custom recsep" );
};
SKIP: {

    skip "nix test but we're not on unix", 1 unless $^O ne 'MSWin32';

    my $rw = File::Edit::Portable->new;

    my $fh = $rw->read($unix);

    $rw->write(copy => $copy, contents => $fh, recsep => $rw->platform_recsep);

    my $eor = $rw->recsep($copy, 'hex');

    is ($eor, '\0a', "platform_recsep() w/ no parameters can be used as custom recsep" );
};
{
    my $rw = File::Edit::Portable->new;

    my @orig_contents = $rw->read($unix);
    {

        my $fh = $rw->read($unix);
        $rw->write(copy => $copy, contents => $fh);
        close $fh;

        my @copy_contents = $rw->read($copy);

        is (
            @orig_contents,
            @copy_contents,
            "file length equal when rewriting with different recsep (unix)",
        );

        my $orig_eof = $rw->recsep($unix, 'hex');
        my $copy_eof = $rw->recsep($copy, 'hex');

        is ($orig_eof, $copy_eof, "orig and copy have same eof (unix)");
    }
}
{
    my $rw = File::Edit::Portable->new;
    my @orig_contents = $rw->read($win);

    my $fh = $rw->read($win);
    $rw->write(copy => $copy, contents => $fh);
    close $fh;

    my @copy_contents = $rw->read($copy);

    is (
        @orig_contents,
        @copy_contents,
        "file length equal when rewriting with different recsep (win)",
    );

    my $orig_eof = $rw->recsep($win, 'hex');
    my $copy_eof = $rw->recsep($copy, 'hex');

    is ($orig_eof, $copy_eof, "orig and copy have same eof (win)");
};
{
    my $rw = File::Edit::Portable->new;
    my $fh = $rw->read($unix);
    $rw->write(copy => $copy, contents => $fh, recsep => "\r\n");
    close $fh;

    my $orig_eof = $rw->recsep($unix, 'hex');
    my $copy_eof = $rw->recsep($copy, 'hex');

    ok ($orig_eof ne $copy_eof, "orig and copy differ w/ recsep (unix)");

    my @orig = $rw->read($unix);
    my @copy = $rw->read($copy);

    is (@orig, @copy,
        "files contain the same num of lines with recsep (unix)");
}
{
    my $rw = File::Edit::Portable->new;
    my $fh = $rw->read($win);
    $rw->write(copy => $copy, contents => $fh, recsep => "\n");
    close $fh;

    my $orig_eof = $rw->recsep($win, 'hex');
    my $copy_eof = $rw->recsep($copy, 'hex');

    ok ($orig_eof ne $copy_eof, "orig and copy differ w/ recsep (win)");

    my @orig = $rw->read($win);
    my @copy = $rw->read($copy);

    is (@orig, @copy,
        "files contain the same num of lines with recsep (win)");
}
{
    my $rw = File::Edit::Portable->new;
    my $file = $unix;
    my $copy = "$tdir/write_bug_19.txt";

    my $fh = $rw->read($file);
    delete $rw->{file};
    eval { $rw->write(copy => $copy, contents => $fh); };

    like ($@, qr/\Qwrite() requires a file\E/, "write() croaks if not handed a file");

    $rw->{file} = $file;
    $rw->write(copy => $copy, contents => $fh, recsep => "\r");

    $fh = $rw->read($file);
    $rw->{is_read} = 0;
    $rw->write(copy => $copy, contents => $fh);

    is ($rw->recsep($copy, 'hex'), '\0a', "write() without is_read has the right recsep");

}
{
    my $rw = File::Edit::Portable->new;

    my $fh = $rw->read($win);
    my $fh2 = $rw->read($unix);

    eval { $rw->write(copy => $copy, contents => $fh); };

    like (
        $@,
        qr/\Qif calling write() with more than one read()/,
        "write() barfs if called without a file and multiple read()s open"
    );

    eval { $rw->write(file => $unix, copy => $copy, contents => $fh); };
    is ($@, '', "...but works if a file is sent in");

}
{
    my $warn;
    local $SIG{__WARN__} = sub { $warn = shift; };

    my $rw = File::Edit::Portable->new;

    my $fh = $rw->read($win);
    $rw->write(copy => $copy, contents => $fh);

    <$fh>;
    like ($warn, qr/\Qreadline() on closed\E/, "write() closes a contents \$fh");
}
{ # multiple reads()
    my $rw = File::Edit::Portable->new;

    my $fh2 = $rw->read($win);
    my $fh3 = $rw->read($unix);

    $rw->write(file => $win, copy => $copy, contents => $fh2);
    is ($rw->recsep($copy, 'type'), 'win', "with multiple read(), win is ok");
    is (defined $rw->{files}{$win}, '', "after write(), win read() disappears");
    is (defined $rw->{files}{$unix}, 1, "...and unix is still defined");

    $rw->write(file => $unix, copy => $copy, contents => $fh3);
    is ($rw->recsep($copy, 'type'), 'nix', "with multiple read(), nix is ok");
    is (defined $rw->{files}{$unix}, '', "after write(), unix read() disappears");
    is (defined $rw->{files}{$win}, '', "...and win is still disappeared");
}
{ #bug 31 - seek on closed fh
    my $rw = File::Edit::Portable->new;

    my $fh;
    $fh = $rw->read($unix);

    $rw->write(file => $unix, copy => $copy, contents => $fh);
    eval { $rw->write(file => $unix, copy => $copy, contents => $fh); };

    like ($@, qr/the file handle you're/, "bug 31 catch - die on closed fh");
}
{
    my $rw = File::Edit::Portable->new;

    my $fh = $rw->read($unix);
    my $fh2 = $rw->read($win);

    $rw->write(file => $unix, copy => $copy, contents => $fh);

    is ($rw->{reads}{count}, 2, "read count is correct");

    is (
        $rw->recsep($copy, 'type'),
        'nix',
        "with two read()s open write() works with 'file' param"
    );

    eval { $rw->write(copy => $copy, contents => $fh2); };

    like (
        $@,
        qr/if calling write/,
        "if read() has been called more than once even with only one file " .
        "still open, write() requires the 'file' param");
}

done_testing();

