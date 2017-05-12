package Log::Saftpresse::Plugin::Postfix::Delivered;

use Moose::Role;

# ABSTRACT: plugin to gather postfix delivered messages statistics
our $VERSION = '1.6'; # VERSION

use Log::Saftpresse::Plugin::Postfix::Utils qw( verp_mung );

requires 'deferred_detail';
requires 'ignore_case';
requires 'deferred_detail';
requires 'message_detail';
requires 'bounce_detail';
requires 'extended';
requires 'uucp_mung';
requires 'ignore_case';
requires 'verp_mung';

sub process_delivered {
	my ( $self, $stash, $notes ) = @_;
	my $service = $stash->{'service'};
	my $message = $stash->{'message'};

	if( $service eq 'smtpd') { return; }

	my ($addr, $size, $relay, $delay, $status, $text);

	if(( ($addr, $size) = $message =~ /from=<([^>]*)>, size=(\d+)/) == 2) {
		$stash->{'size'} = $size;
		$stash->{'from'} = $addr;
		$self->process_from( $stash, $notes );
	} elsif( (
			($addr, $relay, $delay, $status, $text) = $message =~
			/to=<([^>]*)>, (?:orig_to=<[^>]*>, )?relay=([^,]+), (?:conn_use=[^,]+, )?delay=([^,]+), (?:delays=[^,]+, )?(?:dsn=[^,]+, )?status=(\S+)(.*)$/
			) >= 4) {
		$stash->{'to'} = $addr;
		$stash->{'relay'} = $relay;
		$stash->{'delay'} = $delay;
		$stash->{'status'} = $status;
		if( $text =~ /forwarded as / ) {
			$stash->{'forwarded'} = 'true';
		}
		$self->process_to( $stash, $notes );
	}

	return;
}

sub process_to {
	my ( $self, $stash, $notes ) = @_;
	my $message = $stash->{'message'};
	my $qid = $stash->{'queue_id'};
	my $delay = $stash->{'delay'};
	my $status = $stash->{'status'};
	my $time = $stash->{'time'};

	my $addr = $stash->{'to'} = $self->_get_addr_str( $stash->{'to'} );
	(my $domAddr = $addr) =~ s/^[^@]+\@//;	# get domain only

	my $relay = $stash->{'relay'};
	$relay = lc($relay) if( $self->ignore_case );

  if( $self->extended && ( my $from = $notes->get('from-'.$qid) ) ) {
    $stash->{'from'} = $from;
  }

	if($status eq 'sent') {
		# was it actually forwarded, rather than delivered?
		if( defined $stash->{'forwarded'}) {
		    $self->incr_host_one($stash, 'forwarded');
		    return;
		}
		$self->incr_host_one( $stash, 'sent', 'total');
		$self->incr_host_one( $stash, 'sent', 'by_domain', $domAddr);
		$self->incr_host( $stash, 'sent', 'delay', 'by_domain', $domAddr, $delay);
		$self->incr_host_max( $stash, 'sent', 'max_delay', 'by_domain', $domAddr, $delay);
		$self->incr_host_one( $stash, 'sent', 'by_rcpt', $addr);
		if( $self->saftsumm_mode ) {
			$self->incr_host_one( $stash, 'sent', 'per_hr', $time->hour);
			$self->incr_host_one( $stash, 'sent', 'per_day', $time->ymd);
		}

		if( my $size = $notes->get('size-'.$qid) ) {
			$stash->{'size'} = $size;
			$self->incr_host( $stash, 'sent', 'size', 'by_domain', $domAddr, $size);
			$self->incr_host( $stash, 'sent', 'size', 'by_rcpt', $addr, $size);
			$self->incr_host( $stash, 'sent', 'size', 'total', $size);
		} else {
			$self->incr_host_one( $stash, 'sent', 'size', 'no_size');
		}
		# [benning] hum?
		# push(@{$msgDetail{$qid}}, "(sender not in log)") if($opts{'e'});
		# push(@{$msgDetail{$qid}}, $addr) if($opts{'e'});
	} elsif($status eq 'deferred') {
		if( $self->deferred_detail > 0 ) {
		    my ($deferredReas) = $message =~ /, status=deferred \(([^\)]+)/;
		    unless( $self->message_detail ) {
			$deferredReas = said_string_trimmer($deferredReas, 65);
			$deferredReas =~ s/^\d{3} //;
			$deferredReas =~ s/^connect to //;
		    }
		    $self->incr_host_one( $stash, 'deferred', $stash->{'service'}, $deferredReas);
		}
		$self->incr_host_one( $stash, 'deferred', 'total');
		if( $self->saftsumm_mode ) {
			$self->incr_host_one( $stash, 'deferred', 'per_hr', $time->hour);
			$self->incr_host_one( $stash, 'deferred', 'per_day', $time->ymd);
		}
		$self->incr_host_one( $stash, 'deferred', 'by_domain', $domAddr);
		$self->incr_host_max( $stash, 'deferred', 'max_delay', 'by_domain', $domAddr, $delay);
	} elsif($status eq 'bounced') {
		if( $self->bounce_detail > 0 ) {
			my ($bounceReas) = $message =~ /, status=bounced \((.+)\)/;
			unless( $self->message_detail ) {
				$bounceReas = said_string_trimmer($bounceReas, 66);
				$bounceReas =~ s/^\d{3} //;
			}
			$self->incr_host_one( $stash, 'bounced', $relay, $bounceReas);
		}
		$self->incr_host_one( $stash, 'bounced', 'total');
		if( $self->saftsumm_mode ) {
			$self->incr_host_one( $stash, 'bounced', 'per_hr', $time->hour);
			$self->incr_host_one( $stash, 'bounced', 'per_day', $time->ymd);
		}
	}
}

sub process_from {
	my ( $self, $stash, $notes ) = @_;
	my $qid = $stash->{'queue_id'};
	my $addr = $stash->{'from'} = $self->_get_addr_str( $stash->{'from'} );
	my $size = $stash->{'size'};

	return if( $notes->get('size-'.$qid) ); # avoid double-counting!
	$notes->set('size-'.$qid => $size);
	$notes->set('from-'.$qid => $addr) if( $self->extended );

	# Avoid counting forwards
	if( my $client = $notes->get('client-'.$qid) ) {
		# Get the domain out of the sender's address.  If there is
		# none: Use the client hostname/IP-address
		my $domAddr;
		unless((($domAddr = $addr) =~ s/^[^@]+\@(.+)$/$1/) == 1) {
		    $domAddr = $client eq "pickup"? $addr : $client;
		}

		$self->incr_host_one( $stash, 'recieved', 'total');
		$self->incr_host( $stash, 'recieved', 'size', 'total', $size);

		$self->incr_host_one( $stash, 'recieved', 'by_domain', $domAddr);
		$self->incr_host( $stash, 'recieved', 'size', 'by_domain', $domAddr, $size);

		$self->incr_host_one( $stash, 'recieved', 'by_sender', $addr);
		$self->incr_host( $stash, 'recieved', 'size', 'by_sender', $addr, $size);
	}
	return;
}

sub _get_addr_str {
	my ( $self, $addr ) = @_;

	if($addr) {
		if( $self->uucp_mung &&
				$addr =~ /^(.*!)*([^!]+)!([^!@]+)@([^\.]+)$/) {
			$addr = "$4!" . ($1? "$1" : "") . $3 . "\@$2";
		}
		$addr =~ s/(@.+)/\L$1/ unless( $self->ignore_case );
		$addr = lc($addr) if( $self->ignore_case );
		$addr = verp_mung( $self->verp_mung, $addr);
	} else {
		$addr = "<>"
	}

	return( $addr );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Plugin::Postfix::Delivered - plugin to gather postfix delivered messages statistics

=head1 VERSION

version 1.6

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
