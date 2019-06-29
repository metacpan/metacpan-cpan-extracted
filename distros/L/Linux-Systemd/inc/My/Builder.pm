package My::Builder;

use v5.16;
use strict;
use warnings;
use base 'Module::Build';

use ExtUtils::PkgConfig;

sub new {
    my ($class, %args) = @_;

    my $pkg_name = 'libsystemd';
    my %pkg_info;

    eval {
        %pkg_info = ExtUtils::PkgConfig->find($pkg_name);
    };
    if ($@) {
        say
          'Do you need to install libsystemd-dev (debian) or systemd-devel (fedora)?';
        exit;
    }

    say "Found libsystemd-dev version: $pkg_info{modversion}";

    if (defined $pkg_info{cflags}) {
        $args{extra_compiler_flags} = $pkg_info{cflags};
    }
    $args{extra_compiler_flags} .= ' -std=c99';
    $args{extra_linker_flags} = $pkg_info{libs};

    my $builder = Module::Build->new(%args);

    return $builder;
}

1;
