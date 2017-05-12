#!/usr/bin/perl -T

use warnings;
use strict;

#Test that we can build and compare trees

use Test::More tests => 46;

use HTML::Element;

FIRST_BLOCK: {
    my $lol = [
        'html',
        [ 'head', [ 'title', 'I like stuff!' ], ],
        [   'body', { 'lang', 'en-JP' },
            'stuff',
            [ 'p', 'um, p < 4!', { 'class' => 'par123' } ],
            [ 'div', { foo => 'bar' }, ' 1  2  3 ' ],        # at 0.1.2
            [ 'div', { fu  => 'baa' }, " 1 and 2 \xA0 3 " ], # RT #26436 test
            ['hr'],
        ]
    ];
    my $t1 = HTML::Element->new_from_lol($lol);
    isa_ok( $t1, 'HTML::Element' );

    ### added to test ->is_empty() and ->look_up()
    my $hr = $t1->find('hr');
    isa_ok( $hr, 'HTML::Element' );
    ok( $hr->is_empty(), "testing is_empty method on <hr> tag" );
    my $lookuptag = $hr->look_up( "_tag", "body" );
    is( '<body lang="en-JP">',
        $lookuptag->starttag(), "verify hr->look_up found body tag" );
    my %attrs  = $lookuptag->all_attr();
    my @attrs1 = sort keys %attrs;
    my @attrs2 = sort $lookuptag->all_attr_names();
    is_deeply( \@attrs1, \@attrs2, "is_deeply attrs" );

    # Test scalar context
    my $count = $t1->content_list;
    is( $count, 2, "Works in scalar" );

    # Test list context
    my @list = $t1->content_list;
    is( scalar @list, 2, "Should get two items back" );
    isa_ok( $list[0], 'HTML::Element' );
    isa_ok( $list[1], 'HTML::Element' );

    my $div = $t1->find_by_attribute( 'foo', 'bar' );
    isa_ok( $div, 'HTML::Element' );

    ### tests of various output formats
    is( $div->as_text(), " 1  2  3 ", "Dump element in text format" );
    is( $div->as_trimmed_text(), "1 2 3",
        "Dump element in trimmed text format" );
    is( $div->as_text_trimmed(), "1 2 3",
        "Dump element in trimmed text format" );
    is( $div->as_Lisp_form(),
        qq{("_tag" "div" "foo" "bar" "_content" (\n  " 1  2  3 "))\n},
        "Dump element as Lisp form"
    );

    is( $div->address, '0.1.2' );
    is( $div, $t1->address('0.1.2'), 'using address to get the node' );
    ok( $div->same_as($div) );
    ok( $t1->same_as($t1) );
    ok( not( $div->same_as($t1) ) );

    my $div2 = $t1->find_by_attribute( 'fu', 'baa' );
    isa_ok( $div2, 'HTML::Element' );

    ### test for RT #26436 user controlled white space
    is( $div2->as_text(), " 1 and 2 \xA0 3 ", "Dump element in text format" );
    is( $div2->as_trimmed_text(),
        "1 and 2 \xA0 3", "Dump element in trimmed text format" );
    is( $div2->as_trimmed_text( extra_chars => 'a-z\xA0' ),
        "1 2 3", "Dump element in trimmed text format without nbsp or letters");
    is( $div2->as_trimmed_text( extra_chars => '[:alpha:]' ),
        "1 2 \xA0 3", "Dump element in trimmed text format without letters");

    my $t2 = HTML::Element->new_from_lol($lol);
    isa_ok( $t2, 'HTML::Element' );
    ok( $t2->same_as($t1) );
    $t2->address('0.1.2')->attr( 'snap', 123 );
    ok( not( $t2->same_as($t1) ) );

    my $body = $t1->find_by_tag_name('body');
    isa_ok( $body, 'HTML::Element' );
    is( $body->tag, 'body' );

    my $cl = join '~', $body->content_list;
    my @detached = $body->detach_content;
    is( $cl, join '~', @detached );
    $body->push_content(@detached);
    is( $cl, join '~', $body->content_list );

    $t2->delete;
    $t1->delete;
}    # FIRST_BLOCK

TEST2: {    # for normalization
    my $t1 = HTML::Element->new_from_lol( [ 'p', 'stuff', ['hr'], 'thing' ] );
    my @start = $t1->content_list;
    is( scalar(@start), 3 );
    my $lr = $t1->content;

    # $lr is ['stuff', HTML::Element('hr'), 'thing']
    is( $lr->[0], 'stuff' );
    isa_ok( $lr->[1], 'HTML::Element' );
    is( $lr->[2], 'thing' );

    # insert some undefs
    splice @$lr, 1, 0, undef;    # insert an undef between [0] and [1]
    push @$lr, undef;            # append an undef to the end
    unshift @$lr, undef;         # prepend an undef to the front
         # $lr is [undef, 'stuff', undef, H::E('hr'), 'thing', undef]

UNNORMALIZED: {
        my $cl_count = $t1->content_list;
        my @cl       = $t1->content_list;
        is( $cl_count,   6 );
        is( scalar(@cl), $cl_count );    # also == 6
        {
            no warnings;                 # content_list contains undefs
            isnt( join( '~', @start ), join( '~', $t1->content_list ) );
        }
    }

NORMALIZED: {
        $t1->normalize_content;
        my @cl = $t1->content_list;
        eq_array( \@start, \@cl );
    }

    ok( not defined( $t1->attr('foo') ) );
    $t1->attr( 'foo', 'bar' );
    is( $t1->attr('foo'), 'bar' );
    ok( scalar( grep( 'bar', $t1->all_external_attr() ) ) );
    $t1->attr( 'foo', '' );
    ok( scalar( grep( 'bar', $t1->all_external_attr() ) ) );
    $t1->attr( 'foo', undef );    # should delete it
    ok( not grep( 'bar', $t1->all_external_attr() ) );
    $t1->delete;
}    # TEST2

EXTRA_CHARS_IS_FALSE: {
    my $h = HTML::Element->new_from_lol([p => '1  2 0  4']);
    is( $h->as_text, '1  2 0  4', "Dump p in text format" );
    is( $h->as_trimmed_text, '1 2 0 4', "Dump p in trimmed format" );
    is( $h->as_trimmed_text(extra_chars => '0'), '1 2 4',
        "Dump p in trimmed format without 0" );
}
