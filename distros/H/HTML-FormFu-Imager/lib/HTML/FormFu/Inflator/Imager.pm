package HTML::FormFu::Inflator::Imager;
{
  $HTML::FormFu::Inflator::Imager::VERSION = '1.00';
}
use Moose;
extends 'HTML::FormFu::Inflator';

use Imager;
use Scalar::Util qw/ blessed /;
use Carp qw/ croak /;

sub inflator {
    my ( $self, $value ) = @_;

    return unless defined $value && $value ne "";

    croak "not a file"
        unless blessed($value) && $value->isa('HTML::FormFu::Upload');

    my $img = Imager->new;
    
    $img->read( fh => $value->fh )
        or croak $img->errstr;
    
    return $img;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

HTML::FormFu::Inflator::Imager - Imager HTML::FormFu inflator

=head1 SYNOPSIS

    ---
    elements:
      - type: file
        name: photo
        inflators:
          - type: Imager

=head1 DESCRIPTION

Inflate file uploads into L<Imager> objects.

=head1 SEE ALSO

L<HTML::FormFu::Imager>, L<HTML::FormFu>

=head1 AUTHOR

Carl Franks

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
