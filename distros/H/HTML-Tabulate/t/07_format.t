# More format testing

use strict;
use Test::More tests => 1;
use FindBin qw($Bin);

use HTML::Tabulate qw(render);

# Load result strings
my %result = ();
my $test = "$Bin/t07";
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

# Test format with null data
my $t = HTML::Tabulate->new({
  fields => [ qw(id debit credit) ],
  labels => 1,
  field_attr => {
    id => {
      label => 'ID',
    },
    qr/^(credit|debit)$/ => {
      format => sub {
        my ($v, $r, $k) = @_;
        qq(<input type="text" name="$k" value="$v">);
      },
    },
    debit => {
      value => sub {
        my ($v, $r) = @_;
        return $r->{amount} >= 0 ? $r->{amount} : '';
      }
    },
    credit => {
      value => sub {
        my ($v, $r) = @_;
        return $r->{amount} < 0 ? $r->{amount} : '';
      }
    },
  },
});
my $table = $t->render([ { id => 1, amount => 1234 }, { id => 2, amount => -1234 } ]);
report $table, "render1";
is($table, $result{render1}, "render1 result ok");

