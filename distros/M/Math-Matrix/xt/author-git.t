#!perl

BEGIN {
    unless ($ENV{AUTHOR_TESTING}) {
        print "1..0 # SKIP these tests are for author testing";
        exit;
    }
}

use strict;
use warnings;

use Test::More tests => 7;

use IO::Pipe;
use IO::File;
use File::Which qw< which >;
use Sort::Versions qw< versioncmp >;

###############################################################################
# See if we can find a "git" program.
###############################################################################

my $git = which('git');

ok($git, qq|found "git" program|)
  or BAIL_OUT(qq|Unable to find the "git" program!|);

diag(qq|the "git" program is installed as "$git"|);

###############################################################################
# See if we can get the "git" version number.
###############################################################################

my $gitver;
{
    my $pipe = IO::Pipe -> new();
    my @args = ('git --version 2>/dev/null');
    $pipe -> reader(@args);
    my $output = <$pipe>;
    ($gitver) = $output =~ /^git version (\S+)/
      if defined $output;
}

ok($gitver, qq|got "git" version number|)
  or BAIL_OUT(qq|Unable to get the "git" version number!|);

diag(qq|the "git" program is version "$gitver"|);

# See if the working directory is clean.

{
    my $pipe = IO::Pipe -> new();
    my @args = ('git', 'status', '--porcelain');
    $pipe -> reader(@args);
    my @output = <$pipe>;
    ok(@output == 0, 'working directory is clean')
      or diag(qq|  Expected no output from "@args", but got:\n\n|,
              map("    $_", @output), "\n");
}

###############################################################################
# See if the most recent tag matches the most recent entry in the change log.
###############################################################################

# Get the tag with the highest version number.

my $newest_tag;
{
    my $pipe = IO::Pipe -> new();
    my @args = ('git', 'tag', '-l');
    $pipe -> reader(@args);
    my @tags = ();
    while (defined(my $tag = <$pipe>)) {
        $tag =~ s/\s+\z//;
        push @tags, $tag;
    }
    $pipe -> close() or die "can't close pipe after reading: $!";
    @tags = sort { versioncmp($a, $b) } @tags;
    $newest_tag = $tags[-1];
}

if (defined $newest_tag) {
    diag(qq|the most recent git tag is "$newest_tag"|);
} else {
    diag(qq|no git tags found|);
}

# See if we find a change log files.

my $changes_file;
my $num_changes_file;
my @changes_files = ('CHANGES', 'Changes', 'ChangeLog', 'CHANGELOG');
for my $file (@changes_files) {
    next unless -f $file;
    $changes_file = $file;
}

ok(defined($changes_file), qq|found change log file "$changes_file"|)
  or diag("  Found no change log file. Tried: "
          . join(", ", @changes_files));

ok(-s($changes_file), 'changes file is non-empty')
  or diag("  Change log file is empty");

# Get the most recent version number in the changes file.

my $changes_ver;
SKIP: {
    skip 'no changes file found', 1 unless defined $changes_file;

    # Get first line in the changes file.

    my $fh = IO::File -> new($changes_file)
      or die "$changes_file: can't open file for reading: $!\n";
    my $line = <$fh>;
    $line =~ s/\s+\z//;
    $fh -> close()
      or die "$changes_file: can't close file after reading: $!\n";

    # The version should be the first field on the line.
    $changes_ver = (split /\s+/, $line)[0];
}

if (defined $changes_ver) {
    diag(qq|the most recent change log version number is "$changes_ver"|);
} else {
    diag(qq|no change log version number found|);
}

BAIL_OUT('missing git tag and/or change log version number')
  unless (defined($changes_ver) && defined($newest_tag));

ok($changes_ver eq $newest_tag,
   'most recent git tag matches most recent version in change log')
  or diag("      most recent git tag: $newest_tag\n" .
          "    version in change log: $changes_ver");

###############################################################################
# See if the commit corresponding to the most recent tag is also the most
# recent commit.
###############################################################################

# Get the commit corresponding to the most recent tag.

my $commit_tagged;
{
    my $pipe = IO::Pipe -> new();
    my @args = ('git', 'rev-parse', $newest_tag);
    $pipe -> reader(@args);
    $commit_tagged = <$pipe>;
    chomp $commit_tagged if defined $commit_tagged;
}

# Get the most recent commit.

my $commit_newest;
{
    my $pipe = IO::Pipe -> new();
    my @args = ('git', 'log', '-n', '1', '--pretty=format:%H');
    $pipe -> reader(@args);
    $commit_newest = <$pipe>;
    chomp $commit_newest if defined $commit_newest;;
}

ok($commit_tagged eq $commit_newest,
   'the tagged commit is also the most recent commit')
  or diag("    newest commit: $commit_newest\n" .
          "    tagged commit: $commit_tagged");
