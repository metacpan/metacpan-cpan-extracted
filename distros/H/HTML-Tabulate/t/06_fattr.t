# field attribute testing

use Test::More tests => 3;
use strict;
use HTML::Tabulate qw(render);
use Data::Dumper;
use FindBin qw($Bin);

# Load result strings
my %result = ();
my $test = "$Bin/t6";
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

my $print = shift @ARGV || 0;
my $n = 1;
sub report {
  my ($data, $file, $inc) = @_;
  $inc ||= 1;
  if ($print == $n) {
    print STDERR "--> $file\n";
    print $data;
    exit 0;
  }
  $n += $inc;
}

# Procedural render
my $data = [ [ '123', 'Fred Flintstone', 'CEO', '19710430', ], 
             [ '456', 'Barney Rubble', 'Lackey', '19751212', ] ];
my $table = render($data, {
  fields => [ qw(emp_id emp_name emp_title dob emp_fname emp_surname) ],
  labels => {
    emp_name => 'Fullname',
    emp_title => 'Title',
  },
  field_attr => {
    -defaults => { 
      align => 'left',
    },
    emp_id => {
      format => '%07d',
      link => "emp.html?id=%s&src=a b c",
      label_link => "http://www.openfusion.com.au/t/this.html?order=emp_id desc",
      align => 'center',
    },
    emp_name => {
      format => sub { uc(shift) },
    },
    dob => {
      format => sub { my $x = shift; sprintf "%02d/%02d/%02d", 
        substr($x,6,2), substr($x,4,2), substr($x,0,4) },
      label => 'Date Of Birth',
    },
    emp_fname => {
      value => sub { 
        my ($x,$rec) = @_; 
        my $name = $rec->[1]; 
        $name =~ s/\s+\S+\s*$//;
        $name
      },
      label => 'First Names',
    },
    emp_surname => {
      value => sub { 
        my ($x,$rec) = @_; 
        my $name = $rec->[1]; 
        $name =~ s/^.*?(\S+)\s*$/$1/;
        $name
      },
      format => sub { uc(shift) },
    },
  },
});
report $table, "render1";
is($table, $result{render1}, "render1 result ok");


# Regex field attributes
my $t = HTML::Tabulate->new({
  field_attr => {
    -defaults => {
      align => 'center',
    },
    # Timestamps
    qr/_ts$/i => {
      format => sub { $_ = shift; s/^\s*(\d{4})(\d{2})(\d{2}).*$/$1-$2-$3/; $_ },
      label => sub { 
        $_ = shift; 
        s/^[^_]+_//; 
        s/_[^_]+$/ed/; 
        s/eed$/ed/;
        s/yed$/ied/;
        ucfirst $_ 
      },
      class => 'timestamp',
    },
    # UIDs
    qr/_uid$/i => {
      format => "U%05d",
      label => sub { $_ = shift; s/_([^_]+)$/ \U$1/; s/^.*_(\w+)/\u$1/; $_ },
      class => 'uid',
    },
  },
});
$data = [
  { prod_id => 12345, prod_name => 'Foo', 
    prod_create_uid => 3, prod_create_ts => '20031015114902', },
];
$table = $t->render($data, {
  fields => [ qw(prod_id prod_name prod_create_uid prod_create_ts) ],
  labels => 1,
  field_attr => {
    prod_create_ts => {
      class => 'prod_create_ts',
    },
  },
});
report $table, "render2";
is($table, $result{render2}, "render2 result ok");


# Test merge order
$t = HTML::Tabulate->new({
  field_attr => {
    -defaults => { class => 'default' },
    qr/create/ => { class => 'create' },
    prod_create_ts => { class => 'prod_create_ts' },
  },
});
$table = $t->render($data, {
  fields => [ qw(prod_id prod_name prod_create_uid prod_create_ts) ],
  labels => 1,
});
report $table, "render3";
is($table, $result{render3}, "render3 result ok");

