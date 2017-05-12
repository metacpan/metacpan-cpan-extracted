#!/usr/bin/perl -w

use strict;
use Encode;
use Lingua::DE::Wortschatz ':all';

my @args=map {encode("utf8",$_)} @ARGV;
if (defined($args[0]) && ($args[0] !~ /^help/)) {
    if (my $result=use_service(@args)) {
        $result->dump();
        exit;
    }
}
if ($args[0] =~ /^help/) {
    shift @args;
}

print <<HELP;
wsws.pl - Wortschatz-Webservice-Client (c) 2005-2008 Daniel Schröer

Usage: $0 service arguments
Type "$0 help full" for a complete description of all services.

HELP
print help(@args);

__END__

=head1 NAME

wsws.pl - Command line client for the web services at wortschatz.uni-leipzig.de

=head1 SYNOPSIS

  wsws.pl help
  wsws.pl help Thesaurus
  wsws.pl Thesaurus toll
  wsws.pl help C
  wsws.pl C toll 300
  wsws.pl help full

=head1 DESCRIPTION

This is a full featured command line client for the web services
at L<http://wortschatz.uni-leipzig.de>.

The general syntax is

  wsws.pl servicename serviceparameter1 serviceparameter2 ...

All public services at L<http://wortschatz.uni-leipzig.de> are
available. Below is a list of service names and their parameters.
Any parameter with = is optional and defaults to the given value.
Service names can be abbreviated to the shortest unique form.

  * ServiceOverview Name=
  * Cooccurrences Wort Mindestsignifikanz=1 Limit=10
  * Baseform Wort
  * Sentences Wort Limit=10
  * RightNeighbours Wort Limit=10
  * LeftNeighbours Wort Limit=10
  * Frequencies Wort Limit=10
  * Synonyms Wort Limit=10
  * Thesaurus Wort Limit=10
  * Wordforms Word Limit=10
  * Similarity Wort Limit=10
  * LeftCollocationFinder Wort Wortart Limit=10
  * RightCollocationFinder Wort Wortart Limit=10
  * Sachgebiet Wort  
  * Kreuzwortraetsel Wort Wortlaenge Limit=10

Type

  wsws.pl help
  
or

  wsws.pl help full

for an online description of all available services, their parameters and
additional information on what each service does.

=head1 SEE ALSO

=over 2

=item L<Lingua::DE::Wortschatz>

=item L<http://wortschatz.uni-leipzig.de>

=item L<SOAP::Lite>

=back

=head1 AUTHOR/COPYRIGHT

This is C<$Id: wsws.pl 1151 2008-10-05 20:57:26Z schroeer $>.

Copyright 2005 - 2008 Daniel Schröer (L<schroeer@cpan.org>). Any feedback is appreciated.

This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
