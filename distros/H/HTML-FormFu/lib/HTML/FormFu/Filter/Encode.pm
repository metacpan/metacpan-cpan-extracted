use strict;

package HTML::FormFu::Filter::Encode;
$HTML::FormFu::Filter::Encode::VERSION = '2.07';
# ABSTRACT: Encode/Decode Submitted Values

use Moose;
use MooseX::Attribute::Chained;
extends 'HTML::FormFu::Filter';

use Encode qw(encode decode FB_CROAK);

has encode_to => ( is => 'rw', traits => ['Chained'] );

has _candidates => ( is => 'rw' );

sub filter {
    my ( $self, $value ) = @_;

    return if !defined $value;

    my $utf8 = $self->decode_to_utf8($value);

    die "HTML::FormFu::Filter::Encode: Unable to decode given string to utf8"
        if !defined $utf8;

    return $self->encode_from_utf8($utf8);
}

sub get_candidates {
    my ($self) = @_;

    my $ret = $self->_candidates;

    if ( $ret && wantarray ) {
        return @$ret;
    }

    return $ret;
}

sub candidates {
    my ( $self, @candidates ) = @_;

    if ( @_ > 1 ) {
        if ( ref $candidates[0] eq 'ARRAY' ) {
            $self->_candidates( $candidates[0] );
        }
        else {
            $self->_candidates( [@candidates] );
        }
    }

    return $self;
}

sub decode_to_utf8 {
    my ( $self, $value ) = @_;

    my $ret;

    foreach my $candidate ( $self->get_candidates ) {
        eval { $ret = decode( $candidate, $value, FB_CROAK ) };

        if ( !$@ ) {
            last;
        }
    }

    return $ret;
}

sub encode_from_utf8 {
    my ( $self, $value ) = @_;

    my $enc = $self->encode_to;

    if ( !$enc ) {
        return $value;
    }

    return encode( $enc, $value );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormFu::Filter::Encode - Encode/Decode Submitted Values

=head1 VERSION

version 2.07

=head1 SYNOPSIS

   # in your config:
   elements:
      - type: Text
        filters:
           - type: Encode
             candidates:
                - utf8
                - Hebrew

   # if you want to encode the decoded string to something else
   elements:
      - type: Text
        filters:
           - type: Encode
             candidates:
                - utf8
                - Hebrew
             encode_to: UTF-32BE

=head1 AUTHOR

Copyright (c) 2007 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>
All rights reserved.

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Carl Franks <cpan@fireartist.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Carl Franks.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
