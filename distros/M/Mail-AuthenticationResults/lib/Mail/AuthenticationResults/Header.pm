package Mail::AuthenticationResults::Header;
# ABSTRACT: Class modelling the Entire Authentication Results Header set

require 5.008;
use strict;
use warnings;
our $VERSION = '1.20180314'; # VERSION
use Carp;

use Mail::AuthenticationResults::Header::AuthServID;

use base 'Mail::AuthenticationResults::Header::Base';


sub _HAS_VALUE{ return 1; }
sub _HAS_CHILDREN{ return 1; }

sub _ALLOWED_CHILDREN {
    my ( $self, $child ) = @_;
    return 1 if ref $child eq 'Mail::AuthenticationResults::Header::Comment';
    return 1 if ref $child eq 'Mail::AuthenticationResults::Header::Entry';
    return 0;
}


sub set_indent_by {
    my ( $self, $value ) = @_;
    $self->{ 'indent_by' } = $value;
    return $self;
}


sub indent_by {
    my ( $self ) = @_;
    return 4 if ! defined $self->{ 'indent_by' }; #5.8
    return $self->{ 'indent_by'};
}


sub set_indent_on {
    my ( $self, $type ) = @_;
    $self->{ 'indent_type_' . $type } = 1;
    return $self;
}


sub clear_indent_on {
    my ( $self, $type ) = @_;
    $self->{ 'indent_type_' . $type } = 0;
    return $self;
}


sub indent_on {
    my ( $self, $type ) = @_;
    if ( $type eq 'Mail::AuthenticationResults::Header::Entry' ) {
        return 1 if ! defined $self->{ 'indent_type_' . $type }; #5.8
        return $self->{ 'indent_type_' . $type };
    }
    if ( $type eq 'Mail::AuthenticationResults::Header::SubEntry' ) {
        return 0 if ! defined $self->{ 'indent_type_' . $type }; #5.8
        return $self->{ 'indent_type_' . $type };
    }
    elsif ( $type eq 'Mail::AuthenticationResults::Header::Comment' ) {
        return 0 if ! defined $self->{ 'indent_type_' . $type }; #5.8
        return $self->{ 'indent_type_' . $type };
    }
    return 0;
}


sub set_eol {
    my ( $self, $eol ) = @_;
    if ( $eol =~ /^\r?\n$/ ) {
        $self->{ 'eol' } = $eol;
    }
    else {
        croak 'Invalid eol string';
    }
    return $self;
}


sub eol {
    my ( $self ) = @_;
    return "\n" if ! defined $self->{ 'eol' }; #5.8
    return $self->{ 'eol' };
}


sub set_indent_style {
    my ( $self, $style ) = @_;

    if ( $style eq 'none' ) {
        $self->clear_indent_on( 'Mail::AuthenticationResults::Header::Entry' );
        $self->clear_indent_on( 'Mail::AuthenticationResults::Header::SubEntry' );
        $self->clear_indent_on( 'Mail::AuthenticationResults::Header::Comment' );
    }
    elsif ( $style eq 'entry' ) {
        $self->set_indent_by( 4 );
        $self->set_indent_on( 'Mail::AuthenticationResults::Header::Entry' );
        $self->clear_indent_on( 'Mail::AuthenticationResults::Header::SubEntry' );
        $self->clear_indent_on( 'Mail::AuthenticationResults::Header::Comment' );
    }
    elsif ( $style eq 'subentry' ) {
        $self->set_indent_by( 4 );
        $self->set_indent_on( 'Mail::AuthenticationResults::Header::Entry' );
        $self->set_indent_on( 'Mail::AuthenticationResults::Header::SubEntry' );
        $self->clear_indent_on( 'Mail::AuthenticationResults::Header::Comment' );
    }
    elsif ( $style eq 'full' ) {
        $self->set_indent_by( 4 );
        $self->set_indent_on( 'Mail::AuthenticationResults::Header::Entry' );
        $self->set_indent_on( 'Mail::AuthenticationResults::Header::SubEntry' );
        $self->set_indent_on( 'Mail::AuthenticationResults::Header::Comment' );
    }
    else {
        croak "Unknown indent style $style";
    }

    return $self;
}

sub safe_set_value {
    my ( $self, $value ) = @_;
    $self->set_value( $value );
    return $self;
}

sub set_value {
    my ( $self, $value ) = @_;
    croak 'Does not have value' if ! $self->_HAS_VALUE(); # uncoverable branch true
    # HAS_VALUE is 1 for this class
    croak 'Value cannot be undefined' if ! defined $value;
    croak 'value should be an AuthServID type' if ref $value ne 'Mail::AuthenticationResults::Header::AuthServID';
    $self->{ 'value' } = $value;
    return $self;
}

sub add_parent {
    my ( $self, $parent ) = @_;
    return;
}

sub add_child {
    my ( $self, $child ) = @_;
    croak 'Cannot add a SubEntry as a child of a Header' if ref $child eq 'Mail::AuthenticationResults::Header::SubEntry';
    return $self->SUPER::add_child( $child );
}

sub as_string {
    my ( $self ) = @_;
    my $string = q{};
    my $value = q{};
    if ( $self->value() ) {
        $value = $self->value()->as_string();
    }
    else {
        $value = 'unknown';
    }
    $value .= ";";

    $value .= join( ";", map { $_->as_string_prefix() . $_->as_string() } @{ $self->children() } );

    if ( scalar @{ $self->search({ 'isa' => 'entry' } )->children() } == 0 ) {
        #if ( scalar @{ $self->children() } > 0 ) {
        #    $value .= ' ';
        #}
        $value .= ' none';
    }

    return $value;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::AuthenticationResults::Header - Class modelling the Entire Authentication Results Header set

=head1 VERSION

version 1.20180314

=head1 DESCRIPTION

This class represents the main Authentication Results set

Please see L<Mail::AuthenticationResults::Header::Base>

=head1 METHODS

=head2 set_indent_by( $value )

Number of spaces to indent by for as_string()

=head2 indent_by()

Return the number of spaces for as_string() to indent by

=head2 set_indent_on( $class )

The given class will be indented

=head2 clear_indent_on( $class )

The given class will not be indented

=head2 indent_on( $class )

Should the given class be indented

=head2 set_eol( $eol )

Set the eol style for as_string

=head2 eol()

Return the current eol style

=head2 set_indent_style( $style )

Set the as_string indenting style

Options are none, entry, subentry, full

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
