package HTML::FormHandler::Field::PrimaryKey;
# ABSTRACT: primary key field
$HTML::FormHandler::Field::PrimaryKey::VERSION = '0.40068';
use Moose;
extends 'HTML::FormHandler::Field';


has 'is_primary_key' => ( isa => 'Bool', is => 'ro', default => '1' );
has '+widget' => ( default => 'Hidden' );
has '+do_label' => ( default => 0 );
has '+no_value_if_empty' => ( default => 1 );

sub BUILD {
    my $self = shift;
    if ( $self->has_parent ) {
        if ( $self->parent->has_primary_key ) {
            push @{ $self->parent->primary_key }, $self;
        }
        else {
            $self->parent->primary_key( [ $self ] );
        }
    }
}

__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Field::PrimaryKey - primary key field

=head1 VERSION

version 0.40068

=head1 SYNOPSIS

This field is for providing the primary key for Repeatable fields:

   has_field 'addresses' => ( type => 'Repeatable' );
   has_field 'addresses.address_id' => ( type => 'PrimaryKey' );

Do not use this field to hold the primary key of the form's main db object (item).
That primary key is in the 'item_id' attribute.

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
