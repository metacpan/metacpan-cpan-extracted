package Megagram::ResolveSRV;

our $VERSION = '0.01';

=head1 NAME

Megagram::ResolveSRV

=head1 SYNOPSIS

  Tells you the hosts and order to use for services using SRV records (like XMPP, etc).

=head1 ABSTRACT

  use Megagram::ResolveSRV;

  my $rsrv = Megagram::ResolveSRV->new;
  my @hosts = $rsrv->resolve('_xmpp-server._tcp.google.com');

  use Data::Dumper;
  print Dumper(\@hosts);

=head1 BUGS

  Not really a bug, but the weighting logic is a little crummy.
  Feel free to send a patch for it.  It works well enough for me for the moment.

=head1 AUTHOR

  Dusty Wilson
  Megagram Managed Technical Services
  http://www.megagram.com/

=head1 LICENSE

  This module is free software, you can redistribute it and/or modify
  it under the same terms as Perl itself.

=cut

use Net::DNS;

sub new
{
  my $class = shift;
  my %opts = @_;
  my $self = {};
  $self->{dnsobj} = $opts{dnsobj} || Net::DNS::Resolver->new;
  return bless($self, $class);
}

sub resolve
{
  my $self = shift;
  my $domain = shift;
  my $dnsobj = shift || $self->{dnsobj};

  my $query = $dnsobj->search($domain, 'SRV');
  return undef unless $query;

  my $srv = {};
  foreach my $rr ($query->answer)
  {
    next unless $rr->type eq "SRV";
    if ($rr->target eq '.')
    {
      $srv = {};
      last;
    }
    $srv->{count}->{substr('000'.$rr->priority, -3, 3)} ++;
    $srv->{weight}->{substr('000'.$rr->priority, -3, 3)} += $rr->weight;
    push(@{$srv->{priority}->{substr('000'.$rr->priority, -3, 3)}}, {priority => $rr->priority, weight => $rr->weight, port => $rr->port, target => $rr->target});
  }

  foreach my $priority (sort(keys(%{$srv->{priority}})))
  {
    my $weight_total = $srv->{weight}->{$priority};
    my $priority_count = $srv->{count}->{$priority};
    foreach my $record (@{$srv->{priority}->{$priority}})
    {
      if ($weight_total)
      {
        $record->{weight} = 100 / $weight_total * $record->{weight};
      }
      else
      { # don't want div-by-0 error
        $record->{weight} = 100 / $priority_count;
      }
    }
    foreach my $record (@{$srv->{priority}->{$priority}})
    {
      my $order = substr('00000'.int(rand() * $record->{weight} * 100), -5, 5); # flawed logic, but it works for now.
      $srv->{order}->{$priority}->{$order} = $record;
    }
  }

  my @hosts;
  foreach my $priority (sort(keys(%{$srv->{order}})))
  {
    foreach my $order (sort(keys(%{$srv->{order}->{$priority}})))
    {
      push(@hosts, $srv->{order}->{$priority}->{$order});
    }
  }

  return @hosts;
}

1;
