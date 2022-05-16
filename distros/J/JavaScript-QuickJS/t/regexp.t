#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::FailWarnings;

use JavaScript::QuickJS;
use Scalar::Util;

my $regexp = JavaScript::QuickJS->new()->eval('/foo/g');

my @props = (
    [ flags => 'g' ],
    [ global => bool(1) ],
    [ hasIndices => bool(0) ],
    [ multiline => bool(0) ],
    [ source => 'foo' ],
    [ sticky => bool(0) ],
    [ unicode => bool(0) ],
    [ lastIndex => 0 ],
);

for my $p_ar (@props) {
    my ($propname, $value) = @$p_ar;

    cmp_deeply( $regexp->$propname(), $value, "$propname()" );
}

cmp_deeply( $regexp->test('fo'), bool(0), 'test() w/ non-match' );
cmp_deeply( $regexp->test('fooo'), bool(1), 'test() w/ match' );

is(
    $regexp->exec('fo'),
    undef,
    'exec() w/ non-match',
);

is_deeply(
    $regexp->exec('foooo'),
    ['foo'],
    'exec() w/ match',
);

#----------------------------------------------------------------------

{
    my $js = JavaScript::QuickJS->new();
    my $regexp = $js->eval('/foo/g');

    $js->set_globals(
        re_from_perl => $regexp,
    );

    my $match = $js->eval('re_from_perl.exec("foooo")');

    cmp_deeply($match, ['foo'], 'RegExp to Perl, back to JS');

    eval { JavaScript::QuickJS->new()->set_globals( bad => $regexp ) };
    my $err = $@;

    my $re_class = ref $regexp;

    cmp_deeply(
        $err,
        all(
            re( qr<\Q$re_class\E> ),
        ),
        'error when mismatched Perl RegExp object given',
    );
}

done_testing;
