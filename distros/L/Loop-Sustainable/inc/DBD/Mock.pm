#line 1
package DBD::Mock;

# --------------------------------------------------------------------------- #
#   Copyright (c) 2004-2007 Stevan Little, Chris Winters
#   (spawned from original code Copyright (c) 1994 Tim Bunce)
# --------------------------------------------------------------------------- #
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
# --------------------------------------------------------------------------- #

use 5.008001;

use strict;
use warnings;

use DBI;

use DBD::Mock::dr;
use DBD::Mock::db;
use DBD::Mock::st;
use DBD::Mock::StatementTrack;
use DBD::Mock::StatementTrack::Iterator;
use DBD::Mock::Session;
use DBD::Mock::Pool;
use DBD::Mock::Pool::db;

sub import {
    shift;
    $DBI::connect_via = "DBD::Mock::Pool::connect"
      if ( @_ && lc( $_[0] ) eq "pool" );
}

our $VERSION = '1.43';

our $drh    = undef;    # will hold driver handle
our $err    = 0;        # will hold any error codes
our $errstr = '';       # will hold any error messages

sub driver {
    return $drh if defined $drh;
    my ( $class, $attributes ) = @_;
    $attributes = {}
      unless ( defined($attributes) && ( ref($attributes) eq 'HASH' ) );
    $drh = DBI::_new_drh(
        "${class}::dr",
        {
            Name    => 'Mock',
            Version => $DBD::Mock::VERSION,
            Attribution =>
'DBD Mock driver by Chris Winters & Stevan Little (orig. from Tim Bunce)',
            Err    => \$DBD::Mock::err,
            Errstr => \$DBD::Mock::errstr,

            # mock attributes
            mock_connect_fail => 0,

            # and pass in any extra attributes given
            %{$attributes}
        }
    );
    return $drh;
}

sub CLONE { undef $drh }

# NOTE:
# this feature is still quite experimental. It is defaulted to
# be off, but it can be turned on by doing this:
#    $DBD::Mock::AttributeAliasing++;
# and then turned off by doing:
#    $DBD::Mock::AttributeAliasing = 0;
# we shall see how this feature works out.

our $AttributeAliasing = 0;

my %AttributeAliases = (
    mysql => {
        db => {

            # aliases can either be a string which is obvious
            mysql_insertid => 'mock_last_insert_id'
        },
        st => {

            # but they can also be a subroutine reference whose
            # first argument will be either the $dbh or the $sth
            # depending upon which context it is aliased in.
            mysql_insertid =>
              sub { (shift)->{Database}->{'mock_last_insert_id'} }
        }
    },
);

sub _get_mock_attribute_aliases {
    my ($dbname) = @_;
    ( exists $AttributeAliases{ lc($dbname) } )
      || die "Attribute aliases not available for '$dbname'";
    return $AttributeAliases{ lc($dbname) };
}

sub _set_mock_attribute_aliases {
    my ( $dbname, $dbh_or_sth, $key, $value ) = @_;
    return $AttributeAliases{ lc($dbname) }->{$dbh_or_sth}->{$key} = $value;
}

## Some useful constants

use constant NULL_RESULTSET => [ [] ];

1;

__END__

#line 958
