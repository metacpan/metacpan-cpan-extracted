package EPL2::Pad;
# ABSTRACT: Pad (Describe Printer Label)
$EPL2::Pad::VERSION = '0.001';
use 5.010;
use Moose;
use MooseX::Method::Signatures;
use namespace::autoclean;
use EPL2::Types qw(Padwidth Padheight Natural Positive);

use EPL2::Command::A;
use EPL2::Command::B;
use EPL2::Command::O;
use EPL2::Command::N;
use EPL2::Command::Q;
use EPL2::Command::qq;
use EPL2::Command::P;

#Public Attributes
has continuous         => ( is => 'rw', isa => 'Bool',    default => 1, );
has number_sets        => ( is => 'rw', isa => Natural,   default => 1, );
has number_copies      => ( is => 'rw', isa => Natural,   default => 0, );
has clear_image_buffer => ( is => 'rw', isa => 'Bool',    default => 1, );
has height             => ( is => 'rw', isa => Padheight, default => 0, );
has width              => ( is => 'rw', isa => Padwidth,  default => 0, );

#Private Attributes
has commands => ( is => 'ro', isa => 'ArrayRef', default => sub { []; }, init_arg => undef, );

#Methods
method add_command( EPL2::Command $command ) {
    push @{ $self->commands }, $command;
}

method process () {
    my ( $needed_height, @com ) = ( $self->height );
    for my $com ( @{ $self->commands } ) {
        my $this_height = 0;
	    if ( blessed $com eq 'EPL2::Command::A' ) {
            $this_height = $com->height + $com->v_pos;
            $needed_height = $this_height if ( $this_height > $needed_height );
        }
        push @com, $com;
    }

    if ( $self->continuous || $self->height ) {
	    my $height = $self->height;
        if ( $self->continuous ) {
            $height += $needed_height;
        }
		unshift @com, EPL2::Command::Q->new( height => $height );
    }

    unshift @com, EPL2::Command::qq->new( width => $self->width ) if ( $self->width );
    unshift @com, EPL2::Command::O->new;
    unshift @com, EPL2::Command::N->new if ( $self->clear_image_buffer );
    push @com, EPL2::Command::P->new( number_sets => $self->number_sets, number_copies => $self->number_copies );
    return @com;
}

method string ( Str :$delimiter = "\n" ) {
    my $string = '';
    for my $com ( $self->process ) {
        $string .= $com->string( delimiter => $delimiter );
    }
    return $string;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

EPL2::Pad - Pad (Describe Printer Label)

=head1 VERSION

version 0.001

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
