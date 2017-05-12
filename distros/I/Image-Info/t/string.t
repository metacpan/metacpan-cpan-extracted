#!/usr/bin/perl -w

# Load file into a string into memory and then test it

use strict;
use Test::More;
use File::Basename qw(basename);
use File::Spec;

my $tests_per_file; BEGIN { $tests_per_file = 3 }

my (@tests, $tests);

BEGIN
   {
   @tests = grep { !/\.wbmp$/ } glob("img/test*");
   $tests = (scalar @tests) * $tests_per_file;
   plan tests => $tests;
   chdir 't' if -d 't';
   use lib '../lib';
   };

my $requires = 
  {
  xpm => ['Image::Xpm'],
  xbm => ['Image::Xbm'],
  svg => ['XML::LibXML::Reader', 'XML::Simple'],
  };

my $expected_warnings =
  {
  'test-unknowncode.gif' => 'Unknown introduced code 10, ignoring following chunks',
  'test-corruptchunk.jpg' => 'Corrupt JPEG data, 4 extraneous bytes before marker 0xdb',
  };

SKIP:
  {
  skip( 'Need either Perl 5.008 or greater, or IO::String for these tests', $tests )
    unless $] >= 5.008 || do
      {
      eval "use IO::String;";
      $@ ? 0 : 1;
      };

  use Image::Info qw(image_info);

  my $updir = File::Spec->updir();

TESTFILES: for my $f (@tests)
    {
    # extract the extension of the image file
    $f =~ /\.([a-z]+)\z/i; my $x = lc($1 || '');

    SKIP:
      {
      # test for loading the nec. library
      if (exists $requires->{$x})
        {
	for my $r (@{ $requires->{$x} })
          {
          skip( "Need $r for this test", $tests_per_file ) && next TESTFILES
            unless do {
              eval "use $r;";
              $@ ? 0 : 1;
            };
          }
        }

      # 2 tests follow:

      my $file = File::Spec->catfile($updir,$f);
      my $base = basename $file;
      my $h1 = image_info($file);

      is ($h1->{error}, undef, 'no error');
      my $expected_warning = $expected_warnings->{$base};
      is ($h1->{Warn}, $expected_warning, 'no/expected warning');

      my $img = cat($file);
      my $h2 = image_info(\$img);

      is_deeply ($h1, $h2, $file);
      } # end inner SKIP
    } # end for each file
  } # end SKIP all block

sub cat {
    my $file = shift;
    local(*F, $/);
    open(F, $file) || die "Can't open $file: $!";
    binmode F;
    my $c = <F>;
    close(F);
    $c;
}

