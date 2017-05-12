package Form::Processor::Field::EnterPassword;
$Form::Processor::Field::EnterPassword::VERSION = '1.162360';
use strict;
use warnings;
use base 'Form::Processor::Field::Text';

sub init_widget   { return 'password' }
sub init_password { return 1 }            # Don't pre-populate the field.
sub init_size     { return 160 }          # If someone wants a 160 char password, that's up to them.
sub required_message { return 'Please enter a password in this field' }


# ABSTRACT: Input a password


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Processor::Field::EnterPassword - Input a password

=head1 VERSION

version 1.162360

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

This is just a text field that is flagged as a password field
and has a max size of 160 characters (to prevent DDOS by hashing
a very long password.

This doesn't validate the password AT ALL.  That's because
when entering a password don't want to give hints away.

See also L<Form::Processor::Field::TxtPassword>.

See L<https://www.owasp.org/index.php/Password_length_%26_complexityhttps://www.owasp.org/index.php/Password_length_%26_complexity>

=head2 Widget

Fields can be given a widget type that is used as a hint for
the code that renders the field.

This field's widget type is: "password".

=head1 AUTHOR

Bill Moseley <mods@hank.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Bill Moseley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
