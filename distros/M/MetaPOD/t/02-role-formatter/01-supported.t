use strict;
use warnings;

use Test::More tests => 12;
use Test::Fatal;

sub died {
  my ( $exception, $reason ) = @_;
  return isnt( $exception, undef, $reason );
}

sub lived {
  my ( $exception, $reason ) = @_;
  return is( $exception, undef, $reason );
}
{

  package t::sample::v1;
  use Moo;
  with 'MetaPOD::Role::Format';

  sub new_collector {

  }

  sub add_segment {

  }
}
{

  package t::sample::v2;
  use Moo;
  with 'MetaPOD::Role::Format';

  sub supported_versions {
    return qw( v1.0.1 v1.1.0 );
  }

  sub new_collector {

  }

  sub add_segment {

  }
}

lived exception { t::sample::v1->supports_version('v1.0.0') }, 'v1 supports v1.0.0';
lived exception { t::sample::v1->supports_version('v1.0') },   'v1 supports v1.0';
lived exception { t::sample::v1->supports_version('v1') },     'v1 supports v1';
died exception  { t::sample::v1->supports_version('v1.0.1') }, 'v1 !supports v1.0.1';
died exception  { t::sample::v1->supports_version('v1.1.0') }, 'v1 !supports v1.1.0';
died exception  { t::sample::v1->supports_version('v1.1') },   'v1 !supports v1.1';

died exception { t::sample::v2->supports_version('v1.0.0') }, 'v2 !supports v1.0.0';
died exception { t::sample::v2->supports_version('v1.0') },   'v2 !supports v1.0';
died exception { t::sample::v2->supports_version('v1') },     'v2 !supports v1';

lived exception { t::sample::v2->supports_version('v1.0.1') }, 'v2 supports v1.0.1';
lived exception { t::sample::v2->supports_version('v1.1.0') }, 'v2 supports v1.1.0';
lived exception { t::sample::v2->supports_version('v1.1') },   'v2 supports v1.1';
