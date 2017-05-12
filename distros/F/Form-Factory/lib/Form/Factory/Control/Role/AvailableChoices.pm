package Form::Factory::Control::Role::AvailableChoices;
$Form::Factory::Control::Role::AvailableChoices::VERSION = '0.022';
use Moose::Role;

use Form::Factory::Control::Choice;

# ABSTRACT: Controls that list available choices


has available_choices => (
    is        => 'ro',
    isa       => 'ArrayRef[Form::Factory::Control::Choice]',
    required  => 1,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Control::Role::AvailableChoices - Controls that list available choices

=head1 VERSION

version 0.022

=head1 DESCRIPTION

Controls that have a list of possible options to select from may implement this role.

=head1 ATTRIBUTES

=head2 available_choices

The list of L<Form::Factory::Control::Choice> objects.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
