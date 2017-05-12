use strict;
use warnings;
package Device::SerialPort;

my @calls;
sub TIEHANDLE {
  bless { calls => [], args => \@_ }, __PACKAGE__;
}

sub calls {
  my $self = shift;
  splice @calls;
}

sub AUTOLOAD {
  my $self = shift;
  our $AUTOLOAD;
  push @calls, [$AUTOLOAD, @_];
}

1;
