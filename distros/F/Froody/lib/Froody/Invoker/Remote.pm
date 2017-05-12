package Froody::Invoker::Remote;
use strict;
use warnings;

use base qw(Froody::Invoker);

__PACKAGE__->mk_accessors(qw( url ));

use Froody::Response;
use LWP::Simple ();
use URI;

our $VERSION = 0.01;

use Froody::Response::String;
use Froody::Response::Error;

use HTTP::Request::Common;
use LWP::UserAgent;
use Encode qw(encode_utf8);
my $ua = LWP::UserAgent->new;

sub invoke
{
  my $self   = shift;
  my $method = shift;
  my $params = shift;

  # build a URI
  my $uri = URI->new($self->url);
  my $multi = undef;
  for my $key (keys %$params) {
    my $arg_data = $method->arguments->{$key};
    my $value = delete $params->{$key};
    # HTTP::Request::Common doesn't like undef
    $value = '' unless defined $value;
    no warnings 'uninitialized';
    if ($arg_data->{type}[0] eq 'multipart') {
      if (ref($value) eq 'ARRAY' and ref($value->[0])) {
        $value = $value->[0];
      }
      $multi ||= 1;
      if (UNIVERSAL::isa($value, "Froody::Upload")) {
        $value = [ $value->filename, $value->client_filename ];
      } elsif (!ref($value)) {
        $value = [$value];
      }
    } elsif ($arg_data->{type}[0] eq 'csv' and ref($value) eq 'ARRAY') {
      $value = join(",", @$value);
    }
    $params->{$key} = ref $value ? $value : encode_utf8($value);
  }
  $params->{method} = $method->full_name; 

  # Create a request
  my $req = POST $uri, 
    Content_Type => 'form-data',
    Content => [ %$params ];
  my $res = $ua->request($req);

  unless ($res->is_success) {  
    Froody::Error->throw("froody.invoke.remote", "Bad response from remote server - ". $res->status_line); 
  }

  # return whatever we got
  my $frs = Froody::Response::String->new();
  $frs->set_bytes($res->content);
  $frs->structure($method);
  return $frs;
}

sub source {
  shift->url;
}

=head1 NAME

Froody::Invoker::Remote - invoker that calls methods remotely

=head1 SYNOPSIS

  use Froody::Invoker::Remote;

  my $remote = Froody::Invoker::Remote
                 ->new()
                 ->url("http://someserver.com/restendpoint/");
  
  my $method = Froody::Method->new()
                             ->full_name("fred.bar.baz")
                             ->invoker($remote);
  
  my $response = $method->call({ foo => "wibble" });

=head1 DESCRIPTION

An Invoker that calls a remote server to get the Froody::Response.

=head2 Accessors

=over

=item url

The URL of the REST endpoint.

=item source

Returns where this invoker originated

=back

=head1 BUGS

None known.

Please report any bugs you find via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Froody>

=head1 AUTHOR

Copyright Fotango 2005.  All rights reserved.

Please see the main L<Froody> documentation for details of who has worked
on this project.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Froody>, L<Froody::Invoker>

=cut

1;
