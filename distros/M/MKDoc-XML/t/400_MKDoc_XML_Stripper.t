#!/usr/bin/perl
use lib qw (../lib lib);
use Test::More 'no_plan';
use strict;
use warnings;
use MKDoc::XML::Token;
use MKDoc::XML::Stripper;


# let's test this _node_to_tag business
{
    my $r;
    
    $r = MKDoc::XML::Stripper::_node_to_tag ( { _tag => 'b', _open => 1 } );
    is ($r, '<b>');
    
    $r = MKDoc::XML::Stripper::_node_to_tag ( { _tag => 'b', _close => 1 } );
    is ($r, '</b>');
    
    $r = MKDoc::XML::Stripper::_node_to_tag ( { _tag => 'b', _open => 1, _close => 1 } );
    is ($r, '<b />');
    
    $r = MKDoc::XML::Stripper::_node_to_tag ( { _tag => 'b', _open => 1, extra => "foo" } );
    is ($r, '<b extra="foo">');
    
    $r = MKDoc::XML::Stripper::_node_to_tag ( { _tag => 'b', _close => 1, extra => "foo" } );
    is ($r, '</b>');
    
    $r = MKDoc::XML::Stripper::_node_to_tag ( { _tag => 'b', _open => 1, _close => 1, extra => "foo" } );
    is ($r, '<b extra="foo" />');
    
    $r = MKDoc::XML::Stripper::_node_to_tag ( { _tag => 'b', _open => 1, extra => "'foo'" } );
    is ($r, '<b extra="\'foo\'">');
    
    $r = MKDoc::XML::Stripper::_node_to_tag ( { _tag => 'b', _close => 1, extra => "'foo'" } );
    is ($r, '</b>');
    
    $r = MKDoc::XML::Stripper::_node_to_tag ( { _tag => 'b', _open => 1, _close => 1, extra => "'foo'" } );
    is ($r, '<b extra="\'foo\'" />');
    
    $r = MKDoc::XML::Stripper::_node_to_tag ( { _tag => 'b', _open => 1, extra => "\"foo\"" } );
    is ($r, '<b extra=\'"foo"\'>');
    
    $r = MKDoc::XML::Stripper::_node_to_tag ( { _tag => 'b', _close => 1, extra => "\"foo\"" } );
    is ($r, '</b>');
    
    $r = MKDoc::XML::Stripper::_node_to_tag ( { _tag => 'b', _open => 1, _close => 1, extra => "\"foo\"" } );
    is ($r, '<b extra=\'"foo"\' />');
}


# now let's perform some tests on MKDoc::XML::Stripper objects
{
    my $s = new MKDoc::XML::Stripper;
    ok ($s->isa ('MKDoc::XML::Stripper'));
    
    # allow p along with 'class' and 'id' attributes
    $s->allow (qw /p class id/);
    ok ($s->{p});
    is (ref $s->{p}, 'HASH');
    ok ($s->{p}->{class});
    ok ($s->{p}->{id});
    ok (!$s->{p}->{p});
    
    # let's see if the 'strip' method works...
    my $token = undef;
    
    $token = new MKDoc::XML::Token ('hello');
    ok ($s->strip ($token));
    is ($s->strip ($token)->as_string, 'hello');

    $token = new MKDoc::XML::Token ('<hello>');
    ok (!$s->strip ($token));

    $token = new MKDoc::XML::Token ('</hello>');
    ok (!$s->strip ($token));

    $token = new MKDoc::XML::Token ('<hello />');
    ok (!$s->strip ($token));

    $token = new MKDoc::XML::Token ('<hello name="foo" />');
    ok (!$s->strip ($token));

    $token = new MKDoc::XML::Token ('<hello name=\'foo\' />');
    ok (!$s->strip ($token));

    $token = new MKDoc::XML::Token ('<hello name="foo">');
    ok (!$s->strip ($token));

    $token = new MKDoc::XML::Token ('<hello name=\'foo\'>');
    ok (!$s->strip ($token));

    $token = new MKDoc::XML::Token ('<p>');
    ok ($s->strip ($token));
     
    $token = new MKDoc::XML::Token ('<p class="para" id="someid" foo="bar">');
    my $r  = $s->strip ($token)->as_string();
    like ($r, qr /<p/);
    like ($r, qr /class="para"/);
    like ($r, qr /id="someid"/);
    unlike ($r, qr /foo="bar"/);
}


1;


__END__
