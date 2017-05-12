package IRC::Indexer::Report::Network;

use 5.10.1;
use strict;
use warnings;
use Carp;

use Scalar::Util qw/blessed/;

use Storable qw/dclone/;


sub new {
  my $self = {};
  my $class = shift;
  bless $self, $class;
  
  my %args = @_ if @_;
  $args{lc $_} = delete $args{$_} for keys %args;
  
  $self->{ServerMOTDs} = 1 if $args{servermotds};

  if ($args{fromhash}) {
    $self->{Network} = delete $args{fromhash};
  } else { 
    $self->{Network} = {
      Servers => {
       ## ServerName => {
       ##   TrawledAt =>
       ##   IRCD      =>
       ## # optional:
       ##   MOTD => [],
       ## }
      },
    
      OperCount   => undef,
      GlobalUsers => undef,
      ListChans   => [],
      HashChans   => {},
    
      ListLinks  => [],
      LastServer => undef,
    
      ConnectedAt => undef,
      FinishedAt  => undef,
    };
  }
  
  $self->{NOCHANS} = 1 if $args{nochannels};
  return $self
}

## Simple read-only accessors:

sub info { netinfo(@_) }
sub netinfo {
  my $self = shift;
  my %args = @_;
    
  return $self->{Network}
}

sub servers {
  my ($self) = @_;
  return $self->{Network}->{Servers}
}

sub motd_for {
  my ($self, $server) = @_;
  return unless $server;
  return unless exists $self->{Network}->{Servers}->{$server};
  return $self->{Network}->{Servers}->{$server}->{MOTD} // []
}

sub opers {
  my ($self) = @_;
  return $self->{Network}->{OperCount}
}

sub users {
  my ($self) = @_;
  return $self->{Network}->{GlobalUsers}
}

sub hashchans { chanhash(@_) }
sub chanhash {
  my ($self) = @_;
  return $self->{Network}->{HashChans}
}

sub connectedat {
  my ($self) = @_;
  return $self->{Network}->{ConnectedAt}
}

sub finishedat {
  my ($self) = @_;
  return $self->{Network}->{FinishedAt}
}

sub lastserver {
  my ($self) = @_;
  return $self->{Network}->{LastServer}
}

sub add_server {
  my ($self, $info) = @_;
  ## given a Report::Server object (or subclass), merge to this Network
  croak "add_server needs an IRC::Indexer::Report::Server obj"
    unless blessed $info and $info->isa('IRC::Indexer::Report::Server');
  
  ## keyed on reported server name
  ## will "break"-ish on dumb nets announcing dumb names:
  my $network = $self->{Network};
  my $servers = $network->{Servers};

  my $name = $info->server;
  $servers->{$name}->{TrawledAt} = $info->finishedat;
  $servers->{$name}->{IRCD} = $info->ircd;
  $servers->{$name}->{MOTD} = $info->motd
    if $self->{ServerMOTDs};
  
  ## these can all be overriden network-wide:
  $network->{GlobalUsers} = $info->users;
  $network->{OperCount}   = $info->opers;
  $network->{ChanCount}   = $info->totalchans;
  $network->{HashChans}   = $info->chanhash
    unless $self->{NOCHANS};
  $network->{ConnectedAt} = $info->connectedat;
  $network->{FinishedAt}  = $info->finishedat;
  $network->{ListLinks}   = $info->links // [] ;
  $network->{LastServer}  = $name;
}

1;
__END__

=pod

=head1 NAME

IRC::Indexer::Report::Network - Network information class for IRC::Indexer

=head1 SYNOPSIS

  my $network = IRC::Indexer::Report::Network->new;

  ## Or: save server MOTDs to global network hash.  
  ## Tracking a lot of MOTDs will eat memory fast.
  my $network = IRC::Indexer::Report::Network->new(
    ServerMOTDs => 1,
    
    ## Disable channel tracking, perhaps:
    NoChannels => 1,
  );
  
  ## Get ::Report::Server object from finished trawl bot:
  my $info_obj  = $trawler->report;
  ## Feed it to add_server:
  $network->add_server( $info_obj );
  
  ## Get a network info hash:
  my $net_hash = $network->dump;
  
  ## Re-create a Network object from a dumped hash:
  $network = IRC::Indexer::Report::Network->new(
    FromHash => $net_hash,
  );

=head1 DESCRIPTION

This is a simple Network class for L<IRC::Indexer>, providing an easy 
way to merge multiple trawled servers into a single network summary.

=head2 METHODS

=head3 add_server

Merges server information from a Trawl::Bot run.

Argument must be a L<IRC::Indexer::Report::Server> object.

=head3 netinfo

Returns a reference to the network information hash.

=head3 connectedat

Returns the connect timestamp of the last run for this network.

=head3 finishedat

Returns the timestamp of the last run for this network.

=head3 servers

Returns a hash keyed on server name.

=head3 lastserver

Returns the name of the last server added to this network.

=head3 motd_for

Returns the MOTD for a specified server:

  my $motd = $network->motd_for($servername);

Only usable if ServerMOTDs was enabled for this network instance.

=head3 users

Returns the global user count if available via B<LUSERS>

=head3 opers

Returns the global operator count if available via B<LUSERS>

=head3 chanhash

Returns the hash containing parsed B<LIST> results, as described in 
L<IRC::Indexer::Trawl::Bot>


=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

L<http://www.cobaltirc.org>

=cut
