package IRC::Indexer;
our $VERSION = '0.06';

## stub! for now ..

1;
__END__

=pod

=head1 NAME

IRC::Indexer - IRC server stats collection via POE

=head1 SYNOPSIS

  ## Pull stats from a single server:
  $ ircindexer-single -s irc.cobaltirc.org -f JSON -o cobaltirc.json

  ## Generate some example confs:
  $ ircindexer-examplecf -t httpd -o httpd.cf
  $ $EDITOR httpd.cf

  $ mkdir networks/
  $ cd networks/
  $ mkdir cobaltirc
  $ ircindexer-examplecf -t spec -o cobaltirc/eris.oppresses.us.server
  $ $EDITOR cobaltirc/eris.oppresses.us.server
  . . .
  
  ## Spawn a httpd serving JSON:
  $ ircindexer-server-json -c httpd.cf

  ## See IRC::Indexer::Trawl::Bot for more on using trawlers from 
  ## within your own POE-enabled apps.

=head1 DESCRIPTION

IRC::Indexer is a set of modules and utilities useful for trawling IRC 
networks, collecting information, and exporting it to portable formats 
for use in Web frontends and other applications.

L<ircindexer-server-json> serves as a real world example of how to use 
the trawler system to index IRC networks; it is usable as-is to trawl 
sets of IRC servers belonging to configured networks and serve JSON-serialized 
network stats via HTTP.

L<ircindexer-server-json> is fairly scalable; this could be 
used directly to build an IRC trawling/indexing Web application in a 
language of your choice, for example (or just grab data at intervals 
and spit out some graphs for a network or two, see B<examples/> in the 
distribution).

L<ircindexer-single> can be used to trawl a single server in one shot, 
exporting to YAML, JSON, or Perl.
See the documentation or C<ircindexer-single -h> for details.

See the perldoc for L<IRC::Indexer::Trawl::Bot> for more about 
using the trawl bot itself as part of other POE-enabled applications.

The Trawl::Bot instances run asynchronously within a single process; 
L<IRC::Indexer::Trawl::Forking> can be used to run Trawl::Bot 
instances as forked workers that immediately die when complete, if you 
prefer.

See L<IRC::Indexer::POD::ServerSpec> and 
L<IRC::Indexer::POD::NetworkSpec> for details on exported data.

=head1 TODO

=over

=item *
Nothing very useful is done with LINKS data; it's not always available 
and is presented as-is. We should maybe export a hash.

=item *
More useful examples in examples/

=back

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

L<http://www.cobaltirc.org>

=cut
