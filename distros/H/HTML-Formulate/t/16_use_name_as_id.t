# Example forms from perldocs

use Test::More tests => 3;
BEGIN { use_ok( HTML::Formulate ) }
use strict;

# Load result strings
my $test = 't16';
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

# Login form
$f = HTML::Formulate->new({
  use_name_as_id => 1,
  fields => [ qw(username password) ],
  required => 'ALL',
  submit => [ qw(login) ],
  field_attr => {
    password => { type => 'password' },
  },
});
$form = $f->render;
report $form, "login";
is($form, $result{login}, "login form");

# Registration form
$f = HTML::Formulate->new({
  use_name_as_id => 1,
  fields => [ qw(firstname surname email password password_confirm) ],
  required => 'ALL',
  submit => [ qw(register) ],
  field_attr => {
    qr/^password/ => { type => 'password' },
  },
});
$form = $f->render;
report $form, "register";
is($form, $result{register}, "registration form");


