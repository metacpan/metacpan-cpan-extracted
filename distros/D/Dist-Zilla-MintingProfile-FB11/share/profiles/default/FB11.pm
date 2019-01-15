package {{ $name }};

use strict;
use warnings;
use {{ $name }}::Builder;

# ABSTRACT: Brand new FB11 app
our $VERSION = '0';

my $builder = {{ $name }}::Builder->new(
    appname => __PACKAGE__,
    version => $VERSION,
);

$builder->bootstrap;

1;
