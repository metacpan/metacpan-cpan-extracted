use strict;
use warnings;

use Test::More tests => 49;
BEGIN { 
    use_ok('MDOM::Token');
    use_ok('MDOM::Node');
}

{
    my $node = MDOM::Node->new;

    my $token = MDOM::Token->new('hello');
    $node->add_element($token);

    is $token->parent, $node, '$token\'s parent ok';
    ok !$token->previous_sibling, '$token\'s prev sibling is empty';
    ok !$token->next_sibling, '$token\'s next sibling is empty too';

    my @elems = $node->elements;
    is scalar(@elems), 1, 'only 1 elem';
    is $elems[0], $token, 'token truly added';
    is $node->child(0), $token, 'child 0';

    is $node->first_element, $token, 'it is the first one';
    is $node->last_element, $token, '...and also the last';

    my $token2 = MDOM::Token->new('Whitespace', ' ');
    ok !$node->contains($token2), '$token2 not yet added';
    $node->add_element($token2);

    is $token2->parent, $node, '$token2\'s parent ok';
    is $token2->previous_sibling, $token, '$token2\'s prev sibling is $token';
    ok !$token2->next_sibling, 'no next sibling for $token2';

    is scalar($node->elements), 2, '2 elements';
    @elems = $node->elements;

    is $elems[0], $token, '$token is the first one';
    is $node->child(0), $token, 'child 0';
    ok $node->contains($token), 'contains $token';

    is $elems[1], $token2, '$token2 is the second one';
    is $node->child(1), $token2, 'child 1';
    ok $node->contains($token2), 'contains $token2';

    is $elems[2], undef, 'no third one';
    is join(':', @elems), 'hello: ';

    is $node->first_element, $token;
    is $node->last_element, $token2;

    my $token3 = MDOM::Token->new('world');
    ok !$node->contains($token3), '$token3 not yet added';
    $node->add_element($token3);

    is $token3->parent, $node, '$token3\'s parent ok';
    is $token3->previous_sibling, $token2, '$token3\'s prev sibling is $token2';
    ok !$token3->next_sibling, 'no next sibling for $token3';

    is $token2->previous_sibling, $token, '$token2\'s prev sibling is $token';
    is $token2->next_sibling, $token3, '$token2\'s next sibling is $token3';

    my $res = $node->find('Token::Bare');
    is scalar(@$res), 2, '2 bare tokens';
    is join('', @$res), 'helloworld';

    $res = $node->find('MDOM::Token::Bare');
    is scalar(@$res), 2, '2 bare tokens';
    is join('', @$res), 'helloworld';

    $res = $node->find_first('Token::Bare');
    is $res, $token, 'find the first one';

    $res = $node->find_first('Token::Whitespace');
    is $res, $token2, 'find the second one';

    $res = $node->find('Token::Whitespace');
    is scalar(@$res), 1, 'only 1 whitespace found';
    is $res->[0], $token2, '$token2 found';

    @elems = $node->children;
    is join('', @elems), 'hello world';
    @elems = $node->schildren;
    is join('', @elems), 'helloworld';

    is $node->schild(0), $token;
    is $node->schild(1), $token3;

    my $node2 = $node->clone;
    $node2->prune('MDOM::Token::Whitespace');
    is join('', $node2->elements), 'helloworld';
    $node2->prune('Token::Bare');
    is join('', $node2->elements), '';

    $node->prune('MDOM::Token::Bare');
    is join('', $node->elements), ' ';
}

{
    my $node = MDOM::Node->new;

    my $token = MDOM::Token->new('hello');
    $node->__add_element($token);

    my $token2 = MDOM::Token->new('Whitespace', ' ');
    $node->__add_element($token2);

    is scalar($node->elements), 2, '2 elements';
    is $node->child(0), $token, 'child 0';
    is $node->child(1), $token2, 'child 1';
}
