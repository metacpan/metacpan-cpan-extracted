# style 'across' testing

use strict;
use Test::More tests => 3;
use Data::Dumper;
use FindBin qw($Bin);
BEGIN { use_ok( 'HTML::Tabulate' ) }

# Load result strings
my %result = ();
my $test = "$Bin/t8";
die "missing data dir $test" unless -d $test;
opendir my $datadir, $test or die "can't open directory $test";
for (readdir $datadir) {
  next if m/^\./;
  open my $fh, "<$test/$_" or die "can't read $test/$_";
  { 
    local $/ = undef;
    $result{$_} = <$fh>;
  }
  close $fh;
}
close $datadir;

# Standard (style => 'down')
my $t = HTML::Tabulate->new({
  table => { align => 'center' },
  thtr => { class => 'thtr' },
  tr => { class => 'tr' },
  th => { align => 'center' },
  stripe => '#cccccc',
  labels => 1,
});
my $data = [ [ '123', 'Fred Flintstone', 'CEO', '19710430', ], 
             [ '456', 'Barney Rubble', 'Lackey', '19751212', ],
             [ '789', 'Dino', 'Pet', '19950906', ] ];
my $table;
$table = $t->render($data, {
  fields => [ qw(emp_id emp_name emp_title birth_dt) ],
});
is($table, $result{down}, "result down ok");
# print $table, "\n";

$table = $t->render($data, {
  fields => [ qw(emp_id emp_name emp_title birth_dt) ],
  style => 'across',
});
is($table, $result{across}, "result across ok");
print $table, "\n";

