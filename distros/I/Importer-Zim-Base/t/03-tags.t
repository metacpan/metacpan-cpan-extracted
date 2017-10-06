
use 5.010001;
use Test::More;

package M3;

BEGIN { $INC{'M3.pm'} = __FILE__ }

our %EXPORT_TAGS = ( 'tag1' => [qw(f1 f2)], );
our @EXPORT_OK = qw(f1 f2);

sub f1 { }
sub f2 { }
sub f3 { }

package main;

use Importer::Zim::Base;

{
    my @exports = Importer::Zim::Base->_prepare_args( 'M3' => ':tag1' );
    my @expected = (
        { export => 'f1', code => \&M3::f1 },
        { export => 'f2', code => \&M3::f2 },
    );
    is_deeply( \@exports, \@expected, "prepare 'M3' => ':tag1'" );
}
{
    my @exports = Importer::Zim::Base->_prepare_args( 'M3' => ':tag1', 'f1' );
    my @expected = (
        { export => 'f1', code => \&M3::f1 },
        { export => 'f2', code => \&M3::f2 },
    );
    is_deeply( \@exports, \@expected, "Importing a symbol twice is fine" );
}

done_testing;

