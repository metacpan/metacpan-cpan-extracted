package Log::Saftpresse::Plugin::Postfix::Smtp;

use Moose::Role;

# ABSTRACT: plugin to gather postfix smtp client statistics
our $VERSION = '1.6'; # VERSION

sub process_smtp {
	my ( $self, $stash ) = @_;
	my $service = $stash->{'service'};
	if( $service ne 'smtp' ) { return; }

	# Was an IPv6 problem here
	if($stash->{'message'} =~ /^connect to (\S+?): ([^;]+); address \S+ port.*$/) {
		$self->incr_host_one( $stash, 'messages', lc($2), $1);
	} elsif($stash->{'message'} =~ /^connect to ([^[]+)\[\S+?\]: (.+?) \(port \d+\)$/) {
		$self->incr_host_one( $stash, 'messages', lc($2), $1);
	}

	# TODO: is it possible to count connections?
	#$self->incr_host_one( $stash, 'connections');

	return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Plugin::Postfix::Smtp - plugin to gather postfix smtp client statistics

=head1 VERSION

version 1.6

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
