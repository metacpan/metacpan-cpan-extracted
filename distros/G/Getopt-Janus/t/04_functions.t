
require 5;
use strict;
use Test;
BEGIN { plan tests => 17; }
use Getopt::Janus;
print "# Loaded Getopt::Janus version $Getopt::Janus::VERSION\n";

ok 1;
ok defined &yes_no;
ok defined &string;
ok defined &file;
ok defined &new_file;
ok defined &choose;
ok defined &license_artistic;
ok defined &license_gnu;
ok defined &license_either;
ok defined &licence_artistic;
ok defined &licence_gnu;
ok defined &licence_either;
ok defined &run;
ok defined &note_new_files;
ok defined &note_new_file;

ok 1;

foreach my $f (@Getopt::Janus::EXPORT) {
  my $x = prototype($f);
  $x = 'undef' unless defined $x;
  $x = '""' unless length $x;
  print "# Proto for $f is $x\n";
}

ok 1;

print "#Byebye\n";


