#===============================================================================
#
#  DESCRIPTION:  Lib for tests
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
package Flow::Test;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(is_deeply_xml);
our $VERSION = '0.1';



sub xml_ref {
    my $xml  = shift;
    my %tags;
    #collect tags names;
    map { $tags{$_}++ } $xml =~ m/<(\w+)/gis;
    #make handlers
    our $res;
    for ( keys %tags ) {
        my $name = $_;
        $tags{$_} = sub {
            my $attr = shift || {};
            return $res = {
                name    => $name,
                attr    => $attr,
                content => [ grep { ref $_ } @_ ]
            };
          }
    }
    my $rd = new XML::Flow:: \$xml;
    $rd->read( \%tags );
    $res;

}

sub is_deeply_xml {
    my ( $got, $exp, @params ) = @_;
    unless ( is_deeply xml_ref($got), xml_ref($exp), @params ) {
        diag "got:", "<" x 40;
        diag $got;
        diag "expected:", ">" x 40;
        diag $exp;

    }
}
1;


