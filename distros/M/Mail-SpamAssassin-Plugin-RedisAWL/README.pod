package Mail::SpamAssassin::Plugin::RedisAWL;

use Mail::SpamAssassin::Plugin;
use Mail::SpamAssassin::Logger;
use strict;
use warnings;

# ABSTRACT: redis support for spamassassin AWL/TxRep
# VERSION

use vars qw(@ISA);
@ISA = qw(Mail::SpamAssassin::Plugin);

=head1 DESCRIPTION

RedisAWL implements a redis table for the spamassassin AWL/TxRep plugin.

=head1 INSTALLATION

To install the plugin from CPAN:

  $ cpanm Mail::SpamAssassin::Plugin::RedisAWL

=head1 CONFIGURATION

Load the plugin in init.pre:

  loadplugin Mail::SpamAssassin::Plugin::RedisAWL

If you're using the AWL plugin change the AWL datebase type to redis in local.cf:

  auto_whitelist_factory Mail::SpamAssassin::RedisAddrList

If you're using the TxRep plugin use:

  txrep_factory Mail::SpamAssassin::RedisAddrList

And you may have to configure the redis server and prefix:

  auto_whitelist_redis_server 127.0.0.1:6379
  auto_whitelist_redis_prefix awl_

=head1 PARAMETERS

=head2 auto_whitelist_redis_server

The redis server to use.

Default: 127.0.0.1:6379

=head2 auto_whitelist_redis_password (default: no password)

Set if you redis server requires a password.

=head2 auto_whitelist_redis_prefix

A prefix for AWL keys.

Default: awl_

=head2 auto_whitelist_redis_database (default: 0)

Will call SELECT to switch database after connect if set to a non-zero value.

Database 0 is the default in redis.

=head2 auto_whitelist_redis_expire (default: 0)

Add an expire timeout to entries in redis.

The default 0 means that no expire timeout is set.

Timeout must be set in seconds.

An entries expiration timeout will be updated whenever a new score is applied to it.

=head2 auto_whitelist_redis_debug (default: 0)

Turn on/off debug on the Redis connection.

=head1 CHECK YOUR CONFIGURATION

Scan a mail an check debug output for redis/awl messages:

  $ spamassassin -D < /tmp/testmail 2>&1 | egrep -e 'auto-whitelist' -e 'redis'

Query redis for awl data:

  $ redis-cli
  redis 127.0.0.1:6379> keys awl_*
  1)...
  redis 127.0.0.1:6379> get awl_bla@blub.de|ip=1.2.3.4_score
  "-5099"
  redis 127.0.0.1:6379> get awl_bla@blub.de|ip=1.2.3.4_count
  "1"

=cut

sub new {
    my $class = shift;
    my $mailsaobject = shift;

    $class = ref($class) || $class;
    my $self = $class->SUPER::new($mailsaobject);
    bless ($self, $class);

    $mailsaobject->{conf}->{parser}->register_commands( [
        {
            setting => 'auto_whitelist_redis_server',
            type => $Mail::SpamAssassin::Conf::CONF_TYPE_STRING,
            default => '127.0.0.1:6379',
            is_admin => 1,
        }, {
            setting => 'auto_whitelist_redis_prefix',
            type => $Mail::SpamAssassin::Conf::CONF_TYPE_STRING,
            default => 'awl_',
            is_admin => 1,
        }, {
            setting => 'auto_whitelist_redis_password',
            is_admin => 1,
            type => $Mail::SpamAssassin::Conf::CONF_TYPE_STRING,
        }, {
            setting => 'auto_whitelist_redis_database',
            is_admin => 1,
            type => $Mail::SpamAssassin::Conf::CONF_TYPE_NUMERIC,
            default => 0,
        }, {
            setting => 'auto_whitelist_redis_expire',
            is_admin => 1,
            type => $Mail::SpamAssassin::Conf::CONF_TYPE_NUMERIC,
            default => 0,
        }, {
            setting => 'auto_whitelist_redis_debug',
            is_admin => 1,
            type => $Mail::SpamAssassin::Conf::CONF_TYPE_BOOL,
            default => 0,
        },
    ] );

    return( $self );
}

1;
