package Javonet::Sdk::Core::RuntimeLib;
use warnings;
use strict;
use Moose;

my %runtimes = (
    'Clr'       => 0,
    'Go'        => 1,
    'Jvm'       => 2,
    'Netcore'   => 3,
    'Perl'      => 4,
    'Python'    => 5,
    'Ruby'      => 6,
    'Nodejs'    => 7,
    'Cpp'       => 8
);

sub get_runtime {
    my $runtime = shift;
    return $runtimes{$runtime};
}

no Moose;

1;
