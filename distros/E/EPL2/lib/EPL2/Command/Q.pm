package EPL2::Command::Q;
# ABSTRACT: Q Command (Set Form Length)
$EPL2::Command::Q::VERSION = '0.001';
use 5.010;
use Moose;
use MooseX::Method::Signatures;
use namespace::autoclean;
use EPL2::Types 'Padheight';

extends 'EPL2::Command';

#Public Attributes
has height     => ( is => 'rw', isa => Padheight, default => 0, );
has continuous => ( is => 'rw', isa => 'Bool',    default => 1, );

#Methods
method string ( Str :$delimiter = "\n" ) {
    my $string = sprintf 'Q%d', $self->height;
	$string .= ',0' if ( $self->continuous );
    return $string . $delimiter;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

EPL2::Command::Q - Q Command (Set Form Length)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 my $Q = EPL2::Command::Q->new( height => 800 );
 say $Q->string;

=head1 ATTRIBUTES

=head2 height ( Padheight default = 0 )

Describe height of a Label.

=head2 continuous ( Bool default = 1 )

If true sets Gap length or Thickness of black line to 0 for continuous print media.

=head1 METHODS

=head2 string

 param: ( delimiter => "\n" )

Return an EPL2 formatted string used for setting Form height.

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
