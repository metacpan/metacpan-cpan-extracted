
require 5;
use strict;
use Test;
BEGIN { plan tests => 3; }
use Getopt::Janus;
print "# Loaded Getopt::Janus version $Getopt::Janus::VERSION\n";

my $x = rand(1);
ok 1;

if($x >= 0) {
  ok 1;
} else {
  ok 0;
  print "# You should never see this!!!\n";
  # We're testing the parsability of this code, NOT ITS RUNNABILITY

  my $x;

  yes_no $x, "-a", ;
  yes_no $x, "-a", \"Title";
  yes_no $x, "-a", \"Title", \"Description";
  
  string $x, "-a",;
  string $x, "-a", \"Title";
  string $x, "-a", \"Title", \"Description";
  
  file $x, "-a",;
  file $x, "-a", \"Title";
  file $x, "-a", \"Title", \"Description";
  
  new_file $x, "-a",;
  new_file $x, "-a", \"Title";
  new_file $x, "-a", \"Title", \"Description";
  
  choose $x, "-a", from => ['First', 'Second' ];
  choose $x, "-a", \"Title";
  choose $x, "-a", \"Title", \"Description";
  
  license_artistic;
  license_gnu;
  license_either;
  licence_artistic;
  licence_gnu;
  licence_either;

  license_artistic();
  license_gnu();
  license_either();
  licence_artistic();
  licence_gnu();
  licence_either();
  
  run \&main;
  
  run \&main, \"Program Title";
  
  run \&main, \"Program Title", \"A description of the program";
  
  note_new_files(  );
 
  note_new_files '.NO.';
  note_new_file;
  
}

sub main { print "# Stuff.\n"; }

ok 1;

