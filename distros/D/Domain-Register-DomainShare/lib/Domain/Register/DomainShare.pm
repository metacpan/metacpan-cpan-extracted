package Domain::Register::DomainShare;

our $VERSION = '1.02';

=head1 NAME
Domain::Register::DomainShare - an interface to Dot TK's DomainShare API

=cut

=head1 SYNOPSIS

  # use the library
  use Domain::Register::DomainShare;

  # create a new client for DomainShare
  my $client = Domain::Register::DomainShare->new();

  # ping DomainShare server
  my $result = $client->ping();

  ...

  # check domain availability  
  my $result = $client->availability_check({
      email => 'domainshare@example.tk',
      password => 'password',
      domainname => 'testdomain1.tk'
  });

=cut

=head1 DESCRIPTION

Dot TK's DomainShare API service lets developers design computer programs and 
online applications that interact directly with the Dot TK registration system 
for FREE domain name registration services.

That basically means that Dot TK allows developers to register free domain names 
with the .TK extension from their applications.

For more information and a list of available functions, please review the technical
documentation available via http://domainshare.tk.


=head1 SUBROUTINES/METHODS

An object of this class represents a potential dialogue with Dot TK's servers,
and as such needs correct log in credentials to do anything useful.

Standard usage is to create an object and perform an arbitrary number of 
transactions with the remote server. There is a ping transaction which does not 
require parameters, that should be used to test if a connection is still possible. 

No state is saved by the remote server between transactions, so it is not
necessary to log on or log off separately, as long as valid credentials are
supplied.

A full list of available functions is available via the technical documentation 
available via http://domainshare.tk.


=head1 MULTIVALUE PARAMETERS

Although most calls require unique values for the given parameters, some of them
should or could be multivalue. An example multivalue parameter is nameserver.
When registering a domain with specifying nameservers, you need to pass at least
two nameservers.

  # register domain
  my $result = $client->register({
      email => 'domainshare@example.tk',
      password => 'password',
      domainname => 'testdomain1.tk',
      nameserver => ['ns1.example.tk', 'ns2.example.tk' ]
  });

As you see, the multivalue parameter can simply be specified by an array reference.


=head1 RETURN VALUES

Any call to a function will return an array where first element is status code.
The status code will be set to 1 upon success, 0 upon failure. The second element
is a hashref with either an error discription data, or the function's return result. 

Success looks like this:

  $VAR1 = [
	    1,
	    {
	      'status' => 'DOMAIN AVAILABLE',
	      'type' => 'result',
	      'domainname' => 'TEST123.TK',
	      'domaintype' => 'FREE'
	    }
	  ];

Error looks like this:

  $VAR1 = [
	    0,
	    {
	      'reason' => 'Invalid domain name',
	      'type' => 'Server Error'
	    }
	  ];

"type" can be 'Server Error' or 'Input Error'. 'Server Error' means the error was 
returned by API server Input Error relates to missed mandatory fields. Error message
is in the "reason" field in both cases.

=cut

use strict;
use warnings;

use REST::Client;
use URI::Escape;
use XML::Simple;

sub new {
    my $class = shift;
    my $self = bless({}, $class);

    $self->{_client} = REST::Client->new({ host => 'https://api.domainshare.tk', timeout => 10 });
    
    return $self;
}

sub ping {
    my ($self) = @_;
    $self->_make_request('ping', undef, [], {});
}

sub availability_check {
    my ($self, $args) = @_;
    $self->_make_request('availability_check', undef, ['email', 'password', 'domainname'], $args);
}

sub register {
    my ($self, $args) = @_;
    $self->_make_request('register', 'registration', ['email', 'password', 'domainname', 'enduseremail'], $args);
}

sub renew {
    my ($self, $args) = @_;
    $self->_make_request('renew', undef, ['email', 'password', 'domainname'], $args);
}

sub host_registration {
    my ($self, $args) = @_;
    $self->_make_request('host_registration', undef, ['email', 'password', 'hostname', 'ipaddress'], $args);
}

sub host_removal {
    my ($self, $args) = @_;
    $self->_make_request('host_removal', undef, ['email', 'password', 'hostname'], $args);
}

sub host_list {
    my ($self, $args) = @_;
    $self->_make_request('host_list', undef, ['email', 'password', 'domainname'], $args);
}

sub modify {
    my ($self, $args) = @_;
    $self->_make_request('modify', undef, ['email', 'password', 'domainname'], $args);
}

sub resend_email {
    my ($self, $args) = @_;
    $self->_make_request('resend_email', undef, ['email', 'password', 'domainname'], $args);
}

sub domain_deactivate {
    my ($self, $args) = @_;
    $self->_make_request('domain_deactivate', undef, ['email', 'password', 'domainname', 'reason'], $args);
}

sub domain_reactivate {
    my ($self, $args) = @_;
    $self->_make_request('domain_reactivate', undef, ['email', 'password', 'domainname'], $args);
}

sub update_parking {
    my ($self, $args) = @_;
    $self->_make_request('update_parking', undef, ['email', 'password', 'domainname'], $args);
}


sub _make_request {
    my ($self, $name, $xmlname, $fields, $args) = @_;
    $xmlname ||= $name;

    my ($status, $errors) = check_mandatory_fields($args, @$fields);
    return ($status, $errors) unless ($status);
    $self->{_client}->POST("/$name", prepare_post_body($args) );

    print $self->{_client}->responseContent() if $::DotTKDebug;
    my $xc = XMLin($self->{_client}->responseContent());

    return parse_server_reply($xc, $xmlname);
}

sub prepare_post_body {
  my ($args) = @_;
  join ( '&', map {
    my $key = $_;
    if (ref $args->{$key} eq 'ARRAY') {
      my @a = map { URI::Escape::uri_escape($key) . '=' . URI::Escape::uri_escape($_) } @{$args->{$key}};
    } else {
      URI::Escape::uri_escape($key) . '=' . URI::Escape::uri_escape($args->{$_});
    }
    ;
  } (keys %$args));
  #join ( '&', (map { URI::Escape::uri_escape($_) . '=' . URI::Escape::uri_escape($args->{$_}) } keys %$args));
}

sub check_mandatory_fields
{
  my ( $args, @names) = @_;
  for my $name (@names) {
    if ((!defined($args->{$name})) || (length($args->{$name}) == 0)) {
      return (0, { type => "Input error", reason => "$name is mandatory"} );
    }
  }
  return (1, undef);
}

sub parse_server_reply
{
  my ($xc, $namespace) = @_;
  if ($xc->{status} eq 'OK') {
    return (1, values_for($xc, $namespace));
  } else {
    return (0, { type => "Server Error", reason => $xc->{reason} });
  }
}

sub values_for
{
  my ($xc, $namespace) = @_;
  $xc->{"partner_$namespace"};
}

1;


=head1 AUTHOR

Dot TK DomainShare Program 

Please report any bugs or feature requests to C<bug-domain-register-domainshare at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Domain-Register-DomainShare>.  

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Domain::Register::DomainShare

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Domain-Register-DomainShare>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Domain-Register-DomainShare>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Domain-Register-DomainShare>

=item * Search CPAN

L<http://search.cpan.org/dist/Domain-Register-DomainShare/>

=back

=head1 COPYRIGHT

Copyright (c) 2010 Dot TK Ltd. All Rights Reserved. This module is free software; you can redistribute it
and/or modify it under the terms of either:  a) the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any later version, or b) the "Artistic License",
that is, the same terms as Perl itself.

This module requires that the client user have an active account with Dot TK L<http://www.dot.tk> in order 
to access it's key functionality.

=cut

