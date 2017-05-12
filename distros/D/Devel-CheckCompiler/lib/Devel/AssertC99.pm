package Devel::AssertC99;
use strict;
use warnings;
use utf8;
use Devel::CheckCompiler qw/check_c99_or_exit/;

sub import { check_c99_or_exit() }

1;
__END__

=head1 NAME

Devel::AssertC99 - C99 is available

=head1 SYNOPSIS

    use Module::Build;
    use Devel::AssertC99; # <== check at here

    my $builder = Module::Build->new(
        configure_requires => {
            'Devel::AssertC99',
        },
        ...
    );
    $builder->create_build_script;

=head1 DESCRIPTION

This module checks C99 compiler's availability. If it's not available, exit with code 0.

It makes CPAN testers status as N/A.

