#!/usr/bin/perl -T

use warnings;
use strict;

use Test::More;

BEGIN {
    plan skip_all => "Weakref support required"
      unless eval "use Scalar::Util qw(weaken); 1";

    plan tests => 8;
}

#Test that we do not need to call ->delete to free memory

BEGIN {
    our @OBJECTS;

    no strict 'refs';
    *{'CORE::GLOBAL::bless'} = sub {
        my $reference = shift;
        my $class     = @_ ? shift : scalar caller;
        my $object    = CORE::bless($reference, $class);
        our $in_core_bless;
        if ($object->isa('HTML::Element') && !$in_core_bless) {
            local $in_core_bless = 1;
            push @OBJECTS, $object;
            weaken($OBJECTS[-1]);
        }
        return $object;
      };

      sub object_count { return 0 + grep { defined($_) } @OBJECTS; }
      sub clear_objects { @OBJECTS = () }

      use_ok("HTML::TreeBuilder", '-weak');
}

{

    # By default HTML::Parser will convert the &amp; to &
    my $tree = HTML::TreeBuilder->new_from_content('&amp;foo; &bar;');

    ok(object_count() > 0);
    $tree = undef;
    is(object_count(), 0);
    clear_objects();
}

{

    # ignoring entities when parsing source makes it work like you expect XML to
    my $tree = HTML::TreeBuilder->new(no_expand_entities => 1);
    $tree->parse("<p>&amp;foo; &bar; &#39; &l</p>");

    ok(object_count() > 0);
    $tree = undef;
    is(object_count(), 0);
    clear_objects();
}

{

    my $lol = [
        'html',
        ['head', ['title', 'I like stuff!'],],
        [   'body', {'lang', 'en-JP'},
            'stuff',
            ['p', 'um, p < 4!', {'class' => 'par123'}],
            ['div', {foo => 'bar'}, ' 1  2  3 '],              # at 0.1.2
            ['div', {fu  => 'baa'}, " 1 &nbsp; 2 \xA0 3 "],    # RT #26436 test
            ['hr'],
        ]
    ];

    my $tree = HTML::Element->new_from_lol($lol);

    my $start_count = object_count();
    ok($start_count > 0);
    my ($body) = $tree->look_down(_tag => 'body');
    $tree = undef;
    ok(object_count() < $start_count);
    $body = undef;
    is(object_count(), 0);
    clear_objects();
}
