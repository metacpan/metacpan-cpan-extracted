use strict;
use warnings;

# Execute the tests
use Test::More tests => 26;
BEGIN { use_ok('MDOM::Token'); }

my $token = MDOM::Token->new('hello!');
ok $token, 'obj ok';
isa_ok $token, 'MDOM::Token::Bare', 'bare ok';
isa_ok $token, 'MDOM::Token', 'token ok';
is "$token", 'hello!', 'stringify ok';
ok $token->significant, 'plain tokens are significant by default';

$token->set_content('wow');
is $token->content, 'wow', 'set/get_content ok';
$token->add_content('~~~');
is $token->content, 'wow~~~', 'add_content ok';

$token = MDOM::Token->new('Whitespace', "\n\t ");
isa_ok $token, 'MDOM::Token::Whitespace';
isa_ok $token, 'MDOM::Token';
is $token->content, "\n\t ", 'ws content ok';
ok !$token->significant, 'ws is not significant';

$token = MDOM::Token->new('Separator', ":=");
isa_ok $token, 'MDOM::Token::Separator';
isa_ok $token, 'MDOM::Token';
is $token->content, ':=', 'sp content ok';
ok $token->significant, 'separators are significant';

$token = MDOM::Token->new('Comment', "# blah blah blah");
isa_ok $token, 'MDOM::Token::Comment';
isa_ok $token, 'MDOM::Token';
is $token->content, "# blah blah blah", 'cmt content ok';
$token->add_content("\n hey!");
is "$token", "# blah blah blah\n hey!", 'cmt add_content ok';
ok !$token->significant, 'comments are not significant';

$token = MDOM::Token->new('Continuation', "\\\n");
isa_ok $token, 'MDOM::Token::Continuation';
isa_ok $token, 'MDOM::Token';
is $token->content, "\\\n";
ok !$token->significant, 'line continuations are not significant';

$token = MDOM::Token::Whitespace->new("\n");
is $token->content, "\n";
