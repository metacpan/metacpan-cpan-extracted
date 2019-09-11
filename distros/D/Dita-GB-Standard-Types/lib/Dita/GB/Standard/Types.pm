#!/usr/bin/perl
#-------------------------------------------------------------------------------
# The Types of Corpus Available in the Gearhart-Brenan File Naming Standard
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc., 2019
#-------------------------------------------------------------------------------
# podDocumentation
package Dita::GB::Standard::Types;
our $VERSION = 20190911;
require v5.24;
use warnings FATAL => qw(all);
use strict;

# podDocumentation

=pod

=encoding utf-8

=head1 Name

Dita::GB::Standard::Types - The Types of Corpus Available in the
Gearhart-Brenan File Naming Standard.

=head1 Synopsis

The B<GB Standard> is one way of naming files to enable global collaboration
through uncoordinated content sharing.

The B<GB Standard> creates a human readable, deterministic file name which
depends solely on the content to be stored in that file. Such file names are
guaranteed to differ between files that contain differing content while being
frequently identical for files that contain identical content.

The B<GB Standard> name for a file depends on the type of corpus it occurs in.
The following sections describe the types of corpus currently available and the
algorithm for computing the B<GBStandard> name for each such corpus.

=head2 Dita

The B<Dita> corpus contains topic and map files that conform to the
L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html>
standard. The B<GBStandard> names for these files can be computed via L<GB
Standard for Dita|http://metacpan.org/pod/Dita::GB::Standard>.

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.ryffine.com|http://www.ryffine.com>

=head1 Copyright

Copyright (c) 2019 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut

# Tests and documentation

sub test
 {my $p = __PACKAGE__;
  binmode($_, ":utf8") for *STDOUT, *STDERR;
  return if eval "eof(${p}::DATA)";
  my $s = eval "join('', <${p}::DATA>)";
  $@ and die $@;
  eval $s;
  $@ and die $@;
  1
 }

test unless caller;

1;
# podDocumentation
__DATA__
use Test::More tests => 1;

ok 1;
