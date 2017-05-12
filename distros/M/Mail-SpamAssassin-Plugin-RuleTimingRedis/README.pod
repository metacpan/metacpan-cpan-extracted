package Mail::SpamAssassin::Plugin::RuleTimingRedis;

use Mail::SpamAssassin::Plugin;
use Mail::SpamAssassin::Logger;
use Mail::SpamAssassin::Util qw( untaint_var );

use strict;
use warnings;

# ABSTRACT: collect SA rule timings in redis
# VERSION

=head1 DESCRIPTION

RuleTimingRedis is a plugin for spamassassin which gathers and stores performance
data of processed spamassassin rules in a redis server.

=head1 CONFIGURATION

To load the plugin put an loadplugin line into init.pre:

  loadplugin Mail::SpamAssassin::Plugin::RuleTimingRedis

If the RuleTimingRedis.pm is not in perls @INC you need to specify the path:

  loadplugin Mail::SpamAssassin::Plugin::RuleTimingRedis <path-to>/RuleTimingRedis.pm

If your redis server is not listening on 127.0.0.1:6379 configure the address in local.cf:

  timing_redis_server 192.168.0.10:6379

Then restart amavisd.

After the first mail was processed the keys for the processed rules should appear in redis:

  $ redis-cli
  redis 127.0.0.1:6379> KEYS 'sa-timing.*'
     1) "sa-timing.__DRUGS_SLEEP3.count"
     2) "sa-timing.__MAIL_LINK.count"
     3) "sa-timing.__CGATE_RCVD.count"
  ...


=head1 PARAMETERS

The plugin has the following configuration options:

=over

=item timing_redis_server (default: '127.0.0.1:6379')

Address and port of the redis server.

=item timing_redis_password (default: no password)

Set if you redis server requires a password.

=item timing_redis_exclude_re (default: '^__')

Regex to exclude rules from timing statistics.

The current SpamAssassin ruleset is about ~2k rules.
The default will exclude all sub-rules that start with '__' (two underscores).

Set to empty string if you really want to measure all rules.

=item timing_redis_prefix (default: 'sa-timing.')

Prefix to used for the keys in redis.

=item timing_redis_database (default: 0)

Will call SELECT to switch database after connect if set to a non-zero value.

Database 0 is the default in redis.

=item timing_redis_precision (default: 1000000)

Since redis uses integers the floating point value is multiplied
by this factor before storing in redis.

=item timing_redis_bulk_update (default: 50)

Will queue redis updates up to the configured value and execute them
in bulks via a server-side script.

Requires a redis server >= 2.6.0 and Redis perl module >= 1.954.

Set to 0 to disable bulk.

=item timing_redis_debug (default: 0)

Turn on/off debug on the Redis connection.

=item timing_redis_hits_enabled (default: 0)

If enabled for each test that matched an counter will
be incremented in the redis database.

  127.0.0.1:6379> keys *.hits
   1) "sa-timing.MISSING_SUBJECT.hits"
   2) "sa-timing.MISSING_MID.hits"
   3) "sa-timing.NO_RELAYS.hits"
  127.0.0.1:6379> GET "sa-timing.MISSING_SUBJECT.hits"
  "3"

=back

=cut

use Time::HiRes qw(time);

use vars qw(@ISA);
@ISA = qw(Mail::SpamAssassin::Plugin);

use Redis;

our $BULK_TIMING_SCRIPT = <<"EOT";
for i=1,#KEYS do
  redis.call('INCR', KEYS[i] .. ".count" )
  redis.call('INCRBY', KEYS[i] .. ".time", ARGV[i] )
end
return #KEYS
EOT
our $BULK_MINCR_SCRIPT = <<"EOT";
for i=1,#KEYS do
  redis.call('INCR', KEYS[i] )
end
return #KEYS
EOT

sub new {
    my $class = shift;
    my $mailsaobject = shift;

    $class = ref($class) || $class;
    my $self = $class->SUPER::new($mailsaobject);
    bless ($self, $class);

    $mailsaobject->{conf}->{parser}->register_commands( [
        {
            setting => 'timing_redis_server',
            is_admin => 1,
            type => $Mail::SpamAssassin::Conf::CONF_TYPE_STRING,
            default => '127.0.0.1:6379',
        }, {
            setting => 'timing_redis_password',
            is_admin => 1,
            type => $Mail::SpamAssassin::Conf::CONF_TYPE_STRING,
        }, {
            setting => 'timing_redis_exclude_re',
            is_admin => 1,
            type => $Mail::SpamAssassin::Conf::CONF_TYPE_STRING,
            default => '^__',
        }, {
            setting => 'timing_redis_prefix',
            is_admin => 1,
            type => $Mail::SpamAssassin::Conf::CONF_TYPE_STRING,
            default => 'sa-timing.',
        }, {
            setting => 'timing_redis_database',
            is_admin => 1,
            type => $Mail::SpamAssassin::Conf::CONF_TYPE_NUMERIC,
            default => 0,
        }, {
            setting => 'timing_redis_precision',
            is_admin => 1,
            type => $Mail::SpamAssassin::Conf::CONF_TYPE_NUMERIC,
            default => 1000000, # microseconds (millionths of a second)
        }, {
            setting => 'timing_redis_bulk_update',
            is_admin => 1,
            type => $Mail::SpamAssassin::Conf::CONF_TYPE_NUMERIC,
            default => 50,
        }, {
            setting => 'timing_redis_debug',
            is_admin => 1,
            type => $Mail::SpamAssassin::Conf::CONF_TYPE_BOOL,
            default => 0,
        }, {
            setting => 'timing_redis_hits_enabled',
            is_admin => 1,
            type => $Mail::SpamAssassin::Conf::CONF_TYPE_BOOL,
            default => 0,
        },
    ] );

    return( $self );
}

sub _get_redis {
    my $self = shift;
    my $conf = $self->{main}->{conf};
    my ( $server, $debug, $password, $database, $bulk ) =
    	@$conf{ 'timing_redis_server','timing_redis_debug', 'timing_redis_password',
		'timing_redis_database', 'timing_redis_bulk_update' };

    untaint_var( \$server );

    if( ! defined $self->{'_redis'} ) {
	Mail::SpamAssassin::Plugin::info('initializing connection to redis server...');
        eval {
            $self->{'_redis'} = Redis->new(
                'server' => $server,
                'debug' => $debug,
		defined $password ? ( password => $password ) : (),
            );
        };
        if( $@ ) {
            die('could not connect to redis: '.$@);
        }
	if( $database ) {
		Mail::SpamAssassin::Plugin::info("selecting redis database $database...");
		$self->{'_redis'}->select($database);
	}
	if( $bulk ) {
		Mail::SpamAssassin::Plugin::info("loading redis lua bulk script...");
		$self->{'_timing_script'} = $self->{'_redis'}->script_load($BULK_TIMING_SCRIPT);
		$self->{'_mincr_script'} = $self->{'_redis'}->script_load($BULK_MINCR_SCRIPT);
		Mail::SpamAssassin::Plugin::dbg("scripts loaded as ".$self->{'_timing_script'}
      .' and '.$self->{'_mincr_script'});
	}
    }
    return $self->{'_redis'};
}

sub _flush_queue {
    my ( $self, $queue ) = @_;
    my $prefix = $self->{main}->{conf}->{'timing_redis_prefix'};

    my $count = scalar @$queue;
    if( ! $count ) {
	    return;
    }
    Mail::SpamAssassin::Plugin::dbg("flushing $count timing events to redis...");
    my @args;
    push( @args, map { $prefix.$_->[0] } @$queue );
    push( @args, map { $_->[1] } @$queue );

    $self->{'_redis'}->evalsha(
	    $self->{'_timing_script'}, $count, @args, sub {});

    @$queue = ();

    return;
}

sub check_start {
    my ($self, $options) = @_;
    $options->{permsgstatus}->{'rule_timing_queue'} = [];
    return;
}

sub start_rules {
    my ($self, $options) = @_;
    $options->{permsgstatus}->{'rule_timing_start'} = Time::HiRes::time();
    return;
}

sub ran_rule {
    my $time = Time::HiRes::time();
    my ($self, $options) = @_;
    my $exclude_re = $self->{main}->{conf}->{'timing_redis_exclude_re'};
    my $bulk = $self->{main}->{conf}->{'timing_redis_bulk_update'};
    my $queue = $options->{permsgstatus}->{'rule_timing_queue'};

    my $permsg = $options->{permsgstatus};
    my $name = $options->{rulename};
    if( defined $exclude_re
            && $exclude_re ne ''
            &&  $name =~ /$exclude_re/ ) {
        $permsg->{'rule_timing_start'} = Time::HiRes::time();
        return;
    }
    my $prefix = $self->{main}->{conf}->{'timing_redis_prefix'};
    my $precision = $self->{main}->{conf}->{'timing_redis_precision'};

    my $duration = int(($time - $permsg->{'rule_timing_start'}) * $precision);

    my $redis = $self->_get_redis;

    if( $bulk )  {
        push( @$queue, [ $name, $duration ] );

        if( scalar @$queue >= $bulk ) {
            $self->_flush_queue( $queue );
        }
    } else {
        $redis->incrby($prefix.$name.'.time', $duration, sub {} );
        $redis->incr($prefix.$name.'.count', sub {} );
    }

    $permsg->{'rule_timing_start'} = Time::HiRes::time();
    return;
}

sub check_end {
    my ($self, $options) = @_;
    my $prefix = $self->{main}->{conf}->{'timing_redis_prefix'};
    my $bulk = $self->{main}->{conf}->{'timing_redis_bulk_update'};
    my $hits_enabled = $self->{main}->{conf}->{'timing_redis_hits_enabled'};
    my $pms = $options->{permsgstatus};
    my $queue = $pms->{'rule_timing_queue'};

    my $redis = $self->_get_redis;
    if( $bulk ) {
      Mail::SpamAssassin::Plugin::dbg("cleaning up redis timing queue (".scalar(@$queue)." left)...");
      $self->_flush_queue( $queue );
    }
    if( $hits_enabled && $bulk ) {
      my @tests = map { $prefix.$_.'.hits' }
        split(',', $pms->get_names_of_tests_hit);
      if( $bulk ) {
        $self->{'_redis'}->evalsha(
    	    $self->{'_mincr_script'}, scalar(@tests), @tests, sub {});
      } else {
        foreach my $test ( @tests ) {
          $self->{'_redis'}->incr($test, sub {} );
        }
      }
    }

    Mail::SpamAssassin::Plugin::dbg("waiting for redis pipelined responses...");
    $redis->wait_all_responses;

    return;
}

sub finish {
	my $self = shift;
	if( defined $self->{'redis'} ) {
		$self->{'redis'}->quit;
	}
	return;
}

1;
