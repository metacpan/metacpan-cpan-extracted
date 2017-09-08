package Lab::VXI11;

use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

our @EXPORT = qw(
	DEVICE_ASYNC
	DEVICE_ASYNC_VERSION
	DEVICE_CORE
	DEVICE_CORE_VERSION
	DEVICE_INTR
	DEVICE_INTR_VERSION
	DEVICE_TCP
	DEVICE_UDP
);

our $VERSION = '0.02';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Lab::VXI11::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Lab::VXI11', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
=head1 NAME

Lab::VXI11 - Perl interface to VXI-11 Test&Measurement backend

=head1 SYNOPSIS

  use Lab::VXI11;

  my $client = Lab::VXI11->new('132.199.1.2', DEVICE_CORE, DEVICE_CORE_VERSION, "tcp");

  ($error, $lid, $abortPort, $maxRecvSize) = $client->create_link(0, 0, 0, "inst0");

  # Send "*IDN\n" command and read answer.
  ($error, $size) = $client->device_write($lid, 1000, 0, 0, "*IDN?\n");
  ($error, $reason, $data) = $client->device_read($lid, 100, 1000, 0, 0, 0);
  
  ($error) = $client->destroy_link($lid);

=head1 DESCRIPTION

Raw XS interface for VXI-11. Uses Sun's RPC library and C-code created by rpcgen.

The VXI-11 API is documented in the L<VXI-11 specification|http://www.vxibus.org/specifications.html>. A good tutorial can be found in Agilent's application note I<Using Linux to Control LXI Instruments Through VXI-11>.

=head1 INSTALLATION

On Linux, Sun's RPC library is part of the libc (glibc). Just use your CPAN client:

 $ cpanm Lab::VXI11

On Windows this module is untested (VISA contains a VXI11 driver).

=head1 METHODS

See the VXI-11 specs for more details.

=head2 new

  $client = Lab::VXI11->new($host, $prog, $vers, $proto); 

=head2 create_link

  ($erro, $lid, $abortPort, $maxRecvSize) = $client->create_link($clientId, $lockDevice, $lock_timeout, $device);

=head2 device_write

 ($error, $size) = $client->device_write($lid, $io_timeout, $lock_timeout, $flags, $data);

=head2 device_read

 ($error, $reason, $data) = $client->device_read($lid, $requestSize, $io_timeout, $lock_timeout, $flags, $termChar);

C<$termChar> needs to be a number, e.g. C<ord("\n")>.

=head2 device_readstb

 ($error, $stb) = $client->device_readstb($lid, $flags, $lock_timeout, $io_timeout);

=head2 device_trigger

 ($error) = $client->device_trigger($lid, $flags, $lock_timeout, $io_timeout);

=head2 device_clear

 ($error) = $client->device_clear($lid, $flags, $lock_timeout, $io_timeout);

=head2 device_remote

 ($error) = $client->device_remote($lid, $flags, $lock_timeout, $io_timeout);

=head2 device_local

 ($error) = $client->device_local($lid, $flags, $lock_timeout, $io_timeout);

=head2 device_lock

 ($error) = $client->device_remote($lid, $flags, $lock_timeout);

=head2 device_unlock

 ($error) = $client->device_unlock($lid);

=head2 device_enable_srq

 ($error) = $client->device_enable_srq($lid, $enable, $handle);

=head2 device_docmd

 ($error, $data_out) = $client->device_docmd($lid, $flags, $io_timeout, $lock_timeout, $cmd, $network_order, $datasize, $data_in);

=head2 destroy_link

 ($error) = $client->destroy_link($lid);

=head2 create_intr_chan

 ($error) = $client->create_intr_chan($hostAddr, $hostPort, $progNum, $progVers, $progFamily);

=head2 destroy_intr_chan

 ($error) = $client->destroy_intr_chan();

=head1 REPORTING BUGS

Please report bugs at L<https://github.com/amba/Lab-VXI11/issues>.

=head1 CONTACT

Feel free to contact us at the #labmeasurement channel on Freenode IRC.

=head1 AUTHOR

Simon Reinhardt, E<lt>simon.reinhardt@stud.uni-regensburg.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Simon Reinhardt

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
