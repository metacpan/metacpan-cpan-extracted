use strict;
use warnings;
use Test::More qw/no_plan/;

use lib './lib';
use IP::QQWry;

my $qqwry = IP::QQWry->new;
isa_ok( $qqwry, 'IP::QQWry' );

my $db = '/opt/QQWry.Dat';
$qqwry = IP::QQWry->new($db);
isa_ok( $qqwry, 'IP::QQWry' );

SKIP: {
    skip 'have no QQWry.Dat file', unless $qqwry->{fh};

    # these test are for gbk encoding database
    my %info = (
        '166.111.166.111' => {
            base => '清华大学学生宿舍',
            ext  => '14号楼',
        },
        '211.99.222.1' => {
            base => '北京市',
            ext  => '世纪互联数据中心',
        },
        '114.78.123.177' => {
            base => '澳大利亚',
            ext  => '',
        },
    );
    for my $ip ( keys %info ) {
        my ( $base, $ext ) = $qqwry->query($ip);
        is( $base, $info{$ip}->{base}, 'list context query, the base part' );
        is( $ext,  $info{$ip}->{ext},  'list context query, the ext part' );
        my $info = $qqwry->query($ip);
        is( $info,
            $info{$ip}->{base} . $info{$ip}->{ext},
            'scalar context query'
        );
    }

    %info = map {
              $_ =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/
            ? $1 * 256**3 + $2 * 256**2 + $3 * 256 + $4
            : $_
    } %info;

    for my $ip ( keys %info ) {
        is( $qqwry->cached($ip), 1, 'cached' );
        $qqwry->clear($ip);
        is( $qqwry->cached($ip), 0, 'clear cache' );
    }
    for my $ip ( keys %info ) {
        my ( $base, $ext ) = $qqwry->query($ip);
        is( $base, $info{$ip}->{base}, 'list context query, the base part' );
        is( $ext,  $info{$ip}->{ext},  'list context query, the ext part' );
        my $info = $qqwry->query($ip);
        is( $info,
            $info{$ip}->{base} . $info{$ip}->{ext},
            'scalar context query'
        );
    }

    like( $qqwry->db_version, qr/纯真网络\d{4}年\d{1,2}月\d{1,2}日IP数据/,
        'db version' );

    {
        local $_ = 'howdy world!';
        $qqwry = IP::QQWry->new($db);
        $qqwry->query('166.111.166.111');
        is( $_, 'howdy world!', '$_ is not polluted any more' );
    }
}

