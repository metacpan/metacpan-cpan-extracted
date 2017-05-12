use strict;
use warnings;
use utf8;

use Test::More tests => 25;

{
    use_ok('Geography::JapaneseMunicipals');
}

{
    my $names = Geography::JapaneseMunicipals->municipals();
    isa_ok($names, 'ARRAY', 'municipals()');
    is(@{$names}, 1967, 'municipals()');
}

{
    my $names = Geography::JapaneseMunicipals->municipals_in('富山県');
    isa_ok($names, 'ARRAY', 'municipals_in()');
    is_deeply(
        $names,
        [qw(富山市 高岡市 魚津市 氷見市 滑川市 黒部市 砺波市 小矢部市 南砺市 射水市 舟橋村 上市町 立山町 入善町 朝日町)],
        'municipals_in()');
}

{
    my $municipals1 = Geography::JapaneseMunicipals->municipal_infos('東京都渋谷区');
    isa_ok($municipals1, 'ARRAY', 'municipal_infos()');
    is(@{$municipals1}, 1, 'municipal_infos()');
    my $municipal = shift @{$municipals1};
    is($municipal->{region}->{name}, '関東', 'municipal()');
    is($municipal->{prefecture}->{id}, '13', 'municipal()');
    is($municipal->{prefecture}->{name}, '東京都', 'municipal()');
    is($municipal->{id}, '13113', 'municipal()');
    is($municipal->{name}, '渋谷区', 'municipal()');
    my $municipals2 = Geography::JapaneseMunicipals->municipal_infos('13113');
    isa_ok($municipals2, 'ARRAY', 'municipal_infos()');
    is(@{$municipals2}, 1, 'municipal_infos()');
}

{
    my $municipals1 = Geography::JapaneseMunicipals->municipal_infos('東京都');
    isa_ok($municipals1, 'ARRAY', 'municipal_infos()');
    is(@{$municipals1}, 62, 'municipal_infos()');
    my $municipals2 = Geography::JapaneseMunicipals->municipal_infos('13');
    isa_ok($municipals2, 'ARRAY', 'municipal_infos()');
    is(@{$municipals2}, 62, 'municipal_infos()');
    is_deeply($municipals1, $municipals2, 'municipal_infos()');
}

{
    my $municipals = Geography::JapaneseMunicipals->municipal_infos();
    isa_ok($municipals, 'ARRAY', 'municipal_infos()');
    is(@{$municipals}, 1967, 'municipal_infos()');
}

{
    my $id = Geography::JapaneseMunicipals->municipal_id('東京都', '渋谷区');
    is($id, '13113', 'municipal_id()');
}

{
    my $id = Geography::JapaneseMunicipals->municipal_id('東京都渋谷区');
    is($id, '13113', 'municipal_id()');
    $id = Geography::JapaneseMunicipals->municipal_id('東京都横浜市');
    is($id, undef, 'municipal_id()');
}

{
    my $name = Geography::JapaneseMunicipals->municipal_name('01202');
    is($name, '函館市', 'municipal_name()');
}
