package Egg::Request::FastCGI;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: FastCGI.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;
use CGI::Fast;
use base qw/ Egg::Request::CGI /;

our $VERSION = '3.00';

sub _init_handler {
	my($class, $e)= @_;
	my $p= $e->namespace;
	my $name_uc= uc($p);
	my($count, $life_count, $life_time, $reboot);
	if ($count= $ENV{"${name_uc}_FCGI_LIFE_COUNT"}) {
		$life_count= sub { --$count > 0 ? 1: 0 };
	}
	if (my $ltime= $ENV{"${name_uc}_FCGI_LIFE_TIME"}) {
		$ltime+= time;
		$life_time= sub { $ltime > time ? 1: 0 };
	}
	if (my $rl= $ENV{"${name_uc}_FCGI_REBOOT"}) {
		my $name= $rl ne 1 ? $rl: 'reboot';
		$reboot= sub { $_[0]->param($name) ? 0: 1 };
	}
	$reboot     ||= sub { 1 };
	$life_count ||= sub { 1 };
	$life_time  ||= sub { 1 };
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	*{"${p}::handler"}= sub {
		while (my $fcgi= CGI::Fast->new) {
			$p->run($fcgi);
			$reboot->($fcgi) || last;
			$life_count->()  || last;
			$life_time->()   || last;
		}
	  };
	@_;
}

1;

__END__

=head1 NAME

Egg::Request::FastCGI - Request class to use FastCGI. 

=head1 SYNOPSIS

Example is dispatch.fcgi

  #!/usr/bin/perl
  BEGIN {
    $ENV{MYAPP_REQUEST_CLASS}   = 'Egg::Request::FastCGI';
    $ENV{MYAPP_FCGI_LIFE_COUNT} =  200;
    $ENV{MYAPP_FCGI_LIFE_TIME}  = 1800;
    $ENV{MYAPP_FCGI_REBOOT}     = 'boot';
    };
  use MyApp;
  MyApp->handler;

=head1 DESCRIPTION

It is a request class to use FastCGI.

To make it loaded from Egg::Request, environment variable PROJECT_NAME_REQUEST_CLASS
is defined beforehand.

  BEGIN{
   $ENV{MYAPP_REQUEST_CLASS}= 'Egg::Request::FastCGI';
   };

Moreover, the following environment variables are accepted, and define it similarly
in the BEGIN block, please when setting it.

=over 4

=item * [PROJECT_NAME]_FCGI_LIFE_COUNT

After the frequency is processed being set, the process is ended.

=item * [PROJECT_NAME]_FCGI_LIFE_TIME

The process of each set number of seconds is ended.

=item * [PROJECT_NAME]_FCGI_REBOOT

The process is dropped at once when request query of the name is effective when
the name of request query is set.
1 When is set, it is assumed the one that 'reboot' of default was specified.
For instance, the process falls after outputting contents when assuming
http://ho.com/?reboot=1.
Contents are output according to the process that started newly when being 
request it next time.
Please do not forget the invalidated thing in the real thing operation because 
this is a setting for debug.

* Please note no movement the intention when you do debug by starting two or more
  processes.

=back

This module only sets up the handler for L<CGI::Fast>.

Processing requesting original has succeeded to L<Egg::Request::CGI>.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Request>,
L<Egg::Request::CGI>,
L<CGI::Fast>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

