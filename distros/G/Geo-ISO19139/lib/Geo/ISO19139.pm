# Copyrights 2008 by Mark Overmeer.
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 1.05.
use warnings;
use strict;

package Geo::ISO19139;
use vars '$VERSION';
$VERSION = '0.10';


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
