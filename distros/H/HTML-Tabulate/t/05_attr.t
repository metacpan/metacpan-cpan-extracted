# attribute testing - test an example of every type of attribute argument

use Test::More tests => 5;
use HTML::Tabulate qw(render);
use Data::Dumper;
use strict;
use FindBin qw($Bin);

# Load result strings
my %result = ();
my $test = "$Bin/t5";
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

# Render1
my $data = [ [ '123', 'Fred Flintstone', 'CEO', '19710430', ], 
             [ '456', '   Barney Rubble   ', 'Lackey', '19750808', ],
             [ '789', 'Dino  ', 'Pet' ] ];
my $table = render($data, {
  table => { border => 0, class => 'table' },
  tr => { class => 'tr' },
  thtr => { class => 'thtr', bgcolor => '#000066' },
  th => { class => 'th' },
  td => { class => 'td' },
  fields => [ qw(emp_name dob emp_title emp_id) ],
  in_fields => [ qw(emp_id emp_name emp_title dob) ],
  labels => 1,
  label_links => {
    emp_id => 'edit.html?id=%s',
  },
  stripe => [ '#111111', '#222222', '#333333' ],
  null => '&nbsp;',
  trim => 1,
});
# print $table, "\n";
is($table, $result{render1}, "render1 result ok");


# Render2
$table = render($data, {
  fields => [ qw(emp_id emp_name emp_title emp_dob) ],
  table => 0,
  tr => { class => 'tr' },
  labels => 0,
  null => '-',
  stripe => { class => 'stripe' },
});
# print $table, "\n";
is($table, $result{render2}, "render2 result ok");


# Render3
$table = render($data, {
  fields => [ qw(emp_id emp_name emp_title emp_dob) ],
  labels => {
    emp_dob => 'Birth Date',
    emp_name => 'Full Name',
    emp_title => 'Title',
  },
  thtr => { class => 'stripe0' },
  stripe => [ { class => 'stripe1' }, { class => 'stripe2' } ],
});
# print $table, "\n";
is($table, $result{render3}, "render3 result ok");


# Render4 - test empty links
$table = render($data, {
  fields => [ qw(emp_id emp_name delete) ],
  field_attr => {
    delete => { 
      value => sub {
        my ($data, $row, $field) = @_;
        if (length $row->[2] <= 3) {
          return 'delete'; 
        }
      }, 
      link => sub {
        my ($data, $row, $field) = @_;
        if (length $row->[2] <= 3) {
          return "delete.html?id=" . $row->[0];
        }
      },
    },
  },
});
# print $table, "\n";
is($table, $result{render4}, "render4 result ok");


# Render 5 - mixed static and subref attributes
$table = render($data, {
  fields => [ qw(emp_id emp_name emp_title) ],
  tr => { 
    id => sub { 'tr_' . shift->[0] },
  },
  field_attr => {
    emp_title => {
      id => sub { shift; 'title_' . shift->[0] },
      class => 'title',
    },
  },
  trim => 1,
});
# print $table, "\n";
is($table, $result{render5}, "render5 result ok");

