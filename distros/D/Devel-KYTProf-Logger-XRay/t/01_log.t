use strict;
use warnings;
use Test::More;

use AWS::XRay;
use Devel::KYTProf::Logger::XRay;
use Devel::KYTProf;
use IO::Scalar;
use JSON::XS;

my $buf;
no warnings 'redefine';
*AWS::XRay::sock = sub {
    IO::Scalar->new(\$buf);
};

sub example {
    my $t = shift;
    sleep $t;
    1;
}

Devel::KYTProf->add_prof(
    "main", "example",
    sub {
        my ($orig, $t) = @_;
        return [
            'time:%s',
            ['time'],
            {
                'time' => $t,
            },
        ];
    },
);

Devel::KYTProf->logger("Devel::KYTProf::Logger::XRay");

{
    local $AWS::XRay::TRACE_ID = AWS::XRay::new_trace_id();
    local $AWS::XRay::ENABLED  = 1;

    example("1");
    my ($seg) = parse_buf(1);
    is $seg->{name} => "main";
    ok $seg->{end_time} - $seg->{start_time} >= 1.0;
    is $seg->{metadata}->{time} => "1";
    is $seg->{trace_id} => $AWS::XRay::TRACE_ID;
}

done_testing;

sub parse_buf {
    my $expect = shift;
    is $buf =~ s/{"format":"json","version":1}//g => $expect, "includes $expect segment headers";
    my @seg = split /\n/, $buf;
    shift @seg; # despose first ""
    undef $buf;
    return map { decode_json($_) } @seg;
}
