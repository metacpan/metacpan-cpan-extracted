#!/usr/bin/perl -w

# some basic tests of Mediawiki::POD with graphs
use Test::More;

BEGIN
  {
  plan tests => 10;
  chdir 't' if -d 't';

  use lib '../lib';

  use_ok (qw/ Mediawiki::POD /);
  }

can_ok ( 'Mediawiki::POD', qw/
  as_html
  /);

my $pod = Mediawiki::POD->new();

is (ref($pod), 'Mediawiki::POD');

#############################################################################
#############################################################################
# Some parsing tests

my $in = read_file("pod/common.pod");

my $html = $pod->as_html($in);

unlike ($html, qr/\n/, 'no newlines');

$pod->remove_newlines(0);
$html = $pod->as_html($in);
like ($html, qr/\n/, 'newlines');

like ($html, qr/color: #0000ff/, 'found blue');
like ($html, qr/color: #ff0000/, 'found red');

like ($html, qr/last of the Blue/, 'last graph was not dropped');

#############################################################################
# parsing of autosplit nodes with newlines

$in = read_file("pod/split.pod");
$html = $pod->as_html($in);

like ($html, qr/\n/, 'newlines');

like ($html, qr/split/, 'split node found');

#print STDERR $html;

#############################################################################
#############################################################################
# helper sub

sub read_file
  {
  my ($file) = @_;

  open my $FILE, "$file" or die ("Cannot read $file: $!");
  local $/ = undef;
  my $data = <$FILE>;
  close $FILE;
  $data;
  }
