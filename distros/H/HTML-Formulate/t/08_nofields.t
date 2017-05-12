# 'fields' and 'submit' omission

use Test::More tests => 5;
BEGIN { use_ok( HTML::Formulate ) }
use strict;

# Load result strings
my $test = 't08';
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

my $f = HTML::Formulate->new({
  title => 'Warning!',
  text => 'Are you really sure you want to eat the children?',
  submit => [ qw(Yes No) ],
});

# No fields, but submit
my $form = $f->render({});
report $form, "no_fields1";
is($form, $result{no_fields1}, "no fields, submit");

# No fields, empty submit
$f = HTML::Formulate->new({
  title => 'Success!',
  text => 'Password was successfully reset',
  caption => '<p><a href="/admin/">Back</a></p>',
  submit => [],
});

$form = $f->render({});
report $form, "no_fields2";
is($form, $result{no_fields2}, "no fields, empty submit");

# No fields, false submit
$f = HTML::Formulate->new({
  title => 'Success!',
  text => 'Password was successfully reset',
  caption => '<p><a href="/admin/">Back</a></p>',
  submit => 0,
});

$form = $f->render({});
report $form, "no_fields2";
is($form, $result{no_fields2}, "no fields, false submit");

# No fields, no submit
$f = HTML::Formulate->new({
  title => 'Success!',
  text => 'Password was successfully reset',
  caption => '<p><a href="/admin/">Back</a></p>',
});

$form = $f->render({});
report $form, "no_fields2";
is($form, $result{no_fields2}, "no fields, no submit");


# arch-tag: 6c7f45ff-d6d1-45f7-b6a1-70bc69dd1d76
