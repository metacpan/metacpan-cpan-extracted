package HTTP::Router::Route;

use strict;
use warnings;
use base 'Class::Accessor::Fast';
use URI::Template::Restrict;
use HTTP::Router::Match;
use Scalar::Util ();

__PACKAGE__->mk_accessors(qw'path params conditions');

sub new {
    my ($class, %args) = @_;
    return bless {
        path       => '',
        params     => {},
        conditions => {},
        %args,
    }, $class;
}

sub parts {
    my $self = shift;
    $self->{parts} ||= $self->path =~ tr!/!/!;
}

sub append_path {
    my ($self, $path) = @_;
    $self->{path} .= (defined $path ? $path : '');
}

{
    no strict 'refs';
    for my $name (qw'params conditions') {
        *{"add_${name}"} = sub {
            my ($self, %args) = @_;
            while (my ($key, $value) = each %args) {
                $self->$name->{$key} = $value;
            }
        };
    }
}

sub templates {
    my $self = shift;
    $self->{templates} ||= URI::Template::Restrict->new($self->path);
}

{
    no strict 'refs';
    for my $method (qw'variables extract') {
        *{$method} = sub {
            my ($self, @args) = @_;
            $self->templates->$method(@args);
        };
    }
}

sub match {
    my ($self, $req) = @_;
    return unless Scalar::Util::blessed($req) and $req->can('path');

    my $path = $req->path;
    defined $path or return;

    # path, captures
    my %captures;
    if ($self->variables) {
        my $size = $path =~ tr!/!/!;
        $size == $self->parts             or return; # FIXME: ignore parts
        %captures = $self->extract($path)     or return;
        $self->_is_valid_variables(\%captures) or return;
    }
    else {
        $path eq $self->path or return;
    }

    # conditions
    $self->_is_valid_request($req) or return;

    my %params = %captures;
    for my $key (keys %{ $self->params }) {
        next if exists $params{$key};
        $params{$key} = $self->params->{$key};
    }

    return HTTP::Router::Match->new(
        params   => \%params,
        captures => \%captures,
        route    => $self,
    );
}

sub _is_valid_variables {
    my ($self, $vars) = @_;

    for my $name (keys %$vars) {
        return 0 unless $self->_validate($vars->{$name}, $self->conditions->{$name});
    }

    return 1;
}

sub _is_valid_request {
    my ($self, $req) = @_;

    my $conditions = do {
        my %vars = map { $_ => 1 } $self->variables;
        [ grep { !$vars{$_} } keys %{ $self->conditions } ];
    };

    for my $name (@$conditions) {
        return 0 unless my $code = $req->can($name);

        my $value = $code->($req);
        if ($name eq 'method') { # HEAD equals to GET
            $value = 'GET' if $value eq 'HEAD';
        }

        return 0 unless $self->_validate($value, $self->conditions->{$name});
    }

    return 1;
}

sub _validate {
    my ($self, $input, $expected) = @_;
    # arguments
    return 0 unless defined $input;
    return 1 unless defined $expected;
    # validation
    return $input =~ $expected              if ref $expected eq 'Regexp';
    return grep { $input eq $_ } @$expected if ref $expected eq 'ARRAY';
    return $input eq $expected;
}

sub uri_for {
    my ($self, $args) = @_;

    for my $name (keys %{ $args || {} }) {
        return unless $self->_validate($args->{$name}, $self->conditions->{$name});
    }

    return $self->templates->process_to_string(%$args);
}

1;

=for stopwords params

=head1 NAME

HTTP::Router::Route - Route Representation for HTTP::Router

=head1 SYNOPSIS

  use HTTP::Router;
  use HTTP::Router::Route;

  my $router = HTTP::Router->new;

  my $route = HTTP::Router::Route->new(
      path       => '/',
      conditions => { method => 'GET' },
      params     => { controller => 'Root', action => 'index' },
  );

  $router->add_route($route);

=head1 METHODS

=head2 match($req)

Returns a L<HTTP::Router::Match> object, or C<undef>
if route does not match a given request.

=head2 append_path($path)

Appends path to route.

=head2 add_params($params)

Adds parameters to route.

=head2 add_conditions($conditions)

Adds conditions to route.

=head2 extract($path)

Extracts variable values from $path, and returns variable hash.

=head2 uri_for($args?)

Returns a path which is processed with parameters.

=head1 PROPERTIES

=head2 path

Path string for route.

=head2 params

Route specific parameters.

=head2 conditions

Conditions for determining route.

=head2 templates

L<URI::Template::Restrict> representation with route path.

=head2 parts

Size of splitting route path with slash.

=head2 variables

Variable names in route path.

=head1 AUTHOR

NAKAGAWA Masaki E<lt>masaki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::Router>

=cut
