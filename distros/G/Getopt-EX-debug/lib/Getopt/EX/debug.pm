=head1 NAME

Getopt::EX::debug - Getopt::EX debug module

=head1 SYNOPSIS

command -Mdebug

=head1 DESCRIPTION

Enable L<Getopt::EX> debug mode.

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2022 Kazumasa Utashiro

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

package Getopt::EX::debug;

our $VERSION = '1.01';

use strict;
use warnings;

use Getopt::EX::Loader;

$Getopt::EX::Loader::debug = 1;

1;
