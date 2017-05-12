package HTML::Doctype;
use 5.008;
use strict;
use warnings;

our $VERSION = '0.02';

package HTML::Doctype::Detector;
use strict;
use warnings;

sub new
{
    my $class = shift;
    my $p = shift;
    bless { p => $p }, $class;
}

sub _type
{
    my $self = shift;
    my $type = shift;
    my $doct = shift;
    
    my $p = $self->{p};
    
    $self->{type} = $type;
    $self->{location} = $p->get_location;
    $self->{doctype} = $doct;
    
    $p->halt;
    return;
}

sub public_id { shift->{doctype}{ExternalId}{PublicId} }
sub system_id { shift->{doctype}{ExternalId}{SystemId} }

sub has_doctype { defined $_[0]->{doctype} }
sub is_xhtml    { defined $_[0]->{type} and $_[0]->{type} eq "XHTML" }

# fails if
#
#   * the first [ in the decl does not open the internal subset
#   * the internal subset contains ]>
#   * comments outside the internal subset contain >
#   * the internal subset is not closed with ]>
#
sub doctype_length
{
    my $self = shift;
    my $document = shift;
    my $doctyped = $self->{doctype};
    my $location = $self->{location};
    my $gtpos = 0;
    my $gtskip = 0;
    
    # no document type declaration
    return $gtpos unless defined $doctyped;
    
    # < of <!DOCTYPE ...
    my $ltpos = $location->{EntityOffset} - 9;

    $gtpos = index $document, ">", $ltpos;
    
    # malformed doctype, missing >
    return if $gtpos < 0;
    
    $gtskip += $doctyped->{ExternalId}{PublicId} =~ />/g
      if defined $doctyped and exists $doctyped->{ExternalId}{PublicId};
    
    $gtskip += $doctyped->{ExternalId}{SystemId} =~ />/g
      if defined $doctyped and exists $doctyped->{ExternalId}{SystemId};
    
    $gtpos = index $document, ">", $gtpos # +1 ?
      while $gtskip--;
    
    # malformed doctype, missing proper >
    return if $gtpos < 0;
    
    # extract possible doctype
    my $text = substr $document, $ltpos, $gtpos - $ltpos + 1;

    # look for ]> if suspected internal subset
    if (index($text, "[") >= 0)
    {
        my $gtpos2 = index $document, "]>", $ltpos;
        $gtpos = $gtpos2 + 1 if $gtpos2 >= 0;
    }
    
    return $gtpos - $ltpos + 1
}

sub start_dtd
{
    my $self = shift;
    my $doct = shift;
    
    # ignore specified document type declarations without
    # public or system identifier and implied document type
    # declarations (which have just a GeneratedSystemId key)
    return unless exists $doct->{ExternalId}{PublicId} or
                  exists $doct->{ExternalId}{SystemId};
    
    my $puid = $doct->{ExternalId}{PublicId};
    
    # no public identifier means HTML
    return $self->_type("HTML", $doct) unless defined $puid;
    
    # split public identifier at //
    my @comp = split(/\/\//, $puid);
    
    # malformed public identifiers mean HTML
    return $self->_type("HTML", $doct) unless @comp > 2;
    
    # we might want something different than \s and \S here
    # but it is not clear to me what exactly we should expect
    return $self->_type("HTML", $doct) unless $comp[2] =~ /^DTD\s+(\S+)/;
    
    # the first token of the public text description must include
    # the string "XHTML", see XHTML M12N section 3.1, and see also
    # http://w3.org/mid/41584c61.156809450@smtp.bjoern.hoehrmann.de
    return $self->_type("HTML", $doct) unless $1 =~ /XHTML/;
    
    # otherwise considers this document XHTML
    return $self->_type("XHTML", $doct)
}

sub start_element
{
    my $self = shift;
    my $elem = shift;
    
    # no xmlns attribute means HTML
    return $self->_type("HTML") unless exists $elem->{Attributes}{XMLNS};
    
    my $xmlns = $elem->{Attributes}{XMLNS};
    
    # this should use the corresponding helper function to deal
    # with some potential edge cases but it is not in CVS yet
    return $self->_type("HTML") unless $xmlns->{Defaulted} eq "specified";
    
    # see above
    # return $self->_type("HTML") unless "http://www.w3.org/1999/xhtml" eq
    # join '', map { $_->{Data} } @{$xmlns->{CdataChunks}};
    
    return $self->_type("XHTML")
}

1;

__END__

=pod

=head1 NAME

HTML::Doctype - HTML/XHTML/XML Doctype Operations

=head1 SYNOPSIS

  use HTML::Doctype;
  ...

=head1 DESCRIPTION

Experimental module to perform some document type declaration 
related operations. It currently depends on SGML::Parser::OpenSP
for which it provides a handler HTML::Doctype::Detector which can
be used to detect document type declarations.

  my $p = SGML::Parser::OpenSP->new;
  my $h = HTML::Doctype::Detector->new($p);
  $p->handler($h)

  # ...
  $p->parse_string("...");

  if ($h->is_xhtml)
  {
    # ...
  }

...

Future versions may offer additional functionality.

=head1 AUTHOR / COPYRIGHT / LICENSE

  Copyright (c) 2004-2008 Bjoern Hoehrmann <bjoern@hoehrmann.de>.
  This module is licensed under the same terms as Perl itself.

=cut
