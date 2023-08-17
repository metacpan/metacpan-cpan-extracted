#
# $Id$
#
# client::kafka Brik
#
package Metabrik::Client::Kafka;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         host => [ qw(host_list) ],
         host_zookeeper => [ qw(host) ],
         max_fetch_size => [ qw(size) ],
         rtimeout => [ qw(seconds_float) ],
         retry => [ qw(count) ],
         retry_backoff => [ qw(milliseconds) ],
         _broker => [ qw(INTERNAL) ],
         _kc => [ qw(INTERNAL) ],
         _kcli => [ qw(INTERNAL) ],
      },
      attributes_default => {
         host => [ qw(localhost:9092) ],
         host_zookeeper => 'localhost',
         max_fetch_size => 20000000,
         rtimeout => 3,
         retry => 5,
         retry_backoff => 1000,
      },
      commands => {
         create_connection => [ qw(host|OPTIONAL) ],
         create_producer => [ ],
         create_consumer => [ ],
         send => [ qw(topic partition messages) ],
         loop_consumer_fetch => [ qw(topic partition|OPTIONAL) ],
         close => [ ],
         create_topic => [ qw(topic replication_factor|OPTIONAL partitions|OPTIONAL) ],
         alter_topic => [ qw(topic replication_factor|OPTIONAL partitions|OPTIONAL) ],
         delete_topic => [ qw(topic) ],
         list_topics => [ ],
         describe_topic => [ qw(topic) ],
         run_console_producer => [ qw(topic) ],
         run_console_consumer => [ qw(topic) ],
      },
      require_modules => {
         'List::Util' => [ qw(shuffle) ],
         'Kafka' => [ ],
         'Kafka::Connection' => [ ],
         'Kafka::Producer' => [ ],
         'Kafka::Consumer' => [ ],
      },
      require_binaries => {
      },
      optional_binaries => {
      },
      need_packages => {
         freebsd => [ qw(p5-Tree-Trie) ],
      },
   };
}

sub create_connection {
   my $self = shift;
   my ($host) = @_;

   $host ||= $self->host;
   $self->brik_help_run_undef_arg('create_connection', $host) or return;
   $self->brik_help_run_invalid_arg('create_connection', $host, 'ARRAY') or return;
   $self->brik_help_run_empty_array_arg('create_connection', $host) or return;

   # Patch fonction to disable utf8 stuff, it fails strangely.
   {
      no warnings 'redefine';

      *Kafka::Connection::_is_like_server = sub {
         my ($self, $server) = @_;

         unless(
               defined($server)
               && defined(Kafka::Connection::_STRING($server))
               #&& !utf8::is_utf8($server)  # this sucks.
               && $server =~ /^[^:]+:\d+$/
           ) {
            return;
         }

         return $server;
      };
   };

   my $rtimeout = $self->rtimeout;
   my $send_max_attempts = $self->retry;
   my $retry_backoff = $self->retry_backoff;

   # Cause Kafka will connect to the first working broker.
   # By randomizing, different processes will use different brokers.
   my @list = List::Util::shuffle(@$host);

   my $broker = $list[0];  # We take the first, as it is now randomized.
   $self->_broker($broker);

   my $kc;
   eval {
      $kc = Kafka::Connection->new(
         broker_list => [ $broker ],
         timeout => $rtimeout,
         SEND_MAX_ATTEMPTS => $send_max_attempts,
         RETRY_BACKOFF => $retry_backoff,
      );
   };
   if ($@) {
      chomp($@);
      my $str_list = join(',', @list);
      return $self->log->error("create_connection: failed with list [$str_list]: [$@]");
   }

   return $self->_kc($kc);
}

sub create_producer {
   my $self = shift;
   my ($host) = @_;

   my $kc = $self->create_connection or return;

   # Doc:
   # https://kafka.apache.org/documentation/#acks

   my $kp;
   eval {
      $kp = Kafka::Producer->new(
         Connection => $kc,
         #RequiredAcks => $Kafka::WAIT_WRITTEN_TO_LOCAL_LOG,  # 1, default
         RequiredAcks => $Kafka::BLOCK_UNTIL_IS_COMMITTED,  # -1, best
         #RequiredAcks => $Kafka::NOT_SEND_ANY_RESPONSE,  # 0
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("create_producer: failed [$@]");
   }

   return $self->_kcli($kp);
}

sub create_consumer {
   my $self = shift;
   my ($host) = @_;

   my $kc = $self->create_connection or return;

   my $kco;  
   eval {
      $kco = Kafka::Consumer->new(Connection => $kc);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("create_consumer: failed [$@]");
   }

   return $self->_kcli($kco);
}

sub send {
   my $self = shift;
   my ($topic, $partition, $messages) = @_;

   my $kcli = $self->_kcli;
   $self->brik_help_run_undef_arg('create_producer', $kcli) or return;

   $self->brik_help_run_undef_arg('send', $topic) or return;
   $self->brik_help_run_undef_arg('send', $partition) or return;
   $self->brik_help_run_undef_arg('send', $messages) or return;
   $self->brik_help_run_invalid_arg('send', $messages, 'ARRAY', 'SCALAR') or return;

   my $broker = $self->_broker;

   my $r;
   eval {
      $r = $kcli->send($topic, $partition, $messages);
   };
   if ($@) {
      chomp($@);

      # Response $r looks like the following. We should use ErrorCode instead of regexes.
      # {
      #    CorrelationId => -1608629279,
      #    Throttle_Time_Ms => 0,
      #    topics => [ {
      #       partitions => [
      #          { ErrorCode => 0, Log_Append_Time => -1, Offset => 0, Partition => 0 },
      #       ],
      #       TopicName  => "test",
      #    } ],
      # }

      my $no_ack_for_request = 'No acknowledgement for sent request';
      my $cant_connect = 'Cannot connect to broker';
      my $cant_get_metadata = 'Cannot get metadata';
      my $unable_to_write = 'Unable to write due to ongoing Kafka leader selection';
      my $no_known_broker = 'There are no known brokers';
      my $too_big = 'Message is too big';
      my $invalid_arg_messages = 'Invalid argument: messages';
      my $cannot_send = 'Cannot send';
      my $err = $@;
      if ($@ =~ m{^$no_ack_for_request}i) {
         $err = $no_ack_for_request;
      }
      elsif ($@ =~ m{^$cant_connect}i) {
         $err = $cant_connect;
      }
      elsif ($@ =~ m{^$cant_get_metadata}i) {
         $err = $cant_get_metadata;
      }
      elsif ($@ =~ m{^$unable_to_write}i) {
         $err = $unable_to_write;
      }
      elsif ($@ =~ m{^$no_known_broker}i) {
         $err = $no_known_broker;
      }
      elsif ($@ =~ m{^$too_big}i) {
         $err = $too_big;
      }
      elsif ($@ =~ m{^$invalid_arg_messages}i) {
         $err = $invalid_arg_messages;
      }
      elsif ($@ =~ m{^$cannot_send}i) {
         my ($errnum, $details) = $@ =~ m{, (-\d+),.+?'([^']+)', 'Kafka::Exception}si;
         $errnum ||= "unknown";
         $details ||= "unknown";
         $err = "$cannot_send: $errnum, $details";
      }

      my $broker = $self->_broker;

      my $count = 1;
      my $length = length($messages);
      if (ref($messages) eq 'ARRAY') {
         $length = 0;
         $count = scalar(@$messages);
         for (@$messages) {
            $length += length($_);
         }
      }
      return $self->log->error("send: fail for broker [$broker], partition[$partition] ".
         "message count[$count] with length[$length]: [$err]");
   }

   my $count = 1;
   my $length = length($messages);
   if (ref($messages) eq 'ARRAY') {
      $length = 0;
      $count = scalar(@$messages);
      for (@$messages) {
         $length += length($_);
      }
   }
   $self->log->verbose("send: successful for broker [$broker], partition[$partition] ".
      "message count[$count] with length[$length]");

   return $r;
}

sub loop_consumer_fetch {
   my $self = shift;
   my ($topic, $partition) = @_;

   my $kcli = $self->_kcli;
   $self->brik_help_run_undef_arg('create_consumer', $kcli) or return;
   $self->brik_help_run_undef_arg('loop_consumer_fetch', $topic) or return;

   $partition ||= 0;

   my $offsets = $kcli->offsets(
      $topic,
      $partition,
      $Kafka::RECEIVE_EARLIEST_OFFSET,        # time
      $Kafka::DEFAULT_MAX_NUMBER_OF_OFFSETS,  # max_number
   );

   for (@$offsets) {
      print "Received offset: $_\n";
   }

   my $messages = $kcli->fetch(
       $topic,
       $partition,
       0,                       # offset
       $self->max_fetch_size,   # Maximum size of MESSAGE(s) to receive
   );
   for my $message (@$messages) {
      if ($message->valid) {
         print 'payload    : ', $message->payload, "\n";
         print 'key        : ', $message->key, "\n";
         print 'offset     : ', $message->offset, "\n";
         print 'next_offset: ', $message->next_offset, "\n";
      }
      else {
         print 'error      : ', $message->error, "\n";
      }
   }

   return 1;
}

sub close {
   my $self = shift;

   if ($self->_kcli) {
      $self->_kcli(undef);
   }

   if ($self->_kc) {
      $self->_kc->close;
      $self->_kc(undef);
   }

   return 1;
}

sub create_topic {
   my $self = shift;
   my ($topic, $rf, $partitions) = @_;

   $rf ||= 1;
   $partitions ||= 1;
   $self->brik_help_run_undef_arg('create_topic', $topic) or return;

   my $basedir = $ENV{HOME}."/metabrik/server-kafka/kafka";
   my $host = $self->host_zookeeper;

   my $cmd = "$basedir/bin/kafka-topics.sh --create --zookeeper $host:2181 ".
      "--replication-factor $rf --partitions $partitions --topic $topic";

   $self->log->verbose("create_topic: cmd[$cmd]");

   return $self->execute($cmd);
}

sub alter_topic {
   my $self = shift;
   my ($topic, $partitions) = @_;

   $partitions ||= 1;
   $self->brik_help_run_undef_arg('alter_topic', $topic) or return;

   my $basedir = $ENV{HOME}."/metabrik/server-kafka/kafka";
   my $host = $self->host_zookeeper;

   my $cmd = "$basedir/bin/kafka-topics.sh --alter --zookeeper $host:2181 ".
      "--partitions $partitions --topic $topic";

   $self->log->verbose("alter_topic: cmd[$cmd]");

   return $self->execute($cmd);
}

sub delete_topic {
   my $self = shift;
   my ($topic) = @_;

   $self->brik_help_run_undef_arg('delete_topic', $topic) or return;

   my $basedir = $ENV{HOME}."/metabrik/server-kafka/kafka";
   my $host = $self->host_zookeeper;

   my $cmd = "$basedir/bin/kafka-topics.sh --delete --if-exists --zookeeper $host:2181 ".
      "--topic $topic";

   $self->log->verbose("delete_topic: cmd[$cmd]");

   return $self->execute($cmd);
}

sub list_topics {
   my $self = shift;

   my $basedir = $ENV{HOME}."/metabrik/server-kafka/kafka";
   my $host = $self->host_zookeeper;

   my $cmd = "$basedir/bin/kafka-topics.sh --list --zookeeper $host:2181";

   $self->log->verbose("list_topics: cmd[$cmd]");

   return $self->execute($cmd);
}

sub describe_topic {
   my $self = shift;
   my ($topic) = @_;

   $self->brik_help_run_undef_arg('describe_topic', $topic) or return;

   my $basedir = $ENV{HOME}."/metabrik/server-kafka/kafka";
   my $host = $self->host_zookeeper;

   my $cmd = "$basedir/bin/kafka-topics.sh --describe --zookeeper $host:2181 --topic $topic";

   $self->log->verbose("describe_topic: cmd[$cmd]");

   return $self->execute($cmd);
}

# https://stackoverflow.com/questions/16284399/purge-kafka-queue
# kafka-topics.sh --zookeeper localhost:13003 --alter --topic MyTopic --config retention.ms=1000
# Wait, then restore previous retention.ms
#sub purge_topic {
#}

sub run_console_producer {
   my $self = shift;
   my ($topic) = @_;

   $self->brik_help_run_undef_arg('run_console_producer', $topic) or return;

   my $basedir = $ENV{HOME}."/metabrik/server-kafka/kafka";
   my $host = $self->host;

   my $cmd = "$basedir/bin/kafka-console-producer.sh --broker-list $host:9092 --topic $topic";

   $self->log->verbose("run_console_producer: cmd[$cmd]");

   return $self->execute($cmd);
}

sub run_console_consumer {
   my $self = shift;
   my ($topic) = @_;

   $self->brik_help_run_undef_arg('run_console_consumer', $topic) or return;

   my $basedir = $ENV{HOME}."/metabrik/server-kafka/kafka";
   my $host = $self->host;

   my $cmd = "$basedir/bin/kafka-console-consumer.sh --bootstrap-server $host:9092 ".
      "--topic $topic --from-beginning";

   $self->log->verbose("run_console_consumer: cmd[$cmd]");

   return $self->execute($cmd);
}

1;

__END__

=head1 NAME

Metabrik::Client::Kafka - client::kafka Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
