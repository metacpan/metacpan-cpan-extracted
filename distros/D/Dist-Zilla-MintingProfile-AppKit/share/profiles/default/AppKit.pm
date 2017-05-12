package {{ $name }};

use strict;
use warnings;
use {{ $name }}::Builder;

our $VERSION = "0.001";

my $builder = {{ $name }}::Builder->new(
    appname => __PACKAGE__,
    version => $VERSION,
);

$builder->bootstrap;

1;

=head1 NAME

{{ $name }} - Brand new AppKit site

=head1 DESCRIPTION

=head1 METHODS

=head1 ATTRIBUTES


=head1 LICENSE AND COPYRIGHT

Copyright 2015 OpusVL.

This software is licensed according to the "IP Assignment Schedule" provided with the development project.

=cut
