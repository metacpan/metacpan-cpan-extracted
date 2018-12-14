use strict;

package HTML::FormFu::Constraint::Required;
$HTML::FormFu::Constraint::Required::VERSION = '2.07';
# ABSTRACT: Required Field Constraint

use Moose;
extends 'HTML::FormFu::Constraint';

sub constrain_value {
    my ( $self, $value ) = @_;

    return defined $value && length $value;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormFu::Constraint::Required - Required Field Constraint

=head1 VERSION

version 2.07

=head1 DESCRIPTION

States that a value must be submitted. The empty string is not allowed.

=head1 SEE ALSO

Is a sub-class of, and inherits methods from L<HTML::FormFu::Constraint>

L<HTML::FormFu>

=head1 AUTHOR

Carl Franks, C<cfranks@cpan.org>

Based on the original source code of L<HTML::Widget::Constraint::All>, by
Sebastian Riedel, C<sri@oook.de>.

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
