package HTML::FormFu::Filter::NonNumeric;

use strict;
our $VERSION = '2.05'; # VERSION

use Moose;
extends 'HTML::FormFu::Filter::Regex';

sub match {qr/\D+/}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

HTML::FormFu::Filter::NonNumeric - filter removing all non-numeric characters

=head1 VERSION

version 2.05

=head1 DESCRIPTION

Remove all non-numeric characters.

=head1 AUTHOR

Carl Franks, C<cfranks@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
