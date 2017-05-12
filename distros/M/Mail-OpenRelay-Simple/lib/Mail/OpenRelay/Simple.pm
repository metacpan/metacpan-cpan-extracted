package Mail::OpenRelay::Simple;

use 5.008;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use Carp;
use Net::Telnet;

our $VERSION = '0.02';
$VERSION = eval $VERSION;

__PACKAGE__->mk_accessors( qw(host port timeout from_email rcpt_email banner debug));

$| = 1;

sub check {

	my $self       = shift;
	my $host       = $self->host;
	my $port       = $self->port;
	my $timeout    = $self->timeout;
	my $from_email = $self->from_email;
	my $rcpt_email = $self->rcpt_email;
	my $banner     = $self->banner;
	my $debug      = $self->debug;

	$banner     = $banner     ? $banner     : 0; 
	$debug      = $debug      ? $debug      : 0; 
	$from_email = $from_email ? $from_email : "test\@foobar.com"; 
	$rcpt_email = $rcpt_email ? $rcpt_email : "test\@foobar.com"; 

	print ". Try to connect to $host...\n" if $debug == 2;

	my $t = new Net::Telnet(
		Host    => $host,
		Port    => $port    || '25',
		Timeout => $timeout || '8', 
		Errmode => "return"
	);

	if ($t){
		my $match = $t->getline;

		if ($match){

			my $Banner = $match;
			chomp $Banner; for ($Banner) { s/^220\s//; }
	
			if ($match =~ m/^220/){

				print ". HELO foo\n" if $debug == 1;
				$t->print("HELO foo");

				$match = $t->getline;
				if ($match){
					if ($match =~ /^250/){

						print ". MAIL FROM:<$from_email>\n" if $debug == 1; 
						$t->print("MAIL FROM:<$from_email>");

						$match = $t->getline;
				
						if ($match){
							if ($match =~ /^250/){

								print ". RCPT TO:<$rcpt_email>\n" if $debug == 1;
								$t->print("RCPT TO:<$rcpt_email>");
							
								$match = $t->getline;
						
								if ($match){
									if ($match =~ /^250/){
										print "$Banner\n" if $banner == 1;
										return 1;
									} else {
										return 0;
									}
								} else {
									print ". can't send email with $host!\n" if $debug == 1;
								}
							}
						}
					}
				}
			}
		}
		$t->close;
	} else {
		print ". can't connect to host $host on port $port\n" if $debug == 1;
	}

	return;
}

1;
__END__

=head1 NAME

Mail::OpenRelay::Simple - check if a mail server runs as an open relay. 

=head1 SYNOPSIS

  use Mail::OpenRelay::Simple;

  my $host = "127.0.0.1"; 
 
  my $scan = Mail::OpenRelay::Simple->new({
    host       => $host,
    timeout    => 5,
    from_email => "test\@foobar.com",
    rcpt_email => "test\@foobar.com",
    banner     => 0,
    debug      => 0
  });

  print "$host open relay\n" if $scan->check;  

=head1 DESCRIPTION

This module permit to check if a mail server runs as an open relay.

B<Note: this module provides only a simple test. No email message is sended.>

=head1 METHODS

=head2 new

The constructor. Given a host returns a L<Mail::OpenRelay::Simple> object:

  my $scan = Mail::OpenRelay::Simple->new({ host => "127.0.0.1" });

Optionally, you can also specify :

=over 2

=item B<port>

remote port. Default is 25;

=item B<timeout>

default is 8 seconds;
 
=item B<from_email>

default is test\@foobar.com; 

=item B<rcpt_email>

default is test\@foobar.com; 

=item B<banner>

0 (none), 1 (show mail server banner). Default is 0;

=item B<debug>

0 (none), 1 (show all requests). Defualt is 0;

=back

=head2 check 

Checks the target.

  $scan->check;

=head1 SEE ALSO

http://en.wikipedia.org/wiki/Open_mail_relay

=head1 AUTHOR

Matteo Cantoni, E<lt>mcantoni@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

You may distribute this module under the terms of the Artistic license.
See Copying file in the source distribution archive.

Copyright (c) 2006, Matteo Cantoni

=cut
