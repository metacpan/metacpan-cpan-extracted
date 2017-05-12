package JSON::RPC::Simple;

use strict;
use warnings;

use Scalar::Util qw(blessed refaddr);
use Carp qw(croak);

our $VERSION = '0.06';

our $ClientClass = "JSON::RPC::Simple::Client";
sub connect {
    my $pkg = shift;

    require JSON::RPC::Simple::Client;
    
    my $self = $ClientClass->new(@_);
    return $self;
}

sub dispatch_to {
    my $pkg = shift;
    
    require JSON::RPC::Simple::Dispatcher;
    
    my $self = JSON::RPC::Simple::Dispatcher->new();
    return $self->dispatch_to(@_);
}

{    
    my %method_attributes;

    sub fetch_method_arguments {
        my ($pkg, $code) = @_;

        return unless exists $method_attributes{refaddr $code};
        return $method_attributes{refaddr $code};
    }

    my $method_attr_re = qr{
        ^
        JSONRpcMethod
        (?:\(\)|\(
            \s*
            (\w+ (\s*,\s* \w+)*)?
            \s*
        \))?
    }sx;
    
    sub MODIFY_CODE_ATTRIBUTES {
        my ($class, $code, @attributes) = @_;
        
        # Check if this contains a JSONRpcMethod attribute
        my @bad;
        for my $attribute (@attributes) {
            if ($attribute =~ $method_attr_re) {
                my @attrs = split /\s*,\s*/, ($1 || "");
                $method_attributes{refaddr $code} = \@attrs;
            }
            else {
                push @bad, $attribute;
            }
        }
        
        return @bad;
    }
}

1;
__END__

=head1 NAME

JSON::RPC::Simple - Simple JSON-RPC client and dispatcher (WD 1.1 subset only currently)

=head1 SYNOPSIS

As client

  use JSON::RPC::Simple;
  
  my $client = JSON::RPC::Simple->connect("https://www.example.com/API/", {
    timeout => 600,
  });
  my $r = $client->echo({ param1 => "value" });

As server:

  package MyApp::API;
  
  use base qw(JSON::RPC::Simple);

  sub new { return bless {}, shift };
  
  sub echo : JSONRpcMethod(Arg1, Arg2, Arg3) {
    my ($self, $request, $args) = @_;
  }
      
  package MyApp::Handler;
  
  my $dispatcher = JSON::RPC::Simple->dispatch_to({
    "/API" => MyApp::API->new(),
    "/OtherAPI" => "MyApp::OtherAPI",
  });
  
  sub handle {
    my $request = shift; # Assume a HTTP::Request
    my $response = $dispatcher->handle($request->uri->path, $request);
    return $response; # Assume a HTTP::Response
  }
  
=head1 DESCRIPTION

This module is a very simple JSON-RPC 1.1 WD implementation that only 
supports a subset of the specification.

It supports

=over 4

=item Named and positonal arguments

=item Error objects

=back

=head1 USAGE

=head2 As a client

This module provides a class method for creating a client that works as a 
shortcut to C<JSON::RPC::Simple::Client-E<gt>new(...)>. 

=over 4

=item connect(URL)

=item connect(URL, \%OPTIONS)

Returns a new client for the given I<URL> with the optional I<%OPTIONS>.

See L<JSON::RPC::Simple::Client/options> for what options it accepts.

=back

=head1 AUTHOR

Claes Jakobsson, E<lt>claesjac@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2011 by Claes Jakobsson and Glue Finance AB

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
