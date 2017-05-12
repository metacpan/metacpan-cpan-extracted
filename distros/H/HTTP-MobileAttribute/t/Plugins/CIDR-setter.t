use strict;
use warnings;
use Test::Base;

BEGIN {
    eval {
        require Net::CIDR::MobileJP;
        Net::CIDR::MobileJP->import( -profile => 't/perlcriticrc' );
    };
    plan skip_all => "Net::CIDR::MobileJP is not installed." if $@;
};

use File::Spec::Functions;
use HTTP::MobileAttribute plugins => [
    'Core',
    {
        module => 'CIDR',
        config => +{
            cidr => catfile(qw/t Plugins assets cidr.yaml/),
        }
    }
];

plan tests => 1*blocks;

filters {
    input    => [qw/yaml get_display/],
    expected => [qw/yaml/],
};

run_is_deeply input => 'expected';

sub get_display {
    my $env = shift;

    my $hma = HTTP::MobileAttribute->new($env->{HTTP_USER_AGENT});
    $hma->reload_cidr($env->{cidr});
    +{
        result => $hma->isa_cidr($env->{HTTP_REMOTE_ADDR}) ? 1 : 0,
    };
}

__END__

===
--- input
HTTP_USER_AGENT: DoCoMo/1.0/D501i
HTTP_REMOTE_ADDR: 10.100.0.1
cidr:
  I:
    - 10.100.0.1/32
--- expected
result: 1

===
--- input
HTTP_USER_AGENT: DoCoMo/1.0/D501i
HTTP_REMOTE_ADDR: 10.100.0.1
cidr:
  I:
    - 10.100.1.1/32
--- expected
result: 0
