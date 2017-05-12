# 'errors' presentation tests

use Test::More tests => 13;
BEGIN { use_ok( HTML::Formulate ) }
use strict;

# Load result strings
my $test = 't06';
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
  emp_title => 'CEO', addr_id => '225', emp_birth_dt => '20-10-55',
  emp_salutation => 'Sir' };
# Add some base link arguments e.g for a Tabulate table
my $f = HTML::Formulate->new({
  fields => [ qw(emp_id emp_name emp_title emp_birth_dt) ],
  field_attr => {
    emp_id => { type => 'hidden' },
  },
  errors => {
    emp_name => 'Fred Flintstone is a stupid name',
    emp_birth_dt => 'People born in October are not accepted here',
  },
});

# Default errors formatting
my $form = $f->render($d);
report $form, "errors_default";
is($form, $result{errors_default}, "default error formatting");

# Explicit top errors formatting
$form = $f->render($d, {
  title => 'Title here',
  text => 'Text here',
  errors_where => 'top',
});
report $form, "errors_top1";
is($form, $result{errors_top1}, "explicit top with title and text");

# Default column errors formatting
$form = $f->render($d, {
  errors_where => 'column',
});
report $form, "errors_col_default";
is($form, $result{errors_col_default}, "default column error formatting");

# Explicit column errors formatting
$form = $f->render($d, {
  errors_where => 'column',
  field_attr => {
    -errors => { 
      th => { style => 'font-weight:bold' },
      label_format => '<span class="green">%s</span>',
      td_error => { class => 'red' },
    },
  },
});
report $form, "errors_col1";
is($form, $result{errors_col1}, "explicit column error formatting");

# Empty error hash
$f = HTML::Formulate->new({
  fields => [ qw(emp_id emp_name emp_title emp_birth_dt) ],
  field_attr => {
    emp_id => { type => 'hidden' },
  },
});
$form = $f->render($d, {
  errors => {},
});
report $form, "no_errors";
is($form, $result{no_errors}, "empty error hash");

# Bad errors arg
ok(! defined eval { $form = $f->render($d, { errors => [] }) }, 
  "die on bad errors arg");

# sprintf-formatted errors, top
$form = $f->render($d, {
  errors => {
    emp_name => '%s is an invalid value',
    emp_birth_dt => '%s is missing',  
  },
  errors_where => 'top',
});
report $form, "errors_sprintf_top";
is($form, $result{errors_sprintf_top}, "sprintf-formatted errors, top");

# sprintf-formatted errors, column
$form = $f->render($d, {
  errors => {
    emp_name => '%s is an invalid value',
    emp_birth_dt => '%s is missing',  
  },
  errors_where => 'column',
});
report $form, "errors_sprintf_column";
is($form, $result{errors_sprintf_column}, "sprintf-formatted errors, column");

# scalar errors_format 
$form = $f->render($d, {
  errors => {
    emp_name => '%s is an invalid value',
    emp_birth_dt => '%s is missing',  
  },
  errors_format => qq(<p class="big_bad_error">%s</p>\n),
});
report $form, "errors_format_scalar";
is($form, $result{errors_format_scalar}, "scalar errors_format");

# sub errors_format 
$form = $f->render($d, {
  errors => {
    emp_name => '%s is an invalid value',
    emp_birth_dt => '%s is missing',  
  },
  errors_format => sub {
    return qq(<p class="big_bad_errors">\n<font size="-1">) .
      join(qq(</font><br />\n<font size="-1">), @_) .
      qq(</font>\n</p>\n);
  },
});
report $form, "errors_format_sub";
is($form, $result{errors_format_sub}, "sub errors_format");

# multiple errors per field
$form = $f->render($d, {
  errors => {
    emp_name => [ '%s is an invalid value', '%s is not unique' ],
    emp_birth_dt => [ '%s is missing', ],
  },
});
report $form, "errors_multifield_top";
is($form, $result{errors_multifield_top}, "multiple errors per field, top");

# multiple errors per field
$form = $f->render($d, {
  errors => {
    emp_name => [ '%s is an invalid value', '%s is not unique' ],
    emp_birth_dt => [ '%s is missing', ],
  },
  errors_where => 'column',
});
report $form, "errors_multifield_column";
is($form, $result{errors_multifield_column}, "multiple errors per field, column");


# arch-tag: d2df4fa0-016f-4a24-893f-05c67f9b469c
