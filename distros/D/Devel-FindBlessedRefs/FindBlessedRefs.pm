package Devel::FindBlessedRefs;

use strict;
use warnings;
use Carp;

require Exporter;
use base 'Exporter';

our %EXPORT_TAGS = ( all => [qw( find_refs find_refs_with_coderef find_refs_by_coderef )]);
our @EXPORT_OK   = ( @{$EXPORT_TAGS{all}} );

our $VERSION = 1.253;

require XSLoader;
XSLoader::load('Devel::FindBlessedRefs', $VERSION);

*find_refs_by_coderef = \&find_refs_with_coderef;

1;
