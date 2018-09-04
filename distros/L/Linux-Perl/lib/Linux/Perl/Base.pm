package Linux::Perl::Base;

use strict;
use warnings;

sub _get_arch_module {
    my ($class) = @_;

    return $class if caller ne $class;

    require Linux::Perl::ArchLoader;

    return Linux::Perl::ArchLoader::get_arch_module($class);
}

1;
