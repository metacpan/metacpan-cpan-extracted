use strict;
use Test::More tests => 11;

BEGIN {
     $^W = 1;
     eval "require Data::Dumper; import Data::Dumper";
     $@ and eval "sub Dumper {'Install Data::Dumper for detailed diagnostics'}";
}

use HTML::StripScripts;

## test required attributes
my %results;

foreach my $test ( sort keys %results ) {
    my $callback;
    {
        no strict 'refs';
        $callback = \&$test;
    }
    my $Rules =
        $test =~ /^attr/
        ? { p => { align => $callback } }
        : { p => $callback };
    test_callback( $test, $Rules, $results{$test} );
}

BEGIN {
    %results = (
        attr_accept    => '<p align="right">Normal<b>Bold</b></p>',
        attr_reject    => '<p>Normal<b>Bold</b></p>',
        attr_empty     => '<p align="">Normal<b>Bold</b></p>',
        attr_change    => '<p align="left">Normal<b>Bold</b></p>',
        tag_accept     => '<p align="right">Normal<b>Bold</b></p>',
        tag_reject_all => '',
        tag_remove_tag => 'Normal<b>Bold</b>',
        tag_change_attrs =>
            '<p style="text-align:right">Normal<b>Bold</b></p>',
        tag_change_tag =>
            '<blockquote align="right">Normal<b>Bold</b></blockquote>',
        tag_change_content => '<p align="right">Replaced Content</p>',
        tag_add_tag =>
            '<p align="right"><span style="color:red">Normal<b>Bold</b></span></p>'
        ,
    );
}

#===================================
sub test_callback {
#===================================
    my ( $test, $Rules, $result ) = @_;
    my $f = HTML::StripScripts->new( { Rules => $Rules } );

    $f->input_start_document;
    $f->input_start('<p align="right">');
    $f->input_text('Normal');
    $f->input_start('<b>');
    $f->input_text('Bold');
    $f->input_end('</b>');
    $f->input_end('</p>');
    $f->input_end_document;
    is( $f->filtered_document, $result, "$test" )
        or diag( Dumper( $Rules, $f->{_hssRules} ) );
}

#===================================
sub attr_accept {
#===================================
    my ( $filter, $tag, $attr, $val ) = @_;
    return $val;
}

#===================================
sub attr_reject {
#===================================
    my ( $filter, $tag, $attr, $val ) = @_;
    return;
}

#===================================
sub attr_empty {
#===================================
    my ( $filter, $tag, $attr, $val ) = @_;
    return '';
}

#===================================
sub attr_change {
#===================================
    my ( $filter, $tag, $attr, $val ) = @_;
    return 'left';
}

#===================================
sub tag_accept {
#===================================
    my ( $filter, $element ) = @_;
    return 1;
}

#===================================
sub tag_reject_all {
#===================================
    my ( $filter, $element ) = @_;
    return 0;
}

#===================================
sub tag_remove_tag {
#===================================
    my ( $filter, $element ) = @_;
    $element->{tag} = '';
    return 1;
}

#===================================
sub tag_change_attrs {
#===================================
    my ( $filter, $element ) = @_;
    my $attr = $element->{attr};
    if ( my $align = delete $attr->{align} ) {
        $attr->{style} = join( ';',
                               grep { defined $_ } $attr->{style},
                               'text-align:' . $align );
    }
    return 1;
}

#===================================
sub tag_change_tag {
#===================================
    my ( $filter, $element ) = @_;
    $element->{tag} = 'blockquote';
    return 1;
}

#===================================
sub tag_change_content {
#===================================
    my ( $filter, $element ) = @_;
    $element->{content} = 'Replaced Content';
    return 1;
}

#===================================
sub tag_add_tag {
#===================================
    my ( $filter, $element ) = @_;
    $element->{content}
        = '<span style="color:red">' . $element->{content} . '</span>';
    return 1;
}

