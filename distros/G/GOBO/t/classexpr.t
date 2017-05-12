use Test;
plan tests => 29;
use GOBO::ClassExpression;
use GOBO::Statement;
use GOBO::LinkStatement;
use GOBO::NegatedStatement;
use GOBO::Node;
use GOBO::Parsers::GAFParser;
use GOBO::InferenceEngine;
use GOBO::Graph;
use FileHandle;

my $g = new GOBO::Graph;
my $x = GOBO::ClassExpression->parse_idexpr($g, 'a^foo(bar)');
print "x=$x\n";
printf "  target: %s\n", $_ foreach @{$g->get_target_links($x)};
ok($x->isa('GOBO::ClassExpression::Intersection'));
ok scalar(@{$x->arguments}) == 2;
ok grep { $_->id eq 'a' } @{$x->arguments};
ok grep { $_->isa('GOBO::ClassExpression::RelationalExpression') &&
             $_->relation->id eq 'foo' &&
             $_->target->id eq 'bar'
             } @{$x->arguments};

$x = GOBO::ClassExpression->parse_idexpr($g, 'a|foo(bar)');
print "x=$x\n";
ok($x->isa('GOBO::ClassExpression::Union'));
ok scalar(@{$x->arguments}) == 2;
ok grep { $_->id eq 'a' } @{$x->arguments};
ok grep { $_->isa('GOBO::ClassExpression::RelationalExpression') &&
             $_->relation->id eq 'foo' &&
             $_->target->id eq 'bar'
             } @{$x->arguments};

$x = GOBO::ClassExpression->parse_idexpr($g, 'a|b');
print "x=$x\n";
ok($x->isa('GOBO::ClassExpression::Union'));
ok scalar(@{$x->arguments}) == 2;
ok grep { $_->id eq 'a' } @{$x->arguments};
ok grep { $_->id eq 'b' } @{$x->arguments};

$x = GOBO::ClassExpression->parse_idexpr($g, 'a|b|c');
print "x=$x\n";
ok($x->isa('GOBO::ClassExpression::Union'));
ok scalar(@{$x->arguments}) == 3;
ok grep { $_->id eq 'a' } @{$x->arguments};
ok grep { $_->id eq 'b' } @{$x->arguments};
ok grep { $_->id eq 'c' } @{$x->arguments};

my $ie = new GOBO::InferenceEngine(graph=>$g);
ok $ie->subsumed_by(GOBO::ClassExpression->parse_idexpr($g, 'a'),
                    GOBO::ClassExpression->parse_idexpr($g, 'a|b|c'));
ok $ie->subsumed_by(GOBO::ClassExpression->parse_idexpr($g, 'a^z'),
                    GOBO::ClassExpression->parse_idexpr($g, 'a|b|c'));
#TODO
#ok $ie->subsumed_by(GOBO::ClassExpression->parse_idexpr($g, 'a|b'),
#                    GOBO::ClassExpression->parse_idexpr($g, 'a|b|c'));
ok $ie->subsumed_by(GOBO::ClassExpression->parse_idexpr($g, 'a^b'),
                    GOBO::ClassExpression->parse_idexpr($g, 'a'));
ok $ie->subsumed_by(GOBO::ClassExpression->parse_idexpr($g, 'a^b^c'),
                    GOBO::ClassExpression->parse_idexpr($g, 'a^b'));

$x = GOBO::ClassExpression->parse_idexpr($g, 'a^part_of(b^part_of(c))');
#$x = GOBO::ClassExpression->parse_idexpr($g, 'x:a^r:part_of(x:b^r:part_of(x:c))');
ok($x->isa('GOBO::ClassExpression::Intersection'));
ok scalar(@{$x->arguments}) == 2;
ok grep { $_->id eq 'a' } @{$x->arguments};
ok grep { $_->isa('GOBO::ClassExpression::RelationalExpression') &&
             $_->relation->id eq 'part_of' &&
             $_->target->isa('GOBO::ClassExpression::Intersection') &&
             scalar(@{$_->target->arguments}==2)
             } @{$x->arguments};


$x = GOBO::ClassExpression->parse_idexpr($g, 'part_of(b)^part_of(c)');
print "x=$x\n";
ok($x->isa('GOBO::ClassExpression::Intersection'));
ok scalar(@{$x->arguments}) == 2;
ok grep { $_->isa('GOBO::ClassExpression::RelationalExpression') &&
             $_->relation->id eq 'part_of' &&
             $_->target->id eq 'b'
             } @{$x->arguments};
ok grep { $_->isa('GOBO::ClassExpression::RelationalExpression') &&
             $_->relation->id eq 'part_of' &&
             $_->target->id eq 'c'
             } @{$x->arguments};

