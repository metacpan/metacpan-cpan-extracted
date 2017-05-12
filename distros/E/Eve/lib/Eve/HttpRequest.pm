package Eve::HttpRequest;

use parent qw(Eve::Class);

use strict;
use warnings;

use CGI ();

=head1 NAME

B<Eve::HttpRequest> - an abstract HTTP request adapter.

=head1 SYNOPSIS

    use Eve::HttpRequest;

    my $request  = Eve::HttpRequest->new();

    my $uri = $request->get_uri();
    my $method = $request->get_method();
    my $param = $request->get_parameter(name => 'some_parameter');
    my @param_list = $request->get_parameter(name => 'some_list');
    my $cookie = $request->get_cookie(name => 'some_cookie');

=head1 DESCRIPTION

The class defines all methods that any request adapter must implement
in order to be used.

=head1 METHODS

=head2 B<get_uri>

Returns an URI instance built from an HTTP request URI.

=cut

sub get_uri {
    Eve::Error::NotImplemented->throw();
}

=head2 B<get_method>

Returns an HTTP method name.

=cut

sub get_method {
    Eve::Error::NotImplemented->throw();
}

=head2 B<get_parameter()>

Returns a request parameter value or a list of values for a specified
parameter name. When called in a scalar context, will return a single
value, which for a multivalue parameter will result in a first value
of the list:

    my $parameter_value = $request->get_parameter(name => 'some');

To receive a list of all values for a multivalue parameter, call the
method in a list context:

    my @parameter_value_list = $request->get_parameter(name => 'some');

=head3 Arguments

=over 4

=item C<name>

=back

=cut

sub get_parameter {
    Eve::Error::NotImplemented->throw();
}

=head2 B<get_parameter_hash()>

Returns a hash reference with the requested parameter values.

=cut

sub get_parameter_hash {
    my $self = shift;

    my %result = $self->cgi->Vars();

    return \%result;
}

=head2 B<get_cookie()>

Returns a request cookie value for a specified name.

=head3 Arguments

=over 4

=item C<name>

=back

=cut

sub get_cookie {
    Eve::Error::NotImplemented->throw();
}

=head1 SEE ALSO

=over 4

=item C<Eve::Class>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Igor Zinovyev.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=head1 AUTHORS

=over 4

=item L<Igor Zinovyev|mailto:zinigor@gmail.com>

=cut

1;
