use strict;

package HTML::FormFu::Constraint::SingleValue;
$HTML::FormFu::Constraint::SingleValue::VERSION = '2.07';
# ABSTRACT: Single Value Constraint

use Moose;
extends 'HTML::FormFu::Constraint';

sub constrain_values {
    my ( $self, $values ) = @_;

    die;
}

sub constrain_value {
    return 1;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormFu::Constraint::SingleValue - Single Value Constraint

=head1 VERSION

version 2.07

=head1 DESCRIPTION

Ensures that multiple values were not submitted for the named element.

This constraint doesn't honour the C<not()> value.

=head1 SEE ALSO

Is a sub-class of, and inherits methods from L<HTML::FormFu::Constraint>

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
