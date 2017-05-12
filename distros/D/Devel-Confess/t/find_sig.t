use strict;
use warnings;
use Test::More tests => 14;
use Devel::Confess ();
use Scalar::Util qw(blessed);

sub DEFAULT { die "DEFAULT\n" }
sub IGNORE  { die "IGNORE\n" }
sub string  { die "string\n" }
sub stub;
sub Namespaced::string { die "Namespaced::string\n" }
{
  no strict 'refs';
  *{"main::0"} = sub { die "zero\n" };
}
my $coderef = sub { die "coderef\n" };

{
  package CodeOverload;
  use overload '&{}' => sub { sub { die "CodeOverload\n" } };
  sub new { bless {} }
}

{
  package StringOverload;
  use overload '""' => sub { "StringOverload::named" };
  sub named { die "StringOverload::named\n" }
  sub new { bless {} }
}

{
  package FalseOverload;
  use overload
    'bool' => sub { 0 },
    '&{}'  => sub { sub { die "FalseOverload\n" } },
  ;
  sub new { bless {} }
}

sub _ex (&) {
  my $sub = $_[0];
  local $@;
  eval { $sub->(); 1 } and return undef;
  my $e = $@;
  $e =~ s/(?: at .*? line [0-9]+\.)?\n//;
  return $e;
}

sub check_find {
  my $sub = do {
    no warnings 'uninitialized';
    local $SIG{__DIE__} = $_[0];
    Devel::Confess::_find_sig($SIG{__DIE__});
  };
  return "none"
    if !defined $sub;
  _ex {
    (\&$sub)->("welp");
  };
}

sub check_sig {
  no warnings 'uninitialized';
  local $SIG{__DIE__} = $_[0];
  _ex {
    die "none\n";
  };
}

for my $sig (
  undef,
  0,
  {},
  '',
  $coderef,
  'DEFAULT',
  'IGNORE',
  'string',
  'stub',
  'Namespaced::string',
  'nonexistant',
  CodeOverload->new,
  StringOverload->new,
  FalseOverload->new,
) {
  my $name
    = blessed $sig ? (blessed($sig) . " instance")
    : ref $sig ? (ref($sig) . " ref")
    : defined $sig ? qq{"$sig"}
    : 'undef';
  is(check_find($sig), check_sig($sig),
    "correct signal handler for $name"
  );
}
