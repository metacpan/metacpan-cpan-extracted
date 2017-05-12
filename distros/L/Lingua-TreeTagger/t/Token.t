#!/usr/bin/perl

use Test::More tests => 5;

BEGIN {
    use_ok( 'Lingua::TreeTagger::Token' ) || print "Bail out!
";
}

my $pos_token = Lingua::TreeTagger::Token->new(
    'tag'           => 'tag',
    'is_SGML_tag'   => 0,
    'original'      => 'original',
    'lemma'         => 'lemma',
);

cmp_ok(
    ref( $pos_token ), 'eq', 'Lingua::TreeTagger::Token',
    'is a Lingua::TreeTagger::Token'
);

can_ok( $pos_token, qw(
    new
    is_SGML_tag
    original
    lemma
) );

eval {
    my $bad_SGML_tag = Lingua::TreeTagger::Token->new(
        'tag'           => '<tag>',
        'is_SGML_tag'   => 1,
        'original'      => 'original',
    );
};

like(
    $@,
    qr/cannot have a 'original'/,
    "constructor correctly croaks in case of conflict between 'is_SGML_tag' "
    . "and 'original' attributes"
);

eval {
    my $bad_SGML_tag = Lingua::TreeTagger::Token->new(
        'tag'           => 'tag',
        'is_SGML_tag'   => 1,
        'lemma'         => 'lemma',
    );
};

like(
    $@,
    qr/cannot have a 'lemma'/,
    "constructor correctly croaks in case of conflict between 'is_SGML_tag' "
    . "and 'lemma' attributes"
);

