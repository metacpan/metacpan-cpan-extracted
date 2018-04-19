package Linux::Perl::ArchLoader;

use strict;
use warnings;

use Module::Load ();
use Linux::Perl::Constants ();

sub get_arch_module {
    my $module_name = shift() . '::' . Linux::Perl::Constants::get_architecture_name();
    Module::Load::load($module_name);

    return $module_name;
}

1;
