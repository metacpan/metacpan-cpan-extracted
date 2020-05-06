package Awesome::FFI;

use strict;
use warnings;
use FFI::Platypus;
use FFI::Go::String;
use base qw( Exporter );

our @EXPORT_OK = qw( Add Cosine Log );

my $ffi = FFI::Platypus->new( api => 1, lang => 'Go' );
# See FFI::Platypus::Bundle for the how and why
# bundle works.
$ffi->bundle;

$ffi->attach( Add    => ['goint','goint'] => 'goint'     );
$ffi->attach( Cosine => ['gofloat64'    ] => 'gofloat64' );
$ffi->attach( Log    => ['gostring'     ] => 'goint'     );

1;
