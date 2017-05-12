# arch-tag: presentation defn merge and inheritance testing

use Test::More tests => 16;
require_ok( HTML::Tabulate );
use Data::Dumper;
use strict;

# Setup an initial defn
my $t = HTML::Tabulate->new({ 
 table => { border => 0, cellpadding => 0, cellspacing => 3 },
 th => { class => 'foobar' },
 null => '&nbsp;',
 stripe => '#dddddd',
});

my $defn = $t->defn;
ok(defined $defn->{style},              "defn style defined");
ok(ref $defn->{table} eq 'HASH',        "defn table defined");
ok(ref $defn->{table} && defined $defn->{table}->{border},        
  "defn table->{border} defined");
ok(ref $defn->{th} eq 'HASH',           "defn th defined");
ok(defined $defn->{null},               "defn null defined");
ok(defined $defn->{stripe},             "defn strip defined");

# Merge some additional defns
$t->merge({
  table => { align => 'center', cellpadding => 3 },
  labels => 0,
  thtr => { class => 'merge' },
});

$defn = $t->defn;
ok(ref $defn->{table} && $defn->{table}->{align} eq 'center',        
  "defn table->align merged");
ok(ref $defn->{table} && $defn->{table}->{cellpadding} == 3,
  "defn table->cellpadding merged");
ok(defined $defn->{labels}, "defn table->{labels} merged");
ok(ref $defn->{thtr}, "defn table->{thtr} merged");

# Do a render with additional defns
my $data = [
  [ qw(one two three four) ],
  [ qw(a b c d) ],
];
my $table = $t->render($data, {
  table => { cellpadding => 5, class => 'render1' },
  thtr => { class => 'render1' },
  fields => [ qw(Col1 Col2 Col3 Col4) ],
  labels => 1,
  stripe => '#999999',
});
# print $table, "\n";

# Check that render defns were transient
$defn = $t->defn;
ok(ref $defn->{table} && $defn->{table}->{cellpadding} == 3,
  "defn table->cellpadding has merged value");
ok(ref $defn->{table} && ! exists $defn->{table}->{class},
  "defn table->class does not exist");
ok(ref $defn->{thtr} && $defn->{thtr}->{class} eq 'merge',
  "defn thtr->class has merged value");
ok($defn->{labels} == 0, "defn labels has merged value");
ok($defn->{stripe} eq '#dddddd', "defn stripe has initial value");

