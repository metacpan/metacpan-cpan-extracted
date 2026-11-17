package IO::Factotum::Highlight::sky;

use v5.16;
use warnings;

# The short name of IO::Factotum::Highlight::skylighting
use IO::Factotum::Highlight::skylighting ();

sub setup  { IO::Factotum::Highlight::skylighting::setup() }
sub import { IO::Factotum::Highlight::skylighting->import }

1;

__END__

=encoding utf-8

=head1 NAME

IO::Factotum::Highlight::sky - short name of IO::Factotum::Highlight::skylighting

=head1 SYNOPSIS

    perl -MIO::Factotum::Highlight::sky -ne 'print' file.c

    ansicolumn --highlight=sky file.c file.h

=head1 DESCRIPTION

This module is L<IO::Factotum::Highlight::skylighting> by a short
name: syntax highlight by the C<skylighting> command.

=head1 SEE ALSO

L<IO::Factotum::Highlight::skylighting>, L<IO::Factotum>

=cut
