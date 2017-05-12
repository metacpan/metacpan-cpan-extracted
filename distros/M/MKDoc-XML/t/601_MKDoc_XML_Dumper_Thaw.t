#!/usr/bin/perl
use lib qw (../lib lib);
use Test::More 'no_plan';
use strict;
use warnings;
use MKDoc::XML::Dumper;

local $MKDoc::XML::Dumper::IndentLevel = 0;


# xml_to_perl_litteral
{
    my $tree = { _tag => 'litteral', _content => [ 'Foo' ] };
    my $res  = MKDoc::XML::Dumper->xml_to_perl_litteral ($tree);
    is ($res, 'Foo');
}

{
    my $tree = { _tag => 'litteral', _content => [ '' ] };
    my $res  = MKDoc::XML::Dumper->xml_to_perl_litteral ($tree);
    is ($res, '');
}

{
    my $tree = { _tag => 'litteral', _content => [ '0' ] };
    my $res  = MKDoc::XML::Dumper->xml_to_perl_litteral ($tree);
    is ($res, '0');
}

{
    my $tree = { _tag => 'litteral', undef => 'true' };
    my $res  = MKDoc::XML::Dumper->xml_to_perl_litteral ($tree);
    ok (not defined $res);
}


# xml_to_perl_backref
{
    my $ref    = [];
    my $ref_id = $ref + 0;
    
    local $MKDoc::XML::Dumper::BackRef = { 12 => 'Foo' };
    my $res = MKDoc::XML::Dumper->xml_to_perl_backref ( { _tag => 'backref', id => '12' } );
    is ($res, 'Foo');
}

{
    my $ref    = [];
    my $ref_id = $ref + 0;
    
    local $MKDoc::XML::Dumper::BackRef = {};
    my $res = MKDoc::XML::Dumper->xml_to_perl_backref ( { _tag => 'backref', id => '12' } );
    ok (not defined $res);
}


# xml_to_perl_scalar
{
    local $MKDoc::XML::Dumper::IndentLevel = 0;    
    local $MKDoc::XML::Dumper::BackRef     = {};
    my $tree = { _tag => 'scalar', id => '1', bless => 'Foo', _content => [
	           { _tag => 'litteral', _content => [ 'ABCDEF' ] }
	       ] };
    
    my $res = MKDoc::XML::Dumper->xml_to_perl_scalar ($tree);
    ok (ref $res);
    ok ($res->isa ('Foo'));
    is ($$res, 'ABCDEF');
}

{
    local $MKDoc::XML::Dumper::IndentLevel = 0;    
    local $MKDoc::XML::Dumper::BackRef     = {};
    my $tree = { _tag => 'scalar', id => '1', _content => [
	           { _tag => 'litteral', _content => [ 'ABCDEF' ] }
	       ] };
    
    my $res = MKDoc::XML::Dumper->xml_to_perl_scalar ($tree);
    ok (ref $res);
    is (ref $res, 'SCALAR');
    is ($$res, 'ABCDEF');
}


# perl_to_xml_hash
{
    local $MKDoc::XML::Dumper::IndentLevel = 0;    
    local $MKDoc::XML::Dumper::BackRef     = {};
    my $tree = { _tag => 'hash', id => '1', bless => 'Foo' };
    my $res  = MKDoc::XML::Dumper->xml_to_perl_hash ($tree);
    
    ok (ref $res);
    ok ($res->isa ('Foo'));
    ok ($res =~ /HASH/);
    ok (scalar keys %{$res} == 0);
}


{
    local $MKDoc::XML::Dumper::IndentLevel = 0;    
    local $MKDoc::XML::Dumper::BackRef     = {};
    my $tree = { _tag => 'hash', id => '1', bless => 'Foo', _content => [
	           { _tag => 'item', key => 'foo', _content => [
		       { _tag => 'litteral', _content => [ 'bar' ] }
		      ] } ] };
    
    my $res  = MKDoc::XML::Dumper->xml_to_perl_hash ($tree);
    
    ok (ref $res);
    ok ($res->isa ('Foo'));
    ok ($res =~ /HASH/);
    ok (scalar keys %{$res} == 1);
    is ($res->{foo}, 'bar');
}


{
    local $MKDoc::XML::Dumper::IndentLevel = 0;    
    local $MKDoc::XML::Dumper::BackRef     = {};
    my $tree = { _tag => 'hash', id => '1', bless => 'Foo', _content => [
	           { _tag => 'item', key => 'foo', _content => [
		       { _tag => 'litteral', _content => [ 'bar' ] }
		      ] },
	           { _tag => 'item', key => 'baz', _content => [
		       { _tag => 'litteral', _content => [ 'buz' ] }
		      ] }
		  ] };
    
    my $res  = MKDoc::XML::Dumper->xml_to_perl_hash ($tree);
    
    ok (ref $res);
    ok ($res->isa ('Foo'));
    ok ($res =~ /HASH/);
    ok (scalar keys %{$res} == 2);
    is ($res->{foo}, 'bar');
    is ($res->{baz}, 'buz');
}

{
    local $MKDoc::XML::Dumper::IndentLevel = 0;    
    local $MKDoc::XML::Dumper::BackRef     = {};
    my $tree = { _tag => 'hash', id => '1' };
    my $res  = MKDoc::XML::Dumper->xml_to_perl_hash ($tree);
    
    ok (ref $res);
    is (ref $res, 'HASH');
    ok (scalar keys %{$res} == 0);
}

{
    local $MKDoc::XML::Dumper::IndentLevel = 0;    
    local $MKDoc::XML::Dumper::BackRef     = {};
    my $tree = { _tag => 'hash', id => '1', _content => [
	           { _tag => 'item', key => 'foo', _content => [
		       { _tag => 'litteral', _content => [ 'bar' ] }
		      ] } ] };
    
    my $res  = MKDoc::XML::Dumper->xml_to_perl_hash ($tree);
    
    ok (ref $res);
    is (ref $res, 'HASH');
    ok (scalar keys %{$res} == 1);
    is ($res->{foo}, 'bar');
}


{
    local $MKDoc::XML::Dumper::IndentLevel = 0;    
    local $MKDoc::XML::Dumper::BackRef     = {};
    my $tree = { _tag => 'hash', id => '1', _content => [
	           { _tag => 'item', key => 'foo', _content => [
		       { _tag => 'litteral', _content => [ 'bar' ] }
		      ] },
	           { _tag => 'item', key => 'baz', _content => [
		       { _tag => 'litteral', _content => [ 'buz' ] }
		      ] }
		  ] };
    
    my $res  = MKDoc::XML::Dumper->xml_to_perl_hash ($tree);
    
    ok (ref $res);
    is (ref $res, 'HASH');
    ok (scalar keys %{$res} == 2);
    is ($res->{foo}, 'bar');
    is ($res->{baz}, 'buz');
}


# perl_to_xml_hash
{
    local $MKDoc::XML::Dumper::IndentLevel = 0;    
    local $MKDoc::XML::Dumper::BackRef     = {};
    my $tree = { _tag => 'array', id => '1', bless => 'Foo' };
    my $res  = MKDoc::XML::Dumper->xml_to_perl_array ($tree);
    
    ok (ref $res);
    ok ($res->isa ('Foo'));
    ok ($res =~ /ARRAY/);
    ok (@{$res} == 0);
}


{
    local $MKDoc::XML::Dumper::IndentLevel = 0;    
    local $MKDoc::XML::Dumper::BackRef     = {};
    my $tree = { _tag => 'array', id => '1', bless => 'Foo', _content => [
	           { _tag => 'item', key => '0', _content => [
		       { _tag => 'litteral', _content => [ 'bar' ] }
		      ] } ] };
    
    my $res  = MKDoc::XML::Dumper->xml_to_perl_array ($tree);
    
    ok (ref $res);
    ok ($res->isa ('Foo'));
    ok ($res =~ /ARRAY/);
    ok (@{$res} == 1);
    is ($res->[0], 'bar');
}


{
    local $MKDoc::XML::Dumper::IndentLevel = 0;    
    local $MKDoc::XML::Dumper::BackRef     = {};
    my $tree = { _tag => 'array', id => '1', bless => 'Foo', _content => [
	           { _tag => 'item', key => '0', _content => [
		       { _tag => 'litteral', _content => [ 'bar' ] }
		      ] },
	           { _tag => 'item', key => '1', _content => [
		       { _tag => 'litteral', _content => [ 'buz' ] }
		      ] }
		  ] };
    
    my $res  = MKDoc::XML::Dumper->xml_to_perl_array ($tree);
    
    ok (ref $res);
    ok ($res->isa ('Foo'));
    ok ($res =~ /ARRAY/);
    ok (@{$res} == 2);
    is ($res->[0], 'bar');
    is ($res->[1], 'buz');
}

{
    local $MKDoc::XML::Dumper::IndentLevel = 0;    
    local $MKDoc::XML::Dumper::BackRef     = {};
    my $tree = { _tag => 'array', id => '1' };
    my $res  = MKDoc::XML::Dumper->xml_to_perl_array ($tree);
    
    ok (ref $res);
    is (ref $res, 'ARRAY');
    ok (@{$res} == 0);
}

{
    local $MKDoc::XML::Dumper::IndentLevel = 0;    
    local $MKDoc::XML::Dumper::BackRef     = {};
    my $tree = { _tag => 'array', id => '1', _content => [
	           { _tag => 'item', key => '0', _content => [
		       { _tag => 'litteral', _content => [ 'bar' ] }
		      ] } ] };
    
    my $res  = MKDoc::XML::Dumper->xml_to_perl_array ($tree);
    
    ok (ref $res);
    is (ref $res, 'ARRAY');
    ok (@{$res} == 1);
    is ($res->[0], 'bar');
}


{
    local $MKDoc::XML::Dumper::IndentLevel = 0;    
    local $MKDoc::XML::Dumper::BackRef     = {};
    my $tree = { _tag => 'array', id => '1', _content => [
	           { _tag => 'item', key => '0', _content => [
		       { _tag => 'litteral', _content => [ 'bar' ] }
		      ] },
	           { _tag => 'item', key => '1', _content => [
		       { _tag => 'litteral', _content => [ 'buz' ] }
		      ] }
		  ] };
    
    my $res  = MKDoc::XML::Dumper->xml_to_perl_array ($tree);
    
    ok (ref $res);
    is (ref $res, 'ARRAY');
    ok (@{$res} == 2);
    is ($res->[0], 'bar');
    is ($res->[1], 'buz');
}


{
    # let's try some wicked stuff
    local $MKDoc::XML::Dumper::BackRef = {};
    my $tree =
    { _tag => 'ref', id => '1', _content => [
	{ _tag => 'backref', id => '1' } ] };
    
    my $res = MKDoc::XML::Dumper->xml_to_perl ( $tree );
    ok (ref $res);
    is (ref $res, 'REF');
    is ($$res, $res);
}


1;


__END__
