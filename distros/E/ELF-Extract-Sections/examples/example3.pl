#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($ERROR);

use ELF::Extract::Sections;

my $e = ELF::Extract::Sections->new( file => '/lib/libz.so' );
my @sections = @{ $e->sorted_sections( field => 'size', descending => 0 ) };

#print "$sections[-1]";

#$sections[-1]->write_to( file => '/tmp/out.blob' );
#
print $sections[-1]->contents;
