package Logfile::EPrints;

use strict;
use warnings;

use Carp;
use URI;
use Socket;

use Logfile::EPrints::Hit;
use Logfile::EPrints::Hit::Negate;

use Logfile::EPrints::Filter;
use Logfile::EPrints::Institution;
use Logfile::EPrints::Repeated;
use Logfile::EPrints::Parser;
# use Logfile::EPrints::Parser::OAI;
use Logfile::EPrints::RobotsTxtFilter;
use Logfile::EPrints::Period;
use Logfile::EPrints::Filter::Session;

use Logfile::EPrints::Mapping::arXiv;
use Logfile::EPrints::Mapping::DSpace;
use Logfile::EPrints::Mapping::EPrints;

# Maintain backwards compatibility
our @ISA = qw( Logfile::EPrints::Mapping::EPrints );

our $VERSION = '1.20';

1;

__END__

=head1 NAME

Logfile::EPrints - Process Web log files for institutional repositories

=head1 SYNOPSIS

  use Logfile::EPrints;

  my $parser = Logfile::EPrints::Parser->new(
	handler=>Logfile::EPrints::Mapping::EPrints->new(
	  identifier=>'oai:myir:', # Prepended to the eprint id
  	  handler=>Logfile::EPrints::Repeated->new(
	    handler=>Logfile::EPrints::Institution->new(
	  	  handler=>$MyHandler,
	  )),
	),
  );
  open my $fh, "<access_log" or die $!;
  $parser->parse_fh($fh);
  close $fh;

  package MyHandler;

  sub new { ... }
  sub AUTOLOAD { ... }
  sub fulltext {
  	my ($self,$hit) = @_;
	printf("%s from %s requested %s (%s)\n",
	  $hit->hostname||$hit->address,
	  $hit->institution||'Unknown',
	  $hit->page,
	  $hit->identifier,
	);
  }

=head1 DESCRIPTION

The Logfile::* modules provide a means to analyze log files from Web servers (typically Institutional Repositories) by translating HTTP requests into more informative data e.g. a full-text download by a user at Caltech.

The architectural design consists of a series of pluggable filters that read from a log file or stream into Perl objects/callbacks. The first filter in the stream needs to convert from the log file format into a record object representing a single "hit". Subsequent filters can then ignore hits (e.g. from robots) and/or augment them with additional data (e.g. country of origin by GeoIP).

A record object (based on L<Logfile::EPrints::Hit>) stores data about a request and may provide derived information on demand (e.g. translate a hostname to IP address).

Filters in Logfile::EPrints fall into three catagories: parsers, mappers and filters.

=head2 Parsers

A parser retrieves data from a raw web log source and for every log entry it creates a record object and passes this onto it's handler as a 'hit' event. Between the parser and the record object any translation required by the used mappers/filters needs to happen.

=head2 Mappers

Mappers are responsible for mapping HTTP requests into logical requests in the repository. An HTTP request might be a 200 response to the page /200/3 that corresponds to a logical request for document 3 in the eprint record 200. A mapper would typically translate the generic 'hit' invent into other events by calling a different method on its downstream handler.

=head2 Filters

A filter does the legwork in processing log files. A filter may ignore records (e.g. records resulting from robot activity) or add data to the record.

As a special (alpha) case a filter may return a record derived from L<Logfile::EPrints::Hit::Negate> that means 'remove records matching this query'. Therefore filters must return whatever is returned by the downstream handler.

To be useful the final filter will need to write the resulting data to file or, more likely, a database.

=head1 HANDLER CALLBACKS

Logfile::EPrints is weakly typed and doesn't (currently) proscribe what data a record may contain nor the type of events that can happen in a repository. However, the built-in mappers at most use the following four events:

=over 4

=item abstract()

A request for an abstract 'jump-off' page (vs. a fulltext request).

=item fulltext()

A request for a full-text object e.g. HTML document, PDF, image etc.

=item browse()

A request for a browsable list e.g. a subject-based listing.

=item search()

An internal repository search.

=back

=head1 SEE ALSO

L<Logfile::EPrints::Hit>, L<Logfile::EPrints::Mapping>.

Some other CPAN modules:

L<HTTPD::Log::Filter>, L<Apache::ParseLog>, L<Apache::LogRegex>, L<Logfile::Access>.

=head1 AUTHOR

Timothy D Brody, E<lt>tdb01r@ecs.soton.ac.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Timothy D Brody

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
