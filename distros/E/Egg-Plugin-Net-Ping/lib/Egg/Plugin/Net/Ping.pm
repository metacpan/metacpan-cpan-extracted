package Egg::Plugin::Net::Ping;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Ping.pm 271 2008-02-24 06:52:22Z lushe $
#
use strict;
use warnings;
use Net::Ping;
use Carp qw/croak/;

our $VERSION= '3.01';

sub _setup {
	my($e)= @_;
	my $conf= $e->config->{plugin_net_ping} ||= {};
	$conf->{protcol} ||= 'tcp';
	$conf->{timeout} ||= 3;
	$conf->{retry}   ||= 1;
	$conf->{wait}    ||= 0.5;
	$e->next::method;
}
sub ping {
	my $e= shift;
	my $host= shift || croak q{ I want target host. };
	my %option= (
	  %{$e->config->{plugin_net_ping}},
	  %{ $_[1] ? {@_}: ($_[0] || {}) },
	  );
	$option{retry}= 5 if $option{retry}> 5;

	my $ping= Net::Ping->new($option{protcol});
	$ping->bind($option{self_addr}) if $option{self_addr};

	my($result, $count);
	for (1..$option{retry}) {
		++$result if $ping->ping($host, $option{timeout});
		++$count>= $option{retry} and last;
		select(undef, undef, undef, $option{wait});  ## no critic
	}

	$result || 0;
}

1;

__END__

=head1 NAME

Egg::Plugin::Net::Ping - Net::Ping for Egg plugin.

=head1 SYNOPSIS

  use Egg qw/ Net::Ping /;
  
  __PACKAGE__->egg_startup(
    ...
    .....
    plugin_net_ping => {
      protcol => 'tcp',
      timeout => 3,
      retry   => 1,
      wait    => 0.5,
      },
    );

  if ( $e->ping('192.168.1.1') ) {
    print " Ping was answered. !! ";
  } else {
    print " There is no answer to Ping. ";
  }

=head1 DESCRIPTION

It is a plug-in to investigate while arbitrary PC is operating by L<Net::Ping>.

=head1 CONFIGURATION

Please set 'plugin_net_ping'.

=head3 protcol

They are the protocols such as tcp and udp.

Default is 'tcp'.

* I do not think that it operates well perhaps excluding tcp.

=head3 timeout

Time to wait for answer of ping.

Default is '3'.

=head3 retry

Frequency in which ping is done.

=head3 wait

Waiting time to doing next retry.

Default is '0.5'.

=head3 self_addr

Own host address.

=head1 METHODS

=head2 ping ( [TARGET_HOST], [ARGS_HASH] )

Ping is sent to TARGET_HOST, and the succeeding frequency is returned.

ARGS_HASH overwrites initialization.

* When retry is set to five times or more, five is compulsorily set.

  $e->ping('192.168.1.111', retry => 5 );

=head1 SEE ALSO

L<Egg::Release>,
L<Net::Ping>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

