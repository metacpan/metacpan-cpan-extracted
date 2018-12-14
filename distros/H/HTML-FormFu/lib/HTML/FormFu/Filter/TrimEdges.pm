use strict;

package HTML::FormFu::Filter::TrimEdges;
$HTML::FormFu::Filter::TrimEdges::VERSION = '2.07';
# ABSTRACT: filter trimming whitespace

use Moose;
extends 'HTML::FormFu::Filter';

sub filter {
    my ( $self, $value ) = @_;

    return if !defined $value;

    $value =~ s/^\s+//;
    $value =~ s/\s+\z//;

    return $value;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormFu::Filter::TrimEdges - filter trimming whitespace

=head1 VERSION

version 2.07

=head1 DESCRIPTION

Trim whitespaces from beginning and end of string.

=head1 AUTHOR

Mario Minati, C<mario@minati.de>

Based on the original source code of L<HTML::Widget::Filter::TrimEdges>, by
Sebastian Riedel, C<sri@oook.de>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it
under
the same terms as Perl itself.

=head1 AUTHOR

Carl Franks <cpan@fireartist.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Carl Franks.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
