package HTML::Feature::Decoder;
use strict;
use warnings;
use Data::Decode;
use Data::Decode::Chain;
use Data::Decode::Encode::Guess;
use Data::Decode::Encode::Guess::JP;
use Data::Decode::Encode::HTTP::Response;
use base qw(HTML::Feature::Base);

__PACKAGE__->mk_accessors($_) for qw(decoder);

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->_setup;
    return $self;
}

sub _setup {
    my $self    = shift;
    my $decoder = Data::Decode->new(
        strategy => Data::Decode::Chain->new(
            decoders => [
                Data::Decode::Encode::HTTP::Response->new,
                Data::Decode::Encode::Guess::JP->new,
                Data::Decode::Encode::Guess->new,
            ]
        )
    );
    $self->decoder($decoder);
}

sub decode {
    my $self    = shift;
    my $data    = shift;
    my $decoded = $self->decoder->decode($data);
    return $decoded;
}

1;
__END__

=head1 NAME

HTML::Feature::Decoder - Data decoder that relies on Data::Decode. 

=head1 SYNOPSIS

  use HTML::Feature::Decoder;

  my $decoder = HTML::Feature::Decoder->new( context => $html_feature );
  my $decoded = $decoder->decode($indata); # $in_data is either of a string of HTML document or a HTTP::Response object

=head1 DESCRIPTION

This is a wrapper of Data::Decode.

=head1 METHODS

=head2 new

=head2 decode 

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
