# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 13;

#use Test::More (no_plan);
use Data::Dumper;
use strict;

BEGIN {
    use_ok('HTML::WebDAO');
    use_ok('HTML::WebDAO::Engine');
    use_ok('HTML::WebDAO::Lex');
    use_ok('HTML::WebDAO::Container');
    use_ok('HTML::WebDAO::SessionSH');
    use lib 'contrib';
    use_ok('TestWDAO');
}
my $ID = "tcontainer";
ok( ( my $store_ab = new HTML::WebDAO::Store::Abstract:: ), "Create store" );
ok( ( my $session = new HTML::WebDAO::SessionSH:: store => $store_ab ),
    "Create session" );
$session->U_id($ID);

ok( my $lex = ( new HTML::WebDAO::Lex:: content => join "", <DATA> ),
    "Create Lexer" );
isa_ok( $lex, "HTML::WebDAO::Lex" );
my $eng = new HTML::WebDAO::Engine::
  session => $session,
  lexer   => $lex,
  ;
map { $_->value($eng) } @{ $lex->auto };
my ($lmethod) =
  grep { $_->isa('HTML::WebDAO::Lexer::Lmethod') } @{ $lex->tree };
isa_ok( $lmethod, "HTML::WebDAO::Lexer::Lmethod" );
isa_ok(
    my $method_call = $lmethod->value($eng),
    "HTML::WebDAO::Lib::MethodByPath"
);
is( $method_call->fetch($session), 111, "Check call" );

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

__DATA__
<wd>
<regclass class="TestWDAO" alias="testmod"/>
<method path="/testmod1/echo">111</method>
<object id="testmod1" class="testmod"/>
</wd>

