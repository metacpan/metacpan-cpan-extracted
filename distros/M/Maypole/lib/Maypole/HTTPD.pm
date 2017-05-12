package Maypole::HTTPD;
use strict;
use warnings;

use base 'HTTP::Server::Simple::CGI';
use HTTP::Server::Simple::Static;
use Maypole::Constants;
use UNIVERSAL::require;

# signal to Maypole::Application 
BEGIN { $ENV{MAYPOLE_HTTPD} = 1 }

our $VERSION = '0.2';

=head1 NAME

Maypole::HTTPD - Stand alone HTTPD for running Maypole Applications

=head1 SYNOPSIS

  use Maypole::HTTPD;
  my $httpd=Maypole::HTTPD->new(module=>"BeerDB");
  $httpd->run();

=head1 DESCRIPTION

This is a stand-alone HTTPD for running your Maypole Applications.

=cut 

=head2 new

The constructor. Takes a hash of arguments. Currently supported:
    port - TCP port to listen to
    module - Maypole application Module name.

=cut 

sub new 
{
	my ($class, %args) = @_;
	my $self = $class->SUPER::new($args{port});
	$self->module($args{module});
	#eval "use $self->{module}";
    #die $@ if $@;
    $self->module->require or die "Couldn't load driver: $@";
	$self->module->config->uri_base("http://localhost:".$self->port."/");
	return $self;
}

=head2 module

Accessor for application module.

=cut

sub module {
    my $self = shift; 
    $self->{'module'} = shift if (@_); 
    return ( $self->{'module'} ); 
}

=head2 handle_request

Handles the actual request processing. Should not be called directly.

=cut

sub handle_request 
{
	my ($self,$cgi) = @_;
    
    my $rv;
	my $path = $cgi->url( -absolute => 1, -path_info => 1 );	
	
    if ($path =~ m|^/static|) 
    {
		$rv=DECLINED;
	} 
    else 
    {
		$rv = $self->module->run;
	}
    
	if ($rv == OK) {
		print "HTTP/1.1 200 OK\n";
		$self->module->output_now;
		return;
	} 
    elsif ($rv == DECLINED) 
    {
		return $self->serve_static($cgi,"./");
	} 
    else 
    {
		print "HTTP/1.1 404 Not Found\n\nPage not found"; 
	}
}

1;


=head1 SEE ALSO

L<Maypole>

=head1 AUTHOR

Marcus Ramberg, E<lt>marcus@thefeed.no<gt>
Based on Simon Cozens' original implementation.

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Marcus Ramberg


This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
