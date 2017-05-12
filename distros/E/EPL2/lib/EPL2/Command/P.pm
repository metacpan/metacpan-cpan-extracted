package EPL2::Command::P;
# ABSTRACT: P Command (Print)
$EPL2::Command::P::VERSION = '0.001';
use 5.010;
use Moose;
use MooseX::Method::Signatures;
use namespace::autoclean;
use EPL2::Types qw(Positive Natural);

extends 'EPL2::Command';

#Public Attributes
has number_sets   => ( is => 'rw', isa => Positive, default => 1, );
has number_copies => ( is => 'rw', isa => Natural,  default => 0, );

#Methods
method string ( Str :$delimiter = "\n" ) {
    my $string = sprintf 'P%d', $self->number_sets;
    $string .= ',' . $self->number_copies if ( $self->number_copies );
	return $string . $delimiter;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

EPL2::Command::P - P Command (Print)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 my $P = EPL2::Command::P->new;
 say $P->string;

=head1 ATTRIBUTES

=head2 number_sets ( Positive default = 1 )

Number of label sets.

=head2 number_copies ( Natural default = 0 )

Number of copies per set.

=head1 METHODS

=head2 string

 param: ( delimiter => "\n" )

Return an EPL2 formatted string used for printing form.

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
