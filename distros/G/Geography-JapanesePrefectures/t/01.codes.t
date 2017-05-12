use strict;
use warnings;
use Test::More 0.98;
use Geography::JapanesePrefectures;

for my $key (keys %main::) {
    if ($key =~ /^test_(.+)$/) {
        subtest $1 => main->can($key);
    }
}
done_testing;

sub test_prefectures {
    my ( $self, ) = @_;

    is( scalar( Geography::JapanesePrefectures->prefectures ), 47 );
    is( scalar( Geography::JapanesePrefectures::Unicode->prefectures ), 47 );
}

sub test_regions {
    my ( $self, ) = @_;

    is( scalar( Geography::JapanesePrefectures->regions ), 11 );
    {
        my @regions = Geography::JapanesePrefectures->regions;
        ok !utf8::is_utf8($regions[0]);
    }

    is( scalar( Geography::JapanesePrefectures::Unicode->regions ), 11 );
    {
        my @regions = Geography::JapanesePrefectures::Unicode->regions;
        ok utf8::is_utf8($regions[0]);
    }
}

sub test_prefectures_in {
    my ( $self, ) = @_;

    is_deeply(
        [
            sort { $a cmp $b }
              Geography::JapanesePrefectures->prefectures_in('関東')
        ],
        [
            sort { $a cmp $b }
              qw(茨城県 栃木県 群馬県 埼玉県 千葉県 東京都 神奈川県 山梨県)
        ]
    );

    use utf8;
    is_deeply(
        [
            sort { $a cmp $b }
              Geography::JapanesePrefectures::Unicode->prefectures_in('関東')
        ],
        [
            sort { $a cmp $b }
              qw(茨城県 栃木県 群馬県 埼玉県 千葉県 東京都 神奈川県 山梨県)
        ]
    );
}

sub test_prefectures_id {
    my ( $self, ) = @_;

    is( Geography::JapanesePrefectures->prefectures_id('和歌山県'), 30 );
    is( Geography::JapanesePrefectures::Unicode->prefectures_id(Encode::decode_utf8('和歌山県')), 30 );
}

sub test_prefectures_infos {
    my ( $self, ) = @_;

    is( ref(Geography::JapanesePrefectures->prefectures_infos()), "ARRAY" );
    is( scalar(@{Geography::JapanesePrefectures->prefectures_infos()}), 47 );
    is_deeply( [sort keys %{Geography::JapanesePrefectures->prefectures_infos()->[0]}], [sort qw(id name region roman)] );
    is(Geography::JapanesePrefectures->prefectures_infos()->[0]->{name}, '北海道');
    is(Geography::JapanesePrefectures->prefectures_infos()->[0]->{roman}, 'Hokkaido');
    ok !utf8::is_utf8(Geography::JapanesePrefectures->prefectures_infos()->[0]->{name});
    ok utf8::is_utf8(Geography::JapanesePrefectures::Unicode->prefectures_infos()->[0]->{name});
}

