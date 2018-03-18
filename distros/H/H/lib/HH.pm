package HH;
use strict;
use warnings;

our $VERSION = '0.001';

require Carp;

our $AUTOLOAD;

sub AUTOLOAD {
    my ($in, @args) = @_;
    my $meth = $AUTOLOAD;
    $meth =~ s/^.*:://g;

    my %h;
    my ($pkg, $file, $line) = caller(0);
    eval qq[
package $pkg;
#line $line "$file (Via $AUTOLOAD\())"
%h = \$in->\$meth(\@args ? \@args : ());
1;
    ] or die $@;

    return ($meth => \%h);
}

1;
