use v5.36;
use Test::More;
BEGIN
{
    use File::Basename          qw( dirname );
    use File::Spec::Functions   qw( catdir rel2abs );

    require lib;
    lib->import( rel2abs catdir dirname( $0 ), '..', 'lib' );
}

use File::Util::SecureDir;

my $parse = do { no warnings 'once'; $File::Util::SecureDir::parse_sd };
my $sid   = sub( $rev, $auth, @sub ) { pack 'C C x4 n V*', $rev, scalar @sub, $auth, @sub };

my $system   = $sid->( 1, 5, 18 );
my $everyone = $sid->( 1, 1, 0  );

my $ace  = pack( 'C C v V', 0, 0, 8 + length $everyone, 0x2 ) . $everyone;
my $acl  = pack( 'C C v v v', 2, 0, 8 + length $ace, 1, 0 ) . $ace;
my $sd   = pack( 'C C v V V V V', 1, 0, 0x8004, 20, 0, 0, 20 + length $system ) . $system . $acl;

my $info = $parse->( $sd );
ok $info, 'hand-packed SD parses';
is $info->{ owner }, $system, 'owner SID';
ok !$info->{ null_dacl }, 'DACL present';
is scalar $info->{ acez }->@*, 1, 'one allow ACE';
is $info->{ acez }[0][1], 0x2, 'mask';
is $info->{ acez }[0][2], $everyone, 'ACE SID is Everyone';
ok !defined $parse->( 'short' ), 'short buffer -> undef';
ok !defined $parse->( substr $sd, 0, 40 ), 'truncated DACL -> undef';

{
    my $null = pack( 'C C v V V V V', 1, 0, 0, 0, 0, 0, 0 ) . "\0" x 8;
    ok $parse->( $null )->{ null_dacl }, 'no DACL -> null_dacl';
}

done_testing;
