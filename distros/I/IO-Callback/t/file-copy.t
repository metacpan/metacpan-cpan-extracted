# IO::Callback 1.08 t/file-copy.t
# Check that IO::Callback inter-operates with File::Copy

use strict;
use warnings;

use Test::More;
BEGIN {
    eval 'use File::Copy qw/copy/';
    plan skip_all => 'File::Copy required' if $@;
    plan skip_all => 'File::Copy too old' if $File::Copy::VERSION < 2.11;

    plan tests => 8;
}
use Test::NoWarnings;

use File::Slurp;
use File::Temp qw/tempfile/;
use Fatal qw/open close unlink/;

use IO::Callback;

our $test_nowarnings_hook = $SIG{__WARN__};
$SIG{__WARN__} = sub {
    my $warning = shift;
    return if $warning =~ /stat\(\) on unopened filehandle/i;
    $test_nowarnings_hook->($warning);
};

my $test_data = "foo\n" x 100;

my $line = 0;
my $coderef_read_fh = IO::Callback->new('<', sub {
    return if $line++ >= 100;
    return "foo\n";
});

my $got_close = 0;
my $got_data = '';
my $coderef_write_fh = IO::Callback->new('>', sub {
    my $buf = shift;
    if (length $buf) {
        $got_close and die "write after close";
        $got_data .= $buf;
    } else {
        ++$got_close;
    }
});

my ($tmp_fh, $tmp_file) = tempfile();
close $tmp_fh;
unlink $tmp_file;

ok copy($coderef_read_fh, $tmp_file), "copy coderef->realfile succeeded";
my $copy_got = read_file $tmp_file;
is $copy_got, $test_data, "copy coderef->realfile copied correct data";

ok copy($tmp_file, $coderef_write_fh), "copy realfile->coderef succeeded";
close $coderef_write_fh;
is $got_close, 1, "got close on fh";
is $got_data, $test_data, "copy realfile->coderef copied correct data";

my $die_fh = IO::Callback->new('>', sub { IO::Callback::Error });
is copy($tmp_file, $die_fh), 0, "copy gets write error";

unlink $tmp_file;
$die_fh = IO::Callback->new('<', sub { IO::Callback::Error });
is copy($die_fh, $tmp_file), 0, "copy gets read error";

unlink $tmp_file;
