package EPL2::Command::A;
# ABSTRACT: A Command (ASCII Text)
$EPL2::Command::A::VERSION = '0.001';
use 5.010;
use Moose;
use MooseX::Method::Signatures;
use namespace::autoclean;
use EPL2::Types ( 'Natural', 'Rotation', 'Mult', 'Reverse', 'Font', 'Text' );
use Text::Wrap::Smart::XS 'exact_wrap';

extends 'EPL2::Command';

#Public Attributes
has h_pos     => ( is => 'rw', isa => Natural,  default  => 0 );
has v_pos     => ( is => 'rw', isa => Natural,  default  => 0 );
has rotation  => ( is => 'rw', isa => Rotation, default  => 0 );
has font      => ( is => 'rw', isa => Font,     default  => 1 );
has h_mult    => ( is => 'rw', isa => Mult,     default  => 1 );
has v_mult    => ( is => 'rw', isa => Mult,     default  => 1 );
has 'reverse' => ( is => 'rw', isa => Reverse,  default  => 'N' );
has text      => ( is => 'ro', isa => Text,     required => 1 );

#Private Attributes
has width  => ( is => 'ro', init_arg => undef, builder => '_b_width',  lazy => 1 );
has height => ( is => 'ro', init_arg => undef, builder => '_b_height', lazy => 1 );
has fonts  => ( is => 'ro', init_arg => undef, builder => '_b_fonts' );

#Builders
sub _b_width {
    my ($self) = @_;
    my $txt = $self->text;
    $txt =~ s/^"//;
    $txt =~ s/"$//;
    if ( !$self->rotation || $self->rotation == 2 ) {
        return $self->_b_fonts->{ $self->font }{width} * length( $txt );
    }
    return $self->_b_fonts->{$self->font}{height};
}
sub _b_height {
    my ($self) = @_;
    if ( !$self->rotation || $self->rotation == 2 ) {
        return $self->_b_fonts->{$self->font}{height};
    }
    return $self->_b_fonts->{ $self->font }{width} * length( $self->text );
}
sub _b_fonts {
    return {
             (
               1 => { width => 8 + 2,  height => 12 + 2 },
               2 => { width => 10 + 2, height => 16 + 2 },
               3 => { width => 12 + 2, height => 20 + 2 },
               4 => { width => 14 + 2, height => 24 + 2 },
               5 => { width => 32 + 2, height => 48 + 2 }
             )
           };
}

#Methods
method string ( Str :$delimiter = "\n" ) {
    sprintf 'A%d,%d,%d,%d,%d,%d,%s,%s%s',
             $self->h_pos,  $self->v_pos,  $self->rotation, $self->font,
             $self->h_mult, $self->v_mult, $self->reverse,  $self->text,
			 $delimiter;
}

sub multi_lines {
    my $class = shift;
    my %args  = @_;
    my ( @A, $txt );
    $txt = $args{text};
    $txt =~ s/( \r | \n | \t )//mxg;
    $txt =~ s/^"//;
    $txt =~ s/"$//;
    my @chunks = exact_wrap($txt, $args{length});
    delete $args{text};
    delete $args{length};
    for my $chunk ( @chunks ) {
        my $A = $class->new( %args, text => qq{"$chunk"} );
        if ( !$args{rotation} || $args{rotation} == 2 ) {
            $args{v_pos} = $A->v_pos + $A->height;
        }
        else {
            $args{h_pos} = $A->h_pos + $A->width;
        }
        push @A, $A
    }
    return @A;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

EPL2::Command::A - A Command (ASCII Text)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 my $A = EPL2::Command::A->new( text => q{"Ascii TEXT"} );
 say $A->string;
 my $long_text = 'i can haz cheezburger' x 25;
 my @bunch = EPL2::Command::A->multi_lines( h_pos => 50, text => $long_text, length => 21 );
 say $_->string foreach( @bunch );

=head1 ATTRIBUTES

=head2 text ( Text required )

Text used to create Ascii Text.

=head2 h_pos ( Natural default = 0 )

Horizontal Position in dots.

=head2 v_pos ( Natural default = 0 )

Vertical Position in dots.

=head2 rotation ( Rotation default = 0 )

Rotation of Text.

=head2 font ( Font default = 1 )

Font Type of Text. Valid font types are [ 1-5 ]

=head2 h_mult ( Mult default = 1 )

Horizontal Multiplier.

=head2 v_mult ( Mult default = 1 )

Vertical Multiplier.

=head2 reverse ( Reverse default = 'N' )

Reverse black and white print.

=head2 width ( private )

Return width of the text in dots.

=head2 height ( private )

Returns height of the text in dots.

=head2 fonts ( private )

Return Hashref describing valid fonts.

=head1 METHODS

=head2 multi_lines

 params: ( text => 'Stuff to chop up and print muli lines', length => 5 )
   text   - required
   length - required ( number of chars per line )

Return an array of EPL2::Command::A objects based on text and length.

=head2 string

 param: ( delimiter => "\n" )

Return an EPL2 formatted string used for describing a Ascii text.

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
