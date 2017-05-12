use strict;
use warnings;
use Test::More tests => 9;
use Gearman::Client;

our $last_packet = undef;
our @packets;

my $parser = Gearman::ResponseParser::Test->new();

test_packet("\0RES\0\0\0\x0a\0\0\0\x01!", {
    len => 1,
    blobref => \"!", #"
    type => 'no_job',
});

test_packet("\0RES\0\0\0\x0a\0\0\0\0", {
    len => 0,
    blobref => \"", #"
    type => 'no_job',
});

## multiple packets
my $pkt = "\0RES\0\0\0\x0a\0\0\0\0";
test_multi_packet("$pkt$pkt", {
    len => 0,
    blobref => \"", #"
    type => 'no_job',
}, {
    len => 0,
    blobref => \"", #"
    type => 'no_job',
});

# Message split into two packets
test_packet("\0RE", undef);
test_packet("S\0\0\0\x0a\0\0\0\0", {
    len => 0,
    blobref => \"", #"
    type => 'no_job',
});

# Message with payload split into two packets
test_packet("\0RES\0\0\0\x0a\0\0\0\x02a", undef);
test_packet("b", {
    len => 2,
    blobref => \"ab", #"
    type => 'no_job',
});

# Two packets, with the first containing a full message
# and a partial message, and the second containing the
# remainder of the partial message.
test_packet("\0RES\0\0\0\x0a\0\0\0\x02ab\0RES\0\0\0\x0a\0\0\0\x02b", {
    len => 2,
    blobref => \"ab", #"
    type => 'no_job',
});
test_packet("a", {
    len => 2,
    blobref => \"ba", #"
    type => 'no_job',
});

sub test_packet {
    my ($data, $expected) = @_;

    my $test_name = "Parsing ".enc($data);

    $last_packet = undef;
    $parser->parse_data(\$data);
    is_deeply($last_packet, $expected, $test_name);
}

sub test_multi_packet {
    my ($data, @expected) = @_;

    my $test_name = "Parsing ".enc($data);

    @packets = ();
    $parser->parse_data(\$data);

    is_deeply(\@packets, \@expected, $test_name);
}

sub enc {
    my $data = $_[0];
    $data =~ s/([\W])/"%" . uc(sprintf("%2.2x",ord($1)))/eg;
    return $data;
}

package Gearman::ResponseParser::Test;

use Gearman::ResponseParser;
use base qw(Gearman::ResponseParser);

sub on_packet {
    $main::last_packet = $_[1];
    push @main::packets, $_[1];
}
