# Miscellaneous label tests

use Test::More tests => 8;
BEGIN { use_ok( HTML::Formulate ) }
use strict;

# Load result strings
my $test = 't14';
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

# No labels
$form = $f->render($d, {
  fields => [ qw(emp_id emp_name emp_title) ],
  labels => 0,
});
report $form, "nolabels";
is($form, $result{nolabels}, "no labels");

# Auto labels
$form = $f->render($d, {
  fields => [ qw(emp_id emp_name emp_title) ],
});
report $form, "auto";
is($form, $result{auto}, "auto labels");

# Explicit label hash
$form = $f->render($d, {
  fields => [ qw(emp_id emp_name emp_title emp_birth_dt) ],
  labels => {
    emp_name => 'Name',
    emp_title => 'Title',
    emp_birth_dt => 'Birth Date',
    submit => 'Save',
  },
});
report $form, "explicit";
is($form, $result{explicit}, "label hash");

# Explicit label attributes
$form = $f->render($d, {
  fields => [ qw(emp_id emp_name emp_title emp_birth_dt) ],
  field_attr => {
    emp_name => { label => 'Name' },
    emp_title => { label => 'Title' },
    emp_birth_dt => { label => 'Birth Date' },
    submit => { label => 'Save' },
  },
});
report $form, "explicit";
is($form, $result{explicit}, "label attributes");

# Explicit label attributes II
$form = $f->render($d, {
  fields => [ qw(emp_id emp_name emp_title emp_birth_dt) ],
  field_attr => {
    emp_name => { label => 'Name' },
    emp_title => { label => 'Title' },
    emp_birth_dt => { label => 'Birth Date' },
    submit => { value => 'Save' },
  },
});
report $form, "explicit";
is($form, $result{explicit}, "label attributes II");

# Empty labels 
$form = $f->render($d, {
  fields => [ qw(emp_cancel_b emp_id emp_name emp_title) ],
  labels => { emp_cancel_b => '' },
  field_attr => { 
    emp_cancel_b => {
      type => 'checkbox',
      align => 'right',
    },
  },
});
report $form, "empty";
is($form, $result{empty}, "empty label (hash)");

# Empty labels II
$form = $f->render($d, {
  fields => [ qw(emp_cancel_b emp_id emp_name emp_title) ],
  field_attr => { 
    emp_cancel_b => {
      label => '',
      type => 'checkbox',
      align => 'right',
    },
  },
});
report $form, "empty";
is($form, $result{empty}, "empty label (attribute)");

# arch-tag: 13befbec-00fa-47bc-9b5f-00b01589e598

