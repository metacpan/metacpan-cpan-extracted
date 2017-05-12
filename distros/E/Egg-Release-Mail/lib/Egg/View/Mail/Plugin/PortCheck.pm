package Egg::View::Mail::Plugin::PortCheck;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: PortCheck.pm 285 2008-02-28 04:20:55Z lushe $
#
use strict;
use warnings;
use Carp qw/ croak /;

our $VERSION = '0.01';

sub _setup {
	my($class, $e)= @_;
	$e->isa('Egg::Plugin::Net::Scan')
	    || die q{I want setup 'Egg::Plugin::Net::Scan'.};
	my $c= $class->config;
	$c->{scan_host}    ||= 'localhost';
	$c->{scan_port}    ||= 25;
	$c->{scan_timeout} ||= 3;
	$class->mk_accessors('scan');
	$class->next::method($e);
}
sub send {
	my $self= shift;
	my $c   = $self->config;
	my $res = $self->scan || do {
		my $scan= $self->e->port_scan
		   (@{$c}{qw/ scan_host scan_port /}, timeout=> $c->{scan_timeout} );
		$self->scan($scan);
	  };
	$res->is_success ? $self->next::method(@_): 0;
}

1;

__END__

=head1 NAME

Egg::View::Mail::Plugin::PortCheck - The operation of the mail server is checked before Mail Sending. 

=head1 SYNOPSIS

  my $mail= $e->view('mail_label');
  
  $mail->send( ........ ) || do {
  
    unless ($mail->scan->is_success) {
  
       .... The mail server is not operating.
  
    }
  
    };

=head1 DESCRIPTION

It is MAIL plugin that checks the operation of the mail server before Mail Sending. 

When 'PortCheck' is passed to 'setup_plugin' method, it is built in.

  package MyApp::View::Mail::MyComp;
  .........
  
  __PACKAGE__->setup_plugin(qw/ PortCheck /);

It is necessary to set up it and L<Egg::Plugin::Net::Scan>.

  package MyApp;
  use Egg qw/ Net::Scan /;

=head1 CONFIGURATION

=head3 scan_host

Host name to be checked.

Default is 'localhost'.

=head3 scan_port

Port number to be checked.

Default is '25'.

=head3 scan_timeout

Time to wait for answer from check object.

Default is '3'.

=head1 METHODS

=head2 send ([MAIL_DATA_HASH])

Mail is transmitted.

If the check object is not operating, 0 is returned and processing is interrupted.

Please adjust the built-in order when competing with other components for which
'send' method is used.

  __PACKAGE__->setup_plugin(qw/
    Lot
    PortCheck
    /);

=head2 scan

The object returned from L<Egg::Plugin::Net::Scan> is stored.

  if (my $scan= $mail->scan) {
     $e->stash->{error_message}= $scan->is_error;
  }

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::View::Mail>,
L<Egg::View::Mail::Base>,
L<Egg::Plugin::Net::Scan>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

