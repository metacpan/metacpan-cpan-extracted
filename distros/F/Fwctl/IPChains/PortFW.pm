#
#    PortFW.pm - Perl module to interface with ipmasqadm portfw command.
#
#    This file is part of Fwctl.
#
#    Author: Francis J. Lacoste <francis.lacoste@iNsu.COM>
#
#    Copyright (C) 1999,2000 iNsu Innovations Inc.
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
package IPChains::PortFW;

use strict;

use Carp;
use Symbol;

use vars qw( $VERSION $IPMASQADM );

BEGIN {

  ($VERSION) = '$Revision: 1.4 $' =~ /Revision: ([0-9.]+)/;

}

my %VALID_OPTIONS = map { $_ => 1 } qw( LocalAddr LocalPort RemAddr RemPort
					Proto Pref
					);

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my %args = @_;
    my $self = { };

    # Look for ipmasqadm
    my ($path) = grep { -x "$_/ipmasqadm" } split /:/, "/sbin:/bin:/usr/sbin:/usr/bin:$ENV{PATH}";
    die ( "Couldn't find ipmasqadm in PATH ($ENV{PATH})\n" ) unless $path;
    $self->{ipmasqadm} = "$path/ipmasqadm";

    bless $self, $class;

    while ( my ($key,$value) = each %args ) {
	$self->attribute( $key, $value );
    }

    $self;
}

sub attribute {
    my ($self,$key,$value) = @_;

    if ( @_ == 3 ) {
	if ( $VALID_OPTIONS{$key} ) {
	    $self->{$key} = $value;
	} else {
	    carp "Unknown option : $key";
	}
    }

    return $self->{$key};
}

sub clopts {
    my ( $self ) = shift;

    foreach my $key ( keys %VALID_OPTIONS ) {
	delete $self->{$key};
    }
}

sub run_portfw {
    my ( $self, @args ) = @_;

    my ($r_fh,$w_fh) = (gensym,gensym);
    pipe $r_fh, $w_fh
      or die "can't pipe: $!\n";

    my $pid = fork;
    die "can't fork: $!\n" unless defined $pid;

    if ( $pid ) {
	# Don't need this one
	close $w_fh;

	# Collect STDOUT and STDERR
	my $output;
	while ( my $line = <$r_fh> ) {
	    $output .= $line;
	}

	# Collect exit status
	waitpid $pid,0;

	die "ipmasq exit with non zero status:\n$output\n" if $?;

	$output;
    } else {
	# Don't need this one
	close $r_fh;

	# Redirect STDOUT and STDERR to parent
	open ( STDOUT, ">&" . fileno $w_fh )
	  or die "can't redirect STDOUT to proper pipe: $!\n";
	open ( STDERR, ">&" . fileno $w_fh )
	  or die "can't redirect STDERR to proper output fd: $!\n";
	exec( $self->{ipmasqadm}, "portfw", @args )
	  or die "can't exec ipmasqadm: $!";
    }
}

sub append {
    my ( $self ) = shift;

    my @args = ( "-a" );
    croak "missing protocol"	    unless exists $self->{Proto};
    croak "invalid protocol"	    unless $self->{Proto} =~ /udp|tcp|6|17/i;
    croak "missing local address"   unless exists $self->{LocalAddr};
    croak "missing local port"	    unless exists $self->{LocalPort};
    croak "missing remote address"  unless exists $self->{RemAddr};
    croak "missing remote port"	    unless exists $self->{RemPort};
    if ( exists $self->{Pref} ) {
	croak "invalid preference"  unless $self->{Pref} =~ /\d+/ &&
					   $self->{Pref} >= 0;
    }

    push @args, "-P", lc $self->{Proto}, "-L", $self->{LocalAddr},
      $self->{LocalPort}, "-R", $self->{RemAddr}, $self->{RemPort};
    push @args, "-p", $self->{Pref} if exists $self->{Pref};

    $self->run_portfw( @args );
}

sub delete {
    my ( $self ) = shift;

    my @args = ( "-d" );
    croak "missing protocol"	    unless exists $self->{Proto};
    croak "invalid protocol"	    unless $self->{Proto} =~ /udp|tcp|6|17/i;
    croak "missing local address"   unless exists $self->{LocalAddr};
    croak "missing local port"	    unless exists $self->{LocalPort};

    push @args, "-P", lc $self->{Proto}, "-L", $self->{LocalAddr},
      $self->{LocalPort};
    push @args, "-R", $self->{RemAddr}, $self->{RemPort}
      if exists $self->{RemAddr};

    $self->run_portfw( @args );

}

sub flush {
    $_[0]->run_portfw( "-f" );
}

sub list {
    my ($self, $use_dns) = @_;

    my @args = ( "-l" );
    push @args, "-n" unless defined $use_dns && $use_dns;

    my $output = $self->run_portfw( @args );
    return () unless defined $output;

    # Parse output
    my @lines = split /\n/, $output;

    # Skip header line
    shift @lines;

    my @rules = ();
    foreach my $line ( @lines ) {
	my ( $prot, $laddr, $raddr, $lport, $rport, $ignored, $pref ) =
	  split / +/, $line;
	push @rules, $self->new( Proto	    => lc $prot,
				  LocalAddr => $laddr,
				  RemAddr   => $raddr,
				  LocalPort => $lport,
				  RemPort   => $rport,
				);
    }

    @rules;
}

1;

__END__

=pod

=head1 NAME

IPChains::PortFW - Perl module to manipulate portfw masquerading table.

=head1 SYNOPSIS

  my $masq = new IPChains::PortFW( option => value, ... );
  $masq->append();

=head1 DESCRIPTION

IPChains::PortFW is an perl interface to the linux kernel port forwarding
facility. You must have ipmasqadm and the portfw module installed for this
module to work. A kernel compiled with CONFIG_IP_MASQUERADE_IPPORTFW would
also helps.

It has a similar interface than the IPChains(3) module. You create an
IPChains::PortFW object with new(), you can query or set attributes with
the attribute() method and you add or deletes the port forwarding rules using
append() or delete().

=head2 ATTRIBUTES

Here are the attributes valids for IPChains::PortFW.

=over

=item LocalAddr

This is the local address from which packets will be redirected.

=item LocalPort

This is the port from which packets will be redirected.

=item RemAddr

This is the address to which the packets will be forwarded to.

=item RemPort

This is the port to which the packets will be forwarded to.

=item Pref

This is a preferences value used for load balancing in the case when
there are many possible remote destinations.

=back

=head2 METHODS

=over

=item new( [options], ... )

Create a new IPChains::PortFW object and sets its attributes.


=item attribute( attribute [, value] )

Get or sets an attribute. Use undef to delete a value.

=item clopts()

Unset all attributes.

=item append()

Append a rule to the port forwarding masquerade table as specified by
the attributes of the current objects.

=item delete()

Deletes entries in the port forwarding masquerade table. The entries
matching the attributes will be deleted.

=item flush()

Removes all entries from the port forwarding masquerade table.

=item list()

Returns an array of IPChains::PortFW objects. One for each entries
in the port forwarding table.

=back

=head1 EXAMPLE

Redirecting http protocol to internal web server.

my $portfw = new IPChains::PortFW( Proto     => 'udp', 
				   LocalAddr => '199.168.1.10',
				   LocalPort => 80,
				   RemAddr   => '10.0.0.1',
				   RemPort   => 80 );

$portfw->append;

=head1 AUTHOR

Francis J. Lacoste <francis.lacoste@insu.com>

=head1 COPYRIGHT

Copyright (C) iNsu Innovations Inc.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

=head1 SEE ALSO

IPChains(3)

=cut

