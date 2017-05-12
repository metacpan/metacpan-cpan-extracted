# -------------------------------------------------------------------------------------
# MKDoc::XML::Encode
# -------------------------------------------------------------------------------------
# Author : Jean-Michel Hiver.
# Copyright : (c) MKDoc Holdings Ltd, 2003
#
# This modules encodes XML entities &amp; &gt; &lt; &quot; and &apos;.
#
# This module is distributed under the same license as Perl itself.
# -------------------------------------------------------------------------------------
package MKDoc::XML::Encode;
use warnings;
use strict;

our %XML_Encode = (
    '&' => 'amp',
    '<' => 'lt',
    '>' => 'gt',
    '"' => 'quot',
    "'" => 'apos',
);

our $XML_Encode_Pattern = join ("|", keys %XML_Encode);


sub process
{
    (@_ == 2) or warn "MKDoc::XML::Encode::process() should be called with two arguments";
    
    my $class = shift;
    my $data = join '', map { (defined $_) ? $_ : '' } @_;
    $data =~ s/($XML_Encode_Pattern)/&$XML_Encode{$1};/go;
    return $data;
}


1;


__END__


=head1 NAME

MKDoc::XML::Encode - Encodes XML entities


=head1 SYNOPSIS

  use MKDoc::XML::Encode;

  # $xml is now "Chris&apos; Baloon"
  my $xml = MKDoc::XML::Encode->process ("Chris' Baloon");


=head1 SUMMARY

MKDoc::XML::Encode is a very simple module which encodes the following entities.

  &apos;
  &quot;
  &gt;
  &lt;
  &amp;

That's it.

This module and its counterpart L<MKDoc::XML::Decode> are used by L<MKDoc::XML::Dumper>
to XML-encode and XML-decode litterals.


=head1 API

=head2 my $xml_encoded = MKDoc::XML::Encode->process ($some_string);

Does what is said in the summary.


=head1 AUTHOR

Copyright 2003 - MKDoc Holdings Ltd.

Author: Jean-Michel Hiver

This module is free software and is distributed under the same license as Perl
itself. Use it at your own risk.


=head1 SEE ALSO

L<MKDoc::XML::DecodeHO>
L<MKDoc::XML::Encode>

=cut
