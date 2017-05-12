#!/usr/bin/perl
use lib qw (../lib lib);
use Test::More 'no_plan';
use strict;
use warnings;
use MKDoc::XML::Dumper;

local $MKDoc::XML::Dumper::IndentLevel = 0;


# perl_to_xml_litteral
{
    my $res = MKDoc::XML::Dumper->perl_to_xml_litteral ('Foo');
    like ($res, qr /<litteral>Foo<\/litteral>/);
}

{
    my $res = MKDoc::XML::Dumper->perl_to_xml_litteral ('');
    like ($res, qr/<litteral><\/litteral>/);
}

{
    my $res = MKDoc::XML::Dumper->perl_to_xml_litteral ('0');
    like ($res, qr/<litteral>0<\/litteral>/);
}

{
    my $res = MKDoc::XML::Dumper->perl_to_xml_litteral (undef);
    like ($res, qr/<litteral undef="true" \/>/);
}

# perl_to_xml_backref
{
    my $ref    = [];
    my $ref_id = $ref + 0;
    
    local *MKDoc::XML::Dumper::ref_to_id  = sub { 12 };
    local $MKDoc::XML::Dumper::BackRef    = { $ref_id => $ref };
    my $res = MKDoc::XML::Dumper->perl_to_xml_backref ( $ref );
    like ($res, qr/<backref id="\d+" \/>/);
}

{
    my $ref    = [];
    my $ref_id = $ref + 0;
    
    local *MKDoc::XML::Dumper::ref_to_id  = sub { 12 };
    local $MKDoc::XML::Dumper::BackRef    = {};
    my $res = MKDoc::XML::Dumper->perl_to_xml_backref ( $ref );
    ok (not defined $res);
}

# perl_to_xml_scalar
{
    local $MKDoc::XML::Dumper::IndentLevel = 0;    
    local $MKDoc::XML::Dumper::BackRef     = {};
    my $var = 'ABCDEF';
    my $ref = bless \$var, 'Foo';
    my $res = MKDoc::XML::Dumper->perl_to_xml_scalar ($ref);
    like ($res, qr/<scalar id="\d+" bless="Foo">/);
    like ($res, qr/<\/scalar>/);
}

{
    local $MKDoc::XML::Dumper::IndentLevel = 0;    
    local $MKDoc::XML::Dumper::BackRef     = {};
    my $var = 'ABCDEF';
    my $ref = \$var;
    my $res = MKDoc::XML::Dumper->perl_to_xml_scalar ($ref);
    like ($res, qr/<scalar id="\d+">/);
    like ($res, qr/<\/scalar>/);
}

# Quickly test the Indent methods
{
    local $MKDoc::XML::Dumper::IndentLevel = 0;    
    local $MKDoc::XML::Dumper::BackRef     = {};
    MKDoc::XML::Dumper->indent_more();
    is ($MKDoc::XML::Dumper::IndentLevel, 1);
    MKDoc::XML::Dumper->indent_less();
    is ($MKDoc::XML::Dumper::IndentLevel, 0);
}

# perl_to_xml_hash
{
    local $MKDoc::XML::Dumper::IndentLevel = 0;    
    local $MKDoc::XML::Dumper::BackRef     = {};
    my $res = MKDoc::XML::Dumper->perl_to_xml_hash ( bless {}, 'Foo' );
    like ($res, qr /<hash id="\d+" bless="Foo">/);
    like ($res, qr /<\/hash>/);
}

{
    local $MKDoc::XML::Dumper::IndentLevel = 0;    
    local $MKDoc::XML::Dumper::BackRef     = {};
    my $res = MKDoc::XML::Dumper->perl_to_xml_hash ( bless { foo => 'bar' }, 'Foo' );
    like ($res, qr /<hash id="\d+" bless="Foo">/);
    like ($res, qr /<\/hash>/);
    like ($res, qr /<item key="foo">\s+<litteral>bar<\/litteral>\s+<\/item>/);
}

{
    local $MKDoc::XML::Dumper::IndentLevel = 0;    
    local $MKDoc::XML::Dumper::BackRef     = {};
    my $res = MKDoc::XML::Dumper->perl_to_xml_hash ( bless { foo => 'bar', 'baz' => 'buz' }, 'Foo' );
    like ($res, qr /<hash id="\d+" bless="Foo">/);
    like ($res, qr /<\/hash>/);
    like ($res, qr /<item key="foo">\s+<litteral>bar<\/litteral>\s+<\/item>/);
    like ($res, qr /<item key="baz">\s+<litteral>buz<\/litteral>\s+<\/item>/);
}

{
    local $MKDoc::XML::Dumper::IndentLevel = 0;    
    local $MKDoc::XML::Dumper::BackRef     = {};
    my $res = MKDoc::XML::Dumper->perl_to_xml_hash ( {} );
    like ($res, qr /<hash id="\d+">/);
    like ($res, qr /<\/hash>/);
}

{
    local $MKDoc::XML::Dumper::IndentLevel = 0;    
    local $MKDoc::XML::Dumper::BackRef     = {};
    my $res = MKDoc::XML::Dumper->perl_to_xml_hash ( { foo => 'bar' } );
    like ($res, qr /<hash id="\d+">/);
    like ($res, qr /<\/hash>/);
    like ($res, qr /<item key="foo">\s+<litteral>bar<\/litteral>\s+<\/item>/);
}

{
    local $MKDoc::XML::Dumper::IndentLevel = 0;
    local $MKDoc::XML::Dumper::BackRef     = {};
    my $res = MKDoc::XML::Dumper->perl_to_xml_hash ( { foo => 'bar', 'baz' => 'buz' } );
    like ($res, qr /<hash id="\d+">/);
    like ($res, qr /<\/hash>/);
    like ($res, qr /<item key="foo">\s+<litteral>bar<\/litteral>\s+<\/item>/);
    like ($res, qr /<item key="baz">\s+<litteral>buz<\/litteral>\s+<\/item>/);
}

# perl_to_xml_array
{
    local $MKDoc::XML::Dumper::IndentLevel = 0;
    local $MKDoc::XML::Dumper::BackRef     = {};
    my $res = MKDoc::XML::Dumper->perl_to_xml_array ( bless [], 'Foo' );
    like ($res, qr /<array id="\d+" bless="Foo">/);
    like ($res, qr /<\/array>/);
}

{
    local $MKDoc::XML::Dumper::IndentLevel = 0;
    local $MKDoc::XML::Dumper::BackRef     = {};
    my $res = MKDoc::XML::Dumper->perl_to_xml_array ( bless [ qw /foo bar/ ], 'Foo' );
    like ($res, qr /<array id="\d+" bless="Foo">/);
    like ($res, qr /<\/array>/);
    like ($res, qr /<item key="0">\s+<litteral>foo<\/litteral>\s+<\/item>/);
    like ($res, qr /<item key="1">\s+<litteral>bar<\/litteral>\s+<\/item>/);
}

{
    local $MKDoc::XML::Dumper::IndentLevel = 0;
    local $MKDoc::XML::Dumper::BackRef     = {};
    my $res = MKDoc::XML::Dumper->perl_to_xml_array ( bless [ qw /foo bar baz buz/ ], 'Foo' );
    like ($res, qr /<array id="\d+" bless="Foo">/);
    like ($res, qr /<\/array>/);
    like ($res, qr /<item key="0">\s+<litteral>foo<\/litteral>\s+<\/item>/);
    like ($res, qr /<item key="1">\s+<litteral>bar<\/litteral>\s+<\/item>/);
    like ($res, qr /<item key="2">\s+<litteral>baz<\/litteral>\s+<\/item>/);
    like ($res, qr /<item key="3">\s+<litteral>buz<\/litteral>\s+<\/item>/);
}

{
    local $MKDoc::XML::Dumper::IndentLevel = 0;
    local $MKDoc::XML::Dumper::BackRef     = {};
    my $res = MKDoc::XML::Dumper->perl_to_xml_array ( [] );
    like ($res, qr /<array id="\d+">/);
    like ($res, qr /<\/array>/);
}


{
    local $MKDoc::XML::Dumper::IndentLevel = 0;
    local $MKDoc::XML::Dumper::BackRef     = {};
    my $res = MKDoc::XML::Dumper->perl_to_xml_array ( [ qw /foo bar/ ] );
    like ($res, qr /<array id="\d+">/);
    like ($res, qr /<\/array>/);
    like ($res, qr /<item key="0">\s+<litteral>foo<\/litteral>\s+<\/item>/);
    like ($res, qr /<item key="1">\s+<litteral>bar<\/litteral>\s+<\/item>/);
}

{
    local $MKDoc::XML::Dumper::IndentLevel = 0;
    local $MKDoc::XML::Dumper::BackRef     = {};
    my $res = MKDoc::XML::Dumper->perl_to_xml_array ( [ qw /foo bar baz buz/ ] );
    like ($res, qr /<array id="\d+">/);
    like ($res, qr /<\/array>/);
    like ($res, qr /<item key="0">\s+<litteral>foo<\/litteral>\s+<\/item>/);
    like ($res, qr /<item key="1">\s+<litteral>bar<\/litteral>\s+<\/item>/);
    like ($res, qr /<item key="2">\s+<litteral>baz<\/litteral>\s+<\/item>/);
    like ($res, qr /<item key="3">\s+<litteral>buz<\/litteral>\s+<\/item>/);
}

{
    # let's try some wicked stuff
    local $MKDoc::XML::Dumper::IndentLevel = 0;
    local $MKDoc::XML::Dumper::BackRef     = {};
    my $var = undef;
    $var = \"hello";
    $var = \$var;
    my $res = MKDoc::XML::Dumper->perl_to_xml ( $var );
    like ($res, qr /<ref id="\d+">\s+<backref\s+id="\d+"\s+\/>/);
}

1;


__END__
