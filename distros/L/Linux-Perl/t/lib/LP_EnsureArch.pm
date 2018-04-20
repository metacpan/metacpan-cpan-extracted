package LP_EnsureArch;

use strict;
use warnings;

use Test::More;

use Module::Load;
use Linux::Perl::Constants;

use File::Spec;

sub ensure_support {
    my ($module) = @_;

    my $supported = ($^O eq 'linux');
    my $arch = Linux::Perl::Constants::get_architecture_name();

    $supported &&= do {
        my @path = ( 'Linux', 'Perl', $module, "$arch.pm" );
        !!grep { -e File::Spec->catfile( $_, @path ) } @INC;
    };

    if (!$supported) {
        eval {
            require Linux::Seccomp;

            my $x86_64_module = "Linux::Perl::$module\::x86_64";

            require Module::Load;
            Module::Load::load($x86_64_module);

            my $ns_hr = do {
                no strict 'refs';
                \%{"$x86_64_module\::"};
            };

            for my $call ( map { m<\ANR_(.+)> ? $1 : () } keys %$ns_hr ) {
                diag sprintf("Need call: $call (%d)", Linux::Seccomp::syscall_resolve_name($call));
            }
        };
        warn if $@;

        diag "“$module” does not work with $^O/$arch";

        plan tests => 1;
        ok 1;
        done_testing();
        exit;
    }

    return $arch;
}

1;
