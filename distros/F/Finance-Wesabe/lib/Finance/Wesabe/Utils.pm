package Finance::Wesabe::Utils;

use Moose;

extends 'Exporter';

our @EXPORT = qw( mk_simple_field mk_simple_date_field mk_deep_date_field mk_field_map mk_deep_field_map mk_deep_field );

use DateTime::Format::ISO8601;

=head1 NAME

Finance::Wesabe::Utils - Utility methods for Finance::Wesabe

=head1 DESCRIPTION

This module is a collection of utility methods for accessing particular
aspects of the structure returned from an HTTP response.

=head1 METHODS

=head2 mk_simple_field( @fields )

Acceses a top-level hash element.

=cut

sub mk_simple_field {
    my( $package, @fields ) = @_;

    for my $field ( @fields ) {
        ( my $sub = $field ) =~ s{-}{_};

        no strict 'refs';
        *{ "$package\::$sub" } = sub {
            return shift->content->{ $field };
        }
    }
}

=head2 mk_deep_field( @fields )

Acceses data stored in a field with a C<content> sub-key.

=cut

sub mk_deep_field {
    my( $package, @fields ) = @_;

    for my $field ( @fields ) {
        ( my $sub = $field ) =~ s{-}{_};

        no strict 'refs';
        *{ "$package\::$sub" } = sub {
            return shift->content->{ $field }->{ content };
        }
    }
}

=head2 mk_simple_date_field( @fields )

Acceses a top-level hash element and creates a DateTime object.

=cut

sub mk_simple_date_field {
    my( $package, @fields ) = @_;

    for my $field ( @fields ) {
        ( my $sub = $field ) =~ s{-}{_};

        no strict 'refs';
        *{ "$package\::$sub" } = sub {
            return DateTime::Format::ISO8601->parse_datetime( shift->content->{ $field } );
        }
    }
}

=head2 mk_deep_date_field( @fields )

Creates a DateTime object from data stored in a C<content> sub key.

=cut

sub mk_deep_date_field {
    my( $package, @fields ) = @_;

    for my $field ( @fields ) {
        ( my $sub = $field ) =~ s{-}{_};

        no strict 'refs';
        *{ "$package\::$sub" } = sub {
            return DateTime::Format::ISO8601->parse_datetime( shift->content->{ $field }->{ content } );
        }
    }
}

=head2 mk_field_map( %fields )

Similar to C<mk_simple_field>, but uses a different accessor name.

=cut

sub mk_field_map {
    my( $package, %fields ) = @_;

    for my $field ( keys %fields ) {
        my $sub = $fields{ $field };

        no strict 'refs';
        *{ "$package\::$sub" } = sub {
            return shift->content->{ $field };
        }
    }
}

=head2 mk_deep_field_map( %fields )

Similar to C<mk_deep_field>, but uses a different accessor name.

=cut

sub mk_deep_field_map {
    my( $package, %fields ) = @_;

    for my $field ( keys %fields ) {
        my $sub = $fields{ $field };

        no strict 'refs';
        *{ "$package\::$sub" } = sub {
            return shift->content->{ $field }->{ content };
        }
    }
}

no Moose;

__PACKAGE__->meta->make_immutable;

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009-2010 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
