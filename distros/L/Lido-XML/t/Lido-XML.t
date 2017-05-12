use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Lido::XML';
    use_ok $pkg;
}
require_ok $pkg;

my $x = Lido::XML->new;

ok $x , 'go a Lido-XML';

my $data = $x->parse("t/lido.xml");

ok $data , 'parsed a lido record';

my $xml  = $x->to_xml($data);

ok $xml  , 'transformed Perl into lido';

throws_ok {
    $x->parse("t/lido-wrong.xml");
} 'Lido::XML::Error' , 'caught errors';

done_testing 6;
