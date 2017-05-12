package Devel::Profit;
use strict;
use warnings;
our $VERSION = '0.34';

use DynaLoader ();
our @ISA = qw(DynaLoader);

bootstrap Devel::Profit $VERSION;

1;

=head1 NAME

Devel::Profit - A Perl profiler

=head1 AUTHOR

Leon Brocard, C<< <acme@astray.com> >>

=head1 COPYRIGHT

Copyright (C) 2008, Leon Brocard

=head1 LICENSE

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
