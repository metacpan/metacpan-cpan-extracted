use Test::More;
use FormValidator::LazyWay;
use FindBin;
use File::Spec;
use CGI;
use YAML::Syck;
use lib File::Spec->catfile( $FindBin::Bin, 'lib' );
use Data::Dumper;
use utf8;
no warnings 'once';
local $YAML::Syck::ImplicitUnicode = 1;
use warnings;


my $fv = FormValidator::LazyWay->new(
    config => {
        rules   => [qw/Number/],
        setting => {
            strict => {
                delivery => {
                    rule => ['Number#uint']
                }
            }
        }
    }
);

my $res = $fv->check(
    { delivery => 0 },
    {   required => [qw/delivery/],
        defaults => { delivery => 99999 },
    },
);

ok ! $res->has_error, 'not error';

done_testing;

