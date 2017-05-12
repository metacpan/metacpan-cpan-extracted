package Log::Saftpresse::Slurp;

use Moose;

# ABSTRACT: class to read log file inputs
our $VERSION = '1.6'; # VERSION

extends 'Log::Saftpresse::PluginContainer';

use Log::Saftpresse::Log4perl;

use IO::Select;
use Time::HiRes qw( sleep gettimeofday tv_interval );

has 'plugin_prefix' => ( is => 'ro', isa => 'Str',
	default => 'Log::Saftpresse::Input::',
);

has 'io_select' => ( is => 'rw', isa => 'Maybe[IO::Select]' );

sub update_io_select {
	my $self = shift;
	my $s = IO::Select->new;
	foreach my $plugin ( @{$self->plugins} ) {
		$s->add( $plugin->io_handles );
	}
	$self->io_select( $s );
	return;
};

has '_last_run' => ( is => 'rw', isa => 'Maybe[ArrayRef]' );

sub can_read {
	my ( $self, $timeout ) = @_;

	# do we known when we did run last time?
	my $sleep;
	if( defined $self->_last_run ) {
		my $next = [ @{$self->_last_run} ]; $next->[0] += $timeout;
		$sleep = tv_interval( [gettimeofday], $next );
	} else {
		# just sleep for timeout
		$sleep = $timeout;
	}

	$self->update_io_select;

	# use select() when possible
	if( $self->io_select->count ) {
		$self->io_select->can_read( $sleep );
	} elsif( $sleep > 0 ) { # may be negative if clock is drifting
		sleep( $sleep );
	}

	$self->_last_run( [gettimeofday] );
	return( 1 ); # always signal read
}

sub read_events {
	my $self = shift;
	my @events;
	my $eof = 1;

	foreach my $plugin ( @{$self->plugins} ) {
		if( $plugin->can_read ) {
			if( $plugin->eof ) { next; }
      eval {
		  	push( @events, $plugin->read_events );
      };
      if( $@ ) {
        $log->error('error while reading from plugin '.$plugin->name.': '.$@);
      }
		}
		$eof = 0;
	}

	if( $eof ) {
		die('all inputs at EOF');
	}
	if( scalar @events ) { return \@events; }
	return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Slurp - class to read log file inputs

=head1 VERSION

version 1.6

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
