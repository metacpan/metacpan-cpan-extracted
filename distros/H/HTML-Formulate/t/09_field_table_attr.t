# Testing per-field table attributes

use Test::More tests => 5;
BEGIN { use_ok( HTML::Formulate ) }
use strict;

# Load result strings
my $test = 't09';
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

# Standard fields
$form = $f->render($d, {
  submit => [ qw(save cancel) ],
  field_attr => {
    emp_name => {
      tr => { class => 'tr_class' },
      th => { class => 'th_class' },
      td => { class => 'td_class' },
      td_error => { class => 'td_error_class' },
    },
  },
  errors => {
    emp_name => "Fred rhymes with someone else's username",
    emp_title => "CEO's are not permitted on this forum",
  },
  errors_where => 'column',
});
report $form, "standard1";
is($form, $result{standard1}, "standard field");

# Submit buttons
$form = $f->render($d, {
  submit => [ qw(save cancel) ],
  field_attr => {
    -submit => { 
      name => 'op',
      tr => { class => 'tr_class' },
      th => { class => 'th_class' },
      td => { class => 'td_class' },
      td_error => { class => 'td_error_class' },
    },
  },
});
report $form, "submit1";
is($form, $result{submit1}, "submit buttons");

# Code tr
$form = $f->render($d, {
  submit => [ qw(save cancel) ],
  tr => {
    class => 'tr_class',
    id => sub {
      my $r = shift;
      my $name = lc $r->[0];
      $name =~ s/\s+/_/g;
      return "row_$name";
    },
  },
});
report $form, "tr_code";
is($form, $result{tr_code}, "code tr elt");

# Code tr 2
$form = $f->render($d, {
  submit => [ qw(save cancel) ],
  tr => {
    class => sub {
      my ($r, $d) = @_;
      return unless $d;
      my $data = $d->[0];
      return "class_$data->{emp_id}";
    },  
    id => sub {
      my ($r, $d) = @_;
      my $name = lc $r->[0];
      $name =~ s/\s+/_/g;
      return "row_$name";
    },
  },
});
report $form, "tr_code_2";
is($form, $result{tr_code_2}, "code tr elt 2");

