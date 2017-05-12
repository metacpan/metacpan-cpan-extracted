package Dezi::Lucy;
use Moose;
extends 'Dezi::App';

our $VERSION = '0.014';

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Dezi::Lucy - Dezi Apache Lucy backend

=head1 SYNOPSIS

 # create an index
 use Dezi::Lucy;
 my $app = Dezi::Lucy->new(
    invindex   => 'path/to/dezi.index',
    aggregator => 'fs',
    indexer    => 'lucy',
    config     => 'path/to/dezi.conf',
 );
 
 $app->run('path/to/files');
 
 # then search the index
 my $searcher = Dezi::Lucy::Searcher->new(
    invindex => 'path/to/dezi.index',
 );
 my $results = $searcher->search('my query')
 while ( my $result = $results->next ) {
    printf("%s : %s\n", $result->score, $result->uri);
 }


=head1 DESCRIPTION

B<STOP>: Read the L<Dezi> and L<Dezi::App> documentation before you use this
module.

Dezi::Lucy is an Apache Lucy based implementation of L<Dezi::App>
using the L<SWISH::3> bindings for libswish3.

Dezi::Lucy is to Apache Lucy what Solr or ElasticSearch is to Lucene.

See the L<Dezi::App> docs for more information about the class
hierarchy and history.

See the Swish3 development site at L<http://swish3.dezi.org/>.

=head1 Why Not Use Lucy Directly?

You can use Lucy directly. Using Lucy via Dezi::Lucy
offers a few advantages:

=over

=item Aggregators and Filters

You get to use all of Dezi's Aggregators and SWISH::Filter support.
So you can easily index all kinds of file formats 
(email, .txt, .html, .xml, .pdf, .doc, .xls, etc) 
without writing your own parser.

=item SWISH::3

SWISH::3 offers fast and robust XML and HTML parsers 
with an extensible configuration system, build on top of libxml2.

=item Simple now, complex later

You can index your content with Dezi::Lucy,
then build a more complex searching application directly
with Lucy.

=back

=head1 AUTHOR

Peter Karman, E<lt>karpet@dezi.orgE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dezi-app at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dezi-App>.  
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dezi::App

You can also look for information at:

=over 4

=item * Website

L<http://dezi.org/>

=item * IRC

#dezisearch at freenode

=item * Mailing list

L<https://groups.google.com/forum/#!forum/dezi-search>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi-App>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dezi-App>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dezi-App>

=item * Search CPAN

L<https://metacpan.org/dist/Dezi-App/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2014 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL v2 or later.

=head1 SEE ALSO

L<http://dezi.org/>, L<http://swish-e.org/>, L<http://lucy.apache.org/>

