use strict;
use warnings;

use Test::More;
use Term::ANSIColor qw( colorstrip );

# ABSTRACT: Very rudimentary "it does something at all" test

use Devel::Isa::Explainer qw( explain_isa );

{
  my $result = explain_isa('Test::More');

  note $result;

  like( colorstrip($result), qr/Test::More/, "Test::More in output" );
}
{
  require Test::Builder;    # Should already be loaded, but ...
  my $result = explain_isa('Test::Builder');

  note $result;

  like( colorstrip($result), qr/Test::Builder/, "Test::Builder in output" );
}
{
  local $TODO = "Work out what to actually do here";
  local $@;
  eval { my $result = explain_isa('Invalid Namespace?'); };
  my $err = $@;
  ok( $err, "Exception thrown for bogus module name" );
}
{
  local $@;
  eval {
    my $result = explain_isa('Nobody::Loaded::Me');
    note $result;
  };
  my $err = $@;
  ok( $err, "Exception thrown for missing module" );
  like( $err, qr/\(id: Devel::Isa::Explainer#5\)/, "Error code has identifier #5 in it" );
}

done_testing;

