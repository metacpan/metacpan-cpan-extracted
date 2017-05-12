package HTTP::Exception::Base;
$HTTP::Exception::Base::VERSION = '0.04006';
use strict;
use base 'Exception::Class::Base';

################################################################################
# roll our own new, because of message
# error, message and status_message are synonyms
sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my %params = @_;
    $params{status_message} = delete $params{message} if (exists $params{message});

    $class->SUPER::new(%params);
}

################################################################################
# used by Exception::Class for as_string
sub full_message { shift->status_message }

################################################################################
# TODO default-value/required fields, maybe moose? but maybe a moose is too heavy
# but on the other hand, handmade accessors suck
sub status_message  {
    $_[0]->{status_message}         =   $_[1] if (@_ > 1);
    return $_[0]->{status_message}  ||= $_[0]->_status_message;
}
*message    = \&status_message;
*error      = \&status_message;

################################################################################
# though Exception::Class::Base does have fields, the Fields-Accessor returns ()
# so no shift->SUPER::Fields is required
sub Fields { qw(status_message) }

1;


=head1 NAME

HTTP::Exception::Base - Base Class for exception classes created by HTTP::Exception

=head1 VERSION

version 0.04006

=head1 DESCRIPTION

This Class is a Base class for exception classes created by HTTP::Exception.
It inherits from L<Exception::Class::Base>. Please refer to the Documentation
of L<Exception::Class::Base> for methods and accessors a HTTP::Exception inherits.

You won't use this Class directly, so refer to L<HTTP::Exception/"ACCESSORS">
and L<HTTP::Exception/"FIELDS">. The methods and attributes this Class provides
over Exception::Class::Base are described there.

=head1 AUTHOR

Thomas Mueller, C<< <tmueller at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-http-exception at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTTP-Exception>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTTP::Exception::Base

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTTP-Exception>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTTP-Exception>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTTP-Exception>

=item * Search CPAN

L<https://metacpan.org/release/HTTP-Exception>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Thomas Mueller.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
