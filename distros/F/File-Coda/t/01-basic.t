# -*- perl -*-
# Ensure that the write error is reported.
(my $ME = $0) =~ s|.*/||;

use Test::More;
use File::Temp 'tmpnam';
use Errno;
use POSIX qw(strerror locale_h);

umask 077;

$ENV{LC_ALL} = 'C'; # Make the script we'll exec print diagnostics in English.
setlocale LC_ALL, 'C' or die "$ME: failed to set locale: $!\n";

my ($script_fh, $script_name) = tmpnam;
my $err_output = tmpnam;

printf $script_fh <<'-', $^X;
#!%s -Tw -Iblib/lib
use File::Coda;
print 'anything';
-
close $script_fh
  or die "$ME: $script_name: write failed: $!\n";
chmod 500 => $script_name;

my @expect =
  ('ME: closing standard output: ' . strerror(&Errno::EBADF) ."\n",
   'ME: closing standard output: ' . strerror(&Errno::ENOSPC) ."\n");

my $have_dev_full = -w '/dev/full';
$have_dev_full
  or @expect = grep { !/No space/ } @expect;

system (': >&-') == 0
  or plan skip_all => 'you lack a POSIX shell';

plan tests => 1 + @expect;

{
    local %ENV =
      (
       (map { $_ => $ENV{$_} || 'undef' } qw(HOME PATH LOGNAME USER SHELL)),
      );

    system "$script_name >&-               2> $err_output";
    $have_dev_full
      and system "$script_name > /dev/full 2>> $err_output";
}

my $exit_status = $? >> 8;
is $exit_status, 1, 'exit code of sample script';

my $i = 0;
open ERROR, '<', $err_output;
while (@expect && defined (my $line = <ERROR>)) {
    chomp $line;

    # What we expect to see, (from below).
    my $expect = shift @expect;
    chomp $expect;
    $line =~ s!^.*?:!ME:!;
    $line =~ s,: &Errno::EBADF$,: EBADF,;
    $line =~ s,: &Errno::ENOSPC$,: ENOSPC,;

    # Generate a description of this test
    my $desc = "stderr line " . ++$i;

    like $line, qr/^$expect$/, $desc;
}
close ERROR;

unlink $script_name, $err_output;
