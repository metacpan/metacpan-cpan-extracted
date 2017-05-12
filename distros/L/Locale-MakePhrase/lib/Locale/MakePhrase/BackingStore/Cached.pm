package Locale::MakePhrase::BackingStore::Cached;
our $VERSION = 0.2;
our $DEBUG = 0;

#
# This is just a generic caching in-memory backing store, which does
# no translation whatsoever.  Its really just a lame example...!
#
# The returned objects are just the requested languages, used with
# the key.
#

use strict;
use warnings;
use utf8;
use Memoize;
use base qw(Locale::MakePhrase::BackingStore);

#--------------------------------------------------------------------------
#
sub get_rules {
  my ($self,$key,$context,$languages) = @_;
  my @translations;
  foreach my $language (@$languages) {
    my $rule = new Locale::MakePhrase::LanguageRule(
      language => $language,
      translation => "~[$language~] -> $key",
    );
    push @translations, $rule;
  }
  print STDERR "Found translations:\n", Dumper(@translations) if $DEBUG;
  return \@translations;
}

#--------------------------------------------------------------------------
#
# Memoize the function, so that it gets faster...
#
# We should never be calling 'get_translations' in list context as we always
# want to return a reference to a list, not an actual list (for efficency).
#
memoize('get_rules', LIST_CACHE => "FAULT");

1;
__END__
#--------------------------------------------------------------------------

