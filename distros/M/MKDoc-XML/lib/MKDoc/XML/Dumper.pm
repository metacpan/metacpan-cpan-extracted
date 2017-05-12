# -------------------------------------------------------------------------------------
# MKDoc::XML::Dumper
# -------------------------------------------------------------------------------------
# Author : Jean-Michel Hiver.
# Copyright : (c) MKDoc Holdings Ltd, 2003
#
# This module serializes / dumps / freezes Perl structures to a well-formed XML string
# and deserializes / undumps / thaws them back from XML to Perl.
#
# This module is distributed under the same license as Perl itself.
# -------------------------------------------------------------------------------------
package MKDoc::XML::Dumper;
use MKDoc::XML::Encode;
use MKDoc::XML::Decode;
use MKDoc::XML::TreeBuilder;
use Scalar::Util;
use warnings;
use strict;

use vars qw /$IndentLevel $BackRef/;
our $Compat = 0;

sub xml2perl
{
    my $class  = shift;
    my $xml    = shift;
    my (@tree) = MKDoc::XML::TreeBuilder->process_data ($xml);
    while ( (@tree and not ref $tree[0] and $tree[0] =~ /^(\s|\n|\r)*$/) or
            (@tree and ref $tree[0] and $tree[0]->{_tag} and $tree[0]->{_tag} eq '~pi') ) { shift (@tree) }

    local $BackRef = {};
    local $IndentLevel = 0;
    
    return $class->xml_to_perl ($tree[0]);
}


# SECTION THAT UNDUMPS PERL FROM XML NODE
sub xml_to_perl
{
    my $class = shift;
    @_ = map { ref $_ ? $_ : () } @_;
   
    my @res = map {
	$class->xml_to_perl_backwards_compat_perl_tag ($_) ||
	$class->xml_to_perl_backref  ($_) ||
	$class->xml_to_perl_ref      ($_) ||
	$class->xml_to_perl_scalar   ($_) ||
	$class->xml_to_perl_hash     ($_) ||
	$class->xml_to_perl_array    ($_) ||
	$class->xml_to_perl_litteral ($_)
    } @_;
    
    return pop (@res) if (@res == 1);
    return @res;
}


sub xml_to_perl_backwards_compat_perl_tag
{
    my ($class, $tree) = @_;
    ref $tree                  || return ();
    $tree->{_tag} eq 'perl'    || return ();
    
    local ($Compat) = 1;
    return $class->xml_to_perl (@{$tree->{_content}});
}


sub xml_to_perl_backref
{
    my ($class, $tree) = @_;
    ref $tree                  || return ();
    $tree->{_tag} eq 'backref' || return ();
    my $ref_id = $tree->{id}   || return ();
    exists $BackRef->{$ref_id} || return ();
    return $BackRef->{$ref_id};
}


sub xml_to_perl_ref
{
    my ($class, $tree) = @_;
    ref $tree                  || return ();
    $tree->{_tag} eq 'ref'     || return ();
    my $ref_id = $tree->{id}   || return ();
    
    my $ref = \\undef;
    bless $ref, $tree->{bless} if (defined $tree->{bless});
    $BackRef->{$ref_id} = $ref;
    
    ($$ref) = $class->xml_to_perl ( @{$tree->{_content}} );
    return $ref;
}


sub xml_to_perl_scalar
{
    my ($class, $tree) = @_;
    ref $tree                 or return ();
    $tree->{_tag} eq 'scalar' or return ();
    my $ref_id = $tree->{id}  or return ();
    
    my $ref = \\undef;
    bless $ref, $tree->{bless} if (defined $tree->{bless});
    $BackRef->{$ref_id} = $ref;

    ($$ref) = $class->xml_to_perl ( @{$tree->{_content}} );    
    return $ref;
}


sub xml_to_perl_hash
{
    my ($class, $tree) = @_;
    ref $tree                 or return ();
    $tree->{_tag} eq 'hash'   or return ();
    my $ref_id = $tree->{id}  or return ();

    my $ref = {};
    bless $ref, $tree->{bless} if (defined $tree->{bless});    
    $BackRef->{$ref_id} = $ref;
    
    my @items = map { ref $_ ? $_ : () } @{$tree->{_content}};
    foreach my $item (@items)
    {
	my $key      = $item->{key};
	if ($Compat)
	{
	    $ref->{$key} = do {
                my $stuff  = $item->{_content}->[0] || '';
                my $decode = new MKDoc::XML::Decode ('xml');
                $decode->process ($stuff);
            }
	}
	else
	{
	    my ($val)    = $class->xml_to_perl ( @{$item->{_content}} );
	    $ref->{$key} = $val;
	}
    }
    
    return $ref;
}


sub xml_to_perl_array
{
    my ($class, $tree) = @_;
    ref $tree                 or return ();
    $tree->{_tag} eq 'array'  or return ();
    my $ref_id = $tree->{id}  or return ();

    my $ref = [];
    bless $ref, $tree->{bless} if (defined $tree->{bless});    
    $BackRef->{$ref_id} = $ref;
    
    my @items = map { ref $_ ? $_ : () } @{$tree->{_content}};
    foreach my $item (@items)
    {
	my $key      = $item->{key};
	my ($val)    = $class->xml_to_perl ( @{$item->{_content}} );
	$ref->[$key] = $val;
    }
    
    return $ref;
}


sub xml_to_perl_litteral
{
    my ($class, $tree) = @_;
    ref $tree                   or return ();
    $tree->{_tag} eq 'litteral' or return ();
    return undef if ($tree->{undef} and $tree->{undef} eq 'true');
    
    my $decode = new MKDoc::XML::Decode ('xml');
    return $decode->process ($tree->{_content}->[0]);
}


#####################################################################
# DUMPS PERL STRUCTURE TO XML DATA                                  #
#####################################################################


sub perl2xml
{
    my $class = shift;
    my $ref   = shift;
    
    local $BackRef = {};
    local $IndentLevel = 0;
    
    return $class->perl_to_xml ($ref);
}


sub perl_to_xml
{
    my ($class, $ref) = @_;
    $_ = Scalar::Util::reftype ($ref) || '';

    return $class->perl_to_xml_backref  ($ref) ||
           $class->perl_to_xml_ref      ($ref) ||
           $class->perl_to_xml_scalar   ($ref) ||
	   $class->perl_to_xml_hash     ($ref) ||
	   $class->perl_to_xml_array    ($ref) ||
	   $class->perl_to_xml_litteral ($ref);
}


sub perl_to_xml_backref
{
    my ($class, $ref) = @_;
    $ref && ref $ref || return;
    
    my $ref_id = 0 + $ref;
    $BackRef->{$ref_id} || return;
    
    return $class->indent() . qq |<backref id="$ref_id" />| . "\n";
}


sub perl_to_xml_litteral
{
    my ($class, $ref) = @_;
    (defined $ref) ?
        $class->indent() . qq |<litteral>| . MKDoc::XML::Encode->process ($ref) . qq |</litteral>| . "\n" :
	$class->indent() . qq |<litteral undef="true" />| . "\n";
}


sub perl_to_xml_scalar
{
    my ($class, $ref) = @_;
    $ref && ref $ref && Scalar::Util::reftype ($ref) eq 'SCALAR' || return;
    
    my $ref_id = 0 + $ref;
    $BackRef->{$ref_id} = $ref;
    
    my $bless = Scalar::Util::blessed ($ref);
    $bless = ($bless) ? qq | bless="$bless"| : '';

    my $string = '';
    $string   .= $class->indent() . qq |<scalar id="$ref_id"$bless>| . "\n";
    $class->indent_more();
    $string   .= $class->perl_to_xml ($$ref);
    $class->indent_less();
    $string   .= $class->indent() . qq |</scalar>| . "\n";
    
    return $string;
}


sub perl_to_xml_ref
{
    my ($class, $ref) = @_;
    $ref && ref $ref && Scalar::Util::reftype ($ref) eq 'REF' || return;
    
    my $ref_id = 0 + $ref;
    $BackRef->{$ref_id} = $ref;
    
    my $bless = Scalar::Util::blessed ($ref);
    $bless = ($bless) ? qq | bless="$bless"| : '';

    my $string = '';
    $string   .= $class->indent() . qq |<ref id="$ref_id"$bless>| . "\n";
    $class->indent_more();
    $string   .= $class->perl_to_xml ($$ref);
    $class->indent_less();
    $string   .= $class->indent() . qq |</ref>| . "\n";
    
    return $string;
}


sub perl_to_xml_hash
{
    my ($class, $ref) = @_;
    $ref && ref $ref && Scalar::Util::reftype ($ref) eq 'HASH' || return;
    
    my $ref_id = 0 + $ref;
    $BackRef->{$ref_id} = $ref;
    
    my $bless = Scalar::Util::blessed ($ref);
    $bless = ($bless) ? qq | bless="$bless"| : '';
    
    my $string = '';
    $string   .= $class->indent() . qq |<hash id="$ref_id"$bless>| . "\n";
    for (keys %{$ref})
    {
	$class->indent_more();
	$string .= $class->indent() . qq |<item key="$_">| . "\n" ;
	$class->indent_more();
	$string .= $class->perl_to_xml ($ref->{$_});
	$class->indent_less();
	$string .= $class->indent() . qq |</item>| . "\n";
	$class->indent_less();
    }
    $string   .= $class->indent() . qq |</hash>| . "\n";
    
    return $string;
}


sub perl_to_xml_array
{
    my ($class, $ref) = @_;
    $ref && ref $ref && Scalar::Util::reftype ($ref) eq 'ARRAY' || return;
    
    my $ref_id = 0 + $ref;
    $BackRef->{$ref_id} = $ref;
    
    my $bless = Scalar::Util::blessed ($ref);
    $bless = ($bless) ? qq | bless="$bless"| : '';
    
    my $string = '';
    $string   .= $class->indent() . qq |<array id="$ref_id"$bless>| . "\n";
    for (my $i=0; $i < @{$ref}; $i++)
    {
	$class->indent_more();
	$string .= $class->indent() . qq |<item key="$i">| . "\n" ;
	$class->indent_more();
	$string .= $class->perl_to_xml ($ref->[$i]);
	$class->indent_less();
	$string .= $class->indent() . qq |</item>| . "\n";
	$class->indent_less();
    }
    $string   .= $class->indent() . qq |</array>| . "\n";
    
    return $string;
}


sub indent
{
    return "    " x $IndentLevel;
}


sub indent_more
{
    $IndentLevel++;
}


sub indent_less
{
    $IndentLevel--;
}


1;


__END__

=head1 NAME

MKDoc::XML::Dumper - Same as Data::Dumper, but with XML


=head1 SYNOPSIS

  use MKDoc::XML::Dumper;
  use Test::More 'no_plan';
  
  my $stuff  = [ qw /foo bar baz/, [], { hello => 'world', yo => \\'boo' } ];
  my $xml    = MKDoc::XML::Dumper->perl2xml ($stuff);
  my $stuff2 = MKDoc::XML::Dumper->xml2perl ($xml);
  is_deeply ($stuff, $stuff2); # prints 'ok'


=head1 SUMMARY

L<MKDoc::XML::Dumper> provides functionality equivalent to Data::Dumper except that
rather than serializing structures into a Perl string, it serializes them into
a generic XML file format.

Of course since XML cannot be evaled, it also provides a mechanism for undumping
the xml back into a perl structure.

L<MKDoc::XML::Dumper> supports scalar references, hash references, array references,
reference references, and litterals. It also supports circular structures and back
references to avoid creating unwanted extra copies of the same object.

That's all there is to it!


=head1 API

=head2 my $xml = MKDoc::XML::Dumper->perl2xml ($perl);


Turns $perl into an XML string. For instance:

  my $perl = [ qw /foo bar baz/, { adam => 'apple', bruno => 'berry', chris => 'cherry' } ];
  print MKDoc::XML::Dumper->perl2xml ($perl);'


Will print something like:

  <array id="135338912">
    <item key="0">
      <litteral>foo</litteral>
    </item>
    <item key="1">
      <litteral>bar</litteral>
    </item>
    <item key="2">
      <litteral>baz</litteral>
    </item>
    <item key="3">
      <hash id="135338708">
        <item key="bruno">
          <litteral>berry</litteral>
        </item>
        <item key="adam">
          <litteral>apple</litteral>
        </item>
        <item key="chris">
          <litteral>cherry</litteral>
        </item>
      </hash>
    </item>
  </array>


As you can see, every object has an id. This allows for backreferencing, so:

  my $perl = undef;
  $perl    = \$perl;
  print MKDoc::XML::Dumper->perl2xml ($perl);'

  
Prints something like:

  <ref id="135338888">
    <backref id="135338888" />
  </ref>


For the curious, these identifiers are computed using some perl black magic:

  my $id = 0 + $reference;


=head2 my $perl = MKDoc::XML::Dumper->perl2xml ($xml);

Does the exact reverse operation as xml2perl().


=head1 AUTHOR

Copyright 2003 - MKDoc Holdings Ltd.

Author: Jean-Michel Hiver

This module is free software and is distributed under the same license as Perl
itself. Use it at your own risk.


=head1 SEE ALSO

L<MKDoc::XML::Decode>
L<MKDoc::XML::Encode>

=cut
