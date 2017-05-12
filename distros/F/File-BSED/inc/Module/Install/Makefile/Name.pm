package Module::Install::Makefile::Name;

use Module::Install::Base;
@ISA = qw(Module::Install::Base);

$VERSION = '0.67';

use strict;

sub determine_NAME {
    my $self = shift;
    my @modules = glob('*.pm');

    require File::Find;
    File::Find::find( sub {
        push @modules, $File::Find::name if /\.pm/i;
    }, 'lib');

    if (@modules == 1) {
        local *MODULE;
        open MODULE, $modules[0] or die $!;
        while (<MODULE>) {
            next if /^\s*(?:#|$)/;
            $self->module_name($1) if /^\s*package\s+(\w[\w:]*)\s*;\s*$/;
            last;
        }
    }

    return if $self->module_name;

    my $name = MM->guess_name or die <<"END_MESSAGE";
Can't determine a NAME for this distribution.
Please use the 'name' function in Makefile.PL.
END_MESSAGE

    $name =~ s/-/::/g;
    $self->module_name($name);
    return $name;
}

1;
