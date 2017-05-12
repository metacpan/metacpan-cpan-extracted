package KinoSearch1;
use strict;
use warnings;

use 5.008003;

our $VERSION = '1.01';

use constant K_DEBUG => 0;

use XSLoader;
# This loads a large number of disparate subs.
XSLoader::load( 'KinoSearch1', $VERSION );

use base qw( Exporter );
our @EXPORT_OK = qw( K_DEBUG kdump );

sub kdump {
    require Data::Dumper;
    my $kdumper = Data::Dumper->new( [@_] );
    $kdumper->Sortkeys( sub { return [ sort keys %{ $_[0] } ] } );
    $kdumper->Indent(1);
    warn $kdumper->Dump;
}

1;

__END__

__XS__

#include "limits.h"

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_newRV_noinc_GLOBAL
#include "ppport.h"

MODULE = KinoSearch1    PACKAGE = KinoSearch1

PROTOTYPES: disable

BOOT:
    items = 0;

=for comment
Return 1 if memory debugging is enabled.  See KinoSearch1::Util::MemManager.

=cut

IV
memory_debugging_enabled()
CODE:
    RETVAL = KINO_MEM_LEAK_DEBUG;
OUTPUT:
    RETVAL

__POD__

=head1 NAME

KinoSearch1 - search engine library

=head1 VERSION

1.01

=head1 STABLE FORK

KinoSearch1 is a fork of L<KinoSearch> version 0.165 intended to provide
stability and backwards compatibility.  For the latest features, see the main
branch.

=head1 SYNOPSIS

First, write an application to build an inverted index, or "invindex", from
your document collection.

    use KinoSearch1::InvIndexer;
    use KinoSearch1::Analysis::PolyAnalyzer;
    
    my $analyzer
        = KinoSearch1::Analysis::PolyAnalyzer->new( language => 'en' );
    
    my $invindexer = KinoSearch1::InvIndexer->new(
        invindex => '/path/to/invindex',
        create   => 1,
        analyzer => $analyzer,
    );
    
    $invindexer->spec_field( 
        name  => 'title',
        boost => 3,
    );
    $invindexer->spec_field( name => 'bodytext' );
    
    while ( my ( $title, $bodytext ) = each %source_documents ) {
        my $doc = $invindexer->new_doc;
    
        $doc->set_value( title    => $title );
        $doc->set_value( bodytext => $bodytext );
    
        $invindexer->add_doc($doc);
    }
    
    $invindexer->finish;

Then, write a second application to search the invindex:

    use KinoSearch1::Searcher;
    use KinoSearch1::Analysis::PolyAnalyzer;
    
    my $analyzer
        = KinoSearch1::Analysis::PolyAnalyzer->new( language => 'en' );
    
    my $searcher = KinoSearch1::Searcher->new(
        invindex => '/path/to/invindex',
        analyzer => $analyzer,
    );
    
    my $hits = $searcher->search( query => "foo bar" );
    while ( my $hit = $hits->fetch_hit_hashref ) {
        print "$hit->{title}\n";
    }

=head1 DESCRIPTION

KinoSearch1 is a loose port of the Java search engine library Apache Lucene,
written in Perl and C. The archetypal application is website search, but it
can be put to many different uses.

=head2 Features

=over

=item *

Extremely fast and scalable - can handle millions of documents

=item *

Incremental indexing (addition/deletion of documents to/from an existing
index).

=item *

Full support for 12 Indo-European languages.

=item *

Support for boolean operators AND, OR, and AND NOT; parenthetical groupings,
and prepended +plus and -minus

=item *

Algorithmic selection of relevant excerpts and highlighting of search terms
within excerpts

=item *

Highly customizable query and indexing APIs

=item *

Phrase matching

=item *

Stemming

=item *

Stoplists

=back

=head2 Getting Started

KinoSearch1 has many, many classes, but you only need to get aquainted with
three to start with:

=over 

=item *

L<KinoSearch1::InvIndexer|KinoSearch1::InvIndexer>

=item *

L<KinoSearch1::Searcher|KinoSearch1::Searcher>

=item *

L<KinoSearch1::Analysis::PolyAnalyzer|KinoSearch1::Analysis::PolyAnalyzer>

=back

Probably the quickest way to get something up and running is to cut and paste
the sample applications out of
L<KinoSearch1::Docs::Tutorial|KinoSearch1::Docs::Tutorial> and adapt them for
your purposes.  

=head1 SEE ALSO 

The actively developed main branch, L<KinoSearch>.

The KinoSearch homepage, where you'll find links to the mailing list and so
on, is L<http://www.rectangular.com/kinosearch>.

The Lucene homepage is L<http://lucene.apache.org>.

L<KinoSearch1::Docs::FileFormat|KinoSearch1::Docs::FileFormat>, for an overview
of the invindex file format.

=head1 History 

Search::Kinosearch 0.02x, no longer supported, is this suite's forerunner.
L<Plucene|Plucene> is a pure-Perl port of Lucene 1.3. KinoSearch is a
from-scratch project which attempts to draws on the lessons of both. The API
is not compatible with either.

KinoSearch is named for Kino, the main character in John Steinbeck's novella,
"The Pearl".

=head1 SUPPORT

Please direct support questions to the KinoSearch mailing list: subscription
information at L<http://www.rectangular.com/kinosearch>.

=head1 BUGS

UTF-8 scalars are not indexed properly.  This is fixed in KinoSearch 0.3x, but
cannot be fixed in KinoSearch1 without breaking index compatibility with
KinoSearch 0.165 from which KinoSearch1 was forked.

Not thread-safe.

Indexing crashes reliably on Solaris 2.9 or other systems which are fussy
about pointer alignment.

Please report any other bugs or feature requests to
C<bug-kinosearch1@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=KinoSearch1>.

=head1 COPYRIGHT & LICENSE

Copyright 2005-2010 Marvin Humphrey

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

Terms of usage for Apache Lucene, from which portions of KinoSearch1 are
derived, are spelled out in the Apache License: see the file
"ApacheLicense2.0.txt".

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=cut

