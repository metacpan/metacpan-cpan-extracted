use strictures ();
use Test::More;
use Eval::WithLexicals;
use lib 't/lib';

use strictures 1;
use get_strictures_hints;

my $eval = Eval::WithLexicals->with_plugins("HintPersistence")->new(prelude => '');

is_deeply(
  [ $eval->eval('$x = 1') ],
  [ 1 ],
  'Basic non-strict eval ok'
);

is_deeply(
  $eval->lexicals, { },
  'Lexical not stored'
);

my ($strictures_hints, $strictures_warn) = get_strictures_hints::hints();
$eval->eval('use strictures 1');

{
  local $SIG{__WARN__} = sub { };

  ok !eval { $eval->eval('${"x"}') }, 'Unable to use undeclared variable';
  like $@, qr/Can't use string .* as a SCALAR ref/,
  'Correct message in $@';
}

is(
  ${$eval->hints->{q{$^H}}}, $strictures_hints,
 'Hints are set per strictures'
);

is(
  (unpack "H*", ${ $eval->hints->{'${^WARNING_BITS}'} }),
  (unpack "H*", $strictures_warn),
  'Warning bits are set per strictures'
) or do {
  my @cats =
    map {
      [ $_         => $warnings::Bits{$_} ],
      [ "fatal $_" => $warnings::DeadBits{$_} ],
    }
    grep $_ ne 'all',
    keys %warnings::Bits;

  my %info;
  for my $check (
    [ missing => $strictures_warn ],
    [ extra   => ${ $eval->hints->{'${^WARNING_BITS}'} } ],
  ) {
    my $bits = $check->[1];
    $info{$check->[0]} = {
      map { ($bits & $_->[1]) =~ /[^\0]/ ? ( $_->[0] => 1 ) : () }
      @cats
    };
  }

  {
    my @extra = keys %{$info{extra}};
    my @missing = keys %{$info{missing}};
    delete @{$info{missing}}{ @extra };
    delete @{$info{extra}}{ @missing };
  }

  for my $type (qw(missing extra)) {
    my @found = grep $info{$type}{$_}, map $_->[0], @cats;
    diag "$type:"
      if @found;
    diag "    $_"
      for @found;
  }
};

is_deeply(
  $eval->lexicals, { },
  'Lexical not stored'
);

# Assumption about perl internals: sort pragma will set a key in %^H.
$eval->eval(q{ { use hint_hash_pragma 'param' } }),
ok !exists $eval->hints->{q{%^H}}->{hint_hash_pragma},
  "Lexical pragma used below main scope not captured";

$eval->eval(q{ use hint_hash_pragma 'param' }),
is $eval->hints->{q{%^H}}->{hint_hash_pragma}, 'param',
  "Lexical pragma captured";

$eval->eval('my $x = 1');
is_deeply(
  $eval->lexicals->{'$x'}, \1,
  'Lexical captured when preserving hints',
);

done_testing;
