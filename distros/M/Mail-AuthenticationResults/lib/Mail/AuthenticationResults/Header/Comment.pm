package Mail::AuthenticationResults::Header::Comment;
# ABSTRACT: Class modelling Comment parts of the Authentication Results Header

require 5.008;
use strict;
use warnings;
our $VERSION = '2.20210915'; # VERSION
use Scalar::Util qw{ weaken };
use Carp;

use base 'Mail::AuthenticationResults::Header::Base';


sub _HAS_VALUE{ return 1; }

sub safe_set_value {
    my ( $self, $value ) = @_;

    $value = q{} if ! defined $value;

    $value =~ s/\t/ /g;
    $value =~ s/\n/ /g;
    $value =~ s/\r/ /g;

    my $remain = $value;
    my $depth = 0;
    my $nested_ok = 1;
    while ( length $remain > 0 ) {
        my $first = substr( $remain,0,1 );
        $remain   = substr( $remain,1 );
        $depth++ if $first eq '(';
        $depth-- if $first eq ')';
        $nested_ok = 0 if $depth == -1;
    }
    $nested_ok = 0 if $depth != 0;

    # Remove parens if nested comments would be broken by them.
    if ( ! $nested_ok ) {
        $value =~ s/\(/ /g;
        $value =~ s/\)/ /g;
    }

    $value =~ s/^\s+//;
    $value =~ s/\s+$//;
    #$value =~ s/;/ /g;

    $self->set_value( $value );
    return $self;
}

sub set_value {
    my ( $self, $value ) = @_;

    my $remain = $value;
    my $depth = 0;
    while ( length $remain > 0 ) {
        my $first = substr( $remain,0,1 );
        $remain   = substr( $remain,1 );
        $depth++ if $first eq '(';
        $depth-- if $first eq ')';
        croak 'Out of order parens in comment' if $depth == -1;
    }
    croak 'Mismatched parens in comment' if $depth != 0;
    croak 'Invalid characters in value' if $value =~ /\n/;
    croak 'Invalid characters in value' if $value =~ /\r/;

    $self->{ 'value' } = $value;
    return $self;
}

sub build_string {
    my ( $self, $header ) = @_;
    $header->comment( '(' . $self->value() . ')' );
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::AuthenticationResults::Header::Comment - Class modelling Comment parts of the Authentication Results Header

=head1 VERSION

version 2.20210915

=head1 DESCRIPTION

Comments may be associated with many parts of the Authentication Results set, this
class represents a comment.

Please see L<Mail::AuthenticationResults::Header::Base>

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
