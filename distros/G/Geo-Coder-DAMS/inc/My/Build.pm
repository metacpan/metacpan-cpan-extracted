package My::Build;

use strict;
use warnings;
use base 'Module::Build::WithXSpp';

sub new {
    my $class = shift;
    $class->SUPER::new(
        extra_linker_flags => [qw(-ldams)],
        @_,
    );
}

1;
