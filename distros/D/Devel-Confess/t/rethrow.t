use strict;
use warnings;
BEGIN {
  $ENV{DEVEL_CONFESS_OPTIONS} = '';
}
use Test::More tests => 18;
use Devel::Confess ();
use Carp;

my @dies = qw(die Carp::croak Carp::confess);

for my $options ([], ['source']) {
  for my $innerdie (@dies) {
    for my $outerdie (@dies) {
      my $package = "_Die::${innerdie}::Then::${outerdie}"
        . (@$options ? (join '::', '', 'Options', @$options) : '');
      eval sprintf <<'END_CODE', $package, $innerdie, $outerdie;
        package %s;
        sub layer1 { %s("die") }
        sub layer2 { layer1() }
        sub layer3 { eval { layer2() }; %s(our $inner_error = $@) }
        sub layer4 { layer3() }
END_CODE
      Devel::Confess->import('nowarnings', @$options);
      eval { $package->can('layer4')->(); };
      my $e = $@;
      my $inner = do { no strict 'refs'; ${$package.'::inner_error'} };
      Devel::Confess->unimport;
      is $e, $inner,
        "rethrow from $innerdie to $outerdie doesn't modify trace"
        . (@$options ? ' with ' . join(', ', @$options) : '');
    }
  }
}
