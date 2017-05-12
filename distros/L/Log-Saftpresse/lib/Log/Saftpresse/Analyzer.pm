package Log::Saftpresse::Analyzer;

use Moose;

# ABSTRACT: class to analyze log messages
our $VERSION = '1.6'; # VERSION

use Log::Saftpresse::Notes;
use Log::Saftpresse::Counters;
use Log::Saftpresse::Log4perl;

extends 'Log::Saftpresse::PluginContainer';

has 'notes' => (
	is => 'ro', isa => 'Log::Saftpresse::Notes', lazy => 1,
	default => sub { Log::Saftpresse::Notes->new; },
);

has 'stats' => (
	is => 'ro', isa => 'Log::Saftpresse::Counters', lazy => 1,
	default => sub { Log::Saftpresse::Counters->new; },
);

sub process_message {
	my ( $self, $msg ) = @_;
	my $stash = {
		'message' => $msg,
	};
	$self->process_event( $stash );
	return;
}

sub process_event {
	my ( $self, $stash ) = @_;
	
	foreach my $plugin ( @{$self->plugins} ) {
    my $ret;
    eval {
  		$ret = $plugin->process( $stash, $self->notes );
    };
    if( $@ ) {
      $log->error('plugin '.$plugin->name.' failed: '.$@);
    }
		if( defined $ret && $ret eq 'next') {
			last;
		}
	}
	$self->stats->incr_one('events');

	return;
}

sub get_counters {
	my ( $self, $name ) = @_;
	my $plugin = $self->get_plugin( $name );
	if( defined $plugin ) {
		return( $plugin->counters );
	}
	return;
}

sub get_all_counters {
	my $self = shift;
	my %values;

	%values = map {
		$_->name => $_->counters
	} @{$self->plugins};

	return \%values;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Analyzer - class to analyze log messages

=head1 VERSION

version 1.6

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
