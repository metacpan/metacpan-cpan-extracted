package t::common;

use parent Exporter;

our @EXPORT = ( qw[ fake_hg ] );

use Probe::Perl;
use File::Spec::Functions qw[ catfile ];

my $perl;

BEGIN {

    $perl = Probe::Perl->find_perl_interpreter
	or die( "unable to locate Perl interpreter\n" );
}

INIT {

    use constant fake_hg => [ $perl, catfile( 't', 'fake-hg' ) ];
}

1;
