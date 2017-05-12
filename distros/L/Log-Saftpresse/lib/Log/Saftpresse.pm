package Log::Saftpresse;

use Moose;

# ABSTRACT: a modular logfile analyzer
our $VERSION = '1.6'; # VERSION

use Log::Saftpresse::Log4perl;
use Log::Saftpresse::Config;

use Log::Saftpresse::Analyzer;
use Log::Saftpresse::Slurp;
use Log::Saftpresse::CounterOutputs;
use Log::Saftpresse::Outputs;

use Time::Piece;
use Sys::Hostname;


has 'config' => (
	is => 'ro', isa => 'Log::Saftpresse::Config', lazy => 1,
	default => sub { Log::Saftpresse::Config->new },
	handles => [ 'load_config' ],
);

has 'slurp' => (
	is => 'ro', isa => 'Log::Saftpresse::Slurp', lazy => 1,
	default => sub { Log::Saftpresse::Slurp->new },
);

has 'analyzer' => (
	is => 'ro', isa => 'Log::Saftpresse::Analyzer', lazy => 1,
	default => sub { Log::Saftpresse::Analyzer->new },
);

has 'counter_outputs' => (
	is => 'ro', isa => 'Log::Saftpresse::CounterOutputs', lazy => 1,
	default => sub { Log::Saftpresse::CounterOutputs->new },
);

has 'outputs' => (
	is => 'ro', isa => 'Log::Saftpresse::Outputs', lazy => 1,
	default => sub { Log::Saftpresse::Outputs->new },
);

has 'flush_interval' => ( is => 'rw', isa => 'Maybe[Int]' );

has '_last_flush_counters' => (
	is => 'rw', isa => 'Int',
	default => sub { time },
);


sub init {
	my $self = shift;
	my $config = $self->config;
	
	Log::Saftpresse::Log4perl->init(
		$config->get('logging', 'level'),
		$config->get('logging', 'file'),
	);
	$self->flush_interval( $config->get('counters', 'flush_interval') );
	$self->slurp->load_config( $config->get_node('Input') );
	$self->analyzer->load_config( $config->get_node('Plugin') );
	$self->counter_outputs->load_config( $config->get_node('CounterOutput') );
	$self->outputs->load_config( $config->get_node('Output') );

	return;
}

sub _need_flush_counters {
	my $self = shift;

	if( ! defined $self->flush_interval
			|| $self->flush_interval < 1 ) {
		return 0;
	}

	my $next_flush = $self->_last_flush_counters + $self->flush_interval;
	if( time < $next_flush ) {
		return 0;
	}

	return 1;
}

sub _flushed_counters {
	my $self = shift;
	$self->_last_flush_counters( time );
	return;
}

sub saftpresse_version {
  my $version = 'development';
  eval '$version = $VERSION;'; ## no critic
  return $version;
}

sub _startup_event {
  my $self = shift;
  my $version = $self->saftpresse_version;
  return {
    time => Time::Piece->new,
    host => hostname(),
    message => "saftpresse ($version) started",
  };
}


sub run {
	my $self = shift;
	my $slurp = $self->slurp;
	my $last_flush = time;

  $self->outputs->output( $self->_startup_event );

	$log->info('entering main loop');
	for(;;) { # main loop
		my $events;
		if( $slurp->can_read(1) ) {
      $log->debug('checking for new input...');
			$events = $slurp->read_events;
			foreach my $event ( @$events ) {
				$self->analyzer->process_event( $event );
			}
		}
		if( scalar @$events ) {
      $log->debug('sending '.scalar(@$events).' events to outputs...');
			$self->outputs->output( @$events );
		}

		if( $self->_need_flush_counters ){
      $log->debug('flushing counters...');
			$self->counter_outputs->output(
				$self->analyzer->get_all_counters );
			$self->_flushed_counters;
		}
	}

	return;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse - a modular logfile analyzer

=head1 VERSION

version 1.6

=head1 Description

This is the central class of the saftpresse log analyzer.

=head1 Synopsis

  use Log::Saftpresse;

  my $saft = Log:::Saftpresse->new;

  $saft->load_config( $path );
  $saft->init;

  # start main loop
  $saft->run;

=head1 Attributes

=head2 config( L<Log::Saftpresse::Config>)

Holds the configuration.

=head2 slurp( L<Log::Saftpresse::Slurp> )

Holds the slurp class implementing the input.

=head2 analyzer( L<Log::Saftpresse::Analyzer> )

Holds the analyzer object which controls the processing plugins.

=head2 counter_outputs( L<Log::Saftpresse::CounterOutputs> )

Holds the counter output object which controls output of metrics.

=head2 outputs( L<Log::Saftpresse::Outputs> )

Holds the Outputs plugin which controls the event output.

=head2 flush_interval( $seconds )

How often to flush metrics to CounterOutputs.

=head1 Methods

=head2 init

Initialize saftpresse as configured in config file.

Will load slurp, analyzer, counter_outputs, outputs and flush_interval
from configuration.

=head2 run

Run the main loop of saftpresse.

=head1 See also

=over

=item L<Log::Saftpresse::App> 

Commandline glue for this class.

=item bin/saftpresse

Commandline interface of saftpresse with end-user docs.

=back

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
