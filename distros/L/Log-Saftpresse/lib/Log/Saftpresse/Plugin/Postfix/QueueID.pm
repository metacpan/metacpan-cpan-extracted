package Log::Saftpresse::Plugin::Postfix::QueueID;

use Moose::Role;

# ABSTRACT: plugin to parse the postfix queue ID
our $VERSION = '1.6'; # VERSION

sub process_queueid {
	my ( $self, $stash, $notes ) = @_;
	
	if( my ( $queue_id, $msg ) = $stash->{'message'} =~
			/^([A-Z0-9]{8,12}|[b-zB-Z0-9]{15}|NOQUEUE): (.+)$/) {
		$stash->{'queue_id'} = $queue_id;
		$stash->{'message'} = $msg;
    $self->get_tracking_id('queue_id', $stash, $notes);
	}

	return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Plugin::Postfix::QueueID - plugin to parse the postfix queue ID

=head1 VERSION

version 1.6

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
