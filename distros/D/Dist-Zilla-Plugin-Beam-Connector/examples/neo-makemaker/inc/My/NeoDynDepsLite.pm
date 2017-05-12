use 5.006;
use strict;
use warnings;

package inc::My::NeoDynDepsLite;

# ABSTRACT: A Lightweight injector thingy

# AUTHORITY

# Look ma, no Dzil! no Moose! Nothing!

sub new { return bless { ref $_[1] ? %{ $_[1] } : @_[ 1 .. $#_ ] }, $_[0] }

# This is obviously a rediculously tiny and simple big of code
# in comparison with the normal shenanigans.
sub inject_prelude {
  my ( $self, $event ) = @_;
  my $text = $event->prelude;
  my $letter = $self->{letter} || 'H';
  $text .= <<"EOF";
print "This message brought to you by the letter $letter";
EOF
  $event->prelude($text);
  return;
}

1;
