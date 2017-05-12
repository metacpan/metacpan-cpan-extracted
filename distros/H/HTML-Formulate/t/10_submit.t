# Submit location tests

use Test::More tests => 9;
BEGIN { use_ok( HTML::Formulate ) }
use strict;

# Load result strings
my $test = 't10';
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
    emp_id => { type => 'static' },
  },
});
my $form;

# Standard in-table submits
$form = $f->render($d, {
  submit => [ qw(save cancel) ],
});
report $form, "table_submits";
is($form, $result{table_submits}, "in-table submits");

# In-table submits, submit_location 'top'
$form = $f->render($d, {
  submit => [ qw(save cancel) ],
  submit_location => 'top',
});
report $form, "table_submits_top";
is($form, $result{table_submits_top}, "in-table submits, location top");

# In-table submits, submit_location 'both'
$form = $f->render($d, {
  submit => [ qw(save cancel) ],
  submit_location => 'both',
});
report $form, "table_submits_both";
is($form, $result{table_submits_both}, "in-table submits, location both");

# Out-of-table submits
$form = $f->render($d, {
  submit => [ qw(save cancel) ],
  field_attr => {
    -submit => {
      table => 0,
    },
  },
});
report $form, "external_submits";
is($form, $result{external_submits}, "external submits");

# Out-of-table submits 2
$form = $f->render($d, {
  submit => [ qw(save cancel) ],
  field_attr => {
    -submit => {
      table => 0,
      align => 'center',
      class => 'submit',
    },
  },
});
report $form, "external_submits2";
is($form, $result{external_submits2}, "external submits 2");

# Inherited attributes
$form = $f->render($d, {
  submit => [ qw(save cancel) ],
  field_attr => {
    -defaults => { size => 50, maxlength => 255 },
  },
});
report $form, "inherited_attributes";
is($form, $result{inherited_attributes}, "filter inherited attributes");

# Out-of-table submits with location 'top'
$form = $f->render($d, {
  submit => [ qw(save cancel) ],
  submit_location => 'top',
  field_attr => {
    -submit => {
      table => 0,
    },
  },
});
report $form, "external_submits_top";
is($form, $result{external_submits_top}, "external submits, location top");

# Out-of-table submits with location 'both'
$form = $f->render($d, {
  submit => [ qw(save cancel) ],
  submit_location => 'both',
  field_attr => {
    -submit => {
      table => 0,
    },
  },
});
report $form, "external_submits_both";
is($form, $result{external_submits_both}, "external submits, location both");

# arch-tag: 2ffd353c-080f-4a7d-8217-b57855e8f06d
