use strict;
use warnings;

use Scalar::Util 'blessed';
use Test::Simple tests => 3;

use Farly;
use Farly::ASA::Builder;
use Farly::ASA::Parser;
use Farly::ASA::Annotator;

my $parser    = Farly::ASA::Parser->new();
my $annotator = Farly::ASA::Annotator->new();

my $string;
my $tree;

ok( $annotator->isa('Farly::ASA::Annotator'), "constructor" );

$string = "name 10.0.0.0 intranet";

my $named_net = $parser->parse($string);

$string = "name 192.168.10.1 server1";

my $named_host = $parser->parse($string);

$annotator->visit($named_net);
$annotator->visit($named_host);

$string = "access-list acl-outside permit ip intranet 255.0.0.0 host server1 range 80 65535";

my $named_rule = $parser->parse($string);

$annotator->visit($named_rule);

my @actual = visit($named_rule);

my @expected = (
    Farly::Value::String->new('permit'),
    Farly::Value::String->new('acl-outside'),
    Farly::Transport::PortRange->new('80 65535'),
    Farly::IPv4::Address->new('192.168.10.1'),
    Farly::Transport::Protocol->new('0'),
    Farly::IPv4::Network->new('10.0.0.0 255.0.0.0')
);

ok( equals( \@actual, \@expected ), "names coverage" );

$string =
"access-list acl-outside line 1 extended permit tcp any range 1024 65535 OG_NETWORK citrix range 1 1024";

my $in = $parser->parse($string);

$annotator->visit($in);

@actual = visit($in);

my $GROUP = Farly::Object::Ref->new();
$GROUP->set( 'ENTRY', Farly::Value::String->new('GROUP') );
$GROUP->set( 'ID',    Farly::Value::String->new('citrix') );

@expected = (
    $GROUP,
    Farly::Value::String->new('acl-outside'),
    Farly::Value::String->new('permit'),
    Farly::Transport::PortRange->new('1 1024'),
    Farly::Transport::PortRange->new('1024 65535'),
    Farly::Value::Integer->new('1'),
    Farly::Transport::Protocol->new('6'),
    Farly::IPv4::Network->new('0.0.0.0 0.0.0.0'),
    Farly::Value::String->new('extended'),
);

ok( equals( \@actual, \@expected ), "ref and port coverage" );

sub visit {
    my ($node) = @_;

    my @result;

    # set s of explored vertices
    my %seen;

    #stack is all neighbors of s
    my @stack;
    push @stack, $node;

    while (@stack) {

        $node = pop @stack;

        next if ( $seen{$node}++ );

        if ( exists( $node->{'__VALUE__'} ) ) {
            push @result, $node->{'__VALUE__'};
        }
        else {
            foreach my $key ( keys %$node ) {
                next if ( $key eq "EOL" );
                my $next = $node->{$key};
                if ( blessed($next) ) {
                    push @stack, $next;
                }
            }
        }
    }

    return @result;
}

sub equals {
    my ( $arr1, $arr2 ) = @_;

    if ( scalar(@$arr1) != scalar(@$arr2) ) {
        return undef;
    }

    foreach my $s (@$arr1) {
        my $match;
        foreach my $o (@$arr2) {
            if ( $s->equals($o) ) {
                $match = 1;
            }
        }
        if ( !$match ) {
            return undef;
        }
    }

    return 1;

}

