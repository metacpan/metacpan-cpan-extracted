
require 5;
use strict;
use Test;
BEGIN { plan tests => 16; }
BEGIN { @ARGV = qw( --crunky --glorp=Second -- ) }
use Getopt::Janus;
print "# Loaded Getopt::Janus version $Getopt::Janus::VERSION\n";


ok 1;  yes_no my $c, "--crunky", ;
ok 1;  string my $d, "-d", '--dingus', \"Title";
ok 1;  file my $e, '--eegah', "-e", \"Title", \"Description";

my $f;
ok 1;  new_file $f, "-f", '--fla123', \"Title", \"Description";
$f = "chumba\e.dat";

ok 1;  choose my $g,  '--glorp', "-g", from => ['First', 'Second' ];
ok 1;  choose my $i,  '--illbehavior', "-i", from => ['First', 'Second' ];

ok 1;  license_either;
ok 1;  note_new_files '.NO.';

ok 1;  run \&main, \"Program Title", \"A description of the program";
ok 1;  

sub main {
  print "# Starting main.\n";
  ok 1;    
  ok $c;
  ok !$d;
  ok $f, 'chumba100.dat';
    # assumes there is no chumba*.dat already in the current dir
  ok $g, "Second";
  ok $i, "First";
  
  print "# Ending main.\n";
  ok 1;
  return;
}

ok 1;

