package Devel::CCompat::C99::ScopedVariables;

use strict;
use warnings;
use XSLoader;

use Exporter 5.57 'import';

our $VERSION     = '0.002';
our %EXPORT_TAGS = ( 'all' => [] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );

XSLoader::load('Devel::CCompat::C99::ScopedVariables', $VERSION);

1;
__END__
=pod

=head1 DESCRIPTION

Devel::CCompat::C99::ScopedVariables - tests support for C99 scoped variables

A module to highlight platforms which do and do not support scoped variables.

=head1 VERSION

Version 0.001
