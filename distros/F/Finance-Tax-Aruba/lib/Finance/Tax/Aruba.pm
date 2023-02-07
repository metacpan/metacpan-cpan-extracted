use utf8;
package Finance::Tax::Aruba;
our $VERSION = '0.007';
use Moose;
use namespace::autoclean;

# ABSTRACT: A package that deals with tax calculations for Aruba

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::Tax::Aruba - A package that deals with tax calculations for Aruba

=head1 VERSION

version 0.007

=head1 DESCRIPTION

This is a suite that deals with tax calculations for the island of Aruba.
Currently only income taxes for individuals are supported in their most basic
levels.

=head1 SEE ALSO

L<Finance::Tax::Aruba::Income>

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
