package Enbld::HTML;

use strict;
use warnings;

sub new {
    my ( $class, $html ) = @_;

    my $self = {
        html    =>  $html,
    };

    return bless $self, $class;
}

sub parse_version {
    my ( $self, $parser, $version_form ) = @_;

    my $filenames = $self->extract( $parser );

    my %list;

    foreach my $filename ( @{ $filenames } ) {
        while ( $filename =~ /$version_form/g ) {
            $list{$&}++;
        }
    }

    return unless ( keys %list );

    my @versions = keys %list;

    return \@versions;
}

sub extract {
    my ( $self, $parser ) = @_;

    my @candidate;
    while( $self->{html} =~ /$parser/g ) {
        push @candidate, $&;
    }

    return \@candidate;
}

1;
