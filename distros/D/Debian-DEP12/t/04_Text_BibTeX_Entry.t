#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval 'use Text::BibTeX';
plan skip_all => 'Text::BibTeX required' if $@;
plan tests => 1;

use File::Temp;
use Debian::DEP12;

my $tmp = File::Temp->new();
my $fh;
open( $fh, '>', $tmp->filename );
print $fh <<'END';
@Article{Merkys2016,
  author    = {Merkys, Andrius and Vaitkus, Antanas and Butkus, Justas and Okulič-Kazarinas, Mykolas and Kairys, Visvaldas and Gražulis, Saulius},
  journal   = {Journal of Applied Crystallography},
  title     = {{\it COD::CIF::Parser}: an error-correcting {CIF} parser for the {P}erl language},
  year      = {2016},
  month     = {Feb},
  number    = {1},
  pages     = {292--301},
  volume    = {49},
  doi       = {10.1107/S1600576715022396},
  url       = {http://dx.doi.org/10.1107/S1600576715022396},
}
END
close $fh;

my $bibfile = Text::BibTeX::File->new( $tmp->filename );
my $entry = Text::BibTeX::Entry->new( $bibfile );
my $meta = Debian::DEP12->new( $entry );
is( $meta->to_YAML, <<'END' );
Reference:
- Author: Merkys, Andrius and Vaitkus, Antanas and Butkus, Justas and Okulič-Kazarinas,
    Mykolas and Kairys, Visvaldas and Gražulis, Saulius
  DOI: 10.1107/S1600576715022396
  Journal: Journal of Applied Crystallography
  Month: Feb
  Number: 1
  Pages: 292--301
  Title: '{\it COD::CIF::Parser}: an error-correcting {CIF} parser for the {P}erl
    language'
  URL: http://dx.doi.org/10.1107/S1600576715022396
  Volume: 49
  Year: 2016
END
