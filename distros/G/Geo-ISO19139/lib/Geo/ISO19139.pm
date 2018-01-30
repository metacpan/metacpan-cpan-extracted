# Copyrights 2008,2018 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Geo::ISO19139.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Geo::ISO19139;
use vars '$VERSION';
$VERSION = '0.11';


use warnings;
use strict;

use Log::Report 'geo-iso', syntax => 'SHORT';
use XML::Compile::Cache ();
use XML::Compile::Util  qw/unpack_type pack_type/;

my %version2pkg =
 ( 2005 => 'Geo::ISO19139::2005'
 );


sub new(@)
{   my $class = shift;
    my ($direction, %args) = @_;

    # having a default here cannot be maintained over the years.
    my $version = delete $args{version}
        or error __x"an explicit version is required\n";

    my $pkg     = $version2pkg{$version}
        or error __x"no implementation for version '{version}'"
             , version => $version;

    eval "require $pkg";
    $@ and die $@;

    $pkg->new($direction, %args);
}

1;
