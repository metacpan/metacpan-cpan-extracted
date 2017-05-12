package MemcacheDBI;
use strict;
use warnings;
use DBI;
use Clone;
use vars qw( $AUTOLOAD $VERSION );
$VERSION = '0.08';
require 5.10.0;

our $DEBUG;
our $me = '[MemcacheDBI]';

=head1 NAME

MemcacheDBI - Queue memcache calls when in a dbh transaction

=head1 SYNOPSYS

MemcacheDBI is a drop in replacement for DBI.  It allows you to do trivial caching of some objects in a somewhat transactionally safe manner.

  use MemcacheDBI;
  my $dbh = MemcacheDBI->connect($data_source, $user, $password, {} ); # just like DBI
  $dbh->memd_init(\%memcache_connection_args) # see Cache::Memcached::Fast

  # Cache::Memcached::Fast should work using these calls
  $dbh->memd->get();
  $dbh->memd->set();
  $memd = $dbh->memd; #get a handle you can use wherever

  # DBI methods should all work as normal.  Additional new methods listed below
  $dbh->prepare();
  $dbh->execute();
  etc

=head1 DESCRIPTION

Attach your memcached to your DBH handle.  By doing so we can automatically queue set/get calls so that they happen at the same time as a commit.  If a rollback is issued then the queue will be cleared.

=head1 CAVEATS

As long as DBI and Memcache are both up and running your fine.  However this module will experience race conditions when one or the other goes down.  We are currently working to see if some of this can be minimized, but be aware it is impossible to protect you if the DB/Memcache servers go down. 

=head1 METHODS

=head2 memd_init

Normally you would use a MemcacheDBI->connect to create a new handle.  However if you already have a DBH handle you can use this method to create a MemcacheDBI object using your existing handle.

Accepts a the following data types

 Cache::Memcached::Fast (new Cache::Memcached::Fast)
 A DBI handle (DBI->connect)
 HASH of arguments to pass to new Cache::Memcached::Fast

=cut

sub memd_init {
    warn "[debug $DEBUG]$me->memd_init\n" if $DEBUG && $DEBUG > 3;
    my $class = shift;
    my $node = ref $class ? $class : do{ tie my %node, 'MemcacheDBI::Tie'; warn 'whee'; \%node; };
    while (my $handle = shift) {
        if (ref $handle eq 'DBI::db') {
            $node->{'MemcacheDBI'}->{'dbh'} = $handle;
        } elsif (ref $handle eq 'Cache::Memcached::Fast') {
            $node->{'MemcacheDBI'}->{'memd'} = MemcacheDBI::Memd->memd_init($node,$handle);
        } elsif (ref $handle eq 'HASH') {
            $node->{'MemcacheDBI'}->{'memd'} = MemcacheDBI::Memd->memd_init($node,$handle);
        } else {
            die 'Unknown ref type'.do{my @c = caller; ' at '.$c[1].' line '.$c[2]."\n" };
        }
    }
    if (! ref $class) {
        return unless $node->{'MemcacheDBI'}->{'dbh'};
        return bless $node, $class;
    }
    return $class;
}

=head2 memd

Get a memcache object that supports get/set/transactions

=cut

sub memd {
    shift->{'MemcacheDBI'}->{'memd'};
}

=head1 DBI methods can also be used, including but not limited to:

=head2 connect

The same as DBI->connect, returns a MemcacheDBI object so you can get your additional memcache functionality

=cut

sub connect {
    warn "[debug $DEBUG]$me->connect\n" if $DEBUG && $DEBUG > 3;
    my $class = shift;
    tie my %node, 'MemcacheDBI::Tie';
    eval{ $node{'MemcacheDBI'}->{'dbh'} = DBI->connect(@_) } or die $@.do{my @c = caller; ' at '.$c[1].' line '.$c[2]."\n" };
    return unless $node{'MemcacheDBI'}->{'dbh'};
    return bless \%node, $class;
}

=head2 commit

The same as DBI->commit, however it will also commit the memcached queue

=cut

sub commit {
    warn "[debug $DEBUG]$me->commit\n" if $DEBUG && $DEBUG > 3;
    my $self = shift;
    # TODO handle rolling back the memcache stuff if dbh fails
    warn 'Commit ineffective while AutoCommit is on'.do{my @c = caller; ' at '.$c[1].' line '.$c[2]."\n" } if $self->{'AutoCommit'};
    my $memd = $self->memd;
    $memd->commit if $memd;
    $self->{'MemcacheDBI'}->{'dbh'}->commit(@_);
}

=head2 rollback

The same as DBI->rollback, however it will also rollback the memcached queue

=cut

sub rollback {
    warn "[debug $DEBUG]$me->rollback\n" if $DEBUG && $DEBUG > 3;
    my $self = shift;
    warn 'rollback ineffective with AutoCommit enabled'.do{my @c = caller; ' at '.$c[1].' line '.$c[2]."\n" } if $self->{'AutoCommit'};
    my $memd = $self->memd;
    $memd->rollback if $memd;
    $self->{'MemcacheDBI'}->{'dbh'}->rollback(@_);
}

sub AUTOLOAD {
    my $self = shift;
    my($field)=$AUTOLOAD;
    $field =~ s/.*://;
    my $method = (ref $self).'::'.$field;
    warn "[debug $DEBUG]$me create autoload for $method\n" if $DEBUG && $DEBUG > 1;
    no strict 'refs'; ## no critic
    *$method = sub {
        my $self = shift;
        warn "[debug $DEBUG]${me}->{'dbh'}->$field\n" if $DEBUG && $DEBUG > 3;
        die 'Can\'t locate object method "'.$field.'" via package "'.(ref $self->{'MemcacheDBI'}->{'dbh'}).'"'.do{my @c = caller; ' at '.$c[1].' line '.$c[2]."\n" } unless $self->{'MemcacheDBI'}->{'dbh'}->can($field);
        $self->{'MemcacheDBI'}->{'dbh'}->$field(@_);
    };
    die 'Can\'t locate object method "'.$field.'" via package "'.(ref $self->{'MemcacheDBI'}->{'dbh'}).'"'.do{my @c = caller; ' at '.$c[1].' line '.$c[2]."\n" } unless $self->{'MemcacheDBI'}->{'dbh'}->can($field);
    $self->$field(@_);
}

package MemcacheDBI::Memd;

sub memd_init {
    my $class = shift;
    my $dbh = shift;
    my $handle = shift;
    tie my %node, 'MemcacheDBI::Tie', 'memd';
    require Cache::Memcached::Fast;
    $handle = Cache::Memcached::Fast->new($handle) if ref $handle eq 'HASH';
    $node{'MemcacheDBI'}{'memd'} = $handle;
    $node{'MemcacheDBI'}{'dbh'} = $dbh; # careful, circular
    return bless \%node, $class;
}

sub get {
    my ($self,$key) = @_;
    return if $self->{'MemcacheDBI'}->{'dbh'}->{'MemcacheDBI'}->{'queue_delete'}->{$key};
    if (exists $self->{'MemcacheDBI'}->{'dbh'}->{'MemcacheDBI'}->{'queue'}->{$key}) {
        return $self->{'MemcacheDBI'}->{'dbh'}->{'MemcacheDBI'}->{'queue'}->{$key};
    }
    $self->{'MemcacheDBI'}->{'memd'}->get($key);
}

sub set {
    my ($self,$key,$value) = @_;
    delete $self->{'MemcacheDBI'}->{'dbh'}->{'MemcacheDBI'}->{'queue_delete'}->{$key};
    if ($self->{'MemcacheDBI'}->{'dbh'}->{'AutoCommit'}) {
        delete $self->{'MemcacheDBI'}->{'dbh'}->{'MemcacheDBI'}->{'queue'}->{$key};
        return $self->{'MemcacheDBI'}->{'memd'}->set($key, $value);
    }
    $self->{'MemcacheDBI'}->{'dbh'}->{'MemcacheDBI'}->{'queue'}->{$key} = Clone::clone($value);
    1;
}

sub delete {
    my ($self,$key) = @_;
    if ($self->{'MemcacheDBI'}->{'dbh'}->{'AutoCommit'}) {
        delete $self->{'MemcacheDBI'}->{'dbh'}->{'MemcacheDBI'}->{'queue_delete'}->{$key};
        delete $self->{'MemcacheDBI'}->{'dbh'}->{'MemcacheDBI'}->{'queue'}->{$key};
        return $self->{'MemcacheDBI'}->{'memd'}->delete($key);
    }
    my $val = $self->get($key);
    delete $self->{'MemcacheDBI'}->{'dbh'}->{'MemcacheDBI'}->{'queue'}->{$key};
    $self->{'MemcacheDBI'}->{'dbh'}->{'MemcacheDBI'}->{'queue_delete'}->{$key} = 1;
    $val ? 1 : '';
}
sub remove { shift->delete(@_); }

sub namespace {
    my $self = shift;
    if (scalar @_ && !$self->{'MemcacheDBI'}->{'dbh'}->{'AutoCommit'} && (
            $self->{'MemcacheDBI'}->{'dbh'}->{'MemcacheDBI'}->{'queue_delete'}
            || $self->{'MemcacheDBI'}->{'dbh'}->{'MemcacheDBI'}->{'queue'}
        )) {
        die 'Cannot set namespace during a transaction'.do{my @c = caller; ' at '.$c[1].' line '.$c[2]."\n" };
    }
    $self->{'MemcacheDBI'}->{'memd'}->namespace(@_);
}

sub server_versions { shift->{'MemcacheDBI'}->{'memd'}->server_versions(@_); }

# do not confuse this with DBH commits
sub commit {
    my ($self) = @_;
    my $queue = $self->{'MemcacheDBI'}->{'dbh'}->{'MemcacheDBI'}->{'queue'};
    foreach my $key (keys %$queue) {
        $self->{'MemcacheDBI'}->{'memd'}->set($key, $queue->{$key});
    }
    delete $self->{'MemcacheDBI'}->{'dbh'}->{'MemcacheDBI'}->{'queue'};

    $queue = $self->{'MemcacheDBI'}->{'dbh'}->{'MemcacheDBI'}->{'queue_delete'};
    foreach my $key (keys %$queue) {
        $self->{'MemcacheDBI'}->{'memd'}->delete($key);
    }
    delete $self->{'MemcacheDBI'}->{'dbh'}->{'MemcacheDBI'}->{'queue_delete'};

    return 1;
}

sub rollback {
    my ($self) = @_;
    delete $self->{'MemcacheDBI'}->{'dbh'}->{'MemcacheDBI'}->{'queue'};
    delete $self->{'MemcacheDBI'}->{'dbh'}->{'MemcacheDBI'}->{'queue_delete'};

    return 1;
}

package MemcacheDBI::Tie;

# passes all calls to the parent $tie_type unless the key is MemcacheDBI
# allows me to wrap my data in a container while somewhat preseving the parents operation

sub TIEHASH {
    my $class = shift;
    my $tie_type = shift || 'dbh'; # dbh or memd
    return bless {MemcacheDBI=>{tie_type=>$tie_type}}, $class;
}

sub FETCH {
    my ($self,$key) = @_;
    my $short = $self->{'MemcacheDBI'};
    return $short if $key eq 'MemcacheDBI';
    $short->{$short->{'tie_type'}}->{$key};
}

sub STORE {
    my ($self,$key,$value) = @_;
    my $short = $self->{'MemcacheDBI'};
    $short->{$short->{'tie_type'}}->{$key} = $value;
}

sub DELETE {
    my ($self,$key) = @_;
    die 'Cannot delete MemcacheDBI'.do{my @c = caller; ' at '.$c[1].' line '.$c[2]."\n" } if $key eq 'MemcacheDBI';
    my $short = $self->{'MemcacheDBI'};
    delete $short->{$short->{'tie_type'}}->{$key};
}

sub CLEAR {
    my ($self) = @_;
}

sub FIRSTKEY {
    my ($self) = @_;
    my $tmp = $self->{'MemcacheDBI'}->{$self->{'MemcacheDBI'}->{'tie_type'}};
    return unless ref $tmp eq 'HASH';
    keys %$tmp;
    return scalar each %$tmp;
}

sub NEXTKEY {
    my ($self) = @_;
    my $tmp = $self->{'MemcacheDBI'}->{$self->{'MemcacheDBI'}->{'tie_type'}};
    return scalar each %$tmp;
}

sub EXISTS {
    my ($self,$key) = @_;
    return exists $self->{'MemcacheDBI'}->{$self->{'MemcacheDBI'}->{'tie_type'}}->{$key};
}

1;

=head1 REPOSITORY

The code is available on github:

  https://github.com/oaxlin/MemcacheDBI.git

=head1 DISCLAIMER

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

