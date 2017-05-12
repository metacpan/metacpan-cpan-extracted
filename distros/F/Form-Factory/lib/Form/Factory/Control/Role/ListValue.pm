package Form::Factory::Control::Role::ListValue;
$Form::Factory::Control::Role::ListValue::VERSION = '0.022';
use Moose::Role;

excludes qw( 
    Form::Factory::Control::Role::BooleanValue
    Form::Factory::Control::Role::ScalarValue 
);

# ABSTRACT: list-valued controls


use constant default_isa => 'ArrayRef[Str]';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Control::Role::ListValue - list-valued controls

=head1 VERSION

version 0.022

=head1 DESCRIPTION

Implemented by control that are multi-values.

=head1 METHODS

=head2 default_isa

List valued controls are "ArrayRef[Str]" by default.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
