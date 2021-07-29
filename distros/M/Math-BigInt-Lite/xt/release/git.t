#!perl

use strict;
use warnings;

use IO::Pipe;
use IO::File;
use IO::Dir;
use File::Which    qw< which >;
use Sort::Versions qw< versioncmp >;

$| = 1;

my $testno = 0;
my $failno = 0;

END {
    print "1..$testno\n";
    exit $failno == 0 ? 0 : 1;
}

################################################################################
# See if we can find a "git" program.
################################################################################

my $git = which('git');

print "not " unless $git;
print "ok ", ++$testno, " - found 'git' program";
print " ('$git')" if $git;
print "\n";

# There is no point in continuing without the 'git' program.

unless ($git) {
    print STDERR "#   can't continue testing without a 'git' program\n";
    exit 1;
}

################################################################################
# See if we can get the "git" version number.
################################################################################

my $gitver;
{
    my $pipe = IO::Pipe -> new();
    my @args = ('git --version 2>/dev/null');
    $pipe -> reader(@args);
    my $output = <$pipe>;
    ($gitver) = $output =~ /^git version (\S+)/
      if defined $output;
}

unless ($gitver) {
    print "not ";
    $failno++;
}
print "ok ", ++$testno, " - found 'git' version number";
print " ('$gitver')" if $gitver;
print "\n";

################################################################################
# See if the working directory is clean.
################################################################################

{
    my $pipe = IO::Pipe -> new();
    my @args = ('git', 'status', '--porcelain');
    $pipe -> reader(@args);
    my @output = <$pipe>;
    my $ok = @output == 0;
    unless ($ok) {
        print "not ";
        $failno++;
    }
    print "ok ", ++$testno, " - working directory is clean\n";
    unless ($ok) {
        print STDERR "#   expected no output from '@args', but got:\n\n",
          map("    $_", @output), "\n";
    }
}

################################################################################
# Search for changelog files.
################################################################################

my @files;

my $dh = IO::Dir -> new('.')
  or die "can't open the current directory for reading: $!";

for my $filename ($dh -> read()) {

    # changelog, changelog.txt, changes, changes.log, changes.txt changes.log
    next unless $filename =~ / ^
                               (
                                   changelog ( \. txt )?
                               |
                                   changes ( \. ( log | txt ) )?
                               )
                               $
                             /ix && -f $filename;
    my @info = stat(_);
    my ($dev, $ino, $size) = @info[0, 1, 7];
    push @files, $filename;
}

$dh -> close()
  or die "can't close directory after reading: $!";

unless (@files) {
    print "not ";
    $failno++;
}
print "ok ", ++$testno, " - found changelog file(s)";
print " (", join(", ", map("'$_'", @files)), ")" if @files;
print "\n";

################################################################################
# Read all changelog files, and sort all version numbers.
################################################################################

my @vers = ();

for (my $i = 0 ; $i <= $#files ; $i++) {
    my $filename = $files[$i];

    my $fh = IO::File -> new($filename)
      or die "$filename: can't open file for reading: $!\n";

    while (defined(my $line = <$fh>)) {
        push @vers, $1 if $line =~ /^(\S+)/;
    }

    $fh -> close()
      or die "$filename: can't close file after reading: $!\n";
}

# Sort the versions.

@vers = sort { versioncmp($a, $b) } @vers;

unless (@vers) {
    print "not ";
    $failno++;
}
print "ok ", ++$testno, " - found version number(s) in changelog file(s)";
print " ('$vers[-1]')" if @vers;
print "\n";

# Get most recent version (migth be undef).

my $ver = $vers[-1];

################################################################################
# Get the all the git tags.
################################################################################

my @tags;
{
    my $pipe = IO::Pipe -> new();
    my @args = ('git', 'tag', '-l');
    $pipe -> reader(@args);
    while (defined(my $tag = <$pipe>)) {
        next unless $tag =~ /^v?\d/;
        $tag =~ s/\s+\z//;
        push @tags, $tag;
    }
    $pipe -> close() or die "can't close pipe after reading: $!";
}

# Sort the tags.

@tags = sort { versioncmp($a, $b) } @tags;

unless (@tags) {
    print "not ";
    $failno++;
}
print "ok ", ++$testno, " - found git tag(s)";
print " ('$tags[-1]')" if @tags;
print "\n";

# Get newest tag (might be undef).

my $tag = $tags[-1];

################################################################################
# Compare version number with git tag.
################################################################################

++$testno;
if (@vers and @tags) {
    my $ok = versioncmp($ver, $tag) == 0;
    unless ($ok) {
        print "not ";
        $failno++;
    }
    print "ok ", $testno, " - changelog version matches git tag\n";
    print STDERR <<"EOF" unless $ok;
#   latest version in changelog(s): $ver
#                   latest git tag: $tag
EOF
} else {
    print "ok ", $testno, " - skipped (missing version number or git tag)\n";
}

################################################################################
# See if the commit corresponding to the most recent tag is also the most
# recent commit.
################################################################################

# Get the commit corresponding to the most recent tag.

my $commit_tagged;

++$testno;
if (@tags) {
    my $pipe = IO::Pipe -> new();
    my @args = ('git', 'rev-parse', $tag);
    $pipe -> reader(@args);
    $commit_tagged = <$pipe>;
    chomp $commit_tagged if defined $commit_tagged;

    unless ($commit_tagged) {
        print "not ";
        $failno++;
    }
    print "ok ", $testno, " - tag ('$tag') refers to a commit";
    print " ('$commit_tagged')" if $commit_tagged;
    print "\n";
} else {
    print "ok ", $testno, " - skipped (no tags found)\n";
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

unless ($commit_newest) {
    print "not ";
    $failno++;
}
print "ok ", ++$testno, " - found most recent commit";
print " ('$commit_newest')" if $commit_newest;
print "\n";

print STDERR "#   no commits found\n" unless $commit_newest;

################################################################################
# Compare the two commits.
################################################################################

++$testno;
if (defined $commit_tagged and defined $commit_newest) {
    my $ok = $commit_tagged eq $commit_newest;
    unless ($ok) {
        print "not ";
        $failno++;
    }
    print "ok ", $testno, " - the tagged commit is also the most recent commit\n";
    print STDERR <<"EOF" unless $ok;
#   newest commit: $commit_newest
#   tagged commit: $commit_tagged
EOF
} else {
    print "ok ", $testno, " - skipped (missing commit(s))\n";
}
