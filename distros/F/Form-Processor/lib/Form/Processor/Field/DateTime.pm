package Form::Processor::Field::DateTime;
$Form::Processor::Field::DateTime::VERSION = '1.162360';
use strict;
use warnings;
use base 'Form::Processor::Field::DateTimeManip';



# ABSTRACT: Maps to the current DateTime module.




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Processor::Field::DateTime - Maps to the current DateTime module.

=head1 VERSION

version 1.162360

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

This is a module that allows mapping the DateTime field to
the actual field used.  Makes it easier to remap all the forms
in an application to a new field type by overriding instead of
editing all the forms.

Currently this is simply a subclass of L<Form::Processor::Field::DateTimeManip>.

=head1 SUPPORT / WARRANTY

L<Form::Processor> is free software and is provided WITHOUT WARRANTY OF ANY KIND.
Users are expected to review software for fitness and usability.

=head1 AUTHOR

Bill Moseley <mods@hank.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Bill Moseley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
