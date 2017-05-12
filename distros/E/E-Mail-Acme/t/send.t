use strict;

use Test::More;

my $have_prereqs = eval { require File::Temp; require File::Spec; 1; };

plan skip_all => 'Cannot run this test unless current perl is -x' unless -x $^X;
plan skip_all => 'Win32 does not understand shebang' if $^O eq 'MSWin32';

plan skip_all => 'Cannot run this test without File::Temp and File::Spec'
  unless $have_prereqs;

plan tests => 2;

use E'Mail::Acme;#'

my $e_mail = E'Mail::Acme;#'

$e_mail->{from} = 'rjbs@example.org';
$e_mail->{to}   = 'rjbs@example.com';
push @$e_mail,  "Dear so-and-so,"
             ,  ""
             ,  "SENDMAILED!!",
             ,  ""
             ,  "Love,"
             ,  "The Ugly One"
             ;

my $tempdir = File::Temp::tempdir(DIR => 't', CLEANUP => 1);

my $error = "can't prepare executable test script: ";

my $filename = File::Spec->catfile($tempdir, "sendmail");
open FH, ">$filename" or skip "$error$!", 1;

print FH "#!$^X\n" or skip "$error$!", 1;
print FH <DATA>    or skip "$error$!", 1;
close FH           or skip "$error$!", 1;

chmod 0755, $filename;

$e_mail->($filename);

ok(-e "sendmail.log", "we created a sendmail log");

ok(-s "sendmail.log" >= length "$e_mail", "it's at least as big as the input");

__DATA__
my $input = join '', <STDIN>;

unlink 'sendmail.log' if -f 'sendmail.log';

open my $fh, '>sendmail.log'
  or die 'Cannot write to sendmail.log';

print $fh "CLI args: @ARGV\n";
if ( defined $input && length $input ) {
  print $fh "Executed with input on STDIN\n$input";
}
else {
  print $fh "Executed with no input on STDIN\n";
}
