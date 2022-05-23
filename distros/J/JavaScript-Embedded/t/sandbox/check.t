use lib './lib';
use strict;
use warnings;
use JavaScript::Embedded;
use Test::More;

{
    local $@;
    eval {
        my $js = JavaScript::Embedded->new( max_memory => 1 );
    };

    ok $@ =~ /must be at least/;
}

{
    local $@;
    eval {
        my $js = JavaScript::Embedded->new( timeout => '1' );
    };

    ok $@ =~ /must be a number/;
}

{
    local $@;
    eval {
        my $js = JavaScript::Embedded->new( max_memory => 256 * 1024 );
        $js->resize_memory(1);
    };

    ok $@ =~ /must be at least/;
}

{
    local $@;
    eval {
        my $js = JavaScript::Embedded->new( max_memory => 'xxxxx' );
    };

    ok $@ =~ /must be a number/;
}

{
    local $@;
    eval {
        my $js = JavaScript::Embedded->new();
        $js->set_timeout();
    };

    ok $@ =~ /must be a number/;
}

done_testing();
