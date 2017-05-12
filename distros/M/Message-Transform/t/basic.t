#!env perl

use strict;use warnings;

use lib '../lib';
use Test::More;

use_ok('Message::Transform', 'mtransform');

{   #simple
    my $message = { a => 'b' };
    mtransform($message, { x => 'y' });
    ok $message->{x} eq 'y', 'simplest transform';
}

{   #nested
    my $message = { a => 'b' };
    mtransform($message, { x => 'y', c => { d => 'e'} });
    is_deeply $message, {a => 'b', x => 'y', c => { d => 'e'}}, 'simplest nested transform';
}

{   #simple substitution
    my $message = { a => 'b' };
    mtransform($message, { x => ' specials/$message->{a}'});
    ok $message->{x} eq 'b', 'simple substitution';
}

{   #strange
    my $message = { a => 'b' };
    mtransform($message, { x => ' specialundefined$message->{a}'});
    ok $message->{x} eq ' specialundefined$message->{a}', 'unspecified special';
}
#front-door errors
eval {
    mtransform();
};
ok $@, 'no arguments not allowed';
ok $@ =~ /two HASH references required/, 'no arguments throw the correct exception';

eval {
    mtransform({});
};
ok $@, 'one argument not allowed';
ok $@ =~ /two HASH references required/, 'one argument throws the correct exception';
eval {
    mtransform({},{},{});
};
ok $@, 'three arguments not allowed';
ok $@ =~ /two HASH references required/, 'three arguments throw the correct exception';

eval {
    mtransform({},'a');
};
ok $@, 'scalar argument not allowed';
ok $@ =~ /two HASH references required/, 'one scalar agument throws the correct exception';

eval {
    mtransform('a',{});
};
ok $@, 'scalar argument not allowed: part two';
ok $@ =~ /two HASH references required/, 'one scalar agument throws the correct exception: part two';
eval {
    mtransform({},[]);
};
ok $@, 'non HASH-ref argument not allowed';
ok $@ =~ /two HASH references required/, 'non HASH-ref argument throws the correct exception';


done_testing();
