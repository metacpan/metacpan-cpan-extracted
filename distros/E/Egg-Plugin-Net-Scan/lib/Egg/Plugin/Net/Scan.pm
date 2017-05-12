package Egg::Plugin::Net::Scan;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Scan.pm 363 2008-08-20 00:07:33Z lushe $
#
use strict;
use warnings;
use Carp qw/ croak /;
use Socket;

our $VERSION = '3.02';

sub port_scan {
	my $e= shift;
	my $host= shift || croak q{ I want 'Host name' or 'IP address'. };
	my $port= shift || croak q{ I want 'Port number'. };
	my $attr= $_[1] ? {@_}: ($_[0] || {});

	if ($host!~/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) {
		my $name= gethostbyname($host)
		|| return Egg::Plugin::Net::Scan::Result->new(q{ The Host doesn't have IP address. });
		$host= join '.', unpack("C4", $name);
	}
	$attr->{timeout} ||= 1;
	$attr->{protcol} ||= 'tcp';
	my($protname, $alias ,$protnum)= getprotobyname($attr->{protcol});
	my $connect= inet_aton($host)
	|| return Egg::Plugin::Net::Scan::Result->new(qq{ Cannot connect $host\:$port. });
	eval {
		my $main_alrm= alarm(0);
		local($SIG{ALRM})= sub{
			alarm($main_alrm);
			die qq/No response $host\:$port./;
		  };
		alarm($attr->{timeout});
		if ($protname eq 'udp') {
			socket(SOCK, PF_INET, SOCK_DGRAM,  $protnum)
			  || die q/Socket creation fault/;
		} else {
			socket(SOCK, PF_INET, SOCK_STREAM, $protnum)
			  || die q/Socket creation fault/;
		}
		connect(SOCK, sockaddr_in($port, $connect))
		  || die qq/Cannot connect $host\:$port./;
		select(SOCK);
		local $|= 1;
		select(STDOUT);
		close(SOCK);
		alarm($main_alrm);
	 };
	my $err= $@ || 'is success';
	Egg::Plugin::Net::Scan::Result->new($err);
}

package Egg::Plugin::Net::Scan::Result;
use strict;
use base qw/ Class::Accessor::Fast /;

__PACKAGE__->mk_accessors(qw/ is_success no_response is_error /);

sub new {
	my $class = shift;
	my $errstr= shift || 0;
	my $param =
	   $errstr=~/^is success/  ? { is_success=> 1 }
	 : $errstr=~/^No response/ ? { is_block  => 1 }
	 : { is_error=> $errstr };
	bless $param, $class;
}

1;

__END__

=head1 NAME

Egg::Plugin::Net::Scan - Network host's port is checked.

=head1 SYNOPSIS

  use Egg qw/ Net::Scan /;

  # If the port is effective, by the 25th mail is sent.
  my $scan= $e->port_scan('192.168.1.1', 25, timeout => 3 );
  if ( $scan->is_success ) {
    $e->mail->send;
    print " Mail was transmitted.";
  } elsif ( $scan->is_block ) {
    print " Mail server has stopped. ";
  } else {
    print " Error occurs: ". $scan->is_error;
  }

=head1 DESCRIPTION

It is a plugin to check the operational condition of arbitrary host's port.

* Because 'alarm' command is used, it operates in the platform that doesn't
  correspond. A fatal error occurs when it is made to do.

=head1 METHODS

=head2 port_scan ( [TARGET_HOST], [TARGET_PORT], [OPTION] )

The port scan is done and the result is returned
with the 'Egg::Plugin::Net::Scan::Result' object.

When TARGET_HOST and TARGET_PORT are omitted, the exception is generated.

The following options can be passed to OPTION.

=over 4

=item * timeout

Time to wait for answer from port.

* It is judged that it is blocked when there is no answer in this time.

Default is '1'.

=item * protcol

Communication protocol.

Default is 'tcp'.

=back

=head1 RESULT METHODS

It is a method supported by Egg::Plugin::Net::Scan::Result.

  my $result= $e->port_cacan( ....... );

=head2 new

Constructor.

=head2 is_success

When the answer from the port is admitted, true is restored.

=head2 is_block

When the answer from the port doesn't come back within the second of
timeout, true is returned.

=head2 is_error

When some errors occur, the error message is returned.

=head1 SEE ALSO

L<Socket>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

