# -*- perl -*-
# If a script exits successfully, with no write error,
# make sure File::Coda doesn't change anything.

(my $ME = $0) =~ s|.*/||;

use Test::More;
use File::Temp 'tmpnam';
use POSIX qw(locale_h);

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

my $out = "out-$$";

plan tests => 4;

{
    local %ENV =
      (
       (map { $_ => $ENV{$_} || 'undef' } qw(HOME PATH LOGNAME USER SHELL)),
      );

    system "$script_name > $out 2> $err_output";
}

my $exit_status = $? >> 8;
is $exit_status, 0, 'exit code of sample script';

# Expect the err-output file to be empty.
ok -z $err_output, 'no output to stderr';

my $line;
ok open (F, '<', $out)
  && (($line = <F>), 1) && defined $line && $line eq 'anything',
  "failed to open output file, $out, $!";
close F;
ok `cat $out` eq 'anything', 'unexpected stdout';

END { unlink $out; }
