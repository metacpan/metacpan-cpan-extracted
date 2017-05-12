package MyExport;

use warnings;
use strict;
use Exporter::Attributes qw(import);

our $VERSION = '1.3';

our @bar : Exportable(vars) = ( 2, 3, 5, 7 );
our $foo : Exported(vars) = 42;
our %baz : Exported = ( a => 65, b => 66 );

sub hello : Exported(greet,us)               { "hello there" }
sub askme : Exportable                       { "what you will" }
sub hi : Exportable(greet us)                { "hi there" }
sub hey : Exportable(greet) : Exportable(us) { "hey there" }

sub get_foo : Exported(vars)   { $foo }
sub get_bar : Exportable(vars) { @bar }

1;
