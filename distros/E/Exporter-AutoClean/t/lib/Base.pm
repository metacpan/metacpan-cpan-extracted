package Base;
use strict;
use warnings;
use Exporter::AutoClean;

sub import {
    my $class  = shift;
    my $caller = caller;

    {
        no strict 'refs';
        push @{ $caller . '::ISA' }, $class;
    }

    Exporter::AutoClean->export(
        $caller,
        method => sub { 'export function' },
    );
}

sub method {
    'object method';
}

1;
