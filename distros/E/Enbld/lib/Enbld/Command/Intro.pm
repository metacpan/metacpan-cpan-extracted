package Enbld::Command::Intro;

use strict;
use warnings;

use parent qw/Enbld::Command/;

sub do {

    my $module_path = $INC{'Enbld/Command.pm'};
    $module_path =~ s{/Command\.pm$}{};

    my $path = $module_path . '.pm';

    system ( 'perldoc', $path );

    return $_[0];
}

1;
