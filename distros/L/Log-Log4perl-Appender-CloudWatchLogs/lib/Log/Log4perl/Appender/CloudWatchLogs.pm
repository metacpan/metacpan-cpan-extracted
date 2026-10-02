##################################################
package Log::Log4perl::Appender::CloudWatchLogs;
##################################################

use warnings;
use strict;

use Amazon::API::CloudWatchLogs;
use Carp;
use Data::Dumper;
use Encode qw(encode_utf8);
use English qw(-no_match_vars);
use Digest::MD5 qw(md5_hex);
use Data::UUID;
use Scalar::Util qw( reftype );

use constant { ## no critic (ValuesAndExpressions::ProhibitConstantPragma)
  BUFFER_SIZE                 => 1_000,
  MAX_BATCH_BYTES             => 1_048_576,
  MAX_BATCH_EVENTS            => 10_000,
  LOG_EVENT_OVERHEAD_BYTES    => 26,
  MAX_BATCH_SPAN_MILLISECONDS => 24 * 60 * 60 * 1_000,
  MAX_RETRIES                 => 5,
  RETRY_DELAY                 => 1,
  SLASH                       => q{/},
  EMPTY                       => q{},
  TRUE                        => 1,
  FALSE                       => 0,
  MILLISECONDS_PER_SECOND     => 1_000,
  HTTP_OK                     => 200,
  HTTP_BAD_REQUEST            => 400,
};

our $VERSION = '1.0.7';

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(
  qw(
    buffer_size
    cwl
    endpoint_url
    event_count
    events
    group
    group_mode
    max_retries
    retry_delay
    stream
    stream_mode
  )
);

use parent qw( Log::Log4perl::Appender Class::Accessor::Fast);

##################################################
sub new {
##################################################
  my ( $class, %options ) = @_;

  my $self = bless \%options, $class;

  $self->init_buffer;

  $self->init_endpoint_url;

  $self->init_cloudwatch_logs;

  croak 'no group [' . $self->get_group . '] exists.'
    if !$self->check_group;

  croak 'no stream [' . $self->get_stream . '] exists.'
    if !$self->check_stream;

  $self->set_buffer_size( $self->get_buffer_size // BUFFER_SIZE );

  $self->set_max_retries( $self->get_max_retries // MAX_RETRIES );

  $self->set_retry_delay( $self->get_retry_delay // RETRY_DELAY );

  croak "ERROR: buffer size must be > 0"
    if $self->get_buffer_size <= 0;

  croak "ERROR: max retries must be > 0"
    if $self->get_max_retries <= 0;

  croak "ERROR: retry delay must be > 0"
    if $self->get_retry_delay <= 0;

  return $self;
}

##################################################
sub log { ## no critic (Subroutines::ProhibitBuiltinHomonyms)
##################################################
  my ( $self, %params ) = @_;

  my $events = $self->get_events || $self->init_buffer;

  push @{$events},
    {
    message   => $params{message},
    timestamp => time * MILLISECONDS_PER_SECOND,
    };

  $self->set_event_count( $self->get_event_count + 1 );

  if ( $self->get_event_count >= $self->get_buffer_size ) {
    $self->flush_buffer;
  }

  return TRUE;
}

##################################################
sub init_endpoint_url {
##################################################
  my ($self) = @_;

  my $endpoint_url = $ENV{AWS_ENDPOINT_URL} || $self->get_endpoint_url;

  return $self->set_endpoint_url($endpoint_url);
}

##################################################
sub init_cloudwatch_logs {
##################################################
  my ($self) = @_;

  if ( !$self->get_cwl ) {
    $self->set_cwl(
      Amazon::API::CloudWatchLogs->new(
        print_error => TRUE,
        url         => $self->get_endpoint_url,
        no_logger   => TRUE,
      )
    );
  }

  return $self->get_cwl;
}

##################################################
sub check_stream {
##################################################
  my ($self) = @_;

  if ( ref $self->get_stream ) {
    $self->set_stream_mode( $self->get_stream->{mode} || 'create' );
    $self->set_stream( $self->get_stream->{name} );
  }
  else {
    # default mode = 'create'
    $self->set_stream_mode('create');
  }

  my $stream_exists;

  if ( $self->get_stream_mode eq 'create' ) {
    $stream_exists = $self->create_log_stream;
  }
  elsif ( $self->get_stream_mode eq 'append' ) {
    $stream_exists = $self->stream_exists;
  }

  return $stream_exists;
}

##################################################
sub check_group {
##################################################
  my ($self) = @_;

  croak 'no group'
    if !$self->get_group;

  if ( ref $self->get_group ) {
    $self->set_group_mode( $self->get_group->{mode} || 'no' );
    $self->set_group( $self->get_group->{name} );
  }
  else {
    $self->set_group_mode('no');
  }

  return TRUE
    if $self->group_exists;

  # create if the group does not exist?
  return $self->get_group_mode eq 'create' ? $self->create_log_group : FALSE;
}

##################################################
sub create_log_group {
##################################################
  my ($self) = @_;

  my $group = $self->get_group;
  my $cwl   = $self->get_cwl;

  $cwl->CreateLogGroup( { logGroupName => $group } );

  return $cwl->get_response->code eq HTTP_OK ? TRUE : FALSE;
}

##################################################
sub describe_group {
##################################################
  my ($self) = @_;

  my $group_description;

  my $cwl   = $self->get_cwl;
  my $group = $self->get_group;

  my $rsp = $cwl->DescribeLogGroups( { logGroupNamePrefix => $group } );

  if ( $rsp->{logGroups} && reftype( $rsp->{logGroups} ) eq 'ARRAY' ) {
    my %groups = map { ( $_->{logGroupName}, $_ ) } @{ $rsp->{logGroups} };
    $group_description = $groups{$group};
  }

  return $group_description || {};
}

##################################################
sub group_exists {
##################################################
  my ($self) = @_;

  my $group_description = $self->describe_group;

  return keys %{$group_description} ? TRUE : FALSE;
}

##################################################
sub describe_stream {
##################################################
  my ($self) = @_;

  my $group  = $self->get_group;
  my $stream = $self->get_stream;

  my $rsp = $self->get_cwl->DescribeLogStreams(
    { logGroupName        => $group,
      logStreamNamePrefix => $stream,
    },
  );

  my $stream_description;

  if ( $rsp->{logStreams} && reftype( $rsp->{logStreams} ) eq 'ARRAY' ) {
    my %streams
      = map { ( $_->{logStreamName}, $_ ) } @{ $rsp->{logStreams} };

    $stream_description = $streams{$stream};
  }

  return $stream_description || {};
}

##################################################
sub stream_exists {
##################################################
  my ($self) = @_;

  my $stream_description = $self->describe_stream;

  return keys %{$stream_description} ? TRUE : FALSE;
}

##################################################
sub create_log_stream {
##################################################
  my ($self) = @_;

  my $cwl = $self->get_cwl;

  my $ug   = Data::UUID->new;
  my $uuid = $ug->create;

  my $stream_suffix = md5_hex( $ug->to_string($uuid) );
  my $stream_prefix = $self->get_stream;

  my $group = $self->get_group;

  # create stream name consisting of the group name/stream name/unique-id
  if ( !$stream_prefix ) {
    $stream_prefix = substr( $group, 0, 1 ) eq SLASH ? substr( $group, 1 ) : $group;
  }

  $self->set_stream( $stream_prefix . SLASH . $stream_suffix );

  $cwl->CreateLogStream(
    { logGroupName  => $group,
      logStreamName => $self->get_stream,
    },
  );

  my $http_code = $cwl->get_response->code;

  if ( $http_code ne HTTP_OK ) {
    $self->set_stream(EMPTY);
  }

  return $self->get_stream ? TRUE : FALSE;
}

##################################################
sub init_buffer {
##################################################
  my ($self) = @_;

  $self->set_events( [] );
  $self->set_event_count(0);

  return $self->get_events;
}

##################################################
sub flush_buffer {
##################################################
  my ($self) = @_;

  my $cwl    = $self->get_cwl;
  my $group  = $self->get_group;
  my $stream = $self->get_stream;

  my $events      = $self->get_events;
  my $event_count = $self->get_event_count;

  return $event_count
    if !$event_count;

  if ( $cwl->get_credentials->is_token_expired ) {
    $cwl->get_credentials->refresh_token;
  }

  my $flushed_count = 0;

  BATCH: while ( @{$events} ) {

    #
    # An event that cannot fit by itself can never be sent.  Remove it
    # so it does not permanently block everything behind it.
    #
    my $first_event_bytes = event_size( $events->[0] );

    if ( $first_event_bytes > MAX_BATCH_BYTES ) {
      warn sprintf "CloudWatch log event exceeds maximum batch size (%d bytes); dropping event\n", $first_event_bytes;

      shift @{$events};

      $self->set_event_count( $self->get_event_count - 1 );

      next BATCH;
    }

    #
    # Build the next legal PutLogEvents batch from the front of the
    # retained buffer.
    #
    my @batch;
    my $batch_bytes     = 0;
    my $first_timestamp = $events->[0]->{timestamp};

    foreach my $event ( @{$events} ) {

      last
        if @batch >= MAX_BATCH_EVENTS;

      my $event_bytes = event_size($event);

      last
        if $batch_bytes + $event_bytes > MAX_BATCH_BYTES;

      last
        if $event->{timestamp} - $first_timestamp > MAX_BATCH_SPAN_MILLISECONDS;

      push @batch, $event;
      $batch_bytes += $event_bytes;
    }

    #
    # Retry this batch without changing the retained buffer.  Nothing
    # is removed until PutLogEvents has completed successfully.
    #
    my $attempt = 0;
    my $sent    = FALSE;

    while ( $attempt < $self->get_max_retries ) {
      $attempt++;

      my $rsp;

      eval { $rsp = $cwl->PutLogEvents( { logEvents => \@batch, logGroupName => $group, logStreamName => $stream, }, ); };

      if ( !$EVAL_ERROR ) {

        if ( my $rejected = $rsp->{rejectedLogEventsInfo} ) {

          if ( defined $rejected->{tooOldLogEventEndIndex} ) {
            warn sprintf "CloudWatch rejected log events that are too old (end index %d)\n",
              $rejected->{tooOldLogEventEndIndex};
          }

          if ( defined $rejected->{expiredLogEventEndIndex} ) {
            warn sprintf "CloudWatch rejected expired log events (end index %d)\n", $rejected->{expiredLogEventEndIndex};
          }

          if ( defined $rejected->{tooNewLogEventStartIndex} ) {
            warn sprintf "CloudWatch rejected log events that are too new (start index %d)\n",
              $rejected->{tooNewLogEventStartIndex};
          }
        }

        $sent = TRUE;
        last;
      }

      my $error = $EVAL_ERROR;

      if ( ref($error) !~ /Amazon::API::Error/xsm ) {
        croak $error;
      }

      warn $cwl->print_error;

      if ( $attempt < $self->get_max_retries ) {
        sleep $self->get_retry_delay;
      }
    }

    #
    # Leave this batch and everything behind it in the buffer so a
    # subsequent flush can try again.
    #
    if ( !$sent ) {
      warn sprintf "failed to flush %d CloudWatch log events after %d attempts\n", scalar @batch, $self->get_max_retries;

      return $flushed_count;
    }

    #
    # Remove only the batch that CloudWatch accepted.
    #
    my $batch_count = scalar @batch;

    splice @{$events}, 0, $batch_count;

    $self->set_event_count( $self->get_event_count - $batch_count );

    $flushed_count += $batch_count;
  }

  return $flushed_count;
}

##################################################
sub event_size {
##################################################
  my ($event) = @_;

  return length( encode_utf8( $event->{message} ) ) + LOG_EVENT_OVERHEAD_BYTES;
}
##################################################
sub DESTROY {
##################################################
  my ($self) = @_;

  return $self->flush_buffer;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Log::Log4perl::Appender::CloudWatchLogs - Appender to send logs to CloudWatch

B<IMPORTANT:> This distribution depends on one or more L<Amazon::API>
service modules published outside CPAN. You must install those modules
before proceeding.

=over 4

=item * See L<Amazon::API> for the rationale behind publishing these
modules outside CPAN.

=item * See L</NON-CPAN DEPENDENCIES> for instructions on how to install
these modules.

=back

=head1 SYNOPSIS

 use Log::Log4perl;

 my $log4perl_conf =<<'END_OF_TEXT';
 log4perl.rootLogger=DEBUG, CLOUDWATCH
 log4perl.appender.CLOUDWATCH=Log::Log4perl::Appender::CloudWatchLogs
 log4perl.appender.CLOUDWATCH.group=/test-log-group
 log4perl.appender.CLOUDWATCH.stream=stream-prefix
 log4perl.appender.CLOUDWATCH.buffer_size=1
 log4perl.appender.CLOUDWATCH.layout=PatternLayout
 log4perl.appender.CLOUDWATCH.layout.ConversionPattern=%d [%r] %F %L %c - %m
 END_OF_TEXT

 Log::Log4perl::init(\$log4perl_conf);

 my $logger = Log::Log4perl->get_logger('');

=head1 DESCRIPTION

Appender to send logs to AWS CloudWatch. Events are buffered and sent
when the buffer is full or when the appender is destroyed.

=head1 DEPENDENCIES

C<Amazon::API::CloudWatchLogs>, L<Class::Accessor::Fast>,
L<Data::UUID>, L<Log::Log4perl::Appender>

=head1 CONFIGURATION

The appender supports several configuration attributes for logging to
CloudWatch described below.

Example Log::Log4perl configuration:

 ############################################################
 # A simple root logger with a Log::Log4perl::Appender::CloudWatchLogs
 ############################################################
 log4perl.rootLogger=DEBUG, CLOUDWATCH

 log4perl.appender.CLOUDWATCH=Log::Log4perl::Appender::CloudWatchLogs
 log4perl.appender.CLOUDWATCH.group=/test-log-group
 log4perl.appender.CLOUDWATCH.stream=foobar

 log4perl.appender.CLOUDWATCH.layout=PatternLayout
 log4perl.appender.CLOUDWATCH.layout.ConversionPattern=%d [%r] %F %L %c - %m

=head2 Options

=over 4

=item group (required)

=over 10

=item name

Name of the log group where log streams will be written

=item mode

Determines if the log group should be created if it does not exist. By
default, the group must already exist. Set C<mode> to C<create> to
create it when necessary.  valid values: create

I<Note: You can use the dot notation or just set C<group> to the group name.>

 log4perl.appender.CLOUDWATCH=Log::Log4perl::Appender::CloudWatchLogs
 log4perl.appender.CLOUDWATCH.group.name=/ecs/myapp
 log4perl.appender.CLOUDWATCH.stream.name=ecs/myapp/2026-04-06
 log4perl.appender.CLOUDWATCH.group.mode=create

=back

=item stream (optional)

=over 10

=item name

Name of the stream. The name of the stream is used as a prefix unless
the C<mode> option is set to 'append'.  If no stream name is given,
then a unique stream name will be created composed of the log group
name and a unique suffix.

=item mode

If mode is set to 'append' the appender will append logs to the
group/stream provided.  If no mode is provided or the mode is set to
'create' then a new stream will be created. The appender will use the
stream name as a prefix with a suffix consisting of the MD5 hash of a
UUID in order to create a unique stream name.

Example:

 log4perl.appender.CLOUDWATCH=Log::Log4perl::Appender::CloudWatchLogs
 log4perl.appender.CLOUDWATCH.group=/ecs/myapp
 log4perl.appender.CLOUDWATCH.stream=

 stream name = ecs/myapp/f974195a83b143a68672b62457a313ca

valid values: append|create

I<Note: You can use the dot notation or just set C<stream> to the stream name.>

 log4perl.appender.CLOUDWATCH=Log::Log4perl::Appender::CloudWatchLogs
 log4perl.appender.CLOUDWATCH.group.name=/ecs/myapp
 log4perl.appender.CLOUDWATCH.stream.name=ecs/myapp/2026-04-06
 log4perl.appender.CLOUDWATCH.stream.mode=create

=back

=item buffer_size

The number of events to buffer before sending the events to
CloudWatch. The maximum number of events that can sent in one payload
is 10K. The maximum size of the payload is 1,048,576 bytes.

I<Note: C<flush_buffer()> partitions buffered events into batches
satisfying the CloudWatch Logs limits on event count, payload size,
and 24-hour timestamp span.>

default: 1000

See
L<https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_PutLogEvents.html>
for more details.

=item max_retries

The maximum number of attempts to make for a PutLogEvents operation
when an C<Amazon::API::Error> exception is thrown.

default: 5

=item retry_delay

The amount of time, in seconds, to wait between attempts. The value
must be greater than zero.

default: 1

=item endpoint_url

The API endpoint - leave blank for AWS, http://localhost:4566 for
LocalStack (or where you have installed LocalStack).

=back

=head1 CAVEATS

The appender internally uses a null logger to prevent re-entrant
logging calls. Any debugging of the CloudWatch API calls made
internally by the appender should be done outside the context of
this appender - for example, in a standalone test script that
invokes C<Amazon::API::CloudWatchLogs> directly rather than through
Log::Log4perl configuration.

=head1 NON-CPAN DEPENDENCIES

This distribution depends on one or more modules that are published on the
OpenBedrock CPAN-compatible repository rather than on CPAN.

These dependencies are declared normally in the distribution metadata.
However, an installer must know where to obtain distributions that are not
available from CPAN.

The OpenBedrock repository is available at:

  https://cpan.openbedrock.net/orepan2

Distributions like this one that depend on OpenBedrock modules may
include F<cpanfile.darkpan> and/or F<cpanm.darkpan> which identify
only the dependencies that must be obtained from the OpenBedrock
repository.

If L<DarkPAN::Resolver::SQLite> is installed, its C<cpan-distfile>
utility can retrieve these files directly from the CPAN distribution
without installing or manually unpacking them:

  cpan-distfile Log::Log4perl::Appender::CloudWatchLogs cpanfile.darkpan \
    > cpanfile.darkpan

F<cpanfile.darkpan> is primarily useful when installing this
distribution with C<cpm> or C<carton>. F<cpanm.darkpan> is used when
installing with C<cpanm>. See detailed notes for each installer below.

=head2 Installing with cpm

L<cpm> is the preferred installer for distributions that depend on
OpenBedrock modules because its resolver model allows dependencies to be
resolved from both CPAN and the OpenBedrock repository as part of the same
installation.

The OpenBedrock repository provides L<DarkPAN::Resolver::SQLite>, which
uses the repository's multi-version index and can resolve both the latest
available release and specific historical versions.

For example:

    cpm install \
      --resolver +DarkPAN::Resolver::SQLite,https://cpan.openbedrock.net/orepan2 \
      Log::Log4perl::Appender::CloudWatchLogs

The resolver is consulted for dependencies available from the OpenBedrock
repository. Dependencies it cannot satisfy continue through C<cpm>'s
normal resolver chain.

Unlike the standard C<02packages> resolver, the SQLite resolver retains
information about multiple versions of each module. This allows normal
version requirements, including exact historical versions, to be resolved
from the OpenBedrock repository when those releases are available.

For example:

  cpm install \
    --resolver +DarkPAN::Resolver::SQLite,https://cpan.openbedrock.net/orepan2 \
    'Amazon::API@2.8.0'

The standard C<02packages> resolver may also be used when only the currently
indexed release is required:

  cpm install \
    --resolver 02packages,https://cpan.openbedrock.net/orepan2 \
  Log::Log4perl::Appender::CloudWatchLogs  

=head2 Installing with cpanm

L<cpanm> may also be used, but its mirror-oriented dependency
resolution makes mixed CPAN and non-CPAN dependency trees potentially
fragile.

With C<cpanm>, using the C<--mirror> option without C<--mirror-only>
causes C<cpanm> to use its default resolution method (CPAN
MetaDB/MetaCPAN). Distributions not indexed there, like the ones
specified in our F<*.darkpan> files, will not be found.

However, adding the C<--mirror-only> flag tells C<cpanm> to use the
F<02packages.details.txt.gz> index from B<each> configured mirror
(including its default) for resolution. Those indexes contain only one
distribution for each module. C<cpanm> is therefore only able to resolve
the version represented by that entry, even though other versions of
the distribution may still exist on the mirror or on BackPAN.

This becomes a problem when an F<*.darkpan> file pins a module to a
version other than the one represented in F<02packages.details.txt.gz>.
In that case, C<cpanm> will fail to install that module because it
cannot resolve the pinned version through the index, even if the
corresponding distribution tarball still exists in the repository.

To use C<cpanm> you can try:

  cpanm --mirror https://cpan.openbedrock.net/orepan2 --mirror-only \
    < cpanm.darkpan

=head2 Provenance and Verification

L<Amazon::API> service distributions published on the OpenBedrock repository
include provenance information describing how each distribution was
produced and the source metadata from which it was generated.

Generated service classes are intentionally published outside CPAN so
that AWS service models can be updated independently without requiring
hundreds of generated distributions to be uploaded to CPAN.

Instructions for verifying distribution signatures and examining
provenance records are maintained at:

    https://cpan.openbedrock.net/signature

Users who wish to verify an OpenBedrock distribution should follow the
instructions provided on that site.

Provenance records may also be inspected using the tools provided by
L<Amazon::API::Provenance>.

=head1 SEE ALSO

C<Amazon::API::CloudWatchLogs> is an Amazon AWS service implemented by C<Amazon::API>.

For help with C<Amazon::API> service classes see L<Amazon::API::Help>

L<Amazon::API>, L<Amazon::Credentials>, L<Amazon::API::Help>

=head1 AUTHOR

Rob Lauer - E<lt>rlauer6@comcast.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
