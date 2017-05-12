# 'format' tests

use Test::More tests => 3;
BEGIN { use_ok( HTML::Formulate ) }
use strict;

# Load result strings
my $test = 't11';
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

# Simple formatting on text inputs
$form = $f->render($d, {
  field_attr => { 
    emp_name => {
      format => '%s <a href="help.html#emp_name">[help]</a>',
    },
    emp_title => {
      format => '%s <a href="help.html#emp_title">[help]</a>',
    },
  },
});
report $form, "format_simple";
is($form, $result{format_simple}, "formatting with text input");

# Formatting selects
$form = $f->render($d, {
  fields => [ qw(emp_id emp_name emp_division) ],
  field_attr => { 
    emp_division => {
      type => 'select',
      values => [ '', qw(finance hr engineering marketing) ],
      vlabels => [ qw(Select Finance HR Engineering Marketing) ],
      format => '%s <input type="button" name="edit" value="Edit ..." />',
    },
  },
});
report $form, "format_select";
is($form, $result{format_select}, "formatting with select");


# arch-tag: 904d357e-8432-4aca-8eee-3db7949aa656
