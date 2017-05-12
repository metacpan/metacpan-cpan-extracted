#!/usr/bin/perl -T

use warnings;
use strict;

#Test that we don't leak memory

use Test::More;

my $leak_trace_loaded;

# RECOMMEND PREREQ: Test::LeakTrace
BEGIN { $leak_trace_loaded = eval "use Test::LeakTrace; 1" }

plan skip_all => "Test::LeakTrace required for testing memory leaks"
    unless $leak_trace_loaded;

plan tests => 20;

use HTML::TreeBuilder;

my $lacks_weak;

sub first_block {
    my $lol = [
        'html',
        [ 'head', [ 'title', 'I like stuff!' ], ],
        [   'body', { 'lang', 'en-JP' },
            'stuff',
            [ 'p', 'um, p < 4!', { 'class' => 'par123' } ],
            [ 'div', { foo => 'bar' }, ' 1  2  3 ' ],        # at 0.1.2
            [ 'div', { fu  => 'baa' }, " 1 &nbsp; 2 \xA0 3 " ],    # RT #26436 test
            ['hr'],
        ]
    ];
    my $t1 = HTML::Element->new_from_lol($lol);

    ### added to test ->is_empty() and ->look_up()
    my $hr = $t1->find('hr');
    my $lookuptag = $hr->look_up( "_tag", "body" );
    my %attrs  = $lookuptag->all_attr();
    my @attrs1 = sort keys %attrs;
    my @attrs2 = sort $lookuptag->all_attr_names();

    # Test scalar context
    my $count = $t1->content_list;

    # Test list context
    my @list = $t1->content_list;

    my $div = $t1->find_by_attribute( 'foo', 'bar' );

    my $div2 = $t1->find_by_attribute( 'fu', 'baa' );

    my $t2 = HTML::Element->new_from_lol($lol);
    $t2->address('0.1.2')->attr( 'snap', 123 );

    my $body = $t1->find_by_tag_name('body');

    my $cl = join '~', $body->content_list;
    my @detached = $body->detach_content;
    $body->push_content(@detached);

    $t2->delete if $lacks_weak;
    $t1->delete if $lacks_weak;
} # end first_block

sub second_block {
    # for normalization
    my $t1 = HTML::Element->new_from_lol( [ 'p', 'stuff', ['hr'], 'thing' ] );
    my @start = $t1->content_list;
    my $lr = $t1->content;

    # insert some undefs
    splice @$lr, 1, 0, undef;    # insert an undef between [0] and [1]
    push @$lr, undef;            # append an undef to the end
    unshift @$lr, undef;         # prepend an undef to the front
         # $lr is [undef, 'stuff', undef, H::E('hr'), 'thing', undef]

    {
        my $cl_count = $t1->content_list;
        my @cl       = $t1->content_list;
    }

    {
        $t1->normalize_content;
        my @cl = $t1->content_list;
    }

    $t1->attr( 'foo', 'bar' );
    $t1->attr( 'foo', '' );
    $t1->attr( 'foo', undef );    # should delete it
    $t1->delete if $lacks_weak;
} # end second_block

sub empty_tree {
    my $root = HTML::TreeBuilder->new();
    $root->implicit_body_p_tag(1);
    $root->xml_mode(1);
    $root->parse('');
    $root->eof();
    $root->delete if $lacks_weak;
}

sub br_only {
    my $root = HTML::TreeBuilder->new();
    $root->implicit_body_p_tag(1);
    $root->xml_mode(1);
    $root->parse('<br />');
    $root->eof();
    $root->delete if $lacks_weak;
}

sub text_only {
    my $root = HTML::TreeBuilder->new();
    $root->implicit_body_p_tag(1);
    $root->xml_mode(1);
    $root->parse('text');
    $root->eof();
    $root->delete if $lacks_weak;
}

sub empty_table {
    my $root = HTML::TreeBuilder->new();
    $root->implicit_body_p_tag(1);
    $root->xml_mode(1);
    $root->parse('<table></table>');
    $root->eof();
    $root->delete if $lacks_weak;
}

sub escapes {
    my $root   = HTML::TreeBuilder->new();
    my $escape = 'This &#x17f;oftware has &#383;ome bugs';
    my $html   = $root->parse($escape)->eof->elementify();
    $html->delete if $lacks_weak;
}

sub other_languages {
    my $root   = HTML::TreeBuilder->new();
    my $escape = 'Geb&uuml;hr vor Ort von &euro; 30,- pro Woche';   # RT 14212
    my $html   = $root->parse($escape)->eof;
    $html->delete if $lacks_weak;
}

sub rt_18570 {
    my $root   = HTML::TreeBuilder->new();
    my $escape = 'This &sim; is a twiddle';
    my $html   = $root->parse($escape)->eof->elementify();
    $html->delete if $lacks_weak;
}

sub rt_18571 {
    my $root = HTML::TreeBuilder->new();
    my $html = $root->parse('<b>$self->escape</b>')->eof->elementify();
    $html->delete if $lacks_weak;
}

# Try with weak refs, if available:
SKIP: {
    skip('Scalar::Util lacks support for weak references', 10)
        unless HTML::Element->Use_Weak_Refs;

    no_leaks_ok(\&first_block, 'first block has no leaks with weak refs');
    no_leaks_ok(\&second_block, 'second block has no leaks with weak refs');
    no_leaks_ok(\&empty_tree, 'empty_tree has no leaks with weak refs');
    no_leaks_ok(\&br_only, 'br_only has no leaks with weak refs');
    no_leaks_ok(\&text_only, 'text_only has no leaks with weak refs');
    no_leaks_ok(\&empty_table, 'empty_table has no leaks with weak refs');
    no_leaks_ok(\&escapes, 'escapes has no leaks with weak refs');
    no_leaks_ok(\&other_languages, 'other_languages has no leaks with weak refs');
    no_leaks_ok(\&rt_18570, 'rt_18570 has no leaks with weak refs');
    no_leaks_ok(\&rt_18571, 'rt_18571 has no leaks with weak refs');
}

# Try again without weak refs:
$lacks_weak = 1;
HTML::Element->Use_Weak_Refs(0);

no_leaks_ok(\&first_block, 'first block has no leaks without weak refs');
no_leaks_ok(\&second_block, 'second block has no leaks without weak refs');
no_leaks_ok(\&empty_tree, 'empty_tree has no leaks without weak refs');
no_leaks_ok(\&br_only, 'br_only has no leaks without weak refs');
no_leaks_ok(\&text_only, 'text_only has no leaks without weak refs');
no_leaks_ok(\&empty_table, 'empty_table has no leaks without weak refs');
no_leaks_ok(\&escapes, 'escapes has no leaks without weak refs');
no_leaks_ok(\&other_languages, 'other_languages has no leaks without weak refs');
no_leaks_ok(\&rt_18570, 'rt_18570 has no leaks without weak refs');
no_leaks_ok(\&rt_18571, 'rt_18571 has no leaks without weak refs');
