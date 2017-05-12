# -------------------------------------------------------------------------------------
# MKDoc::XML::Tokenizer
# -------------------------------------------------------------------------------------
# Author : Jean-Michel Hiver.
# Copyright : (c) MKDoc Holdings Ltd, 2003
#
# This module turns an XML string into a list of tokens and returns this list.
# It is using Robert D. Cameron "REX: XML Shallow Parsing with Regular Expressions"
#
# This module is distributed under the same license as Perl itself.
# -------------------------------------------------------------------------------------
package MKDoc::XML::Tokenizer;
use MKDoc::XML::Token;
use strict;
use warnings;

our $prev_token;

# REX/Perl 1.0 
# Robert D. Cameron "REX: XML Shallow Parsing with Regular Expressions",
# Technical Report TR 1998-17, School of Computing Science, Simon Fraser 
# University, November, 1998.
# Copyright (c) 1998, Robert D. Cameron. 
# The following code may be freely used and distributed provided that
# this copyright and citation notice remains intact and that modifications
# or additions are clearly identified.
#
# Additions:
# ----------
#   added 'my' and 'our' keywords in front of variables
#   I like strict mode :)
my $TextSE = "[^<]+";
my $UntilHyphen = "[^-]*-";
my $Until2Hyphens = "$UntilHyphen(?:[^-]$UntilHyphen)*-";
my $CommentCE = "$Until2Hyphens>?";
my $UntilRSBs = "[^\\]]*](?:[^\\]]+])*]+";
my $CDATA_CE = "$UntilRSBs(?:[^\\]>]$UntilRSBs)*>";
my $S = "[ \\n\\t\\r]+";
my $NameStrt = "[A-Za-z_:]|[^\\x00-\\x7F]";
my $NameChar = "[A-Za-z0-9_:.-]|[^\\x00-\\x7F]";
my $Name = "(?:$NameStrt)(?:$NameChar)*";
my $QuoteSE = "\"[^\"]*\"|'[^']*'";
my $DT_IdentSE = "$S$Name(?:$S(?:$Name|$QuoteSE))*";
my $MarkupDeclCE = "(?:[^\\]\"'><]+|$QuoteSE)*>";
my $S1 = "[\\n\\r\\t ]";
my $UntilQMs = "[^?]*\\?+";
my $PI_Tail = "\\?>|$S1$UntilQMs(?:[^>?]$UntilQMs)*>";
my $DT_ItemSE = "<(?:!(?:--$Until2Hyphens>|[^-]$MarkupDeclCE)|\\?$Name(?:$PI_Tail))|%$Name;|$S";
my $DocTypeCE = "$DT_IdentSE(?:$S)?(?:\\[(?:$DT_ItemSE)*](?:$S)?)?>?";
my $DeclCE = "--(?:$CommentCE)?|\\[CDATA\\[(?:$CDATA_CE)?|DOCTYPE(?:$DocTypeCE)?";
my $PI_CE = "$Name(?:$PI_Tail)?";
my $EndTagCE = "$Name(?:$S)?>?";
my $AttValSE = "\"[^<\"]*\"|'[^<']*'";
my $ElemTagCE = "$Name(?:$S$Name(?:$S)?=(?:$S)?(?:$AttValSE))*(?:$S)?/?>?";
my $MarkupSPE = "<(?:!(?:$DeclCE)?|\\?(?:$PI_CE)?|/(?:$EndTagCE)?|(?:$ElemTagCE)?)";
our $XML_SPE = "$TextSE|$MarkupSPE";


# Rather than have this:
# sub ShallowParse { 
#   my($XML_document) = @_;
#   return $XML_document =~ /$XML_SPE/g;
# }
sub process_data
{
    my $class = shift;
    my $xml   = shift;
    
    # remove trailing whitespace
    $xml =~ s/^(?:\s|\r|\n)*\</\</s;
    $xml =~ s/\>(?:\s|\r|\n)*$/\>/s;

    local ($prev_token) = '';
    my @res  = map {
       _check_001();
       _check_002();
       $prev_token = $_;
       bless \$_, 'MKDoc::XML::Token';
    } $xml =~ /$XML_SPE/go;   

    return \@res;
}


# <p foobar>
sub _check_002
{
    $prev_token =~ /^</ or return;
    $prev_token =~ />$/ or
    die "cannot tokenize: $prev_token$_";
}


# <!-- stuff like -- that -->
sub _check_001
{
    /^<!--/ and /--$/ and die "invalid comment token: $_";
}


sub process_file
{
    my $class = shift;
    my $file  = shift;
    open FP, "<$file" || do {
	warn "Cannot read-open $file";
	return [];
    };
    
    my $data = '';
    while (<FP>) { $data .= $_ }
    close FP;
    
    return $class->process_data ($data);
}


1;


__END__


=head1 NAME

MKDoc::XML::Tokenizer - Tokenize XML the REX way


=head1 SYNOPSIS

  my $tokens = MKDoc::XML::Tokenizer->process_data ($some_xml);
  foreach my $token (@{$tokens})
  {
      print "'" . $token->as_string() . "' is text\n" if (defined $token->text());
      print "'" . $token->as_string() . "' is a self closing tag\n" if (defined $token->tag_self_close());
      print "'" . $token->as_string() . "' is an opening tag\n" if (defined $token->tag_open());
      print "'" . $token->as_string() . "' is a closing tag\n" if (defined $token->tag_close());
      print "'" . $token->as_string() . "' is a processing instruction\n" if (defined $token->pi());
      print "'" . $token->as_string() . "' is a declaration\n" if (defined $token->declaration());
      print "'" . $token->as_string() . "' is a comment\n" if (defined $token->comment());
      print "'" . $token->as_string() . "' is a tag\n" if (defined $token->tag());
      print "'" . $token->as_string() . "' is a pseudo-tag (NOT text and NOT tag)\n" if (defined $token->pseudotag());
      print "'" . $token->as_string() . "' is a leaf token (NOT opening tag)\n" if (defined $token->leaf());
  }


=head1 SUMMARY

L<MKDoc::XML::Tokenizer> is a module which uses Robert D. Cameron REX
technique to parse XML (ignore the carriage returns):

  [^<]+|<(?:!(?:--(?:[^-]*-(?:[^-][^-]*-)*->?)?|\[CDATA\[(?:[^\]]*](?:[^\]]+])
  *]+(?:[^\]>][^\]]*](?:[^\]]+])*]+)*>)?|DOCTYPE(?:[ \n\t\r]+(?:[A-Za-z_:]|[^\
  x00-\x7F])(?:[A-Za-z0-9_:.-]|[^\x00-\x7F])*(?:[ \n\t\r]+(?:(?:[A-Za-z_:]|[^\
  x00-\x7F])(?:[A-Za-z0-9_:.-]|[^\x00-\x7F])*|"[^"]*"|'[^']*'))*(?:[ \n\t\r]+)
  ?(?:\[(?:<(?:!(?:--[^-]*-(?:[^-][^-]*-)*->|[^-](?:[^\]"'><]+|"[^"]*"|'[^']*'
  )*>)|\?(?:[A-Za-z_:]|[^\x00-\x7F])(?:[A-Za-z0-9_:.-]|[^\x00-\x7F])*(?:\?>|[\
  n\r\t ][^?]*\?+(?:[^>?][^?]*\?+)*>))|%(?:[A-Za-z_:]|[^\x00-\x7F])(?:[A-Za-z0
  -9_:.-]|[^\x00-\x7F])*;|[ \n\t\r]+)*](?:[ \n\t\r]+)?)?>?)?)?|\?(?:(?:[A-Za-z
  _:]|[^\x00-\x7F])(?:[A-Za-z0-9_:.-]|[^\x00-\x7F])*(?:\?>|[\n\r\t ][^?]*\?+(?
  :[^>?][^?]*\?+)*>)?)?|/(?:(?:[A-Za-z_:]|[^\x00-\x7F])(?:[A-Za-z0-9_:.-]|[^\x
  00-\x7F])*(?:[ \n\t\r]+)?>?)?|(?:(?:[A-Za-z_:]|[^\x00-\x7F])(?:[A-Za-z0-9_:.
  -]|[^\x00-\x7F])*(?:[ \n\t\r]+(?:[A-Za-z_:]|[^\x00-\x7F])(?:[A-Za-z0-9_:.-]|
  [^\x00-\x7F])*(?:[ \n\t\r]+)?=(?:[ \n\t\r]+)?(?:"[^<"]*"|'[^<']*'))*(?:[ \n\
  t\r]+)?/?>?)?)

That's right. One big regex, and it works rather well.


=head1 DISCLAIMER

B<This module does low level XML manipulation. It will somehow parse even broken XML
and try to do something with it. Do not use it unless you know what you're doing.>


=head1 API


=head2 my $tokens = MKDoc::XML::Tokenizer->process_data ($some_xml);

Splits $some_xml into a list of L<MKDoc::XML::Token> objects and returns
an array reference to the list of tokens.


=head2 my $tokens = MKDoc::XML::Tokenizer->process_file ('/some/file.xml');

Same as MKDoc::XML::Tokenizer->process_data ($some_xml), except that it
reads $some_xml from '/some/file.xml'.


=head1 NOTES

L<MKDoc::XML::Tokenizer> works with L<MKDoc::XML::Token>, which can be used
when building a full tree is not necessary. If you need to build a tree, look
at L<MKDoc::XML::TreeBuilder>.


=head1 AUTHOR

Copyright 2003 - MKDoc Holdings Ltd.

Author: Jean-Michel Hiver

This module is free software and is distributed under the same license as Perl
itself. Use it at your own risk.


=head1 SEE ALSO

L<MKDoc::XML::Token>
L<MKDoc::XML::TreeBuilder>

=cut
