#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper qw{Dumper};
use File::Basename qw{basename};
use Getopt::Std;
use ExtUtils::MakeMaker::META_MERGE::GitHub;
$Data::Dumper::Indent  = 1; #smaller index
$Data::Dumper::Terse   = 1; #remove $VAR1 header

my $login_default = 'git';
my $host_default  = 'github.com'; #support gitlab
my $owner_default = '';
my $repo_default  = '';
my @return        = qx{git remote -v 2> /dev/null};
if (@return) {
  my $line  = $return[0];
  chomp $line;
  my @parts = split /\s+/, $line;
  my $git   = $parts[1];
  if ($git =~ m/\A([^:]+)@([^:]+):([^\/]+)\/([^\.]+)\.git\Z/) {
    $login_default = $1;
    $host_default  = $2;
    $owner_default = $3;
    $repo_default  = $4;
  } else {
    warn(qq{Warning: git url "$git" not matched\n});
  }
} else {
  warn(qq{Warning: git repository not found in path\n});
}

my $basename   = basename($0);
my $syntax     = qq{Syntax: $basename [-h host] [-l login] [[owner] repository_name]\n};
my $opt        = {};
getopts('h:l:', $opt);
my $owner      = shift       || $owner_default or die($syntax);
my $repo       = shift       || $repo_default  or die($syntax);
my $login      = $opt->{'l'} || $login_default or die($syntax);
my $host       = $opt->{'h'} || $host_default  or die($syntax);
my $mm         = ExtUtils::MakeMaker::META_MERGE::GitHub->new(
                   login => $login,
                   host  => $host,
                   owner => $owner,
                   repo  => $repo,
                 );
my %META_MERGE = $mm->META_MERGE;
print Dumper(\%META_MERGE);

__END__

=head1 NAME

perl-ExtUtils-MakeMaker-META_MERGE-GitHub.pl - Perl script to generate META_MERGE from current path github.com repository

=cut
