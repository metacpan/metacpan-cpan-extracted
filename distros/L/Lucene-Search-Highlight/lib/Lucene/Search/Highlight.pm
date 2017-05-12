package Lucene::Search::Highlight;
require DynaLoader;
require Exporter;

use 5.006;
use warnings;
use strict;

our $VERSION = '0.01';
our @ISA = qw( Exporter DynaLoader );
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );
bootstrap Lucene::Search::Highlight $VERSION;

# This flag is necessary so that external variables get exported
# On Linux this corresponds to RTLD_GLOBAL of the function dlopen
sub dl_load_flags { 0x01 }

1; # End of Lucene

=head1 NAME

Lucene::Search::Highlight -- Highlight terms in Lucene search results

=head1 SYNOPSIS

=head2 Load highlight classes into namespace

  use Lucene::Search::Highlight;

=head2 Create Formatter and Query Scorer

  my $formatter = new Lucene::Search::Highlight::SimpleHTMLFormatter("<b>", "</b>");
  my $scorer = new Lucene::Search::Highlight::QueryScorer($query);

=head2 Create Highlighter

  my $highlighter = new Lucene::Search::Highlight::Highlighter($formatter, $scorer);

=head2 Get best fragements with highlighted terms

  my $fragement  = $highlighter->getBestFragment($analyzer, $field, $text);
  my $fragements = $highlighter->getBestFragments($analyzer, $field, $text, $num_fragements, $separator);

=head1 DESCRIPTION

Lucene::Search::Highlight is an extention of the original Lucene package and provides
"keyword in context" features typically used to highlight search terms in the text of
Lucene results pages. The Highlighter class is the central component and can be used to
extract the most interesting sections of a piece of text and highlight them, with the
help of Scorer and Formatter classes.

=head1 REQUIREMENTS

This module requires L<Lucene> to be installed.

=head1 INSTALLATION

This module requires the clucene contrib library to be installed. The best way to
get it is to go to the following page
    
    http://sourceforge.net/projects/clucene/

and download the latest clucene-contrib version. Currently it is clucene-contrib-0.9.14.
Make sure you compile it with debug disabled and install it in your standard library path.

On a Linux platform this goes as follows:

    wget http://kent.dl.sourceforge.net/sourceforge/clucene/clucene-contrib-0.9.14.tar.gz
    tar xzf clucene-contrib-0.9.14.tar.gz
    cd clucene-contrib-0.9.14
    ./autogen.sh
    ./configure --disable-debug --prefix=/usr --exec-prefix=/usr
    make
    make check
    (as root) make install

To install the perl module itself, run the following commands:

    perl Makefile.PL
    make
    make test
    (as root) make install

=head1 AUTHOR

Thomas Busch <tbusch at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007 Thomas Busch

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

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
