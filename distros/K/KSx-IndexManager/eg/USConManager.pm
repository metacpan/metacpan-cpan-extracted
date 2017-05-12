# this takes the example application from KinoSearch and shows how it could be
# written using IndexManager. -- hdp, 2007-07-01

use strict;
use warnings;

package USConManager;

use base qw(KSx::IndexManager);
use File::Basename qw(basename);

__PACKAGE__->mk_group_accessors(inherited => qw(base_url));
__PACKAGE__->base_url('/us_constitution');
__PACKAGE__->schema_class('USConSchema');

# expect a filename as input
# this is largely a copy of invindexer.plx from the KS example
sub to_doc {
  my ($self, $filepath) = @_;

  open my $fh, '<', $filepath or die "Can't open $filepath: $!";
  my $raw = do { local $/; <$fh> };

  my %doc = (
    url => join("/", $self->base_url, basename($filepath)),
  );

  $raw =~ m#<title>(.*?)</title>#s
      or die "couldn't isolate title in '$filepath'";
  $doc{title} = $1;
  $raw =~ m#<div id="bodytext">(.*?)</div><!--bodytext-->#s
      or die "couldn't isolate bodytext in '$filepath'";
  $doc{content} = $1;
  $doc{content} =~ s/<.*?>/ /gsm;

  return \%doc;
}
  
1;
