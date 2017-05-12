package My::Builder;

use v5.10.1;
use strict;
use warnings;
use base 'Module::Build';
use lib "inc";

use Try::Tiny;
use ExtUtils::PkgConfig;

sub new {
    my ($class, %args) = @_;

    my $pkg_name = 'libatasmart';
    my %pkg_info;

    try {
        %pkg_info = ExtUtils::PkgConfig->find($pkg_name);
    }
    catch {
        say "Do you need to install libatasmart-dev?";
        exit;
    };

    say "Found libatasmart version: $pkg_info{modversion}";

    if (defined $pkg_info{cflags}) {
        $args{extra_compiler_flags} = $pkg_info{cflags};
    }
    $args{extra_linker_flags} = $pkg_info{libs};

    my $builder = Module::Build->new(%args);

    return $builder;
}

1;
