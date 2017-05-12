# SOAP::Lite style Hoobot

package Hoobot;

use strict;
use warnings;
use Hoobot::Page;

our $VERSION = '0.5.0'; # semi sane

our @_objs;

END {
  require Data::Dumper;
#  print STDERR Data::Dumper->Dump([\@_objs],['*_objs']);
}

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;
  my $self = bless {}, $class;

  local %_ = @_;
  for (keys %_) {
    $self->$_($_{$_});
  }

  push @_objs, $self;
  
  $self;
}

# method (construct a linked Hoobot::Page)
sub page {
  my $self = shift;
  $self = $self->new unless ref $self;

  return Hoobot::Page->new(
    hoobot => $self,
    page => shift,
  );
}

# accessor
sub hoobot {
  my $self = shift;
  $self = $self->new unless ref $self;
  return $self->{hoobot} unless @_;

  $self->{hoobot} = shift;

  return $self;
}

# recursing accessor
sub ua {
  my $self = shift;
  $self = $self->new unless ref $self;
  unless (@_) {
    # we know the value
    return $self->{ua} if defined $self->{ua};
    # our parent knows the value?
    return $self->hoobot->ua if defined $self->hoobot;
    # otherwise create our own
    require LWP::UserAgent;
    return $self->{ua} = LWP::UserAgent->new;
  }
  
  # TODO: check interface
  $self->{ua} = shift;

  return $self;
}

# recursing accessor
sub host {
  my $self = shift;
  $self = $self->new unless ref $self;
  unless (@_) {
    return $self->{host} if defined $self->{host};
    return $self->hoobot->host if defined $self->hoobot;
    return $self->{host} = $ENV{HOOBOT_HOST} || 'http://www.bbc.co.uk';
  }
  
  $self->{host} = shift;

  return $self;
}

1;

__END__

=head1 NAME

Hoobot - Access h2g2 from the internet (a future WWW::H2G2/DNA)

=head1 SYNOPSIS

  use Hoobot;
  # download the status page and print it
  print Hoobot
    -> page('status')
    -> update
    -> response  # returns an HTTP::Response object
    -> content;

=head1 DESCRIPTION

The Hoobot is a set of modules for accessing the 'h2g2' website, now run
by the BBC on their 'DNA' software.  The Hoobot class is a container for
data for the entire 'session'.

=head1 LICENSE AND COPYRIGHT

Copyright E<copy> Benjamin Smith, 2003.  All right reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The full text of the licenses can be found in the F<Artistic> and
F<COPYING> files included with this module.

=head1 AUTHOR

Benjamin Smith <bsmith@cpan.org>, also on irc as integral in #perl/freenode,
and h2g2 itself, L<http://www.bbc.co.uk/dna/U183117>.

=head1 SEE ALSO

L<http://www.bbc.co.uk/h2g2/>

L<Hoobot::Page>, L<Hoobot::Login>
