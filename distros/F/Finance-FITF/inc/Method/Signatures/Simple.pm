#line 1
package Method::Signatures::Simple;
BEGIN {
  $Method::Signatures::Simple::VERSION = '0.06';
}

use warnings;
use strict;

#line 17

use base q/Devel::Declare::MethodInstaller::Simple/;

sub import {
    my $class = shift;
    my %opts  = @_;
    $opts{into}     ||= caller;
    $opts{invocant} ||= '$self';

    $class->install_methodhandler(
      name => 'method',
      %opts,
    );
}

sub parse_proto {
    my $self = shift;
    my ($proto) = @_;
    $proto ||= '';
    $proto =~ s/[\r\n]//g;
    my $invocant = $self->{invocant};

    $invocant = $1 if $proto =~ s{^(\$\w+):\s*}{};

    my $inject = "my ${invocant} = shift;";
    $inject .= "my ($proto) = \@_;" if defined $proto and length $proto;

    return $inject;
}


#line 228

1; # End of Method::Signatures::Simple