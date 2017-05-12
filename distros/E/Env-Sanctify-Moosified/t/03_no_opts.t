use strict;
use warnings;
use Test::More tests => 6;
use Env::Sanctify::Moosified;

$ENV{SANCTIFY_REGEX_TEST} = 'Sanctify this';
$ENV{SANCTIFY_RESTORE_TEST} = 'moocow';
delete $ENV{SANCTIFY_NO_VAR};

{
  my $sanctify = Env::Sanctify::Moosified->consecrate();

  is( $ENV{SANCTIFY_RESTORE_TEST}, 'moocow', 'It is a cow again' );
  is( $ENV{SANCTIFY_REGEX_TEST}, 'Sanctify this', 'Yes sanctification worked' );
  ok( !$ENV{SANCTIFY_NO_VAR}, 'Nothing to see there' );

}

is( $ENV{SANCTIFY_RESTORE_TEST}, 'moocow', 'It is a cow again' );
is( $ENV{SANCTIFY_REGEX_TEST}, 'Sanctify this', 'Yes sanctification worked' );
ok( !$ENV{SANCTIFY_NO_VAR}, 'Nothing to see there' );
