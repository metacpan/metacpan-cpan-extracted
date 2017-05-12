package Exporter::Declare::Magic::Parser;
use strict;
use warnings;

use base 'Devel::Declare::Parser';
use Devel::Declare::Interface;
BEGIN { Devel::Declare::Interface::register_parser( 'export' )};

__PACKAGE__->add_accessor( '_inject' );
__PACKAGE__->add_accessor( 'parser' );

sub inject {
    my $self = shift;
    my @out;

    if( my $items = $self->_inject() ) {
        my $ref = ref( $items );
        if ( $ref eq 'ARRAY' ) {
            push @out => @$items;
        }
        elsif ( !$ref ) {
            push @out => $items;
        }
        else {
            $self->bail( "$items is not a valid injection" );
        }
    }
    return @out;
}

sub _check_parts {
    my $self = shift;
    $self->bail( "You must provide a name to " . $self->name . "()" )
        if ( !$self->parts || !@{ $self->parts });

    if ( @{ $self->parts } > 3 ) {
        ( undef, undef, undef, my @bad ) = @{ $self->parts };
        $self->bail(
            "Syntax error near: " . join( ' and ',
                map { $self->format_part($_)} @bad
            )
        );
    }
}

sub sort_parts {
    my $self = shift;

    if ($self->parts->[0] =~ m/^[\%\$\&\@]/) {
        $self->parts->[0] = [
            $self->parts->[0],
            undef,
        ];
    }

    $self->bail(
        "Parsing Error, unrecognized tokens: "
        . join( ', ', map {"'$_'"} $self->has_non_string_or_quote_parts )
    ) if $self->has_non_string_or_quote_parts;

    my ( @names, @specs );
    for my $part (@{ $self->parts }) {
        $self->bail( "Bad part: $part" ) unless ref($part);
        $part->[1] && $part->[1] eq '('
            ? ( push @specs => $part )
            : ( push @names => $part )
    }

    if ( @names > 2 ) {
        ( undef, undef, my @bad ) = @names;
        $self->bail(
            "Syntax error near: " . join( ' and ',
                map { $self->format_part($_)} @bad
            )
        );
    }

    return ( \@names, \@specs );
}

sub strip_prototype {
    my $self = shift;
    my $parts = $self->parts;
    return unless @$parts > 3;
    return unless ref( $parts->[2] );
    return unless $parts->[2]->[0] eq 'sub';
    return unless ref( $parts->[3] );
    return unless $parts->[3]->[1] eq '(';
    return unless !$parts->[2]->[1];
    $self->prototype(
          $parts->[3]->[1]
        . $parts->[3]->[0]
        . $self->end_quote($parts->[3]->[1])
    );
    delete $parts->[3];
}

sub rewrite {
    my $self = shift;

    $self->strip_prototype;
    $self->_check_parts;

    my $is_arrow = $self->parts->[1]
                && ($self->parts->[1] eq '=>' || $self->parts->[1] eq ',');
    if ( $is_arrow && $self->parts->[2] ) {
        my $is_ref = !ref( $self->parts->[2] );
        my $is_sub = $is_ref ? 0 : $self->parts->[2]->[0] eq 'sub';

        if (( $is_arrow && $is_ref )
        || ( @{ $self->parts } == 1 )) {
            $self->new_parts([ $self->parts->[0], $self->parts->[2] ]);
            return 1;
        }
        elsif (( $is_arrow && $is_sub )
        || ( @{ $self->parts } == 1 )) {
            $self->new_parts([ $self->parts->[0] ]);
            return 1;
        }
    }

    my ( $names, $specs ) = $self->sort_parts();
    $self->parser( $names->[1] ? $names->[1]->[0] : undef );
    push @$names => 'undef' unless @$names > 1;
    $self->new_parts( $names );

    if ( @$specs ) {
        $self->bail( "Too many spec defenitions" )
            if @$specs > 1;
        my $specs = eval "{ " . $specs->[0]->[0] . " }"
              || $self->bail($@);
        $self->_inject( delete $specs->{ inject });
    }

    1;
}

1;

__END__

=head1 NAME

Exporter::Declare::Magic::Parser - The parser behind the export() magic.

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Exporter-Declare is free software; Standard perl licence.

Exporter-Declare is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the license for more details.
