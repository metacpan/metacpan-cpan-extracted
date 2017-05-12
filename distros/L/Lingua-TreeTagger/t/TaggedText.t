#!/usr/bin/perl

use Test::More tests => 12;

use Lingua::TreeTagger;

BEGIN {
    use_ok( 'Lingua::TreeTagger::TaggedText' ) || print "Bail out!
";
}


my @sample_tagged_lines = (
    "<lines>\n",
    "original1\ttag1\tlemma1\n",
    "original2\ttag2\tlemma2\n",
    "original3\ttag3\tlemma3\n",
    "</lines>\n",
);

eval {
    my $bad_tagged_text = Lingua::TreeTagger::TaggedText->new(
        \@sample_tagged_lines
    );
};

like(
    $@,
    qr/Attempt to create/,
    'constructor correctly croaks in case of missing argument'
);




my $tagger = eval { Lingua::TreeTagger->new(
    'language' => 'english-utf8',
) };

SKIP: {
    skip "English parameter file is not installed", 10
      if $@ =~ /no parameter file for language english/;

    my $tagged_text = Lingua::TreeTagger::TaggedText->new(
        \@sample_tagged_lines,
        $tagger
    );

    cmp_ok(
        ref( $tagged_text ), 'eq', 'Lingua::TreeTagger::TaggedText',
        'is a Lingua::TreeTagger::TaggedText'
    );

    can_ok( $tagged_text, qw(
        new
        sequence
        length
        _creator
        _fields
        as_text
        as_XML
        _get_fields
        _check_requested_fields)
    );

    cmp_ok(
        $tagged_text->as_text(), 'eq', join( q{}, @sample_tagged_lines ),
        'method as_text works fine with default settings'
    );

    cmp_ok(
        $tagged_text->as_text( {
            'fields'          => [ qw( lemma original ) ],
            'field_delimiter' => q{:},
            'token_delimiter' => q{ },
        } ),
        'eq',
        "<lines> lemma1:original1 lemma2:original2 lemma3:original3 </lines> ",
        'method as_text works fine with custom settings'
    );

    eval {
        $tagged_text->as_text( { 'fields' => [ ] } );
    };

    like(
        $@,
        qr/empty 'field' parameter/,
        'method as_text correctly croaks when parameter field is an empty list'
    );

    eval {
        $tagged_text->_check_requested_fields( qw( lemma dummy1 dummy2 ) );
    };

    like(
        $@,
        qr/\(dummy1, dummy2\)/,
        'method _check_requested_fields correctly croaks at unavailable fields'
    );

    cmp_ok(
        $tagged_text->as_XML(),
        'eq',
            qq{<lines>\n}
          . qq{<w lemma="lemma1" type="tag1">original1</w>\n}
          . qq{<w lemma="lemma2" type="tag2">original2</w>\n}
          . qq{<w lemma="lemma3" type="tag3">original3</w>\n}
          . qq{</lines>\n},
        'method as_XML works fine with default settings'
    );

    my $attributes_ref = {
        'original'  => 'bar',
        'lemma'     => 'baz',
    };

    my @attributes_keys = keys %$attributes_ref;

    if ( $attributes_keys[0] eq 'original' ) {
        cmp_ok(
            $tagged_text->as_XML( {
                'element'       => 'foo',
                'content'       => 'tag',
                'attributes'    => $attributes_ref,
            } ),
            'eq',
                qq{<lines>\n}
              . qq{<foo baz="lemma1" bar="original1">tag1</foo>\n}
              . qq{<foo baz="lemma2" bar="original2">tag2</foo>\n}
              . qq{<foo baz="lemma3" bar="original3">tag3</foo>\n}
              . qq{</lines>\n},
            'method as_XML works fine with custom settings'
        );
    }
    else {
        cmp_ok(
            $tagged_text->as_XML( {
                'element'       => 'foo',
                'content'       => 'tag',
                'attributes'    => $attributes_ref,
            } ),
            'eq',
                qq{<lines>\n}
              . qq{<foo baz="lemma1" bar="original1">tag1</foo>\n}
              . qq{<foo baz="lemma2" bar="original2">tag2</foo>\n}
              . qq{<foo baz="lemma3" bar="original3">tag3</foo>\n}
              . qq{</lines>\n},
            'method as_XML works fine with custom settings'
        );
    }

    eval {
        $tagged_text->as_XML( {
            'attributes'    => {
                'original'      => q{},
            },
        } );
    };

    like(
        $@,
        qr/Empty attribute names/,
        'method as_XML correctly croaks at empty attribute names'
    );

    eval {
        $tagged_text->as_XML( { 'element' => q{} } );
    };

    like(
        $@,
        qr/empty 'element' parameter/,
        'method as_XML correctly croaks at empty element parameter'
    );
}

