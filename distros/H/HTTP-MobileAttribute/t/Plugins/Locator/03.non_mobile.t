use Test::More;
plan skip_all => "this module requires Geo::Coordinates::Converter && Geo::Coordinates::Converter::iArea" unless eval "use Geo::Coordinates::Converter; use Geo::Coordinates::Converter::iArea; 1;";
plan tests => 1;

use HTTP::MobileAttribute plugins => [qw/Locator/];

{
    local $ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 (Windows; U; Windows NT 5.1; ja; rv:1.8.1.11) Gecko/20071127 Firefox/2.0.0.11';
    my $agent = HTTP::MobileAttribute->new;
    eval { $agent->get_location({}) };
    like $@, qr/^Invalid mobile user agent:/;
}
