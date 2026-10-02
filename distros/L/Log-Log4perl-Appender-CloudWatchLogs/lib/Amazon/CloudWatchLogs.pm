package Amazon::CloudWatchLogs;

use strict;
use warnings;

BEGIN {
  $ENV{PERL_JSON_BACKEND} = 'Cpanel::JSON::XS,JSON::XS,JSON::PP';
  use JSON qw(decode_json);
}

use Amazon::API::CloudWatchLogs;
use CLI::Simple::Constants qw(:chars :booleans);
use CLI::Simple::Utils qw(choose);
use Carp;
use Data::Dumper;
use Data::UUID;
use Date::Format;
use Digest::MD5 qw( md5_hex );
use English qw( -no_match_vars );
use Tie::IxHash;
use Time::HiRes;

use Readonly;

# http response codes
Readonly my $HTTP_BAD_REQUEST => 400;
Readonly my $HTTP_OK          => 200;

# defaults & magic values
Readonly my $GROUP_COLOR         => q{green};
Readonly my $STREAM_COLOR        => q{magenta};
Readonly my $DISCOVERY_INTERVAL  => 1;
Readonly my $ISO_8601_FORMAT     => q{%Y-%m-%dT%H:%M:%SZ};
Readonly my $ITER_LIMIT          => 5;
Readonly my $LOCALSTACK_ENDPOINT => q{http://localhost:4566};
Readonly my $LOG_DELAY           => 1;
Readonly my $TIME_ZONE           => q{GMT};
Readonly my $MAX_DELETE_ATTEMPTS => 5;

# time
Readonly my $MILLISECONDS_PER_SECOND => 1000;
Readonly my $SECONDS_IN_MINUTE       => 60;
Readonly my $MINUTES_IN_HOUR         => 60;
Readonly my $HOURS_IN_DAY            => 24;
Readonly my $SECONDS_IN_HOUR         => $SECONDS_IN_MINUTE * $MINUTES_IN_HOUR;
Readonly my $SECONDS_IN_DAY          => $SECONDS_IN_HOUR * $HOURS_IN_DAY;
Readonly my $LAMBDA_IDLE_LIMIT       => 20 * $SECONDS_IN_MINUTE;
Readonly my $DELETE_STREAM_DELAY     => 0.1;

our $VERSION   = '1.0.7';
our $GIT_SHA   = '80e5cf9d6dfbcd9d33093766899181d4dd944c4a';
our $GIT_DIRTY = '80e5cf9d6dfbcd9d33093766899181d4dd944c4a';

__PACKAGE__->use_log4perl( level => 'info' );

use parent qw(CLI::Simple);

caller or exit __PACKAGE__->main;

#########################################################################
sub cmd_prune_streams {
#########################################################################
  my ($self) = @_;

  my ( $group, $older_than ) = $self->get_args;

  if ( $group && !$older_than ) {
    $older_than = $group;
    $group      = $self->get_group;
  }

  die "usage: prune-streams --group group-name older-than\n"
    if !$group || !$older_than;

  my $cutoff = _parse_start_time($older_than) * $MILLISECONDS_PER_SECOND;

  my $cwl = $self->get_cwl;

  my $decode_always = $cwl->get_decode_always;
  my $use_paginator = $cwl->get_use_paginator;

  $cwl->set_decode_always($TRUE);
  $cwl->set_use_paginator($FALSE);

  my $next_token = $EMPTY;
  my $deleted    = 0;

  PAGE: while ($TRUE) {

    my $rsp = $cwl->DescribeLogStreams(
      { logGroupName => $group,
        orderBy      => 'LastEventTime',
        descending   => 0,
        $next_token ? ( nextToken => $next_token ) : (),
      },
    );

    foreach my $stream ( @{ $rsp->{logStreams} // [] } ) {

      next
        if !exists $stream->{lastEventTimestamp};

      $self->get_logger->debug(
        sub {
          return Dumper(
            [ stream           => $stream,
              last             => fmt_time( $stream->{lastEventTimestamp} ),
              last_raw         => $stream->{lastEventTimestamp},
              cutoff_formatted => fmt_time($cutoff),
              cutoff_raw       => $cutoff
            ]
          );
        }
      );

      last PAGE
        if $stream->{lastEventTimestamp} >= $cutoff;

      my $stream_name = $stream->{logStreamName};

      my $attempt = 0;

      DELETE: while ($TRUE) {
        my $err;

        if ( !$self->get_dryrun ) {
          eval { $cwl->DeleteLogStream( { logGroupName => $group, logStreamName => $stream_name, }, ); };
          $err = $EVAL_ERROR;
          Time::HiRes::sleep($DELETE_STREAM_DELAY);
        }

        last DELETE
          if !$err;

        die "$err"
          if "$err" !~ /ThrottlingException/xsm || ++$attempt >= $MAX_DELETE_ATTEMPTS;

      }

      print {*STDOUT} "$stream_name\n";
      $deleted++;
    }

    $next_token = $rsp->{nextToken};

    last if !$next_token;
  }

  $cwl->set_decode_always($decode_always);
  $cwl->set_use_paginator($use_paginator);

  return $SUCCESS;
}

#########################################################################
sub cmd_version {
#########################################################################

  print {*STDOUT} sprintf "%s v%s\n", $ENV{MODULINO_WRAPPER}, $VERSION;
  print {*STDOUT} "Copyright (C) 2026, TBC Development Group, LLC. All rights reserved.\n";

  return $SUCCESS;
}

#########################################################################
sub cmd_delete_group {
#########################################################################
  my ($self) = @_;

  my $cwl = $self->get_cwl;

  my $group_name = $self->get_group;

  croak 'no group'
    if !$group_name;

  $cwl->set_print_error($FALSE);
  $cwl->set_raise_error($TRUE);

  eval { return $cwl->DeleteLogGroup( { logGroupName => $group_name } ); };

  if ($EVAL_ERROR) {
    if ( $cwl->get_response->code eq $HTTP_OK ) {
      printf "%s deleted.\n", $group_name;
    }
    elsif ( $cwl->get_response->code eq $HTTP_BAD_REQUEST ) {
      print $cwl->print_error;
    }
    else {
      print $EVAL_ERROR;
    }
  }

  return $TRUE;
}

#########################################################################
sub cmd_create_group {
#########################################################################
  my ($self) = @_;

  my $cwl = $self->get_cwl;

  my $group_name = $self->get_group;

  croak 'no group'
    if !$group_name;

  $cwl->set_raise_error($FALSE);
  $cwl->set_print_error($TRUE);

  $cwl->CreateLogGroup( { logGroupName => $group_name } );

  if ( $cwl->get_response->code eq $HTTP_OK ) {
    printf "%s\n", $group_name;
  }

  return $TRUE;
}

#########################################################################
sub _create_stream {
#########################################################################
  my ($self) = @_;

  my $group  = $self->get_group;
  my $stream = $self->get_stream;

  croak 'no group'
    if !$group;

  croak 'no stream'
    if !$stream;

  my $cwl = $self->get_cwl;

  $cwl->set_raise_error($FALSE);
  $cwl->set_print_error($TRUE);

  my $ug   = Data::UUID->new;
  my $uuid = $ug->create;

  my $stream_suffix = md5_hex( $ug->to_string($uuid) );
  my $stream_prefix = $stream;

  my $stream_name = $stream_prefix . $SLASH . $stream_suffix;

  $cwl->CreateLogStream(
    { logGroupName  => $group,
      logStreamName => $stream_name,
    },
  );

  return $cwl->get_response->code eq $HTTP_OK ? ( $group, $stream_name ) : ();
}

#########################################################################
sub cmd_create_stream {
#########################################################################
  my ($self) = @_;

  my ( $group, $stream ) = $self->_create_stream;

  if ( $group && $stream ) {
    print "$group $stream\n";
  }

  return $TRUE;
}

#########################################################################
sub cmd_list_groups {
#########################################################################
  my ($self) = @_;

  my $cwl = $self->get_cwl;

  my $rsp = $cwl->DescribeLogGroups->{logGroups};

  my %log_groups = map { ( $_->{logGroupName}, $_ ) } @{$rsp};

  require Text::ASCIITable;

  require Number::Bytes::Human;

  my $t = Text::ASCIITable->new(
    { headingText => 'Log Groups',
      allowANSI   => $self->get_color,
    },
  );

  $t->setCols( 'Group Name', 'Size', 'Creation Date' );

  foreach my $g ( sort keys %log_groups ) {

    my ( $bytes, $creation_time ) = @{ $log_groups{$g} }{qw(storedBytes creationTime)};

    $bytes = $bytes ? Number::Bytes::Human::format_bytes($bytes) : $EMPTY;

    $t->addRow( $g, $bytes, fmt_time($creation_time) );
  }

  print $t;

  return $TRUE;
}

#########################################################################
sub cmd_get_stream {
#########################################################################
  my ($self) = @_;

  my $cwl = $self->get_cwl;

  my $use_paginator = $cwl->get_use_paginator;
  $cwl->set_use_paginator($FALSE);

  my $group = $self->get_group;

  croak 'no group'
    if !$group;

  my $stream_list = $self->fetch_streams;

  croak 'no stream'
    if !$stream_list && !$self->get_follow;

  my $start_time = $self->get_start_time * $MILLISECONDS_PER_SECOND;

  # preserve order
  my %stream_tokens;
  tie %stream_tokens, 'Tie::IxHash', map { $_ => $EMPTY } keys %{ $stream_list // {} }; ## no critic (ProhibitTies)

  my $last_discovery = Time::HiRes::time;
  my %idle_streams;
  my %idle_since;
  my %retired_streams;

  if ( $self->get_follow ) {
    $SIG{INT} = sub { exit 1 };
  }

  binmode STDOUT, ':encoding(UTF-8)';

  my $decode_always = $cwl->get_decode_always;
  $cwl->set_decode_always($FALSE);

  FOLLOW: while ($TRUE) {

    if ( $self->get_follow && Time::HiRes::time - $last_discovery >= $self->get_discovery_interval ) {
      $self->refresh_streams( \%stream_tokens, \%idle_streams, \%idle_since, \%retired_streams );
      $last_discovery = Time::HiRes::time;
    }

    my $got_events = $FALSE;
    my @pass_events;  # accumulate all events this pass for sorted output

    foreach my $stream_name ( keys %stream_tokens ) {

      my $rsp;
      my $attempt = 0;

      GET_LOG_EVENTS:
      while ($TRUE) {

        $rsp = eval {

          return $cwl->GetLogEvents(
            { logGroupName  => $group,
              logStreamName => $stream_name,
              $stream_tokens{$stream_name}
              ? ( nextToken => $stream_tokens{$stream_name} )
              : (
                startTime     => $start_time,
                startFromHead => \1,
              ),
            }
          );
        };

        if ( !$EVAL_ERROR ) {
          last GET_LOG_EVENTS;
        }

        die $EVAL_ERROR
          if $EVAL_ERROR !~ /API\s+ERROR\(599\)/xsm || ++$attempt >= 3;

        Time::HiRes::sleep( $self->get_sleep_time );
      }

      if ($rsp) {
        $rsp = decode_json($rsp) // {};
      }

      my $new_token = $rsp->{nextForwardToken};

      if ( $rsp->{events} && @{ $rsp->{events} } ) {
        $got_events = $TRUE;
        delete $idle_since{$stream_name};

        my ( $colored_group, $colored_stream ) = ( $group, $stream_name );

        if ( my $color = $self->get_color ) {
          $colored_group  = Term::ANSIColor::colored( $colored_group,  $GROUP_COLOR );
          $colored_stream = Term::ANSIColor::colored( $colored_stream, $STREAM_COLOR );
        }

        my @prefix;

        push @prefix, $self->get_no_group_name  ? () : $colored_group;
        push @prefix, $self->get_no_stream_name ? () : $colored_stream;

        push @prefix, @prefix ? $EMPTY : ();

        my $message_prfx = join $SPACE, @prefix;

        for my $e ( @{ $rsp->{events} } ) {
          push @pass_events,
            {
            timestamp => $e->{timestamp},
            message   => $e->{message},
            prefix    => $message_prfx,
            };
        }
      }
      elsif ( defined $stream_tokens{$stream_name}
        && $stream_tokens{$stream_name}
        && defined $new_token
        && $new_token eq $stream_tokens{$stream_name} ) {
        # token has stabilized with no events -- stream is idle

        if ( $self->get_follow ) {
          $idle_since{$stream_name} //= Time::HiRes::time;
          $idle_streams{$stream_name} = { token => $new_token, };
        }

        delete $stream_tokens{$stream_name};
        next;
      }

      $stream_tokens{$stream_name} = $new_token;
    }

    # print all events for this pass sorted by timestamp (oldest first)
    for my $e ( sort { $a->{timestamp} <=> $b->{timestamp} } @pass_events ) {
      my $message = choose {
        return $e->{message}
          if $decode_always;

        return eval { decode_json( $e->{message} ) } // $e->{message};
      };

      chomp $message;
      printf "%s[%s] %s\n", $e->{prefix}, fmt_time( $e->{timestamp} ), $message;
    }

    last if !$self->get_follow && !$got_events;

    if ( !$got_events && $self->get_follow ) {
      Time::HiRes::sleep( $self->get_sleep_time );
    }
  }

  $cwl->set_decode_always($decode_always);
  $cwl->set_use_paginator($use_paginator);

  return $SUCCESS;
}

#########################################################################
sub cmd_list_streams {
#########################################################################
  my ($self) = @_;

  my $group = $self->get_group;

  croak 'no group'
    if !$group;

  my $log_streams = $self->fetch_streams;

  croak 'no streams'
    if !$log_streams;

  require Text::ASCIITable;

  my $t = Text::ASCIITable->new(
    { headingText => sprintf( 'Log Streams (%s)', $group ),
      allowANSI   => $self->get_color,
    },
  );

  $t->setCols( 'Stream Name', 'Creation Date', 'Last Event' );

  foreach my $s ( reverse values %{$log_streams} ) {

    my ( $creation_time, $last_event ) = @{$s}{qw(creationTime lastEventTimestamp)};

    $creation_time = fmt_time($creation_time);

    $last_event = $last_event ? fmt_time($last_event) : $EMPTY;

    $t->addRow( $s->{logStreamName}, $creation_time, $last_event );
  }

  print $t;

  return $TRUE;
}

#########################################################################
sub init {
#########################################################################
  my ($self) = @_;

  return $self->command('version')
    if $self->get_version;

  # -- log message formatting
  if ( $self->get_localstack ) {
    $self->set_endpoint_url($LOCALSTACK_ENDPOINT);
  }

  # -- start-time
  if ( my $start_time = $self->get_start_time ) {
    $self->set_start_time( parse_start_time($start_time) );
  }

  $self->set_discovery_interval( $self->get_discovery_interval // $DISCOVERY_INTERVAL );

  croak '--discovery-interval must be greater than zero'
    if $self->get_discovery_interval <= 0;

  if ( defined $self->get_limit ) {
    croak '--limit must be greater than zero'
      if $self->get_limit <= 0;
  }

  if ( $self->get_follow && defined $self->get_limit ) {
    croak '--limit cannot be used with --follow';
  }

  $self->set_sleep_time( $self->get_sleep_time // $LOG_DELAY );

  croak '--sleep-time must be greater than zero'
    if $self->get_sleep_time <= 0;

  $self->set_cwl(
    Amazon::API::CloudWatchLogs->new(
      debug       => $ENV{DEBUG} || $self->get_debug,
      print_error => $TRUE,
      url         => $self->get_endpoint_url,
      region      => $self->get_region,
      profile     => $self->get_profile,
    )
  );

  if ( $self->get_color ) {
    require Term::ANSIColor;
  }

  return;
}

#########################################################################
sub fmt_time {
#########################################################################
  my ( $time, $seconds ) = @_;

  if ( !$time ) {
    $time    = time;
    $seconds = $TRUE;
  }

  $time = $seconds ? $time : $time / $MILLISECONDS_PER_SECOND;

  return time2str( $ISO_8601_FORMAT, $time, $TIME_ZONE );
}

#########################################################################
sub parse_start_time {
#########################################################################
  my ($start_time) = @_;

  return _parse_start_time($start_time)
    if $start_time =~ /\A\d+[dhm]\z/xsmi;

  $start_time =~ s/(\d+)\s*(?:m|min)\s+/$1 min /xsm;

  eval { require Date::Manip }; ## scandeps: recommends

  return _parse_start_time($start_time)
    if $EVAL_ERROR;

  my $date = Date::Manip::ParseDate($start_time)
    or croak "invalid start time: $start_time";

  return Date::Manip::UnixDate( $date, '%s' );
}

#########################################################################
sub _parse_start_time {
#########################################################################
  my ($start_time) = @_;

  my $seconds;

  if ( $start_time =~ /\A(\d+)d\z/xsmi ) {
    $seconds = $1 * $SECONDS_IN_DAY;
  }
  elsif ( $start_time =~ /\A(\d+)h\z/xsmi ) {
    $seconds = $1 * $SECONDS_IN_HOUR;
  }
  elsif ( $start_time =~ /\A(\d+)m\z/xsmi ) {
    $seconds = $1 * $SECONDS_IN_MINUTE;
  }
  else {
    croak 'invalid start time, must be N(d|h|m)';
  }

  return time - $seconds;
}

#########################################################################
sub fetch_streams {
#########################################################################
  my ($self) = @_;

  my $cwl = $self->get_cwl;

  my @streams;

  my $next_token = $EMPTY;

  my $limit = $self->get_limit;

  my $page_limit = $limit && $limit < $ITER_LIMIT ? $limit : $ITER_LIMIT;

  my $start_time = $self->get_start_time * $MILLISECONDS_PER_SECOND;

  my $logstream_prefix = $self->get_stream;
  my $decode_always    = $cwl->get_decode_always;
  my $use_paginator    = $cwl->get_use_paginator;

  $cwl->set_decode_always($TRUE);
  $cwl->set_use_paginator($FALSE);

  LOOP: while ($TRUE) {

    my $rsp = $cwl->DescribeLogStreams(
      { logGroupName => $self->get_group,
        limit        => $page_limit,
        orderBy      => 'LastEventTime',
        descending   => \1,
        $next_token ? ( nextToken => $next_token ) : (),
      },
    );

    # these are returned newest-active-first (descending => 1 above)

    my @log_streams    = @{ $rsp->{logStreams} // [] };
    my @active_streams = grep { exists $_->{lastEventTimestamp} } @log_streams;

    # filter out streams older than the requested start_time
    my @relevant
      = $start_time
      ? grep { exists $_->{lastEventTimestamp} && $_->{lastEventTimestamp} >= $start_time } @active_streams
      : @log_streams;

    # in descending order, once a page yields nothing relevant we've
    # paged past the requested window - stop, don't fall back to
    # including the (irrelevant, older) streams on this page

    last LOOP
      if $start_time
      && @active_streams
      && !@relevant;

    foreach my $s (@relevant) {

      my $stream_name = $s->{logStreamName};
      next if $logstream_prefix && $stream_name !~ /^\Q$logstream_prefix\E/ixsm;
      push @streams, $s;

      last LOOP if $limit && @streams >= $limit;
    }

    $next_token = $rsp->{nextToken};

    last if !$next_token;

    last if $limit && $limit <= @streams;
  }

  $cwl->set_decode_always($decode_always);
  $cwl->set_use_paginator($use_paginator);

  my %ordered_hash;
  tie %ordered_hash, 'Tie::IxHash', map { ( $_->{logStreamName}, $_ ) } @streams; ## no critic (ProhibitTies)

  return @streams ? \%ordered_hash : undef;
}

#########################################################################
sub cmd_last_stream {
#########################################################################
  my ($self) = @_;

  my $limit = $self->get_limit;
  $self->set_limit(1);

  my $last_stream = $self->fetch_streams();

  if ($last_stream) {
    print JSON->new->pretty->encode( values %{$last_stream} );
  }

  $self->set_limit($limit);

  return $TRUE;
}

#########################################################################
sub refresh_streams {
#########################################################################
  my ( $self, $stream_tokens, $idle_streams, $idle_since, $retired_streams ) = @_;

  my $stream_list     = $self->fetch_streams;
  my $is_lambda_group = $self->get_group =~ m{\A/aws/lambda/}xsm;
  my $now             = Time::HiRes::time;

  # Give idle streams one poll at each discovery interval. Lambda streams
  # that have remained idle beyond the grace period are retired instead.
  foreach my $stream_name ( keys %{$idle_streams} ) {
    next if exists $stream_tokens->{$stream_name};

    my $idle_stream = $idle_streams->{$stream_name};

    if ( $is_lambda_group
      && exists $idle_since->{$stream_name}
      && $now - $idle_since->{$stream_name} >= $LAMBDA_IDLE_LIMIT ) {

      $retired_streams->{$stream_name} = { retired_at => $now * $MILLISECONDS_PER_SECOND, };

      delete $idle_streams->{$stream_name};
      delete $idle_since->{$stream_name};
      next;
    }

    $stream_tokens->{$stream_name} = $idle_stream->{token};
    delete $idle_streams->{$stream_name};
  }

  # Add newly discovered streams. A retired Lambda stream is only
  # reactivated when DescribeLogStreams reports newer activity.
  foreach my $stream_name ( keys %{ $stream_list // {} } ) {
    next if exists $stream_tokens->{$stream_name};
    next if exists $idle_streams->{$stream_name};

    if ( my $retired_stream = $retired_streams->{$stream_name} ) {
      my $last_event_timestamp = $stream_list->{$stream_name}->{lastEventTimestamp} // 0;
      next if $last_event_timestamp <= $retired_stream->{retired_at};
      delete $retired_streams->{$stream_name};
      delete $idle_since->{$stream_name};
    }

    $stream_tokens->{$stream_name} = $EMPTY;
  }

  return;
}

#########################################################################
sub main {
#########################################################################

  my %commands = (
    'create-group'  => \&cmd_create_group,
    'create-stream' => \&cmd_create_stream,
    'delete-group'  => \&cmd_delete_group,
    'get-stream'    => \&cmd_get_stream,
    'last-stream'   => \&cmd_last_stream,
    'list-groups'   => \&cmd_list_groups,
    'list-streams'  => \&cmd_list_streams,
    'prune-streams' => \&cmd_prune_streams,
    'version'       => \&cmd_version,
  );

  my @option_specs = qw(
    color|c!
    debug|d
    discovery-interval=i
    dryrun
    endpoint-url|u=s
    follow|f
    group|g=s
    help|h
    localstack|l
    limit|L=i
    no-group-name|G
    no-stream-name|S!
    profile|p=s
    region|r=s
    sleep-time=i
    start-time|t=s
    stream|s=s
    version|v
  );

  my %defaults = (
    color          => $TRUE,
    no_group_name  => $FALSE,
    no_stream_name => $FALSE,
    endpoint_url   => $ENV{AWS_ENDPOINT_URL},
    region         => $ENV{AWS_REGION}  || $ENV{AWS_DEFAULT_REGION},
    profile        => $ENV{AWS_PROFILE} || 'default',
    start_time     => 0,
  );

  my $cli = Amazon::CloudWatchLogs->new(
    commands        => \%commands,
    default_options => \%defaults,
    option_specs    => \@option_specs,
    extra_options   => [qw(cwl)],
    abbreviations   => $TRUE,
  );

  return $cli->run;
}

1;

## no critic

__END__

=pod

=encoding utf8

=head1 NAME

Amazon::CloudWatchLogs - CLI tool for interacting with AWS CloudWatch Logs

=head1 SYNOPSIS

 aws-logs [options] command

=head1 DESCRIPTION

C<Amazon::CloudWatchLogs> provides a command-line interface for common
AWS CloudWatch Logs operations including listing log groups and streams,
retrieving log events, and creating or deleting groups and streams.

The module is implemented as a L<CLI::Simple> modulino and invoked via
the C<aws-logs> script.

=head2 Commands

=over 5

=item create-group

Create a new CloudWatch log group.

 aws-logs -g /my/log/group create-group

=item create-stream

Create a new log stream within a log group. The value supplied with
C<--stream> is used as a prefix; a unique suffix is generated and
appended to create the actual log stream name.

 aws-logs -g /my/log/group -s my-stream create-stream

For example, the resulting stream name will have the form:

 my-stream/<unique-id>

The command prints the log group and generated log stream name after
successful creation.

=item delete-group

Delete a log group and all of its log streams.

 aws-logs -g /my/log/group delete-group

=item get-stream

Retrieve log events from all matching streams in a log group. Use
C<--follow> to continue polling the streams for new events.

 aws-logs -g /aws/lambda/my-function -t '1 hour ago' get-stream
 aws-logs -g /aws/lambda/my-function -t 30m --follow get-stream

Streams are discovered in descending C<LastEventTime> order. During
each polling pass, one page of events is retrieved from each stream
and the events collected during that pass are sorted by timestamp
before being displayed.

Because streams are paginated independently, output is not guaranteed
to be globally chronological across multiple streams.

The C<--start-time> option sets the starting event time for each
stream. See L</Start Time Formats>.

=item last-stream

Display the metadata for the most recently active log stream in a
log group, optionally filtered by a stream name prefix.

 aws-logs -g /aws/lambda/my-function last-stream
 aws-logs -g /aws/lambda/my-function -s '2026/05' last-stream

Output is a JSON object containing the stream metadata including
C<logStreamName>, C<firstEventTimestamp>, C<lastEventTimestamp>,
and C<lastIngestionTime>.

=item list-groups

List all CloudWatch log groups in the current account and region.

 aws-logs list-groups

=item list-streams

List all log streams for a log group.

 aws-logs -g /aws/lambda/my-function list-streams
 aws-logs -g /aws/lambda/my-function -L 5 list-streams

=item help

Display usage information.

=item prune-streams

Delete log streams whose last event is older than the specified age.

 aws-logs -g group-name prune-streams older-than

Example:

 aws-logs -g /aws/lambda/my-function prune-streams 7d

The C<older-than> argument is required and accepts a number followed by
C<m>, C<h>, or C<d> for minutes, hours, or days (for example, C<30m>,
C<12h>, or C<7d>). Streams without a C<lastEventTimestamp> are not deleted.

CloudWatch Logs retention policies expire log events but do not delete
the corresponding log stream resources. This command can be used to
remove stale stream metadata after those events have expired.

=item version

Display the program version and copyright information.

 aws-logs version

=back

=head2 Options

=over 5

=item --color, -c

Display output in color by default. Use C<--no-color> to disable. Colors are
applied to the log group name (green) and stream name (magenta) in the
output prefix.

=item --debug, -d

Enable verbose debug output including raw API requests and responses.
Note that enabling debug mode with large log volumes will significantly
impact performance due to L<Data::Dumper> output for every API call.

=item --discovery-interval

Number of seconds between stream discovery and idle-stream polling passes when
C<--follow> is enabled. Default: C<1>. See L</Follow Mode>.

=item --dryrun

Display the log streams that would be deleted by C<prune-streams>
without deleting them.

=item --endpoint-url, -u

Override the CloudWatch Logs endpoint URL. Useful for testing against
LocalStack or other compatible endpoints.

=item --follow, -f

Continuously tail log streams and periodically discover newly
created streams. See L</Follow Mode> for details.

=item --group, -g

The CloudWatch log group name. Required for most commands.

=item --help, -h

Display usage information.

=item --limit, -L

Maximum number of matching log streams to retrieve. If omitted, all
matching streams are retrieved. C<--limit> cannot be used with
C<--follow>.

=item --localstack, -l

Use LocalStack. Shorthand for C<--endpoint-url http://localhost:4566>.

=item --no-group-name, -G

Exclude the log group name from the output prefix.

=item --no-stream-name, -S

Exclude the log stream name from the output prefix.

=item --profile, -p

AWS credentials profile to use. Defaults to C<$AWS_PROFILE>, or
C<default> if C<$AWS_PROFILE> is not set.

=item --region, -r

AWS region. Defaults to C<$AWS_REGION>, falling back to
C<$AWS_DEFAULT_REGION>.

=item --sleep-time

Number of seconds to sleep between polls when no events are found.
Default: C<1>. See L</Follow Mode>.

=item --stream, -s

Log stream name or prefix.

For C<create-stream>, this value is used as the prefix for the newly
created stream name.

For commands that retrieve or list streams, only streams whose names
begin with this value are included.

=item --start-time, -t

Retrieve events whose timestamp is at or after the specified time.
See L</Start Time Formats>.

=item --version, -v

Display the program version and copyright information.

=back

=head2 Start Time Formats

The C<--start-time> option accepts compact relative formats:

 aws-logs -t 30m ...     # 30 minutes ago
 aws-logs -t 2h ...      # 2 hours ago
 aws-logs -t 7d ...      # 7 days ago

If L<Date::Manip> is installed, a much broader set of natural language
formats is supported:

 aws-logs -t 'yesterday' ...
 aws-logs -t '2 days ago' ...
 aws-logs -t 'last Tuesday' ...
 aws-logs -t '2026-04-08 10:00' ...

B<Note:> C<--start-time> is also used during stream discovery.
Streams whose C<lastEventTimestamp> is older than C<--start-time>
are excluded from iteration. Because CloudWatch Logs updates
C<lastEventTimestamp> on an eventual consistency basis, very recently
active streams may not be discovered immediately.

=head2 Follow Mode

When C<--follow> is enabled, C<get-stream> continuously polls matching log
streams for new events.

Streams are maintained in three states:

=over 5

=item active

Active streams are polled on every pass using the forward pagination token
from the previous C<GetLogEvents> call.

=item idle

When a stream returns no events and its forward token no longer advances, the
stream is considered caught up and moved to the idle set. Idle streams are
polled once per discovery interval rather than on every pass.

If an idle stream produces new events, it becomes active again.

=item retired

For Lambda log groups, idle streams are retired from direct polling
after remaining inactive for 20 minutes. Retired streams are not
polled directly, but stream discovery can reactivate them if
CloudWatch reports newer activity.

=back

This keeps active streams responsive while avoiding repeated C<GetLogEvents>
calls against streams that are already caught up.

Stream discovery runs independently of event polling. Every
C<--discovery-interval> seconds, C<DescribeLogStreams> is called and newly
discovered matching streams are added to the active set.

The C<--start-time> option still controls which streams are initially
considered relevant. For example:

 aws-logs -g /aws/lambda/my-function -t 1h --follow get-stream

will display events from Lambda streams active within the requested one-hour
window, then continue following those streams while also discovering newly
active streams.

Because Lambda execution environments create distinct log streams and old
streams can accumulate quickly, exhausted Lambda streams are eventually
retired from direct polling. If a retired stream later becomes active again,
periodic discovery can return it to the active set.

=head1 PERFORMANCE

=head2 JSON Backend

C<GetLogEvents> responses can be large. A single page can contain up
to 1 MB of log events or up to 10,000 events. Decoding these responses
with L<JSON::PP> (pure Perl) can introduce significant latency compared
with an XS-based JSON implementation.

C<Amazon::CloudWatchLogs> selects the fastest available JSON backend
automatically:

 BEGIN {
   $ENV{PERL_JSON_BACKEND} = 'Cpanel::JSON::XS,JSON::XS,JSON::PP';
   use JSON qw(decode_json);
 }

Installing L<Cpanel::JSON::XS> is B<strongly recommended>:

 cpanm Cpanel::JSON::XS

=head2 Shape Deserialization

C<get-stream> bypasses L<Amazon::API>'s normal Botocore shape
deserialization for C<GetLogEvents> responses by disabling the
C<decode_always> flag.

Normally, L<Amazon::API> walks the Botocore response shape and
recursively deserializes each field into Perl hashes, arrays, and
scalars. For a response containing thousands of log events, that
processing adds overhead with little benefit to C<get-stream>, which
only requires the C<message> and C<timestamp> fields.

Instead, C<get-stream> requests the raw JSON response and decodes it
directly. Combined with an XS JSON backend, this significantly reduces
the overhead of processing large C<GetLogEvents> responses.

=head2 Benchmarks

The following timings are representative for a single Lambda log stream
with approximately 9,500 events:

Metric                        aws-logs    AWS CLI
Per page (GetLogEvents)       ~0.42s      ~0.40s
Total (all pages, all setup)  ~3.5s       ~2.8s (single stream, no discovery)

=head1 DEPENDENCIES

=head2 Required

L<Amazon::API::CloudWatchLogs>, L<CLI::Simple>,
L<Data::UUID>, L<Date::Format>, L<JSON>,
L<Number::Bytes::Human>, L<Readonly>,
L<Text::ASCIITable>, L<Tie::IxHash>

=head2 Optional but Recommended

=over 5

=item L<Cpanel::JSON::XS> or L<JSON::XS>

Dramatically faster JSON decoding for large payloads. Without one of
these, L<JSON::PP> is used and performance on large log volumes will be
significantly degraded. See L</PERFORMANCE>.

=item L<Date::Manip>

Natural language time parsing for C<--start-time>. Without it, only
the compact C<{n}d>, C<{n}h>, and C<{n}m> formats are supported.

=back

=head1 VERSION

This documentation refers to version 1.0.7

=head1 SEE ALSO

L<Amazon::API::CloudWatchLogs>, L<Amazon::Credentials>, L<Amazon::API>,
L<CLI::Simple>, L<Cpanel::JSON::XS>

=head1 AUTHOR

Rob Lauer - <rlauer@treasurersbriefcase.com>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
