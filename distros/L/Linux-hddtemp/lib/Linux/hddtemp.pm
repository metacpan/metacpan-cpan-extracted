## Linux::hddtemp - monitors hard drive temperatures using the
##  linux hddtemp utility

package Linux::hddtemp;

use strict;
use warnings;
use IO::Socket;
use vars qw($VERSION);
$VERSION = "0.01";

sub new {
  my $self = shift;
  my $class = ref($self) || $self;
  my %args;
  $#_ % 2 ? %args = @_ : warn "Odd argument list at " . __PACKAGE__ . "::new";
  my %options = (
    port => 7634,
    host => 'localhost',
    separator => '|',
  );
  return bless { %options, %args}, $class;
}

sub get {
  my $self = shift;
  my %info;
  
  my $data = $self->_raw;
 ## Escape bad chars for regex
  (my $s = $self->{separator}) =~ s/([\|\[\]\-\^\$])/\\$1/g; 
  foreach my $drive (split(/$s$s/, $$data)) {
    $drive =~ s/^$s//;
    $drive =~ s/$s$//;
    my @drive = split(/$s/, $drive);
    $info{$drive[0]} = {
      name => $drive[1],
      temp => $drive[2],
      unit => $drive[3],
    }
  }
  
  return \%info;
}

sub _raw {
  my $self = shift;
  my $data;
  
  my $sock = IO::Socket::INET->new(
    Proto => 'tcp',
    PeerAddr => $self->{host},
    PeerPort => $self->{port},
  ) || _croak("Could not connect to $self->{host}:$self->{port}: $@");
  
  while(<$sock>) {
    $data .= $_;
  }
  $sock->shutdown(2);
  
  return \$data;
}

sub _croak {
  my $msg = shift;
  require Carp;
  Carp::croak($msg);
}


1;

__END__

=head1 NAME

Linux::hddtemp - monitors hard drive temperatures using the linux hddtemp utility

=head1 SYNOPSIS

  use Linux::hddtemp;
  
  my $hdt = Linux::hddtemp->new();
  my $temps = $hdt->get();
  print $temps->{/dev/hda}{temp};
  
  ## or:
  print Linux::hddtemp->new()->get()->{/dev/hda}{temp};

=head1 DESCRIPTION

C<Linux::hddtemp> will fetch hard drive temperatures from the linux
hddtemp utility, see L<SEE ALSO|/"SEE ALSO"> below.

You will need hddtemp to run in daemon mode for this module to work.
This can simply be done with the -d option of hddtemp, see the hddtemp
manual for more information.

=head2 METHODS

The following methods can be used.

=head3 new 

  my $hdt = Linux::hddtemp->new(
    host => 'localhost',
    port => 7634,
    separator => '|',
  );

C<new> creates a new Linux::hddtemp object using the configuration
passed to it.

=head4 options

The following options can be passed to C<new>

=over 4

=item host

Specifies the host/ip-address where hddtemp is run, defaults to
localhost.

=item port

Specifies the port to which hddtemp is listening, as set with the -p
option of hddtemp, defaults to 7634.

=item separator

Specifies the separator set with the -s option of hddtemp, defaults
to |.

=back

=head3 get

  my $hashref = $hdt->get();
  print $hashref->{/dev/hda}{name} . ": " . $hashref->{/dev/hda}{temp};

C<get> returns a hashref containing temperatures and other information
returned from the hddtemp daemon in the following format:

  {
    /dev/hda => { # device (as specified with the hddtemp options)
      name => 'MAXTOR 6L200P0',  # name of the device
      temp => 32,  # the temperature of the device
      unit => 'C'  # temperature unit (normally degrees celcius)
    }
  }

Note that C<temp> is in most cases a normal integer, but can also be
'UKN' if the temperature of the disk is unknown or 'SLP' if the
drive is sleeping. In those cases, C<unit> will be '*'.

=head1 SEE ALSO

L<http://dev.yorhel.nl/Linux-hddtemp/>,
hddtemp(8),
L<http://www.guzu.net/linux/hddtemp.php>

=head1 BUGS

If you find a bug, please report it at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Linux-hddtemp> or send
an e-mail to the author.

=head1 AUTHOR

Y. Heling, E<lt>yorhel@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Y. Heling

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut