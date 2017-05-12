package Form::Factory::Control::Role::PresetValue;
$Form::Factory::Control::Role::PresetValue::VERSION = '0.022';
use Moose::Role;

# ABSTRACT: controls with preset values


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Control::Role::PresetValue - controls with preset values

=head1 VERSION

version 0.022

=head1 DESCRIPTION

This role provides no methods or attributes. It flags the control as one with a preset value that does not change based upon user input. Buttons and hidden values are examples of presets.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
