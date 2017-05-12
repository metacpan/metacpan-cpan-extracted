package EPL2::Command::qq;
# ABSTRACT: q Command (Set Label Width)
$EPL2::Command::qq::VERSION = '0.001';
use 5.010;
use Moose;
use MooseX::Method::Signatures;
use namespace::autoclean;
use EPL2::Types 'Padwidth';

extends 'EPL2::Command';

has width => ( is => 'rw', isa => Padwidth,  default => 0, );

#Methods
method string ( Str :$delimiter = "\n" ) { sprintf 'q%d%s', $self->width, $delimiter; }

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

EPL2::Command::qq - q Command (Set Label Width)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 my $qq = EPL2::Command::qq->new( width => 800 );
 say $qq->string;

=head1 ATTRIBUTES

=head2 width ( default = 0 )

Describe width of a Label.

=head1 METHODS

=head2 string

 param: ( delimiter => "\n" )

Return an EPL2 formatted string used for setting label width.

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
