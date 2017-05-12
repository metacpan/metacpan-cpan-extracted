# Title testing

use Test::More tests => 8;
use HTML::Tabulate 0.21;
use Data::Dumper;
use strict;
use FindBin qw($Bin);

# Load result strings
my %result = ();
my $test = "$Bin/t13";
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

# Scalar title, vanilla formatting
$table = $t->render($data, {
  title => 'Current Employees',
});
report $table, "title1";
is($table, $result{title1}, "title scalar, no formatting");

# Hashref title, vanilla formatting
$table = $t->render($data, {
  title => { value => 'Current Employees' },
});
report $table, "title1";
is($table, $result{title1}, "title hashref, no formatting");

# Hashref title, sprintf formatting
$table = $t->render($data, {
  title => { 
    value => 'Current Employees', 
    format => qq(<h1 align="center" class="foo">%s</h1>\n),
  },
});
report $table, "title2";
is($table, $result{title2}, "title hashref, sprintf formatting");

# Hashref title, subref formatting
$table = $t->render($data, {
  title => { 
    value => 'Current Employees',
    format => sub { sprintf qq(<h1 align="center" class="foo">%s</h1>\n), shift },
  },
});
report $table, "title2";
is($table, $result{title2}, "title hashref, subref formatting");

# Hashref title, old-style formatting
$table = $t->render($data, {
  title => { title => 'Current Employees', tag => 'h1', 
    class => 'foo', align => 'center', }
});
report $table, "title2";
is($table, $result{title2}, "title hashref, old-style formatting");

# Hashref title, old-style formatting, no tag
$table = $t->render($data, {
  title => { title => 'Current Employees', class => 'label' },
});
report $table, "title3";
is($table, $result{title3}, "title hashref, old-style formatting, no tag");

# Hashref title, no value, no title
$table = $t->render($data, {
  title => { align => 'center', class => 'foo' },
});
report $table, "title4";
is($table, $result{title4}, "title hashref, no value");

# Subref title
$table = $t->render($data, {
  title => sub {
    my ($dataset, $type) = @_;
    my $title = "Current Employees";
    $title .= ' (' . scalar(@$dataset) . ')' if ref $dataset eq 'ARRAY';
    sprintf qq(<h1 align="center">%s</h1>\n), $title;
  },
});
report $table, "title5";
is($table, $result{title5}, "title subref");

