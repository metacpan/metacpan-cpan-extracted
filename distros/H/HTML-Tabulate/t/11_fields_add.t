# fields_add testing

use Test::More tests => 1;
use HTML::Tabulate 0.15;
use Data::Dumper;
use strict;
use FindBin qw($Bin);

# Load result strings
my %result = ();
my $test = "$Bin/t11";
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
             [ '456', 'Barney Rubble', 'Lackey', '19750808', ],
             [ '789', 'Dino', 'Pet' ] ];
my $t = HTML::Tabulate->new;
my $table = $t->render($data, {
  labels => 1,
  null => '-',
  fields => [ qw(emp_id emp_name emp_title emp_birth_dt emp_modify_ts emp_create_ts) ],
  fields_add => {
    emp_birth_dt => 'edit',
    emp_name => [ qw(emp_givenname emp_surname) ],
  },
  fields_omit => [ qw(emp_modify_ts emp_create_ts) ],
  field_attr => {
    emp_surname => {
      value => sub { my ($x,$r) = @_; my $name = $r->[1]; $name =~ s/^\s*\w+\s*//; $name }
    },
    emp_givenname => {
      value => sub { my ($x,$r) = @_; my $name = $r->[1]; $name =~ s/\s.*//; $name }
    },
    edit => {
      value => 'edit',
      link => sub { my ($x,$r) = @_; sprintf 'edit.html?emp_id=%s', $r->[0] },
    }
  },
});
# print $table, "\n";
is($table, $result{render1}, "render1 result ok");

