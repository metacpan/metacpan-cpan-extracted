# 'caption' testing

use Test::More tests => 11;
use HTML::Tabulate 0.26;
use Data::Dumper;
use strict;
use FindBin qw($Bin);

# Load result strings
my %result = ();
my $test = "$Bin/t15";
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
  caption => 'As at April 2004',
});
report $table, "caption1";
is($table, $result{caption1}, "(text) caption bare");

$table = $t->render($data, {
  caption => 'As at <b>April 2004</b>', 
});
report $table, "caption2";
is($table, $result{caption2}, "(text) caption with partial markup");

$table = $t->render($data, {
  caption => '<p>As at April 2004</p>',
});
report $table, "caption1";
is($table, $result{caption1}, "(text) caption tag-wrapped");

$table = $t->render($data, {
  caption => "As at April 2004\n(multiple lines)\nBlah blah blah", 
});
report $table, "caption3";
is($table, $result{caption3}, "(text) caption multiline bare");

$table = $t->render($data, {
  caption => "<p>As at April 2004</p>\n<p>(multiple lines)</p>\n", 
});
report $table, "caption4";
is($table, $result{caption4}, "(text) caption multiline tag-wrapped");

$table = $t->render($data, {
  title => 'Current Employees',
  text => "One two three four",
  caption => "<p>As at April 2004</p>\n<p>(multiple lines)</p>\n",
});
report $table, "caption5";
is($table, $result{caption5}, "(text) title, text, caption");

$table = $t->render($data, {
  caption => {
    value => 'Employee Data', 
    format => '<div class="emp_data">%s</div>',
  },
});
report $table, "caption6";
is($table, $result{caption6}, "(text) caption explicit format");

$table = $t->render($data, {
  caption => sub {
    my ($set, $type) = @_;
    my $caption = 'Employee Data';
    $caption .= ' (' . scalar(@$set) . ' records)' if ref $set eq 'ARRAY';
    sprintf '<p>%s</p>', $caption;
  }
});
report $table, "caption7";
is($table, $result{caption7}, "(text) caption subref");

$table = $t->render($data, {
  caption => {
    value => 'Employee Data',
    format => sub {
      my ($caption, $set, $type) = @_;
      $caption .= ' (' . scalar(@$set) . ' records)' if ref $set eq 'ARRAY';
      sprintf '<p>%s</p>', $caption;
    }
  }
});
report $table, "caption7";
is($table, $result{caption7}, "(text) caption format subref");


# New-style, using <caption> tag within table
$table = $t->render($data, {
  caption => { value => 'As at April 2004', type => 'caption_caption' },
});
report $table, "caption10";
is($table, $result{caption10}, "(caption) caption bare");

$table = $t->render($data, {
  caption => {
    type => 'caption_caption',
    value => 'Employee Data',
    format => sub {
      my ($caption, $set, $type) = @_;
      $caption .= ' (' . scalar(@$set) . ' records)'
      if ref $set eq 'ARRAY';
      $caption
    },
  },
});
report $table, "caption11";
is($table, $result{caption11}, "(caption) caption format subref");

