use Test::More;
use Test::HexString;
#use Data::HexDump;

BEGIN {
    use_ok 'Game::Tibia::Packet::Charlist';
}

my @tests = ({
        packet => pack('H*', 'b000a9f361c8871562f3089c17f74337dc9ecaa1ffe3b7d570f53bafb0022c21e970acd6f6cbeef3d1514d18f451ce01eb16e860058d8115025b73d8a79a1ee5e6a05c9bfc3be9e3075d98c63cf2d49888994b300ebd916235fab3cc6e7591192d3352abeef5865345bc6a7e58cf1d15ebcd64dc67ab0bd4ddbfd8916986a7e30e738d475e1067d8dc766c832faedd2ca12288c715b0652fdf9693eaa55de0ec7e432de0a6d8013a5718fa056c145de7ea8a'),
        xtea => pack('H*', 'ac71a27fcda681aa3109ebf5f21ee3a8')
    },{
        packet => pack('H*', 'b00077d0ea975721f1c2fb23a407dccb4333363dad550e3e5e4611c9e4eca9fe65ce37e919dae32f2e2b58804d8a94e2e9002d0b407a03f27512d450f99bf4c433befe49c078301bbfcc72113e63d4864c42a3417ba110f1386a8b9d3de3a0b214f09dd2ca3f73427adb67cc4a1d1503a31772c9fd34ea4d8b5a09aff38d1539012c82af2b0854620daf65440c6fd4285074d74edf78a268f804862777192585aaa7a708eb4c96e16a99e1b81aaf3fb7ebd4'),
        xtea => pack('H*', 'b940816e07cdb96e54418baac5bfe275')
});

for my $test (@tests) {
    my $instance = Game::Tibia::Packet::Charlist->new(
        packet => $test->{packet},
        xtea    => $test->{xtea},
        version => 810
    );
    #warn HexDump $instance->finalize;

    is_hexstr $instance->finalize, $test->{packet};
}

done_testing;



