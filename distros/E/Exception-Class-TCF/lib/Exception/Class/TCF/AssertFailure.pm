package Exception::Class::TCF::AssertFailure;
require Exporter;
use Exception::Class::TCF;
use vars qw(@ISA @EXPORT_OK);

@ISA       = qw(Exception::Class::TCF::Error Exporter);
@EXPORT_OK = qw(&assert);

sub assert (&@) {
    my $block = shift;
    if ( not $block->() ) {
        my $exc = Exception::Class::TCF::AssertFailure->new( @_ );
        &Exception::Class::TCF::throw($exc);
    }
}


