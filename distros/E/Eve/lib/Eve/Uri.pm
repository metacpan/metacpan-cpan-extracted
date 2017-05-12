package Eve::Uri;

use parent qw(Eve::Class);

use strict;
use warnings;

use URI;
use URI::QueryParam;

use Eve::Exception;

=head1 NAME

B<Eve::Uri> - a URI automation class.

=head1 SYNOPSIS

    use Eve::Uri;

    my $uri  = Eve::Uri->new(
        string => 'http://domain.com/path/script?foo=bar&baz=1&baz=2');

    my $string = $uri->string;
    my $host = $uri->host;
    my $fragment = $uri->fragment;
    my $query_string = $uri->query;

    my $query_parameter = $uri->get_query_parameter(name => 'foo');
    my @query_parameter_list = $uri->get_query_parameter(name => 'baz');

    $uri->set_query_parameter(name => 'foo', value => 'some');
    $uri->set_query_parameter(name => 'baz', value => [3, 4]);

    $uri->set_query_hash(hash => {'name' => 'foo', 'value' => 'some'});
    $uri->set_query_hash(
        hash => {'name' => 'foo', 'value' => 'some'}, delimiter => '&');
    my $query_hash = $uri->get_query_hash();

    my $another_uri = $uri->clone();

    my $matches_hash = $uri->match($another_uri) # empty hash - no placeholders

    $another_uri->query = 'another=query';
    $matches_hash = $uri->match($another_uri); # undef

    $another_uri->path_concat('/some/deeper/path');

    my $placeholder_uri = Eve::Uri->new(
        string => 'http://domain.com/:placeholder/:another');

    my $substituted_uri = $placeholder_uri->substitute(
        hash => {
            'placeholder' => 'first_value',
            'another' => 'another_value'});

    print $substituted_uri->string;
    # http://domain.com/first_value/another_value

    my $uri_is_relative = $uri->is_relative();

=head1 DESCRIPTION

The class provides automation for different common operations with
URIs. A URI is automaticaly brought to the canonical form after
creation or after using any setter method.

=head3 Attributes

=over 4

=item C<fragment>

a fragment part of the URI.

=item C<query>

a query string part of the URI

=item C<string>

an URI as a string

=back

=head3 Constructor arguments

=over 4

=item C<string>

a string that can contain placeholders that are preceded with a
semicolon character (':').

=back

=head1 METHODS

=head2 B<init()>

=cut

sub init {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my $string);

    $self->{'_uri'} = URI->new($string)->canonical();

    # Dummy properties for URI parts
    $self->{'string'} = undef;
    $self->{'path'} = undef;
    $self->{'host'} = undef;
    $self->{'query'} = undef;
    $self->{'fragment'} = undef;
}

# Getter for the path property
sub _get_path {
    my $self = shift;

    return $self->_uri->path();
}

# Setter for the path property
sub _set_path {
    my ($self, $string) = @_;

    $self->_uri->path($string);

    return $self->path;
}

# Getter for the string property
sub _get_string {
    my $self = shift;

    return $self->_uri->as_string();
}

# Setter for the string property
sub _set_string {
    my ($self, $string) = @_;

    $self->_uri = URI->new($string)->canonical();

    return $self->string;
}

# Getter for the host property
sub _get_host {
    my $self = shift;

    if (not $self->_uri->scheme()) {
        return;
    }

    return $self->_uri->host();
}

# Setter for the host property
sub _set_host {
    my ($self, $string) = @_;

    $self->_uri->scheme('http');

    $self->_uri->host($string);

    return $self->host;
}

# Getter for the query property
sub _get_query {
    my $self = shift;

    return $self->_uri->query();
}

# Setter for the query property
sub _set_query {
    my ($self, $string) = @_;

    $self->_uri->query($string);

    return $self->query;
}

# Getter for the fragment property
sub _get_fragment {
    my $self = shift;

    return $self->_uri->fragment();
}

# Setter for the fragment property
sub _set_fragment {
    my ($self, $string) = @_;

    $self->_uri->fragment($string);

    return $self->fragment;
}

=head2 B<clone()>

Clones and returns the object.

=head3 Returns

The object identical to self.

=cut

sub clone {
    my ($self) = @_;

    return $self->new(string => $self->string);
}

=head2 B<match()>

Matches self against other URI.

=head3 Arguments

=over 4

=item C<uri>

a URI instance to match with.

=back

=head3 Returns

If it matches then a substitutions hash is returned, otherwise -
undef. If no placeholders in the URI empty hash is returned. Note that
the method ignores query and fragment parts of URI.

=cut

sub match {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my $uri);

    my $pattern_uri = $self->clone();
    my $matching_uri = $uri->clone();

    $pattern_uri->query = undef;
    $pattern_uri->fragment = undef;
    $matching_uri->query = undef;
    $matching_uri->fragment = undef;

    my $pattern = $pattern_uri->string;
    $pattern =~ s/\:([a-zA-Z]\w+)/(?<$1>\\w+)/g;

    my $group;
    if ($matching_uri->string =~ /^$pattern\/?$/) {
        $group = {};
        if (%+) {
            %$group = %+;
        }
    }

    return $group;
}

=head2 B<path_concat()>

Concatenates the url path with another path.

=head3 Arguments

=over 4

=item C<string>

=back

=cut

sub path_concat {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my $string);

    my $segments = [
        $self->_uri->path_segments(),
        $self->_uri->new($string)->path_segments()];
    $self->_uri->path_segments(grep($_, @{$segments}));

    return $self;
}

=head2 B<substitute()>

Substitutes values to the URI placeholders.

=head3 Arguments

=over 4

=item C<hash>

a hash of substitutions.

=back

=head3 Throws

=over 4

=item C<Eve::Error::Value>

when not enough or redundant substitutions are specified.

=back

=cut

sub substitute {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my $hash);

    my $string = $self->string;

    for my $key (keys %{$hash}) {
        my $value = $hash->{$key};
        if ($string =~ s/\:$key/$value/g) {
            # It is okay
        } else {
            Eve::Error::Value->throw(
                message => 'Redundant substitutions are specified');
        }
    }

    if ($string =~ /\:([a-zA-Z]\w+)/) {
        Eve::Error::Value->throw(
            message => 'Not enough substitutions are specified');
    }

    return $self->new(string => $string);
}

=head2 B<get_query_parameter()>

Returns a query parameter value for a certain parameter name.

=head3 Arguments

=over 4

=item C<name>

=back

=cut

sub get_query_parameter {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my $name);

    return $self->_uri->query_param($name);
}

=head2 B<set_query_parameter()>

Sets a query parameter value or a list of values for a certain
parameter name.

=head3 Arguments

=over 4

=item C<name>

=item C<value>

If a scalar value is passed, it is assigned as a single value for the
parameter name. If a list reference is passed, the parameter is
assigned as a list.

=back

=cut

sub set_query_parameter {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my ($name, $value));

    my $result;
    if (not defined $value) {
        $result = $self->_uri->query_param_delete($name);
    } else {
        $result = $self->_uri->query_param($name, $value);
    }

    return $result;
}

=head2 B<get_query_hash()>

Gets query string parameters as a hash.

=cut

sub get_query_hash {
    my $self = shift;

    my %result = $self->_uri->query_form();

    return \%result;
}

=head2 B<set_query_hash()>

Sets query string parameters as a hash.

=head3 Arguments

=over 4

=item C<hash>

=item C<delimiter>

=back

=cut

sub set_query_hash {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my $hash, my $delimiter = '&');

    $self->_uri->query_form($hash, $delimiter);

    return $self->_uri->query;
}

=head2 B<is_relative()>

Returns 0 or 1 depending on the URI.

=head3 Returns

=over 4

=item C<1>

the URI is relative, e.g. C</some/path>

=item C<0>

the URI is absolute, e.g. C<http://example.com>

=back

=cut

sub is_relative {
    my $self = shift;

    return ($self->_uri->scheme() ? 0 : 1);
}

=head1 SEE ALSO

=over 4

=item C<URI>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Igor Zinovyev.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=head1 AUTHOR

=over 4

=item L<Sergey Konoplev|mailto:gray.ru@gmail.com>

=item L<Igor Zinovyev|mailto:zinigor@gmail.com>

=back

=cut

1;
