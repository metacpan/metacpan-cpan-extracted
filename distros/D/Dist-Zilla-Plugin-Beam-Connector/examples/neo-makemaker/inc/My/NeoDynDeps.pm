use 5.006;
use strict;
use warnings;

package inc::My::NeoDynDeps;

# ABSTRACT: A new dependency injector thingy

# AUTHORITY

use Moose qw( with );
with 'Dist::Zilla::Role::Plugin';
no Moose;
__PACKAGE__->meta->make_immutable;

# This is obviously a rediculously tiny and simple big of code
# in comparison with the normal shenanigans.
sub inject_prelude {
    my ( $self, $event ) = @_;
    my $text = $event->prelude;
    $text .= <<'EOF';
if( 'MSWin32' eq $^OS ) {
  die "Sorry, Win32 Unsupported";
}
EOF
    $event->prelude($text);
    return;
}

1;

