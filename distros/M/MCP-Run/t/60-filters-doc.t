use strict;
use warnings;
use Test::More;
use lib 'lib';

use MCP::Run::Compress;

# MCP::Run::Compress::Filters is pure POD. No line of code loads it, so
# nothing keeps it in sync with the filter table in MCP::Run::Compress --
# which is how it came to promise 44 commands that had no filter at all
# (karr #17). This test is that something: it compares what the reference
# documents against what the compressor registers, in both directions.
#
# The require also gives the file its only compile check, and hands us its
# path without guessing at cwd.
require MCP::Run::Compress::Filters;
my $POD_FILE = $INC{'MCP/Run/Compress/Filters.pm'};

# --------------------------------------------------------------------------
# Normalisation -- read this before touching anything below.
#
# Both sides are reduced to the same shape: a B<command identity>, the
# shortest command line that makes the filter match.
#
# Registry side. A parsed_command filter carries its structure, so the
# identity is read from the structure and never from the storage key:
#
#     { program => 'git', subcommand => 'diff', flags => { stat => 1 } }
#         ->  "git diff --stat"
#
# Flags are rendered by name only, never by value: _match_parsed_command
# tests a flag for presence, not for a value, so the value is not part of
# the identity. One-letter flags get one dash, longer ones two. An
# undefined subcommand contributes nothing, so { program => 'pytest' }
# is "pytest" -- that filter really does match every pytest invocation,
# and that is what the reference has to say about it.
#
# A legacy regex filter has no structure to read, so its identity is
# decoded from the pattern -- but only for the deliberately narrow subset
# that is a plain anchored literal: ^word, ^word\s+word, optional trailing
# \b. "^git\s+diff\b" is "git diff". Anything outside that subset is not
# guessed; it has to be listed in %REGEX_IDENTITY, with a reason.
#
# Refusing to guess is the point. A decoder clever enough to read any
# regex would eventually read one wrong and report drift where there is
# none -- and a test that cries wolf gets disarmed rather than debugged,
# which is exactly the failure mode this file exists to prevent.
#
# Documentation side. Every C<...> on an =item line inside =head1 COMMANDS
# is one identity, and an item may carry several
# (=item C<ip addr>, C<ip route>, C<ip link>). Only that section is read:
# =head1 FILTER STAGES numbers its items and ADDING CUSTOM FILTERS shows
# example code, neither documents a command.
#
# The rule both sides follow, stated in the reference as well: the command
# named in an =item is the filter's identity and nothing more. Everything a
# filter does not actually require belongs in the prose. C<iptables -L>
# would be a lie about a filter that matches every iptables call, so the
# item reads C<iptables> and the prose mentions -L.
# --------------------------------------------------------------------------

my %REGEX_IDENTITY = (

  # The Co-Authored-By rewrite has to match inside compound commands
  # (`cd x && git add . && git commit -m "..."`), so it can be neither
  # anchored nor decoded. It speaks for exactly one command.
  '\bgit\b[^&|;]*?(?<![=])\bcommit\b' => ['git commit'],

  # A third word decides this one (push/pull, not list), which
  # _match_parsed_command cannot express -- it knows program and subcommand
  # only. The alternation that follows from that is not something the
  # decoder above should learn to read.
  '^shopify\s+theme\s+(?:push|pull)\b' => ['shopify theme push', 'shopify theme pull'],
);

sub identity_from_regex {
  my ($regex) = @_;

  return @{ $REGEX_IDENTITY{$regex} } if $REGEX_IDENTITY{$regex};

  my $rest = $regex;
  return () unless $rest =~ s/\A\^//;    # must be anchored at the start
  $rest =~ s/\\b\z//;                    # a trailing word boundary is noise

  my @words;
  for my $word (split /\\s\+|[ ]/, $rest) {
    return () unless length $word;
    # A literal word is letters, digits, _ - and backslash-escaped
    # punctuation. Drop the escapes, then anything left outside that set
    # means the pattern is doing something this decoder must not pretend
    # to understand.
    my $probe = $word;
    $probe =~ s/\\[^A-Za-z0-9]//g;
    return () if $probe =~ /[^A-Za-z0-9_-]/;
    $word =~ s/\\([^A-Za-z0-9])/$1/g;
    push @words, $word;
  }

  return () unless @words;
  return join ' ', @words;
}

sub identity_from_parsed {
  my ($parsed) = @_;
  my @parts = ($parsed->{program} // '');
  push @parts, $parsed->{subcommand} if defined $parsed->{subcommand};
  for my $flag (sort keys %{ $parsed->{flags} // {} }) {
    push @parts, (length($flag) == 1 ? "-$flag" : "--$flag");
  }
  return join ' ', @parts;
}

sub documented_identities {
  my ($file) = @_;

  open my $fh, '<', $file or die "cannot read $file: $!";
  my (@identities, $in_commands);
  while (my $line = <$fh>) {
    if ($line =~ /^=head1\s+(.*\S)/) {
      $in_commands = ($1 eq 'COMMANDS') ? 1 : 0;
      next;
    }
    next unless $in_commands;
    next unless $line =~ /^=item\s+(.*\S)/;
    push @identities, ($1 =~ /C<([^>]+)>/g);
  }
  close $fh;

  return @identities;
}

subtest 'every registered filter has a readable identity' => sub {
  my $compressor = MCP::Run::Compress->new;

  for my $key (sort keys %{ $compressor->filters }) {
    my $filter = $compressor->filters->{$key};
    next if $filter->{parsed_command};

    my @identity = identity_from_regex($filter->{command});
    ok scalar(@identity),
      "regex filter '$filter->{command}' has a documentable identity"
      or diag <<"DIAG";
This filter matches by regex, and the pattern is not a plain anchored
literal, so this test will not guess what command it stands for. Either
simplify the pattern, switch it to a parsed_command, or add it to
%REGEX_IDENTITY in $0 together with the reason it cannot be decoded.
DIAG
  }

  done_testing;
};

subtest 'the %REGEX_IDENTITY overrides are still live' => sub {
  my $compressor = MCP::Run::Compress->new;

  # An override for a filter that no longer exists would silently keep a
  # documentation entry alive that nothing backs any more.
  for my $key (sort keys %REGEX_IDENTITY) {
    ok exists $compressor->filters->{$key},
      "override '$key' still names a registered filter";
  }

  done_testing;
};

subtest 'documentation and filter table agree' => sub {
  my $compressor = MCP::Run::Compress->new;

  my %registered;
  for my $key (sort keys %{ $compressor->filters }) {
    my $filter = $compressor->filters->{$key};
    my @identity
      = $filter->{parsed_command}
      ? identity_from_parsed($filter->{parsed_command})
      : identity_from_regex($filter->{command});
    $registered{$_} = 1 for @identity;
  }

  my %documented = map { $_ => 1 } documented_identities($POD_FILE);

  my @promised_but_missing = sort grep { !$registered{$_} } keys %documented;
  my @registered_but_silent = sort grep { !$documented{$_} } keys %registered;

  is_deeply \@promised_but_missing, [],
    'no command is documented without a filter'
    or diag "The reference promises these, but no filter matches them:\n"
    . join('', map {"  $_\n"} @promised_but_missing)
    . "Build the filter, or drop the =item. A reference that lists a command\n"
    . "the compressor ignores is worse than one that stays quiet about it.\n";

  is_deeply \@registered_but_silent, [], 'no filter is left undocumented'
    or diag "These filters exist, but the reference never mentions them:\n"
    . join('', map {"  $_\n"} @registered_but_silent)
    . "Add an =item C<...> for each under the fitting =head2 in the COMMANDS\n"
    . "section, describing what the filter actually does to the output.\n";

  note sprintf 'reference and filter table agree on %d command identities',
    scalar keys %registered;

  done_testing;
};

done_testing;
