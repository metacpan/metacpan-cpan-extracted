package Log::Saftpresse::Plugin::Amavis;

use Moose;

# ABSTRACT: plugin to parse amavisd-new logs
our $VERSION = '1.6'; # VERSION


extends 'Log::Saftpresse::Plugin';

with 'Log::Saftpresse::Plugin::Role::CounterUtils';
with 'Log::Saftpresse::Plugin::Role::Tracking';

use Log::Saftpresse::Log4perl;
use JSON;

has 'json' => (
	is => 'ro', isa => 'JSON', lazy => 1,
	default => sub { JSON->new; },
);

has 'test_stats' => ( is => 'ro', isa => 'Bool', default => 1 );

sub process {
	my ( $self, $stash, $notes ) = @_;
	my $program = $stash->{'program'};
	if( ! defined $program || $program ne 'amavis' ) {
		return;
	}

	if ( my ( $log_id, $msg ) = $stash->{'message'} =~ /^\(([^\)]+)\) (.+)$/ ) {
		$stash->{'log_id'} = $log_id;
		$stash->{'message'} = $msg;
	}

	# if JSON logging is configured decode JSON
	if( $stash->{'message'} =~ /^{/ ) {
		my $json_data;
		eval {
			$json_data = $self->json->decode( $stash->{'message'} );
		};
		if( $@ ) {
      $log->warn('error while parsing amavis JSON log message: '.$@);
      return;
    }
		if( ref($json_data) ne 'HASH' ) {
			return;
		}
		@$stash{keys %$json_data} = values %$json_data;
	}

	if( ! defined $stash->{'action'} ) {
		return;
	}

  $self->get_tracking_id('queue_id', $stash, $notes);
  if( defined $stash->{'queued_as'}
      && ref($stash->{'queued_as'}) eq 'ARRAY' ) {
    foreach my $queued_as_id ( @{$stash->{'queued_as'}} ) {
      $self->set_tracking_id('queue_id', $stash, $notes, $queued_as_id);
    }
  }

	$self->incr_host_one($stash, 'total' );
	$self->count_fields_occur( $stash, 'content_type' );
	$self->count_array_field_values( $stash, 'action' );
	$self->count_fields_value( $stash, 'size', 'score' );

	if( $self->test_stats ) {
		$self->count_array_field_values( $stash, 'tests' );
	}

	return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Plugin::Amavis - plugin to parse amavisd-new logs

=head1 VERSION

version 1.6

=head1 Description

This plugin parses Amavis log lines. Currently only JSON format log lines are parsed.

=head1 Synopsis

  <Plugin amavis>
    module = "Amavis"
    test_stats = 1
  </Plugin>

=head1 Options

=over

=item test_stats (default: 1)

Enable/disable generation of a counter per spam/ham test.

=back

=head1 Configure Amavis/Rsyslog for JSON output

First increase the maximum message size in rsyslog:

  $MaxMessageSize 32k

Then configure your $log_templ in amavisd.conf for JSON output:

  $logline_maxlen = ( 32*1024 ) - 50; # 32k max message size, keep 50 bytes for syslog
  $log_templ = <<'EOD';
  [:report_json]
  EOD

=head1 Input

This plugin expects a log line with

  'program' => 'amavis'

and an amavis report_json message like

  'message' => '(04529-01) {"@timestamp":"2015-06-12T04:51:48.725Z","action":["PASS"],...}'

=head1 Output

The plugin will outout the field log_id and will copy all fields
in the JSON data structure to the event.

=head1 Counters

The plugin will create the following counters:

  <host>.total
  <host>.content_type.<content_type>
  <host>.action.<action>
  <host>.size
  <host>.score

If option test_stats is enabled:

  <host>.tests.<test>

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
