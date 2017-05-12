# Jabber::Component::Proxy
# (c) DJ Adams 2001

# $Id: Proxy.pm,v 1.3 2002/04/01 18:02:32 dj Exp $

=head1 NAME

Jabber::Component::Proxy - A simple proxy for Jabber Components

=head1 SYNOPSIS

  use Jabber::Component::Proxy

  # Create proxy
  my $proxy = new Jabber::Component::Proxy(
    server    => 'localhost:6789',
    identauth => 'conference.qmacro.dyndns.org',
    realcomp  => 'conference.internal',
    rulefile  => './access.xml',
  );  

  $proxy->start;

=head1 DESCRIPTION

Jabber::Component::Proxy is a simple proxy mechanism that you can
use to control access to your Jabber services. If you attach a
component to your Jabber server, and give that component a 'real'
resolvable FQDN, people on other Jabber servers can access that 
component. 

This might be what you want. But what if you want to allow access
to some people but not others? How can you control access on a
domain name basis, for example? Currently component access is 
all or nothing:

- give a component a resolvable name and the world can use it
- give a component an internal name and no one but those connected
  the same Jabber server as the component can use it

(This is assuming of course you're running an s2s service).

You can effect a sort of access control, for non-local users, using
this module. 

=head1 VERSION

0.01 (early)

=head1 AUTHOR

DJ Adams

=head1 SEE ALSO

Jabber::Connection

=cut

package Jabber::Component::Proxy;

use vars qw($VERSION);
$VERSION = '0.02';

use Jabber::Connection;
use Jabber::NodeFactory;
use XML::XPath;
use XML::XPath::XMLParser;

use warnings;
use strict;


sub new {

  my $class = shift; my %args = @_;
  my $self = {};

  # My (the client's) host/port and Identity
  $self->{server} = $args{server};
  $self->{realcomp} = $args{realcomp};
  $self->{rulefile} = $args{rulefile};
  ($self->{id}, $self->{pass}) = split(':', $args{identauth});

  die "Bad rulefile $args{rulefile}"
    unless -f $args{rulefile} and -r $args{rulefile};

  # Connect to Jabber
  $self->{connection} = new Jabber::Connection(
    server    => $self->{server},
    localname => $self->{id},
    ns        => 'jabber:component:accept',
#   log       => 1,
#   debug     => 1,
  );

  $self->{connection}->connect
      or  die "oops: ".$self->{connection}->lastError;
  _debug("Connected");

  $self->{connection}->auth($self->{pass});
  _debug("Authenticated");

  # Node factory
  $self->{nf} = new Jabber::NodeFactory;

  # Set up handlers
  $self->{connection}->register_handler('iq', sub { $self->_proxy(@_) } );
  $self->{connection}->register_handler('message', sub { $self->_proxy(@_) } );
  $self->{connection}->register_handler('presence', sub { $self->_proxy(@_) } );

  # Set up HUP handler
  $SIG{HUP} = sub { $self->_readrules };

  # Set up end handler
  $SIG{KILL} = $SIG{TERM} = $SIG{INT} = sub { $self->_cleanup };

  _debug("Handlers set up");

  bless $self, $class;

  # Read in rules
  $self->_readrules;

  return $self;
 
}


# Start the proxy
sub start {

  my $self = shift;

  _debug("Starting proxy");

  # Go!
  $self->{connection}->start;

}


sub _debug {

  print STDERR "DEBUG: @_\n";

}


sub _proxy {

  my $self = shift;
  my $node = shift;

  my $from = _breakJID($node->attr('from'));
  my $to = _breakJID($node->attr('to'));

  # Going back OUT
  if ($from->{host} eq $self->{realcomp}) {
    $node->attr('from', _makeJID($from->{user}, $self->{id}, $from->{resource}));
    $node->attr('to',pack("H*",$to->{user}));
  }

  # Coming IN
  else {

    # Only proceed if allowed
    my $userhost = _makeJID($from->{user}, $from->{host}, undef);
    if ($self->_access($userhost)) {
      $node->attr('to', _makeJID($to->{user}, $self->{realcomp}, $to->{resource}));
      $node->attr('from', _makeJID(unpack("H*",$node->attr('from')), $self->{id}, $from->{resource}));
    }

    # Deny if not allowed
    else {
      _debug("denying $userhost");
      $node->attr('type', 'error');
      my $error = $node->insertTag('error');
      $error->attr('code', 403);
      $error->data('Forbidden');
      $node = _toFrom($node);
    }

  }

  $self->{connection}->send($node);


}


sub _access {

  my $self = shift;
  my $from = shift;

  my $allowed = 0;

  if (exists $self->{rules}->{allow}) {
    foreach my $rule (@{$self->{rules}->{allow}}) {
      $allowed = 1, last if $from =~ /$rule$/;
    }
  }
  else { $allowed = 1 }

  if ($allowed and exists $self->{rules}->{deny}) {
    foreach my $rule (@{$self->{rules}->{deny}}) {
      $allowed = 0, last if $from =~ /$rule$/;
    }
  }

  return $allowed;

}


sub _toFrom {
  my $node = shift;
  my $to = $node->attr('to');
  $node->attr('to', $node->attr('from'));
  $node->attr('from', $to);
  return $node; 
}


sub _breakJID {

  my $jid = shift;
  my ($u, $h, $r) = $jid =~ m/^([^@]+(?=\@))?\@?([\w+\.\-]+)\/?([\w \-]+)?$/;
  return {
    user => $u,
    host => $h,
    resource => $r,
  };

}


sub _makeJID {

  my ($u, $h, $r) = @_;
  my $jid;
  $jid = $u.'@' if defined($u);
  $jid.=$h;
  $jid.= '/'.$r if defined($r);
  return $jid;

}


sub _readrules {

  my $self = shift;

  _debug("Reading access rules");
  delete $self->{rules};
  my $xp = XML::XPath->new(filename => $self->{rulefile});
  foreach (qw/allow deny/) {
    foreach my $node ($xp->find("/access/$_/address")->get_nodelist) {
      _debug("Adding $_ rule for ".$node->string_value);
      push(@{$self->{rules}->{$_}}, $node->string_value);
    }
  }

}


sub _cleanup {

  my $self = shift;

  _debug("Shutting down");
  $self->{connection}->disconnect;

  exit;

}


1;

