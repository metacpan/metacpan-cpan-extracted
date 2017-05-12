# 'text' testing

use Test::More tests => 6;
use HTML::Tabulate 0.20;
use Data::Dumper;
use strict;
use FindBin qw($Bin);

# Load result strings
my %result = ();
my $test = "$Bin/t14";
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

my $print = shift @ARGV || 0;
my $n = 1;
sub report {
  my ($data, $file, $inc) = @_;
  $inc ||= 1;
  if ($print == $n) {
    print STDERR "--> $file\n";
    print $data;
    exit 0;
  }
  $n += $inc;
}

my $data = [ [ '123', 'Fred Flintstone', 'CEO', '19710430', ], 
             [ '456', 'Barney Rubble', 'Lackey', '19750808', ],
             [ '789', 'Dino', 'Pet' ] ];
my $t = HTML::Tabulate->new({ 
  fields => [ qw(emp_id emp_name emp_title emp_birth_dt) ],
});
my $table;

$table = $t->render($data, {
  text => 'As at April 2004',
});
report $table, "text1";
is($table, $result{text1}, "text bare");

$table = $t->render($data, {
  text => 'As at <b>April 2004</b>',
});
report $table, "text2";
is($table, $result{text2}, "text with partial markup");

$table = $t->render($data, {
  text => '<p>As at April 2004</p>',
});
report $table, "text1";
is($table, $result{text1}, "text tag-wrapped");

$table = $t->render($data, {
  text => "As at April 2004\n(multiple lines)\nBlah blah blah",
});
report $table, "text3";
is($table, $result{text3}, "text multiline bare");

$table = $t->render($data, {
  text => "<p>As at April 2004</p>\n<p>(multiple lines)</p>\n",
});
report $table, "text4";
is($table, $result{text4}, "text multiline tag-wrapped");

$table = $t->render($data, {
  title => 'Current Employees',
  text => "<p>As at April 2004</p>\n<p>(multiple lines)</p>\n",
});
report $table, "text5";
is($table, $result{text5}, "title and text");

