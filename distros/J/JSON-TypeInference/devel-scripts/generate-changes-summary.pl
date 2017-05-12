#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long qw(:config posix_default no_ignore_case bundling);
use Pod::Usage qw(pod2usage);

sub capture {
  my ($cmd) = @_;
  my $out = `$cmd`;
  chomp $out;
  return $out;
}

sub fetch_latest_tag {
  return capture(q!git for-each-ref --sort=-committerdate --format='%(refname:short)' -- refs/tags/ | head -1!);
}

sub merge_commit_ltsv {
  my ($from) = @_;
  my $log = capture(qq!git log --merges --reverse --format='subject:%s%x09body:%b' $from!);
  my @lines = split "\n", $log;
  return [ map {
    my @entries = split "\t", $_;
    +{ map { split ':', $_, 2 } @entries };
  } @lines ];
}

sub extract_pull_request_id {
  my ($text) = @_;
  my ($id) = $text =~ m/\AMerge pull request #(\d+)/;
  return $id;
}

sub format_change {
  my ($change) = @_;
  return sprintf '    - #%d %s', $change->{pull_request_id}, $change->{body};
}

GetOptions(
  \my %options,
  qw(
    help
    all
    from=s
  )
);
pod2usage(-verbose => 1, -exitval => 0) if $options{help};
die 'Either --all or --from is available'
  if exists $options{all} && exists $options{from};

my $from_clause = $options{all} ? '' : ($options{from} // fetch_latest_tag()) . '...';
my $summaries = [ map {
  keys %$_ ?
    +{ %$_, pull_request_id => extract_pull_request_id($_->{subject}) } :
    ()
} @{merge_commit_ltsv($from_clause)} ];

print format_change($_) . "\n" for (@$summaries);

__END__

=encoding utf-8

=head1 SYNOPSIS

    $ generate-changes-summary.pl [--all|--from COMMIT]

=head1 OPTIONS

=over 4

=item --all

=item --from COMMIT

=back

=cut

