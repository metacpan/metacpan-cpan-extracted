package Device::ISDN::OCLM::HTML;

use strict;

use HTML::Element;

use vars qw ($VERSION);

$VERSION = "0.40";

sub
_toText
{
  my ($class, $html) = @_;

  my $text = undef;

  $html->traverse (sub {
    my ($node) = @_;
    if (!ref ($node)) {
      if (!defined ($text)) {
	$text = $node;
      } else {
	$text .= $node;
      }
    }
    return 1;
  });

  if (defined ($text)) {
    $text =~ s/^\s*//;
    $text =~ s/\s*$//;
    $text = undef if ($text eq '');
  }

  return $text;
}

1;
