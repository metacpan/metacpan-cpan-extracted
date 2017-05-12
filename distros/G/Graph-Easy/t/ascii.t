#!/usr/bin/perl -w

use Test::More;
use strict;

sub _write_utf8_file
{
    my ($out_path, $contents) = @_;

    open my $out_fh, '>:encoding(utf8)', $out_path
        or die "Cannot open '$out_path' for writing - $!";

    print {$out_fh} $contents;

    close($out_fh);

    return;
}

# test text file input => ASCII output, and back to as_txt() again

BEGIN
   {
   plan tests => 451;
   # TEST
   use_ok ("Graph::Easy") or die($@);
   # TEST
   use_ok ("Graph::Easy::Parser") or die($@);
   };

#############################################################################
# parser object

my $parser = Graph::Easy::Parser->new( debug => 0);

is (ref($parser), 'Graph::Easy::Parser');
is ($parser->error(), '', 'no error yet');

opendir DIR, "t/in" or die ("Cannot read dir 'in': $!");
my @files = readdir(DIR); closedir(DIR);

my @failures;

eval { require Test::Differences; };

binmode (STDERR, ':utf8') or die ("Cannot do binmode(':utf8') on STDERR: $!");
binmode (STDOUT, ':utf8') or die ("Cannot do binmode(':utf8') on STDOUT: $!");

foreach my $f (sort @files)
  {
      my $path =  "t/in/$f";
  next unless -f $path; 			# only files

  next unless $f =~ /\.txt/;			# ignore anything else

  print "# at $f\n";
  my $txt = readfile($path);
  my $graph = $parser->from_text($txt);		# reuse parser object

  $txt =~ s/\n\s+\z/\n/;			# remove trailing whitespace
  $txt =~ s/(^|\n)\s*#[^#]{2}.*\n//g;		# remove comments

  $f =~ /^(\d+)/;
  my $nodes = $1;

  if (!defined $graph)
    {
    warn ("Graph input was invalid: " . $parser->error());
    push @failures, $f;
    next;
    }
  is (scalar $graph->nodes(), $nodes, "$nodes nodes");

  # for slow testing machines
  $graph->timeout(20);
  my $ascii = $graph->as_ascii();

  my $out_path = "t/out/$f";
  my $out = readfile($out_path);
  $out =~ s/(^|\n)\s*#[^#=]{2}.*\n//g;		# remove comments
  $out =~ s/\n\n\z/\n/mg;			# remove empty lines

# print "txt: $txt\n";
# print "ascii: $ascii\n";
# print "should: $out\n";

  if (!
    is ($ascii, $out, "from $f"))
    {
        if ($ENV{__SHLOMIF__UPDATE_ME})
        {
            _write_utf8_file($out_path, $ascii);
        }
    push @failures, $f;
    if (defined $Test::Differences::VERSION)
      {
      Test::Differences::eq_or_diff ($ascii, $out);
      }
    else
      {
      fail ("Test::Differences not installed");
      }
    }

  my $txt_path = "t/txt/$f";
  # if the txt output differes, read it in
  if (-f $txt_path)
    {
    $txt = readfile($txt_path);
    }
#  else
#    {
#    # input might have whitespace at front, remove it because output doesn't
#    $txt =~ s/(^|\n)\x20+/$1/g;
#    }

  if (!
    is ($graph->as_txt(), $txt, "$f as_txt"))
    {
        if ($ENV{__SHLOMIF__UPDATE_ME})
        {
            _write_utf8_file($txt_path, scalar( $graph->as_txt() ));
        }
    push @failures, $f;
    if (defined $Test::Differences::VERSION)
      {
      Test::Differences::eq_or_diff ($graph->as_txt(), $txt);
      }
    else
      {
      fail ("Test::Differences not installed");
      }
    }

  # print a debug output
  my $debug = $ascii;
  $debug =~ s/\n/\n# /g;
  print "# Generated:\n#\n# $debug\n";
  }

if (@failures)
  {
  print "# !!! Failed the following tests:\n";
  for my $f (@failures)
    {
    print "#      $f\n";
    }
  print "# !!!\n\n";
  }

1;

sub readfile
  {
  my ($filename) = @_;

  open my $fh, $filename or die ("Cannot read file ${filename}: $!");
  binmode ($fh, ':utf8') or die ("Cannot do binmode(':utf8') on ${fh}: $!");
  local $/ = undef;				# slurp mode
  my $doc = <$fh>;
  close $fh;

  $doc;
  }
