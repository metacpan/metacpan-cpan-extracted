use strict;

package HTML::FormFu::Filter::NonNumeric;
$HTML::FormFu::Filter::NonNumeric::VERSION = '2.07';
# ABSTRACT: filter removing all non-numeric characters

use Moose;
extends 'HTML::FormFu::Filter::Regex';

sub match {qr/\D+/}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormFu::Filter::NonNumeric - filter removing all non-numeric characters

=head1 VERSION

version 2.07

=head1 DESCRIPTION

Remove all non-numeric characters.

=head1 AUTHOR

Carl Franks, C<cfranks@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Carl Franks <cpan@fireartist.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Carl Franks.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
