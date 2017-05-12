package Test::HTTP::Router;

use strict;
use warnings;
use Exporter 'import';
use Test::Builder;
use Test::Deep;
use Test::MockObject;

our @EXPORT = qw(
    path_ok path_not_ok
    match_ok match_not_ok
    params_ok params_not_ok
);

our $Test = Test::Builder->new;

sub to_request {
    my $args = ref $_[0] ? shift : { @_ };
    my $req  = Test::MockObject->new;
    $req->set_always($_ => $args->{$_}) for keys %$args;
    $req;
}

sub path_ok {
    my ($router, $path, $message) = @_;
    my $req = to_request(path => $path);
    $Test->ok(my $match = $router->match($req) ? 1 : 0, $message || "matched $path");
}

sub path_not_ok {
    my ($router, $path, $message) = @_;
    my $req = to_request(path => $path);
    $Test->ok(my $match = $router->match($req) ? 0 : 1, $message || "not matched $path");
}

sub match_ok {
    my $router  = shift;
    my $message = (@_ == 3 || @_ == 2 and not ref $_[-1]) ? pop : undef;
    my $req     = ref $_[0] ? $_[0] : to_request(%{ $_[1] || {} }, path => $_[0]);
    $Test->ok(my $match = $router->match($req) ? 1 : 0, $message || "matched @{[$req->path]} with conditions");
}

sub match_not_ok {
    my $router  = shift;
    my $message = (@_ == 3 || @_ == 2 and not ref $_[-1]) ? pop : undef;
    my $req     = ref $_[0] ? $_[0] : to_request(%{ $_[1] || {} }, path => $_[0]);
    $Test->ok(my $match = $router->match($req) ? 0 : 1, $message || "not matched @{[$req->path]} with conditions");
}

sub params_ok {
    my $router  = shift;
    my $message = (@_ == 4 || @_ == 3 and not ref $_[-1]) ? pop : undef;
    my $params  = $_[-1];
    my $req     = ref $_[0] ? $_[0] : to_request(%{ $_[1] || {} }, path => $_[0]);

    my $match = $router->match($req);
    $Test->ok($match and eq_deeply($match->params, $params) ? 1 : 0, $message || "valid params at @{[$req->path]}");
}

sub params_not_ok {
    my $router  = shift;
    my $message = (@_ == 4 || @_ == 3 and not ref $_[-1]) ? pop : undef;
    my $params  = $_[-1];
    my $req     = ref $_[0] ? $_[0] : to_request(%{ $_[1] || {} }, path => $_[0]);

    my $match = $router->match($req);
    $Test->ok($match and eq_deeply($match->params, $params) ? 0 : 1, $message || "invalid params at @{[$req->path]}");
}

1;

=head1 NAME

Test::HTTP::Router - Route Testing

=head1 SYNOPSIS

  use Test::More;
  use Test::HTTP::Router;
  use HTTP::Router;

  my $router = HTTP::Router->new;
  $router->add_route('/' => (
      conditions => { method => 'GET' },
      params     => { controller => 'Root', action => 'index' },
  ));

  match_ok $router, '/', { method => 'GET' };
  params_ok $router, '/', { method => 'GET' }, { controller => 'Root', action => 'index' };

=head1 METHODS

=head2 path_ok($router, $path, $message?)

=head2 path_not_ok($router, $path, $message?)

=head2 match_ok($router, $path, $conditions, $message?)

=head2 match_not_ok($router, $path, $conditions, $message?)

=head2 params_ok($router, $path, $conditions, $params, $message?)

=head2 params_not_ok($router, $path, $conditions, $params, $message?)

=cut
