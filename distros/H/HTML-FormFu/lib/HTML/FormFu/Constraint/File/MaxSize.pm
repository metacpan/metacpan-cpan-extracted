use strict;

package HTML::FormFu::Constraint::File::MaxSize;
$HTML::FormFu::Constraint::File::MaxSize::VERSION = '2.07';
# ABSTRACT: Maximum File Size Constraint

use Moose;
extends 'HTML::FormFu::Constraint::File::Size';

sub _localize_args {
    my ($self) = @_;

    return $self->max;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormFu::Constraint::File::MaxSize - Maximum File Size Constraint

=head1 VERSION

version 2.07

=head1 DESCRIPTION

Ensure that an uploaded file meets maximum size constraints.

Overrides L<HTML::FormFu::Constraint/localize_args>, so that the value of
L</maximum> is passed as an argument to L<localize|HTML::FormFu/localize>.

This constraint doesn't honour the C<not()> value.

=head1 METHODS

=head2 maximum

=head2 max

The maximum file size in bytes.

L</max> is an alias for L</maximum>.

=head1 SEE ALSO

Is a sub-class of, and inherits methods from
L<HTML::FormFu::Constraint::File::Size>, L<HTML::FormFu::Constraint>

L<HTML::FormFu>

=head1 AUTHOR

Carl Franks C<cfranks@cpan.org>

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
