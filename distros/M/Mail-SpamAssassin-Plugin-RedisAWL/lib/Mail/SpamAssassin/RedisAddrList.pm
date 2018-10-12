package Mail::SpamAssassin::RedisAddrList;

use strict;
use warnings;

# ABSTRACT: redis address list for spamassassin auto-whitelist
our $VERSION = '1.002'; # VERSION

use Mail::SpamAssassin::PersistentAddrList;
use Mail::SpamAssassin::Util qw(untaint_var);
use Mail::SpamAssassin::Logger;

use Redis;

our @ISA = qw(Mail::SpamAssassin::PersistentAddrList);

###########################################################################

sub new {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = $class->SUPER::new(@_);
  $self->{class} = $class;
  bless ($self, $class);
  $self;
}

###########################################################################

sub new_checker {
  my ($factory, $main) = @_;
  my $class = $factory->{class};
  my $conf = $main->{conf};
  my $prefix = $conf->{auto_whitelist_redis_prefix} || 'awl_';
  my $redis_server = $conf->{auto_whitelist_redis_server};
  my $password = $conf->{auto_whitelist_redis_password};
  my $database = $conf->{auto_whitelist_redis_database};
  my $expire = $conf->{auto_whitelist_redis_expire} || 0;
  my $debug = $conf->{auto_whitelist_redis_debug};

  untaint_var( \$redis_server );

  my $self = {
    'main' => $main,
    'prefix' => $prefix,
    'expire' => $expire,
  };

  Mail::SpamAssassin::Plugin::info('initializing connection to redis server...');
  eval {
    $self->{'redis'} = Redis->new(
      server => defined $redis_server ?
        $redis_server : '127.0.0.1:6379',
      debug => $debug,
      defined $password ? ( password => $password ) : (),
    );
  };
  if( $@ ) {
    die('could not connect to redis: '.$@);
  }

  if( $database ) {
    Mail::SpamAssassin::Plugin::info("selecting redis database $database...");
    $self->{'redis'}->select($database);
  }

  bless ($self, $class);
  return $self;
}

###########################################################################

sub finish {
  my $self = shift;

  $self->{'redis'}->quit;
}

###########################################################################

sub get_addr_entry {
  my ($self, $addr, $signedby) = @_;

  my $entry = {
    addr => $addr,
  };

  my ( $count, $score ) = $self->{'redis'}->mget(
    $self->{'prefix'}.$addr.'_count',
    $self->{'prefix'}.$addr.'_score',
  );
  $entry->{count} =  defined $count ? $count : 0;
  $entry->{totscore} = defined $score ? $score / 1000 : 0;

  dbg("auto-whitelist: redis-based $addr scores ".$entry->{count}.'/'.$entry->{totscore});
  return $entry;
}

sub _update_addr_expire {
  my ($self, $addr) = @_;
  my $expire = $self->{'expire'};
  return unless $expire;

  $self->{'redis'}->expire($self->{'prefix'}.$addr.'_count', $expire, sub {});
  $self->{'redis'}->expire($self->{'prefix'}.$addr.'_score', $expire, sub {});

  return;
}

sub add_score {
    my($self, $entry, $score) = @_;

    $entry->{count} ||= 0;
    $entry->{addr}  ||= '';

    $entry->{count}++;
    $entry->{totscore} += $score;

    dbg("auto-whitelist: add_score: new count: ".$entry->{count}.", new totscore: ".$entry->{totscore});

    $self->{'redis'}->incr( $self->{'prefix'}.$entry->{'addr'}.'_count' );
    $self->{'redis'}->incrby( $self->{'prefix'}.$entry->{'addr'}.'_score', int($score * 1000) );
    $self->_update_addr_expire($entry->{addr});

    return $entry;
}

sub remove_entry {
  my ($self, $entry) = @_;

  my $addr = $entry->{addr};
  $self->{'redis'}->del(
	  $self->{'prefix'}.$addr.'_count',
	  $self->{'prefix'}.$addr.'_score' );

  if ( my ($mailaddr) = ($addr) =~ /^(.*)\|ip=none$/) {
    # it doesn't have an IP attached.
    # try to delete any per-IP entries for this addr as well.
    # could be slow...

    $mailaddr =~ s/\*//g;
    my @keys = $self->{'redis'}->keys($self->{'prefix'}.$mailaddr.'*');
    $self->{'redis'}->del( @keys );
  }

  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::SpamAssassin::RedisAddrList - redis address list for spamassassin auto-whitelist

=head1 VERSION

version 1.002

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Markus Benning.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
