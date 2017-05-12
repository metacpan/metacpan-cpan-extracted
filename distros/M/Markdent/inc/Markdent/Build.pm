package Markdent::Build;

use strict;
use warnings;

use base 'Module::Build';

sub find_test_files {
    my $self = shift;

    my $tests = $self->SUPER::find_test_files(@_);

    push @{$tests}, $self->expand_test_dir('xt')
        if $ENV{AUTHOR_TESTING};

    return $tests;
}

1;
