package Eve::HttpRequest::Psgi;

use parent qw(Eve::HttpRequest);

use strict;
use warnings;

use Hash::MultiValue;
use JSON::XS;
use Plack::Request;

=head1 NAME

B<Eve::HttpRequest::Psgi> - an HTTP request adapter for the PSGI interface.

=head1 SYNOPSIS

    use Eve::HttpRequest::Psgi;

    my $request  = Eve::HttpRequest->new(
        uri_constructor => sub { return Eve::Uri->new(@_); },
        env_hash => $env_hash);

    my $uri = $request->get_uri();
    my $method = $request->get_method();
    my $param = $request->get_parameter(name => 'some_parameter');
    my @param_list = $request->get_parameter(name => 'some_list');
    my $cookie = $request->get_cookie(name => 'some_cookie');

    my $upload_hash = $request->get_upload(name => 'huge_file');

=head1 DESCRIPTION

The class adapts some functionality of the C<Plack::Request> module.

=head3 Constructor arguments

=over 4

=item C<uri_constructor>

a code reference returning a newly constructed URI

=item C<env_hash>

an environment hash that is supplied to an application by a PSGI handler.

=back

=head1 METHODS

=head2 B<init()>

=cut

sub init {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(
        \%arg_hash, my ($uri_constructor, $env_hash));

    $self->{'cgi'} = Plack::Request->new($env_hash);
    $self->{'_uri_constructor'} = $uri_constructor;

    $self->{'_body_parameters'} = Hash::MultiValue->from_mixed({
        %{$self->cgi->query_parameters()->as_hashref_mixed()},
        %{$self->cgi->body_parameters()->as_hashref_mixed()}});
    $self->{'_cookies'} = $self->cgi->cookies();

    if ($self->cgi->headers->content_type() eq 'application/json') {
        $self->_body_parameters = Hash::MultiValue->new(
            %{$self->cgi->query_parameters()->as_hashref_mixed()},
            %{JSON::XS->new()->utf8()->decode($self->cgi->content())});
    }

    return;
}

=head2 B<get_uri>

Returns an URI instance built from an HTTP request URI.

=cut

sub get_uri {
    my $self = shift;

    my $uri = $self->_uri_constructor->(
        string => $self->cgi->uri()->canonical());

    $uri->set_query_hash(hash => $self->cgi->query_parameters()->as_hashref());

    return $uri;
}

=head2 B<get_method>

Returns an HTTP method name.

=cut

sub get_method {
    my $self = shift;

    return $self->cgi->method();
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
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my ($name));

    my @result = $self->_body_parameters->get_all($name);
    my $result = $self->_body_parameters->get($name);

    if (scalar @result > 1) {
        return @result;
    } else {
        return $result;
    }
}

=head2 B<get_upload()>

Returns a hash containing information about an uploaded file. This
hash will have C<tempname>, C<size> and C<filename> keys, values for
which represent the temporary file path, its size in bytes and the
original name of the file.

=head3 Arguments

=over 4

=item C<name>

=back

=cut

sub get_upload {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my ($name));

    my $upload = $self->cgi->uploads->{$name};

    my $result = defined $upload ? {
        'tempname' => $upload->tempname,
        'size' => $upload->size,
        'filename' => $upload->filename,
        'content_type' => $upload->content_type} : undef;

    return $result;
}

=head2 B<get_parameter_hash()>

Returns a hash reference with the requested parameter values.

=cut

sub get_parameter_hash {
    my $self = shift;

    return $self->_body_parameters;
}

=head2 B<get_cookie()>

Returns a request cookie value for a specified name.

=head3 Arguments

=over 4

=item C<name>

=back

=cut

sub get_cookie {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my ($name));

    my $result = defined $self->_cookies->{$name} ?
        $self->_cookies->{$name} : undef;

    return $result;
}

=head1 SEE ALSO

=over 4

=item C<CGI>

=item C<Eve::Class>

=item C<Eve::Uri>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Igor Zinovyev.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=head1 AUTHORS

=over 4

=item L<Sergey Konoplev|mailto:gray.ru@gmail.com>

=item L<Igor Zinovyev|mailto:zinigor@gmail.com>

=cut

1;
