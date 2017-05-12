package Test;
use strict;
use warnings;

use base 'Exporter';
use Cwd qw(cwd abs_path);
use Config;

our @EXPORT = qw(
    $sep
    cwd
    abs_path
    set_env_min
    set_env_more
);

our $sep = $Config::Config{path_sep};

sub import {
    strict->import;
    warnings->import;
    goto &Exporter::import;
}

sub set_env_min {
    $ENV{PATH} = join $sep,
        $Config::Config{bin},
        $Config::Config{installbin},
        $Config::Config{installsitebin},
        ;
    delete $ENV{PERL5LIB};
}

sub set_env_more {
    set_env_min();
    $ENV{PERL5LIB} = join $sep,
        'foo/lib',
        'bar/lib',
        ;
}

1;
