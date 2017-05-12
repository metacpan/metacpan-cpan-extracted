# field attribute merge and inheritance testing

use strict;
use Test::More tests => 5;
use Data::Dumper;
use FindBin qw($Bin);
BEGIN { use_ok( 'HTML::Tabulate' ) }

# Load result strings
my %result = ();
my $test = "$Bin/t4";
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

# Setup an initial defn
my $t = HTML::Tabulate->new({ 
  field_attr => {
    -defaults => {
      format => sub { uc(shift) },
      align => 'center',
    },
    emp_id => {
      format => "%07d",
    },
  },
});

# Test
my $defn = $t->defn;
ok(ref $defn->{field_attr}, "defn field_attr defined");
ok(ref $defn->{field_attr}->{-defaults} eq 'HASH', "defn -defaults defined");
ok(ref $defn->{field_attr}->{emp_id} eq 'HASH', "defn emp_id defined");

# Render
my $data = [ [ '123', 'Fred Flintstone', 'CEO' ], 
             [ '456', 'Barney Rubble', 'Lackey' ] ];
my $table = $t->render($data, {
  fields => [ qw(emp_id emp_name emp_title) ],
  field_attr => {
    emp_id => {
      link => "emp.html?id=%s",
    },
    emp_name => {
      format => sub { ucfirst(shift) },
    },
    emp_title => {
      align => 'left',
    },
  },
});
# print $table, "\n";
is($table, $result{render1}, "render1 result ok");

