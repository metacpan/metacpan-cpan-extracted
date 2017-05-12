#!/usr/bin/env perl
use strict;
use warnings;
use Carp;
use Pod::Usage qw( pod2usage );
use Getopt::Long qw( :config gnu_getopt );
use version; my $VERSION = qv('0.0.1');
use English qw( -no_match_vars );
use File::Slurp qw( read_file write_file );
use Data::Dumper;
$Data::Dumper::Indent = 1;

use lib qw( ../blib/lib );
use MMS::Parser;

my %config = (dumpall => 0,);
GetOptions(\%config, 'usage', 'help', 'man', 'version', 'dumpall|d!',
   'save|s!', 'force|f!');
pod2usage(message => "$0 $VERSION", -verbose => 99, -sections => '')
  if $config{version};
pod2usage(-verbose => 99, -sections => 'USAGE') if $config{usage};
pod2usage(-verbose => 99, -sections => 'USAGE|EXAMPLES|OPTIONS')
  if $config{help};
pod2usage(-verbose => 2) if $config{man};
pod2usage(-verbose => 99, -sections => 'USAGE')
  unless @ARGV == 1 && -e $ARGV[0];

# Script implementation here
my $packed = read_file $ARGV[0], binmode => ':raw';
my $parser = MMS::Parser->create();

# First of all, establish which type this MMS packet is
my $type = $parser->message_type_head($packed)->[1];
$type = join '-', map { ucfirst lc } split /_/, $type;
print {*STDOUT} "Message is of type $type\n";

my $decoded;
if ($type eq 'M-Send-Req') {
   $decoded = $parser->M_Send_Req_message($packed);
}
elsif ($type eq 'M-Retrieve-Conf') {
   $decoded = $parser->M_Retrieve_Conf_message($packed);
}

if (!$decoded) {
   print {*STDOUT} "no further decoding for this type\n";
   exit 0;
}

print {*STDOUT} Data::Dumper->Dump([$decoded], ['Message'])
  if $config{dumpall};

my @headers = split /\n/, Dumper($decoded->{headers});
shift @headers;
pop @headers;
print {*STDOUT} join "\n", 'Headers:', @headers, '';

my @parts = @{$decoded->{body}};
print {*STDOUT} 'Message has ', scalar(@parts), ' part',
  (scalar(@parts) == 1 ? '' : 's'), ":\n";
my $index = 0;
for my $part (@parts) {
   ++$index;
   my $content_type = $part->{headers}{content_type};
   my $media_type   = $content_type->{media_type};
   print {*STDOUT} "$index) $media_type\n";
   if ($media_type eq 'text/plain') {
      (my $text = $part->{data}) =~ s{^}{   | }mxsg;
      print {*STDOUT} $text, "\n";
   }
   next unless $config{save} && exists $content_type->{parameters}{name};
   my $filename = $content_type->{parameters}{name};
   if (-e $filename && !$config{force}) {
      print {*STDOUT} "   * $filename already exists, skipping\n";
      next;
   }
   print {*STDOUT} "   * saving part data into $filename\n";
   write_file $filename, {binmode => ':raw'}, $part->{data};
} ## end for my $part (@parts)

__END__

=head1 NAME

message-structure.pl - a tiny example of usage for MMS::Parser;


=head1 VERSION

Call:

   shell$ message-structure.pl --version


=head1 USAGE

   message-structure.pl [--usage] [--help] [--man] [--version]

   message-structure.pl [-d|--dumpall] [-f|--force] [-s|--save] file.mms

  
=head1 EXAMPLES

   # Get the usage lines
   shell$ message-structure.pl

   # basic decoding of a message
   shell$ message-structure.pl file.mms

   # save all parts that have an associated name (which is the case
   # for images, more or less)
   shell$ message-structure.pl -s file.mms

   # by default, files are not overwritten when -s is in use, but we
   # can force this
   shell$ message-structure.pl -sf file.mms

   # show a dump of the entire parsed structure
   shell$ message-structure.pl -d file.mms

  
=head1 DESCRIPTION

This is only a tiny example to show MMS::Parser (preliminar) capabilities.
The status of MMS::Parser is still in a flux, but you can get an idea of
what will be available.


=head1 OPTIONS

=over

=item --dumpall | -d

dump the parsed message. Note that this dump could contain binary data
and leave your terminal in a bad mood. Caveat emptor.

=item --force | -f

when used together with C<-s|--save>, force saving even if a file is already
present.


=item --help

print a somewhat more verbose help, showing usage, this description of
the options and some examples from the synopsis.

=item --man

print out the full documentation for the script.

=item --save | -s

save parts that have a name that can be used to save the file itself.

=item --usage

print a concise usage line and exit.

=item --version

print the version of the script.

=back

=head1 DIAGNOSTICS

You don't really want to know...


=head1 CONFIGURATION AND ENVIRONMENT

message-structure.pl requires no configuration files or environment variables.


=head1 DEPENDENCIES

None beyond those of L<MMS::Parser>.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through http://rt.cpan.org/


=head1 AUTHOR

Flavio Poletti C<flavio@polettix.it>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Flavio Poletti C<flavio@polettix.it>. All rights reserved.

This script is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>
and L<perlgpl>.

Questo script è software libero: potete ridistribuirlo e/o
modificarlo negli stessi termini di Perl stesso. Vedete anche
L<perlartistic> e L<perlgpl>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=head1 NEGAZIONE DELLA GARANZIA

Poiché questo software viene dato con una licenza gratuita, non
c'è alcuna garanzia associata ad esso, ai fini e per quanto permesso
dalle leggi applicabili. A meno di quanto possa essere specificato
altrove, il proprietario e detentore del copyright fornisce questo
software "così com'è" senza garanzia di alcun tipo, sia essa espressa
o implicita, includendo fra l'altro (senza però limitarsi a questo)
eventuali garanzie implicite di commerciabilità e adeguatezza per
uno scopo particolare. L'intero rischio riguardo alla qualità ed
alle prestazioni di questo software rimane a voi. Se il software
dovesse dimostrarsi difettoso, vi assumete tutte le responsabilità
ed i costi per tutti i necessari servizi, riparazioni o correzioni.

In nessun caso, a meno che ciò non sia richiesto dalle leggi vigenti
o sia regolato da un accordo scritto, alcuno dei detentori del diritto
di copyright, o qualunque altra parte che possa modificare, o redistribuire
questo software così come consentito dalla licenza di cui sopra, potrà
essere considerato responsabile nei vostri confronti per danni, ivi
inclusi danni generali, speciali, incidentali o conseguenziali, derivanti
dall'utilizzo o dall'incapacità di utilizzo di questo software. Ciò
include, a puro titolo di esempio e senza limitarsi ad essi, la perdita
di dati, l'alterazione involontaria o indesiderata di dati, le perdite
sostenute da voi o da terze parti o un fallimento del software ad
operare con un qualsivoglia altro software. Tale negazione di garanzia
rimane in essere anche se i dententori del copyright, o qualsiasi altra
parte, è stata avvisata della possibilità di tali danneggiamenti.

Se decidete di utilizzare questo software, lo fate a vostro rischio
e pericolo. Se pensate che i termini di questa negazione di garanzia
non si confacciano alle vostre esigenze, o al vostro modo di
considerare un software, o ancora al modo in cui avete sempre trattato
software di terze parti, non usatelo. Se lo usate, accettate espressamente
questa negazione di garanzia e la piena responsabilità per qualsiasi
tipo di danno, di qualsiasi natura, possa derivarne.

=cut
