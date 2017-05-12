package Log::Saftpresse::Plugin::Postfix::Tls;

use Moose::Role;

# ABSTRACT: plugin to gather TLS statistics
our $VERSION = '1.6'; # VERSION

sub process_tls {
	my ( $self, $stash, $notes ) = @_;
	my $service = $stash->{'service'};
	my $pid = $stash->{'pid'};
	my $message = $stash->{'message'};
	my $queue_id = $stash->{'queue_id'};

	if( $service ne 'smtp' && $service ne 'smtpd' ) {
		return;
	}

	if( my ($tlsLevel,$tlsHost, $tlsAddr, $tlsProto, $tlsCipher, $tlsKeylen) =
		$message =~ /^(\S+) TLS connection established (?:from|to) ([^\[]+)\[([^\]]+)\]:(?:\d+:)? (\S+) with cipher (\S+) \((\d+)\/(\d+) bits\)/ ) {
		my $tls_params = {
			'tls_level' => $tlsLevel,
			'tls_proto' => $tlsProto,
			'tls_chipher' => $tlsCipher,
			'tls_keylen' => $tlsKeylen,
		};
		$self->incr_tls_stats( $stash, $tls_params, 'tls_conn', $service);
		@$stash{keys %$tls_params} = values %$tls_params;
		$notes->set($service.'-tls-'.$pid, $tls_params);

		return;
	}

	my $tls_params = $notes->get($service.'-tls-'.$pid);
	if( defined $tls_params ) {
		if( $service eq 'smtpd' ) {
			if( $message =~ /^connect from/ ) { # we missed the disconnect?
				$notes->remove($service.'-tls-'.$pid);
				return;
			} elsif( $message =~ /^disconnect/ ) {
				$notes->remove($service.'-tls-'.$pid);
			} elsif( $message =~ /^client=/ ) {
				$self->incr_tls_stats( $stash, $tls_params, 'tls_msg', $service);
			}
			@$stash{keys %$tls_params} = values %$tls_params;
		} elsif( $service eq 'smtp' &&
		       		$message =~ /status=(sent|bounced|deferred)/ ) {
			$self->incr_tls_stats( $stash, $tls_params, 'tls_msg', $service);
			$notes->remove($service.'-tls-'.$pid);
			# postfix/smtp closes the TLS connection after each delivery
			# see postfix-users maillist (2015-02-05)
			# but there may be more than one recipients so remember
			# TLS parameters for this queue_id
			if( defined $queue_id ) {
				$notes->set($service.'-tls-'.$queue_id, $tls_params);
			}
		}
	} elsif( defined $queue_id &&
			defined($tls_params = $notes->get($service.'-tls-'.$queue_id))
			) {
		@$stash{keys %$tls_params} = values %$tls_params;
	}

	return;
}

sub incr_tls_stats {
	my ( $self, $stash, $tls_params, @path ) = @_;

	$self->incr_host_one( $stash, @path, 'total');
	$self->incr_host_one( $stash, @path, 'level', $tls_params->{'tls_level'});
	$self->incr_host_one( $stash, @path, 'proto', $tls_params->{'tls_proto'});
	$self->incr_host_one( $stash, @path, 'cipher', $tls_params->{'tls_chipher'});
	$self->incr_host_one( $stash, @path, 'keylen', $tls_params->{'tls_keylen'});

	return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Plugin::Postfix::Tls - plugin to gather TLS statistics

=head1 VERSION

version 1.6

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
