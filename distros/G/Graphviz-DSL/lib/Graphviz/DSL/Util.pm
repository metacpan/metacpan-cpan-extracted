package Graphviz::DSL::Util;
use strict;
use warnings;

use parent qw/Exporter/;
use Carp ();

our @EXPORT_OK = qw/parse_id validate_compass/;

my @valid_compasses = qw/n ne e se s sw w nw c _/;

sub parse_id {
    my $id_str = shift;

    my $id = $id_str;
    my ($port, $compass);
    if ($id =~ m{:}) {
        ($id, $port, $compass) = split /:/, $id, 3;

        if (defined $port && !defined $compass) {
            if (grep { $port eq $_ } @valid_compasses) {
                $compass = $port;
                $port = undef;
            }
        }
    }

    return ($id, $port, $compass);
}

sub validate_compass {
    my $compass = shift;

    unless (grep { $compass eq $_ } @valid_compasses) {
        Carp::croak("Invalid compass '$compass'");
    }

    return $compass;
}

1;
