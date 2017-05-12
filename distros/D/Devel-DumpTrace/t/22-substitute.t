package Test::DX;

use Devel::DumpTrace ':test';
use PadWalker;
use Test::More tests => 36;
use strict;
use warnings;
use vars qw($g @g %g $G);

# exercise  Devel::DumpTrace::perform_variable_substitutions  on objects

my ($m,@m,%m,$M);
our ($o,@o,%o,$O);

$Devel::DumpTrace::XEVAL_SEPARATOR = ':';
my $S = $Devel::DumpTrace::XEVAL_SEPARATOR;
my $T = $Devel::DumpTrace::HASH_PAIR_SEPARATOR;

{
  package Array::Object;
  sub new {
    my ($pkg, @list) = @_;
    return bless [ @list ], $pkg;
  }
  sub method {
    my $self = shift @_;
    return join ':', @$self;
  }
};

{
  package Hash::Object;
  sub new {
    my ($pkg, $value) = @_;
    bless { attr => $value }, $pkg;
  }
  sub method {
    my $self = shift @_;
    return $self->{attr};
  }
};

save_pads();

$g = $o = new Array::Object(1,2,3,'foo');
$m = new Array::Object(1,2,3,'foo');
$G = $M = $O = new Hash::Object('blah');

foreach my $var (qw($g $m $o)) {
  my $subst = substitute($var, __PACKAGE__);
  ok($subst eq "[Array::Object: 1,2,3,'foo']", "subst $var") or diag $subst;

  my $xsubst = xsubstitute($var, __PACKAGE__);
  ok($xsubst eq $var . $S . $subst, qq'xsubst $var');
}

foreach my $var (qw($G $M $O)) {
  my $subst = substitute($var, __PACKAGE__);
  ok($subst eq "{Hash::Object: 'attr'${T}'blah'}",
     "subst $var") or diag $subst;

  my $xsubst = xsubstitute($var, __PACKAGE__);
  ok($xsubst eq $var . $S . $subst, qq'xsubst $var');
}

my $i = 3;
save_pads();
foreach my $var (qw($g->[$i] $m->[$i] $o->[$i])) {
  my $subst = substitute($var, __PACKAGE__);
  ok($subst eq "[Array::Object: 1,2,3,'foo']->[3]", "subst $var");

  my $xsubst = xsubstitute($var, __PACKAGE__);
  my $xpect = substr($var,0,2) . $S
    . "[Array::Object: 1,2,3,'foo']->[\$i${S}3]";
  ok($xsubst eq $xpect, "xsubst $var") or diag "$xsubst ne $xpect";
}

foreach my $var (qw($g->method(42) $m->method(42) $o->method(42))) {
  my $subst = substitute($var, __PACKAGE__);
  ok($subst eq "[Array::Object: 1,2,3,'foo']->method(42)", "subst $var");

  my $xsubst = xsubstitute($var, __PACKAGE__);
  ok($xsubst eq substr($var,0,2) . $S . $subst, "xsubst $var");
}

$i = 'attr';
foreach my $var (qw($G->{$i} $M->{$i} $O->{$i})) {
  my $subst = substitute($var, __PACKAGE__);
  ok($subst eq "{Hash::Object: 'attr'${T}'blah'}->{'attr'}", "subst $var");

  my $xsubst = xsubstitute($var, __PACKAGE__);

  # $i also gets substituted.
  my $xpect = substr($var,0,2) . $S
    . "{Hash::Object: 'attr'${T}'blah'}->{\$i${S}'attr'}";
  ok($xsubst eq $xpect, "xsubst $var") or diag $xsubst . " ne " . $xpect;
}

foreach my $var (qw($G->method $M->method $O->method)) {
  my $subst = substitute($var, __PACKAGE__);
  ok($subst eq "{Hash::Object: 'attr'${T}'blah'}->method", "subst $var")
    or diag $subst;

  my $xsubst = xsubstitute($var, __PACKAGE__);
  ok($xsubst eq substr($var,0,2) . $S . $subst, "xsubst $var");
}

