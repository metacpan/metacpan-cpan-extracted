use strict;
use warnings;

# just like t/01-basic.t, but we have more than one conflicts_module

use Path::Tiny;
my $code = path('t', '01-basic.t')->slurp_utf8;

$code =~ s/(\[ 'Test::CheckBreaks' => \{ conflicts_module => )'Moose::Conflicts'/$1\[ qw\(Foo::Conflicts Bar::Conflicts\) \]/;

# note we expect the modules in reverse (alphabetical) order
$code =~ s/'Moose::Conflicts'/qw(Bar::Conflicts Foo::Conflicts)/g;

eval $code;
die $@ if $@;
