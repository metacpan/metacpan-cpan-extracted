package EPL2::Command::B;
# ABSTRACT: B Command (Bar code)
$EPL2::Command::B::VERSION = '0.001';
use Moose;
use MooseX::Method::Signatures;
use namespace::autoclean;
use EPL2::Types ( 'Natural', 'Rotation', 'Human', 'Barcode', 'Text' );
use 5.010;

extends 'EPL2::Command';

#Public Attributes
has h_pos      => ( is => 'rw', isa => Natural,  default  => 0 );
has v_pos      => ( is => 'rw', isa => Natural,  default  => 0 );
has rotation   => ( is => 'rw', isa => Rotation, default  => 0 );
has barcode    => ( is => 'rw', isa => Barcode,  default  => 3 );
has narrow_bar => ( is => 'rw', isa => Natural,  default  => 3 );
has wide_bar   => ( is => 'rw', isa => Natural,  default  => 7 );
has height     => ( is => 'rw', isa => Natural,  default  => 20 );
has human      => ( is => 'rw', isa => Human,    default  => 'N' );
has text       => ( is => 'ro', isa => Text,     required => 1 );

#Methods
method string ( Str :$delimiter = "\n" ) {
    sprintf 'B%d,%d,%d,%s,%d,%d,%d,%s,%s%s',
             $self->h_pos,    $self->v_pos,  $self->rotation, $self->barcode, $self->narrow_bar,
             $self->wide_bar, $self->height, $self->human,    $self->text,    $delimiter;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

EPL2::Command::B - B Command (Bar code)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 my $B = EPL2::Command::B->new( text => q{"BARCODETEXT"} );
 say $B->string;

=head1 ATTRIBUTES

=head2 text ( Text required )

Text used to create barcode.

=head2 h_pos ( Natural default = 0 )

Horizontal Position in dots.

=head2 v_pos ( Natural default = 0 )

Vertical Position in dots.

=head2 rotation ( Rotation default = 0 )

Rotation of Barcode.

=head2 barcode ( Barcode default = 3 )

Type of Barcode.

=head2 narrow_bar ( Natural default = 3 )

Thickness of narrow bar.

=head2 wide_bar ( Natural default = 7 )

Thickness of wide bar.

=head2 height ( Natural default = 20 )

Height of barcode.

=head2 human ( Human default = 'N' )

Print Human readable text of barcode.

=head1 METHODS

=head2 string

 param: ( delimiter => "\n" )

Return an EPL2 formatted string used for describing a barcode.

=head1 SEE ALSO

L<EPL2>

L<EPL2::Types>

=head1 AUTHOR

Ted Katseres <tedkat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Ted Katseres.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
