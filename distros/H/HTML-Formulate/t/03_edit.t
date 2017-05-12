# Edit form testing

use Test::More tests => 14;
BEGIN { use_ok( HTML::Formulate ) }
use strict;

# Load result strings
my $test = 't03';
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

my ($f, $form);

# Simple employee create form
$f = HTML::Formulate->new({
     fields => [ qw(firstname surname email position) ],
     required => [ qw(firstname surname) ],
});
$form = $f->render;
report $form, "simple1";
is($form, $result{simple1}, "simple employee create");

my $d = { emp_id => '123', emp_name => 'Fred Flintstone', 
  emp_title => 'CEO', emp_addr_id => '225', emp_birth_dt => '20-10-55',
  emp_notes => qq(Started with company in 1983.\nFavourite colour: "green".\nFavourite tag: <input>.\n),
  emp_modify_uid => 12, emp_modify_ts => 20031231, 
  emp_create_uid => 6,  emp_create_ts => 20020804,
};

# Simple employee edit form
$f = HTML::Formulate->new({
  fields => [ qw(emp_id emp_name emp_title emp_birth_dt) ],
  required => [ qw(emp_name) ],
  field_attr => {
    emp_id => { type => 'hidden' },
  },
});
$form = $f->render($d);
report $form, "simple2";
is($form, $result{simple2}, "simple employee edit");

# Submit buttons
$f = HTML::Formulate->new({
  fields => [ qw(emp_id emp_name emp_title) ],
  field_attr => {
    emp_id => { type => 'static' },
  },
});
$form = $f->render($d, {
  submit => [ qw(save cancel) ],
  field_attr => {
    emp_id => { type => 'static', vlabel => 'E%05d' },
  },
});
report $form, "submit1";
is($form, $result{submit1}, "submit buttons 1, scalar vlabel");

$form = $f->render($d, {
  submit => [ qw(save cancel) ],
  field_attr => {
    emp_id => { type => 'static', vlabel => sub { sprintf 'E%05d', shift } },
  },
});
report $form, "submit1";
is($form, $result{submit1}, "submit buttons 1, sub vlabel");

$form = $f->render($d, {
  submit => [ qw(save cancel) ],
  field_attr => {
    -submit => { name => 'op' },
  },
});
report $form, "submit2";
is($form, $result{submit2}, "submit buttons 2");

# Select list
$form = $f->render($d, {
  fields => [ qw(emp_id emp_salutation emp_name emp_title) ],
  field_attr => {
    emp_id => { type => 'hidden' },
    emp_salutation => {
      type => 'select',
      values => [ qw(NONE Mr Ms Mrs Miss Dr Sir Prof) ],
      vlabels => { NONE => 'None', Prof => 'Professor' },
    },
  },
});
report $form, "select";
is($form, $result{select}, "select list");

# Change password form
my $f2 = HTML::Formulate->new({
  fields => [ qw(username password pass_confirm) ],
  submit => [ qw(save cancel) ],
  field_attr => {
    qr/^pass/ => { type => 'password' },
  },
});
$form = $f2->render({});
report $form, "password";
is($form, $result{password}, "password form");

# Hidden hashref
$form = $f->render($d, {
  fields => [ qw(emp_id emp_name emp_title emp_birth_dt) ],
  hidden => { abc => 123, def => 456, ghi => 789, 
    emp_modify_ts => '', emp_title => 'Flunky' },
  field_attr => { 
    emp_birth_dt => { type => 'hidden' },
  },
});
report $form, "hidden";
is($form, $result{hidden}, "hidden hashref");

# Hidden arrayref
$form = $f->render($d, {
  fields => [ qw(emp_id emp_name emp_title emp_birth_dt) ],
  hidden => [ qw(abc def ghi emp_title) ],
  field_attr => { 
    emp_birth_dt => { type => 'hidden' },
    abc => { value => 345 },
  },
});
report $form, "hidden2";
is($form, $result{hidden2}, "hidden arrayref");

# Input field attributes
$form = $f->render($d, {
  fields => [ qw(emp_id emp_name emp_birth_dt) ],
  field_attr => {
    -defaults => { size => 40, maxlength => 40 },
    emp_name => { size => 60, maxlength => 100, class => 'td_class', input_class => 'input_class' },
  },
});
report $form, "input_attr";
is($form, $result{input_attr}, "input attributes");

# Textarea
$form = $f->render($d, {
  fields => [ qw(emp_id emp_name emp_notes) ],
  field_attr => {
    emp_notes => { type => 'textarea', rows => 10, cols => 60, wrap => 'virtual' },
  },
});
report $form, "textarea";
is($form, $result{textarea}, "textarea");

# Custom values
$form = $f->render($d, {
  fields => [ qw(emp_id emp_name emp_birth_dt) ],
  field_attr => {
    emp_birth_dt => {
      type => 'display',
      value => "<!-- Foobar -->Arbitrary string/widget/code",
      escape => 0,
    },
  },
});
report $form, "custom";
is($form, $result{custom}, "custom field values");

# Omit fields
$form = $f->render($d, {
  fields => [ qw(emp_id emp_name emp_birth_dt) ],
  field_attr => {
    emp_birth_dt => {
      type => 'omit',
      value => "<!-- Foobar -->Arbitrary string/widget/code",
      escape => 0,
    },
  },
});
report $form, "omit";
is($form, $result{omit}, "omit fields");


