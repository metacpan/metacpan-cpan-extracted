package IO::Factotum::Highlight::gnu;

use v5.16;
use warnings;

# The short name of IO::Factotum::Highlight::sourcehighlight
use IO::Factotum::Highlight::sourcehighlight ();

sub setup  { IO::Factotum::Highlight::sourcehighlight::setup() }
sub import { IO::Factotum::Highlight::sourcehighlight->import }

1;

__END__

=encoding utf-8

=head1 NAME

IO::Factotum::Highlight::gnu - short name of IO::Factotum::Highlight::sourcehighlight

=head1 SYNOPSIS

    perl -MIO::Factotum::Highlight::gnu -ne 'print' file.c

    ansicolumn --highlight=gnu file.c file.h

=head1 DESCRIPTION

This module is L<IO::Factotum::Highlight::sourcehighlight> by a short
name: syntax highlight by the C<source-highlight> command of GNU
Source-highlight.

=head1 SEE ALSO

L<IO::Factotum::Highlight::sourcehighlight>, L<IO::Factotum>

=cut
