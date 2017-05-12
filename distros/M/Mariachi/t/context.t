#!perl -w
use strict;
use Test::More;
use FindBin;
use File::Spec::Functions;

# right, how does this work?

# There are a bunch of messages in testmess, each ending in .message
# For each of these messages there are several test files that represent
# what should be returned by the various first functions.
#
#  foo.message       - should be the message
#  foo.paragraph     - the first original paragraph of the message
#  foo.sentence      - the first original sentence of the message
#  foo.line          - the first two original lines of the message
#
# each of these files can be terminated by a __END__ - everything after
# this will be ignored.  Note that unlike Perl's __END__ this can happen
# in the middle of a line and doens't require a line to iteself.

# Read in the files we're going to test:

opendir DIRHANDLE, catdir($FindBin::Bin, "testmess")
 or die "Can't open testdir: $!";

my @files;
foreach my $file (readdir DIRHANDLE)
{
  next unless $file =~ /\.message$/;
  $file =~ s/.message$//;
  push @files, $file;
}

close DIRHANDLE;

# print out the number of tests we're going to run
plan tests => 1 + @files*4;

# load the Mariachi message module
use_ok('Mariachi::Message');

# process each of the messages
foreach my $file (@files)
{
  my $m = Mariachi::Message->new(slurp("$file.message"));

  isa_ok($m, 'Mariachi::Message', "message '$file' loaded");

  SKIP:
  {
    skip "No .paragraph", 1
     unless -e catfile($FindBin::Bin,"testmess","$file.paragraph");
    is $m->first_paragraph, slurp("$file.paragraph"),
       "message '$file' paragraph";
  }

  SKIP:
  {
    skip "No .lines", 1
     unless -e catfile($FindBin::Bin,"testmess","$file.lines");
    is $m->first_lines(2), slurp("$file.lines"),
       "message '$file' lines";
  }

  SKIP:
  {
    skip "No .sentence", 1
     unless -e catfile($FindBin::Bin,"testmess","$file.sentence");
    is $m->first_sentence, slurp("$file.sentence"),
       "message '$file' sentence";
  }

}

# load in an entire file, forget the bits after __END__
sub slurp
{
  # get the filename
  my $filename = catfile($FindBin::Bin,"testmess",shift);

  # load that file's content into $file
  local $/ = undef;
  open FH, "<$filename"
   or die "Couldn't open '$filename': $!";
  my $file = <FH>;

  # get rid of bits after __END__ and return
  $file =~ s/__END__.*$//s;
  return $file;
}
