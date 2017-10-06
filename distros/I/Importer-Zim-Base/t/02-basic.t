
use 5.010001;
use Test::More;

use Importer::Zim::Base;

{
    my @exports = Importer::Zim::Base->_prepare_args( 'M1' => qw(f1 f2) );
    my @expected = (
        { export => 'f1', code => \&M1::f1 },
        { export => 'f2', code => \&M1::f2 },
    );
    is_deeply( \@exports, \@expected, "prepare 'M1' => qw(f1 f2)" );
}
{
    my @exports = Importer::Zim::Base->_prepare_args(
        'M1' => 'f1' => { -as => 'g1' },
        'f2', 'f3' => { -as => 'h3' }
    );
    my @expected = (
        { export => 'g1', code => \&M1::f1 },
        { export => 'f2', code => \&M1::f2 },
        { export => 'h3', code => \&M1::f3 },
    );
    is_deeply( \@exports, \@expected,
        "prepare 'M1' => 'f1' => { -as => 'g1' }, 'f2', 'f3' => { -as => 'h3' }"
    );
}
{
    my @exports = Importer::Zim::Base->_prepare_args( 'M1' => qw(f1 f1) );
    my @expected = ( { export => 'f1', code => \&M1::f1 }, );
    is_deeply( \@exports, \@expected, "Importing a symbol twice is fine" );
}
{
    my @exports = Importer::Zim::Base->_prepare_args(
        'M1' => ( "f1", "f1" => { -as => 'g1' } ) );
    my @expected = (
        { export => 'f1', code => \&M1::f1 },
        { export => 'g1', code => \&M1::f1 },
    );
    is_deeply( \@exports, \@expected,
        "Importing to different targets is always fine" );
}
{
    my @exports = Importer::Zim::Base->_prepare_args(
        'M1' => { -strict => 0 } => 'f4' );
    my @expected = ( { export => 'f4', code => \&M1::f4 }, );
    is_deeply( \@exports, \@expected,
        "Importing non-exportable symbols with -strict => 0" )
}

done_testing;

package M1;

BEGIN { $INC{'M1.pm'} = __FILE__; }
BEGIN { our @EXPORT_OK = qw(f1 f2 f3); }

sub f1 { }
sub f2 { }
sub f3 { }

sub f4 { }
