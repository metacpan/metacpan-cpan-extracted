package MKDoc::XML;
use strict;
use warnings;

our $VERSION = '0.75';


1;


__END__

=head1 NAME

MKDoc::XML - The MKDoc XML Toolkit


=head1 SYNOPSIS

This is an article, not a module.


=head1 SUMMARY

MKDoc is a web content management system written in Perl which focuses on
standards compliance, accessiblity and usability issues, and multi-lingual
websites.

At MKDoc Ltd we have decided to gradually break up our existing commercial
software into a collection of completely independent, well-documented,
well-tested open-source CPAN modules.

Ultimately we want MKDoc code to be a coherent collection of module
distributions, yet each distribution should be usable and useful in itself.

MKDoc::XML is part of this effort.

You could help us and turn some of MKDoc's code into a CPAN module.
You can take a look at the existing code at http://download.mkdoc.org/.

If you are interested in some functionality which you would like to
see as a standalone CPAN module, send an email to
<mkdoc-modules@lists.webarch.co.uk>.


=head1 DISCLAIMER 

=over

=item B<MKDoc::XML is a low level XML library.>

=item MKDoc::XML::* modules do not make sure your XML is well-formed.

=item MKDoc::XML::* modules can be used to work with somehow broken XML.

=item MKDoc::XML::* modules should not be used as high-level parsers with
      general purpose XML unless you know what you're doing.

=back


=head1 WHAT'S IN THE BOX


=head2 XML tokenizer

L<MKDoc::XML::Tokenizer> splits your XML / XHTML files into a list of
L<MKDoc::XML::Token> objects using a single regex.


=head2 XML tree builder

L<MKDoc::XML::TreeBuilder> sits on top of L<MKDoc::XML::Tokenizer> and builds
parsed trees out of your XML / XHTML data.


=head2 XML stripper

L<MKDoc::XML::Stripper> objects removes unwanted markup from your XML / HTML
data. Useful to remove all those nasty presentational tags or 'style'
attributes from your XHTML data for example.


=head2 XML tagger

L<MKDoc::XML::Tagger> module matches expressions in XML / XHTML documents and
tag them appropriately. For example, you could automatically hyperlink certain
glossary words or add <abbr> tags based on a dictionary of abbreviations and
acronyms.


=head2 XML entity decoder

L<MKDoc::XML::Decode> is a pluggable, configurable entity expander module which
currently supports html entities, numerical entities and basic xml entities.


=head2 XML entity encoder

L<MKDoc::XML::Encode> does the exact reverse operation as L<MKDoc::XML::Decode>.


=head2 XML Dumper

L<MKDoc::XML::Dumper> serializes arbitrarily complex perl structures into XML strings.
It is also able of doing the reverse operation, i.e. deserializing an XML string into
a perl structure.


=head1 AUTHOR

Copyright 2003 - MKDoc Holdings Ltd.

Author: Jean-Michel Hiver

This module is free software and is distributed under the same license as Perl
itself. Use it at your own risk.


=head1 SEE ALSO

  Petal: http://search.cpan.org/dist/Petal/
  MKDoc: http://www.mkdoc.com/

Help us open-source MKDoc. Join the mkdoc-modules mailing list:

  mkdoc-modules@lists.webarch.co.uk

=cut
