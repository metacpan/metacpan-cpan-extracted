
use 5.010001;
use Test::More;
use Test::Deep;

use Importer::Zim::Base;

{
    my @exports = Importer::Zim::Base->_prepare_args(
        'Getopt::Long' => {
            -filter => sub {/^&?\w/}
        }
    );
    my @expected
      = ( { export => 'GetOptions', code => \&Getopt::Long::GetOptions }, );
    is_deeply( \@exports, \@expected,
        "prepare 'Getopt::Long' => { -filter => sub { /^&?\w/ } }" );
}
{
    my @exports = Importer::Zim::Base->_prepare_args(
        'Getopt::Long' => { -filter => qr/^&?\w/ } );
    my @expected
      = ( { export => 'GetOptions', code => \&Getopt::Long::GetOptions }, );
    is_deeply( \@exports, \@expected,
        "prepare 'Getopt::Long' => { -filter => qr/^&?\w/ }" );
}
{
    my @exports = Importer::Zim::Base->_prepare_args(
        'Fcntl' => {
            -filter => sub {/^O_/}
        }
    );
    my $expected
      = array_each(
        { export => re('^O_'), code => code( sub { ref $_[0] eq 'CODE' } ) }
      );
    cmp_deeply( \@exports, $expected,
        "prepare 'Fcntl' => { -filter => sub { /^O_/ } }" );
}
{
    my @exports = Importer::Zim::Base->_prepare_args(
        'Fcntl' => { -filter => qr/^O_/ } );
    my $expected
      = array_each(
        { export => re('^O_'), code => code( sub { ref $_[0] eq 'CODE' } ) }
      );
    cmp_deeply( \@exports, $expected,
        "prepare 'Fcntl' => { -filter => qr/^O_/ }" );
}

done_testing;
