package
    MyVersionedExporter;

use vars qw( $VERSION @EXPORT_OK @ISA );
$VERSION = 1.5;

use Exporter;
@ISA = qw( Exporter );
@EXPORT_OK = qw( foo );

sub foo {
    return 1;
}

1;
