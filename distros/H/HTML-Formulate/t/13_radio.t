# radio list tests

use Test::More tests => 8;
use Test::Differences;
BEGIN { use_ok( HTML::Formulate ) }
use strict;

# Load result strings
my $test = 't13';
my %result = ();
$test = "t/$test" if -d "t/$test";
die "missing data dir $test" unless -d $test;
opendir DATADIR, $test or die "can't open directory $test";
for (readdir DATADIR) {
  next if m/^\./;
  open FILE, "<$test/$_" or die "can't read $test/$_";
  { 
    local $/ = undef;
    $result{$_} = <FILE>;
  }
  close FILE;
}
close DATADIR;

my $print = shift @ARGV || 0;
my $t = 1;
sub report {
  my ($data, $file, $inc) = @_;
  $inc ||= 1;
  if ($print == $t) {
    print STDERR "--> $file\n";
    print $data;
    exit 0;
  }
  $t += $inc;
}

my $d = { emp_id => '123', emp_name => 'Fred Flintstone', 
  emp_title => 'CEO', emp_addr_id => '225', emp_birth_dt => '20-10-55',
  emp_notes => "Started with company in 1983.\nFavourite colour: green.\n",
  emp_modify_uid => 12, emp_modify_ts => 20031231, 
  emp_create_uid => 6,  emp_create_ts => 20020804,
};
my $f = HTML::Formulate->new({
  fields => [ qw(emp_id emp_name emp_title) ],
  field_attr => {
    -defaults => { size => 40, maxlength => 255 },
    emp_id => { type => 'static' },
  },
});
my $form;

# Array vlabels
$form = $f->render($d, {
  fields => [ qw(emp_id emp_name emp_division) ],
  field_attr => { 
    emp_division => {
      type => 'radio',
      values => [ qw(finance hr engineering marketing) ],
      vlabels => [ qw(Finance HR Engineering Marketing) ],
    },
  },
});
report $form, "simple1";
is($form, $result{simple1}, "arrayref vlabels");

# Hashref vlabels
$form = $f->render($d, {
  fields => [ qw(emp_id emp_name emp_division) ],
  field_attr => { 
    emp_division => {
      type => 'radio',
      values => [ qw(finance hr engineering marketing) ],
      vlabels => { 
        finance => 'Finance',
        hr => 'HR',
        engineering => 'Engineering',
        marketing => 'Marketing',
      },
    },
  },
});
report $form, "simple1";
is($form, $result{simple1}, "hashref vlabels");

# Subrefs - vlabels returns scalar
$form = $f->render($d, {
  fields => [ qw(emp_id emp_name emp_division) ],
  field_attr => { 
    emp_division => {
      type => 'radio',
      # subref values, returning arrayref
      values => sub { [ qw(one two three four five) ] },
      # subref vlabels, returning scalar
      vlabels => sub { ucfirst shift },
      size => 2,
    },
  },
});
report $form, "subrefs";
is($form, $result{subrefs}, "subrefs, scalar vlabels");

# Subrefs - vlabels returns arrayref
$form = $f->render($d, {
  fields => [ qw(emp_id emp_name emp_division) ],
  field_attr => { 
    emp_division => {
      type => 'radio',
      # subref values, returning array
      values => sub { qw(one two three four five) },
      # subref vlabels, returning arrayref
      vlabels => sub { [ qw(ABC DEF GHI JKL MNO) ] },
    },
  },
});
report $form, "subrefs2";
is($form, $result{subrefs2}, "subrefs, arrayref vlabels");

# Subrefs - vlabels returns array
$form = $f->render($d, {
  fields => [ qw(emp_id emp_name emp_division) ],
  field_attr => { 
    emp_division => {
      type => 'radio',
      # subref values, returning array
      values => sub { qw(one two three four five) },
      # subref vlabels, returning array
      vlabels => sub { qw(ABC DEF GHI JKL MNO) },
    },
  },
});
report $form, "subrefs2";
is($form, $result{subrefs2}, "subrefs, array vlabels");

# Subrefs - vlabels returns hashref
$form = $f->render($d, {
  fields => [ qw(emp_id emp_name emp_division) ],
  field_attr => { 
    emp_division => {
      type => 'radio',
      # subref values, returning arrayref
      values => sub { [ qw(one two three four five) ] },
      # subref vlabels, returning hashref
      vlabels => sub { { one => 'ABC', two => 'DEF', three => 'GHI', four => 'JKL', five => 'MNO' } },
    },
  },
});
report $form, "subrefs2";
is($form, $result{subrefs2}, "subrefs, hashref vlabels");

# Subrefs - vlabels returns hashref
$form = $f->render($d, {
  fields => [ qw(emp_id emp_name emp_division) ],
  use_name_as_id => 1,
  field_attr => { 
    emp_division => {
      type => 'radio',
      # subref values, returning arrayref
      values => sub { [ qw(one two three four five) ] },
      # subref vlabels, returning hashref
      vlabels => sub { { one => 'ABC', two => 'DEF', three => 'GHI', four => 'JKL', five => 'MNO' } },
    },
  },
});
report $form, "use_name_as_id";
is($form, $result{use_name_as_id}, "radio use_name_as_id");


