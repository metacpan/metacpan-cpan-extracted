package EPL2::Command::O;
# ABSTRACT: O Command (Hardware Options)
$EPL2::Command::O::VERSION = '0.001';
use 5.010;
use Moose;
use MooseX::Method::Signatures;
use namespace::autoclean;

extends 'EPL2::Command';

#Public Attributes

#Methods
method string ( Str :$delimiter = "\n" ) { sprintf 'O%s', $delimiter; }

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

EPL2::Command::O - O Command (Hardware Options)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 my $O = EPL2::Command::O->new;
 say $O->string;

=head1 METHODS

=head2 string

 param: ( delimiter => "\n" )

Return an EPL2 formatted string used for setting hardware options.

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
