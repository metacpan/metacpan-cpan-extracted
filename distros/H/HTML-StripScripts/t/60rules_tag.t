use strict;
use Test::More tests => 48;

BEGIN { $^W = 1 }

use HTML::StripScripts;

my %tags_b = ( 'undef'   => undef,
               '0'       => 0,
               '1'       => 1,
               'sub'     => \&b_callback,
               'hash'    => {},
               'tag_sub' => { tag => \&b_callback }
);
my %tags_default = ( 'undef'   => undef,
                     '0'       => 0,
                     '1'       => 1,
                     'sub'     => \&default_callback,
                     'hash'    => {},
                     'tag_0'   => { tag => 0 },
                     'tag_1'   => { tag => 1 },
                     'tag_sub' => { tag => \&default_callback }
);

my %results;

foreach my $b (qw(undef 0 1 sub hash tag_sub)) {
    foreach my $default (qw(undef 0 1 sub hash tag_0 tag_1 tag_sub)) {
        my $test = "${b} :: ${default}";
        test_tag( $test, $tags_b{$b}, $tags_default{$default},
                  $results{$test} );
    }
}

#===================================
sub test_tag {
#===================================
    my ( $test, $b, $default, $result ) = @_;
    my %Rules;
    if ( defined $b ) {
        $Rules{'b'} = $b;
    }

    if ( defined $default ) {
        $Rules{'*'} = $default;
    }

    my $f = HTML::StripScripts->new( { Rules => \%Rules } );

    $f->input_start_document;
    $f->input_start('<b>');
    $f->input_text('foo');
    $f->input_end('</b>');
    $f->input_start('<i>');
    $f->input_text('bar');
    $f->input_end('</i>');
    $f->input_end_document;
    is( $f->filtered_document, $result, "$test" );
}

#===================================
sub b_callback {
#===================================
    my ( $filter, $e ) = @_;
    $e->{content}
        = "[B : tag='$e->{tag}', content='$e->{content}']" . $e->{content};
    return 1;
}

#===================================
sub default_callback {
#===================================
    my ( $filter, $e ) = @_;
    $e->{content} = "[DEFAULT : tag='$e->{tag}', content='$e->{content}']"
        . $e->{content};
    return 1;
}


BEGIN {

    my $filt  = '<!--filtered-->';
    my $def_b = "[DEFAULT : tag='b', content='foo']";
    my $def_i = "[DEFAULT : tag='i', content='bar']";
    my $b     = "[B : tag='b', content='foo']";

    %results = (
        'undef :: undef'   => "<b>foo</b><i>bar</i>",
        'undef :: 0'       => "${filt}foo${filt}${filt}bar${filt}",
        'undef :: 1'       => "<b>foo</b><i>bar</i>",
        'undef :: sub'     => "<b>${def_b}foo</b><i>${def_i}bar</i>",
        'undef :: hash'    => "<b>foo</b><i>bar</i>",
        'undef :: tag_0'   => "${filt}foo${filt}${filt}bar${filt}",
        'undef :: tag_1'   => "<b>foo</b><i>bar</i>",
        'undef :: tag_sub' => "<b>${def_b}foo</b><i>${def_i}bar</i>",
        '0 :: undef'       => "${filt}foo${filt}<i>bar</i>",
        '0 :: 0'           => "${filt}foo${filt}${filt}bar${filt}",
        '0 :: 1'           => "${filt}foo${filt}<i>bar</i>",
        '0 :: sub'         => "${filt}foo${filt}<i>${def_i}bar</i>",
        '0 :: hash'        => "${filt}foo${filt}<i>bar</i>",
        '0 :: tag_0'       => "${filt}foo${filt}${filt}bar${filt}",
        '0 :: tag_1'       => "${filt}foo${filt}<i>bar</i>",
        '0 :: tag_sub'     => "${filt}foo${filt}<i>${def_i}bar</i>",
        '1 :: undef'       => "<b>foo</b><i>bar</i>",
        '1 :: 0'           => "<b>foo</b>${filt}bar${filt}",
        '1 :: 1'           => "<b>foo</b><i>bar</i>",
        '1 :: sub'         => "<b>${def_b}foo</b><i>${def_i}bar</i>",
        '1 :: hash'        => "<b>foo</b><i>bar</i>",
        '1 :: tag_0'       => "<b>foo</b>${filt}bar${filt}",
        '1 :: tag_1'       => "<b>foo</b><i>bar</i>",
        '1 :: tag_sub'     => "<b>${def_b}foo</b><i>${def_i}bar</i>",
        'sub :: undef'     => "<b>${b}foo</b><i>bar</i>",
        'sub :: 0'         => "<b>${b}foo</b>${filt}bar${filt}",
        'sub :: 1'         => "<b>${b}foo</b><i>bar</i>",
        'sub :: sub'     => "<b>${b}foo</b><i>${def_i}bar</i>",
        'sub :: hash'    => "<b>${b}foo</b><i>bar</i>",
        'sub :: tag_0'   => "<b>${b}foo</b>${filt}bar${filt}",
        'sub :: tag_1'   => "<b>${b}foo</b><i>bar</i>",
        'sub :: tag_sub' => "<b>${b}foo</b><i>${def_i}bar</i>",
        'hash :: undef'  => "<b>foo</b><i>bar</i>",
        'hash :: 0'      => "<b>foo</b>${filt}bar${filt}",
        'hash :: 1'      => "<b>foo</b><i>bar</i>",
        'hash :: sub'        => "<b>${def_b}foo</b><i>${def_i}bar</i>",
        'hash :: hash'       => "<b>foo</b><i>bar</i>",
        'hash :: tag_0'      => "<b>foo</b>${filt}bar${filt}",
        'hash :: tag_1'      => "<b>foo</b><i>bar</i>",
        'hash :: tag_sub'    => "<b>${def_b}foo</b><i>${def_i}bar</i>",
        'tag_sub :: undef'   => "<b>${b}foo</b><i>bar</i>",
        'tag_sub :: 0'       => "<b>${b}foo</b>${filt}bar${filt}",
        'tag_sub :: 1'       => "<b>${b}foo</b><i>bar</i>",
        'tag_sub :: sub'     => "<b>${b}foo</b><i>${def_i}bar</i>",
        'tag_sub :: hash'    => "<b>${b}foo</b><i>bar</i>",
        'tag_sub :: tag_0'   => "<b>${b}foo</b>${filt}bar${filt}",
        'tag_sub :: tag_1'   => "<b>${b}foo</b><i>bar</i>",
        'tag_sub :: tag_sub' => "<b>${b}foo</b><i>${def_i}bar</i>",

    );
}
