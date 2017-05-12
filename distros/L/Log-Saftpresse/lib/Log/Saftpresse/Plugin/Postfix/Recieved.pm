package Log::Saftpresse::Plugin::Postfix::Recieved;

use Moose::Role;

# ABSTRACT: plugin to gather postfix recieved messages statistics
our $VERSION = '1.6'; # VERSION

use Log::Saftpresse::Plugin::Postfix::Utils qw( postfix_remote );

sub process_recieved {
	my ( $self, $stash, $notes ) = @_;
	my $service = $stash->{'service'};
	my $message = $stash->{'message'};
	my $qid = $stash->{'queue_id'};

	if( $service eq 'smtpd' &&
			$message =~ /client=(.+?)(,|$)/ ) {
		my ( $host, $addr ) = postfix_remote( $1 );
		$stash->{'client_host'} = $host;
		$stash->{'client_ip'} = $addr;
		$self->incr_host_one( $stash, 'incoming', 'total');
		if( $self->saftsumm_mode ) {
			$self->incr_per_time_one( $stash );
		}
		$notes->set('client-'.$qid => $host);
    if( $message =~ /orig_queue_id=(.+?)(,|$)/) {
      $stash->{'orig_queue_id'} = $1;
      $self->get_tracking_id('queue_id', $stash, $notes, $1);
      $self->set_tracking_id('pid', $stash, $notes);
    }
    $self->set_tracking_id('queue_id', $stash, $notes);
	} elsif( $service eq 'pickup' &&
			$message =~ /(sender|uid)=/ ) {
		$self->incr_host_one( $stash, 'incoming', 'total');
		if( $self->saftsumm_mode ) {
			$self->incr_per_time_one( $stash );
		}
		$notes->set('client-'.$qid => 'pickup');
    $self->set_tracking_id('queue_id', $stash, $notes);
	}

	return;
}

sub incr_per_time_one {
	my ( $self, $stash ) = @_;
	my $time = $stash->{'time'};
	$self->incr_host_one( $stash, 'incoming', 'per_hr', $time->hour );
	$self->incr_host_one( $stash, 'incoming', 'per_mday', $time->mday );
	$self->incr_host_one( $stash, 'incoming', 'per_wday', $time->wday );
	$self->incr_host_one( $stash, 'incoming', 'per_day', $time->ymd );
	return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Plugin::Postfix::Recieved - plugin to gather postfix recieved messages statistics

=head1 VERSION

version 1.6

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
