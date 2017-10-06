
use 5.010001;
use Test::More;

use Importer::Zim::Base;

{
    my @exports = Importer::Zim::Base->_prepare_args(
        'M4' => { -prefix => 'foo_' } => qw(f1 f2) );
    my @expected = (
        { export => 'foo_f1', code => \&M4::f1 },
        { export => 'foo_f2', code => \&M4::f2 },
    );
    is_deeply( \@exports, \@expected,
        "prepare 'M4' => { -prefix => 'foo_' } =>  qw(f1 f2)" );
}
{
    my @exports = Importer::Zim::Base->_prepare_args(
        'M4' => { -prefix => 'foo_' } => (
            'f1' => { -as => 'g1' },
            'f2', 'f3' => { -as => 'h3' }
        )
    );
    my @expected = (
        { export => 'foo_g1', code => \&M4::f1 },
        { export => 'foo_f2', code => \&M4::f2 },
        { export => 'foo_h3', code => \&M4::f3 },
    );
    is_deeply( \@exports, \@expected,
        "prepare 'M4' => { -prefix => 'foo_ } => 'f1' => { -as => 'g1' }, 'f2', 'f3' => { -as => 'h3' }"
    );
}
{
    my @exports = Importer::Zim::Base->_prepare_args(
        'M4' => ( "f1", "f1" => { -as => 'g1', -prefix => 'foo_' } ) );
    my @expected = (
        { export => 'f1',     code => \&M4::f1 },
        { export => 'foo_g1', code => \&M4::f1 },
    );
    is_deeply( \@exports, \@expected,
        "Importing to different targets is always fine" );
}
{
    my @exports = Importer::Zim::Base->_prepare_args(
        'M4' => { -prefix => 'foo_' } => ':tag1' );
    my @expected = (
        { export => 'foo_f1', code => \&M4::f1 },
        { export => 'foo_f2', code => \&M4::f2 },
    );
    is_deeply( \@exports, \@expected,
        "prepare 'M4' => { -prefix => 'foo_' } => ':tag1'" );
}

done_testing;

package M4;

BEGIN { $INC{'M4.pm'} = __FILE__; }
BEGIN { our @EXPORT_OK = qw(f1 f2 f3); }
BEGIN { our %EXPORT_TAGS = ( 'tag1' => [qw(f1 f2)], ); }

sub f1 { }
sub f2 { }
sub f3 { }

sub f4 { }
