package MyAutocompleter;
use strict;
use warnings;
use Test::More;
use JavaScript::Autocomplete::Backend;

#plan 'no_plan';
plan tests => 1;

use base qw(JavaScript::Autocomplete::Backend);

my @NAMES = qw(alice alfred anne bob charlie); 
sub expand {
    my ($self, $query) = @_;
    # do something to expand the query
    my $re = qr/^\Q$query\E/i;
    my @names = grep /$re/, @NAMES;
    (lc $query, \@names, [], [""]);
}

$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING}   = 'hl=en&js=true&qu=al';

my $ac = MyAutocompleter->new(@_);
$ac->header;
my ($query, $names, $values, $prefix) = $ac->expand($ac->query);
my $got = $ac->output($query, $names, $values, $prefix);
my $expected = qq{sendRPCDone(frameElement, "al", new Array("alice", "alfred"), new Array(), new Array(""));\n};

is ($got, $expected);

