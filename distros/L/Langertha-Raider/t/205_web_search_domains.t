#!/usr/bin/env perl
# ABSTRACT: web_search allowed_domains / blocked_domains as Claude Code's WebSearch: filtered results, query operators, not both (ADR 0026)
use strict;
use warnings;
use Test2::V0;
use Future;
use IO::Async::Loop;
use Langertha::Raider::WebTools qw( build_web_tools_server );

local @ENV{qw( BRAVE_API_KEY SERPER_API_KEY GOOGLE_API_KEY GOOGLE_CSE_ID )};

# A search that answers from a fixed list and records what it was asked.
package Fake::Result {
  sub new   { my ( $class, %a ) = @_; bless {%a}, $class }
  sub title   { $_[0]{title} }
  sub url     { $_[0]{url} }
  sub snippet { $_[0]{snippet} }
}
package Fake::Search {
  use parent 'IO::Async::Notifier';
  sub results { $_[0]{results} //= [] }
  sub asked   { $_[0]{asked} //= [] }
  sub search {
    my ( $self, %a ) = @_;
    push @{ $self->asked }, \%a;
    my @r = @{ $self->results };
    splice @r, $a{limit} if @r > $a{limit};
    return Future->done( { results => \@r } );
  }
}

my $loop = IO::Async::Loop->new;
my $ws = Fake::Search->new;
@{ $ws->results } = map { Fake::Result->new( title => $_->[0], url => $_->[1], snippet => 's' ) } (
  [ 'Perl docs',     'https://perldoc.perl.org/functions' ],
  [ 'CPAN',          'https://metacpan.org/pod/Moose' ],
  [ 'Perl news',     'https://news.perl.org/x' ],
  [ 'Spam',          'https://spam.example/perl' ],
  [ 'Not a host',    'mailto:x@y' ],
  [ 'Fake perl',     'https://notperl.org/x' ],
);
my $server = build_web_tools_server( loop => $loop, web_search => $ws, fetch_timeout => 5 );
my ($tool) = grep { $_->name eq 'web_search' } @{ $server->tools };
my $search = sub { $tool->code->( $tool, { query => 'perl', @_ } ) };
sub text_of { join '', map { $_->{text} // '' } @{ $_[0]{content} // [] } }
sub urls_of { [ text_of( $_[0] ) =~ m{^    (\S+://\S+|mailto:\S+)$}mg ] }

subtest 'the schema' => sub {
  my $props = $tool->input_schema->{properties};
  is $props->{allowed_domains}{type}, 'array', 'allowed_domains: an array';
  is $props->{blocked_domains}{items}{type}, 'string', 'blocked_domains: of strings';
  is $tool->input_schema->{required}, ['query'], 'only query is required';
};

subtest 'no filter: as before' => sub {
  my $r = $search->();
  is scalar @{ urls_of($r) }, 6, 'every result';
  is $ws->asked->[-1], { query => 'perl', limit => 8 }, 'the query and limit as given';
};

subtest 'allowed_domains: only those domains and their subdomains' => sub {
  my $r = $search->( allowed_domains => [ 'perl.org' ] );
  is urls_of($r), [ 'https://perldoc.perl.org/functions', 'https://news.perl.org/x' ],
    'perl.org covers its subdomains, not notperl.org';
  is $ws->asked->[-1], { query => 'perl site:perl.org', limit => 24 }, 'one domain: site: in the query; three times the limit asked for';

  $r = $search->( allowed_domains => [ 'https://MetaCPAN.org/some/path', '*.perl.org' ], limit => 2 );
  is urls_of($r), [ 'https://perldoc.perl.org/functions', 'https://metacpan.org/pod/Moose' ],
    'entries as URLs or with *. are domains; the limit holds after filtering';
  is $ws->asked->[-1], { query => 'perl', limit => 6 }, 'several domains: no operator, the filter decides';
};

subtest 'blocked_domains: never those domains' => sub {
  my $r = $search->( blocked_domains => [ 'spam.example', 'perl.org' ] );
  is urls_of($r), [ 'https://metacpan.org/pod/Moose', 'mailto:x@y', 'https://notperl.org/x' ], 'filtered out';
  is $ws->asked->[-1]{query}, 'perl -site:spam.example -site:perl.org', '-site: for each in the query';
  is $ws->asked->[-1]{limit}, 24, 'three times the limit';
  $search->( blocked_domains => [], limit => 100 );
  is $ws->asked->[-1], { query => 'perl', limit => 100 }, 'an empty list is no filter';
};

subtest 'both at once: an error, nothing searched' => sub {
  my $n = @{ $ws->asked };
  my $r = $search->( allowed_domains => ['perl.org'], blocked_domains => ['spam.example'] );
  ok $r->{isError}, 'an error result';
  is text_of($r), '<tool_use_error>Error: Cannot specify both allowed_domains and blocked_domains in the same request</tool_use_error>', 'says so';
  is scalar @{ $ws->asked }, $n, 'no search';
};

subtest 'nothing left: No results.' => sub {
  is text_of( $search->( allowed_domains => ['nowhere.example'] ) ), 'No results.', 'said so';
};

done_testing;
