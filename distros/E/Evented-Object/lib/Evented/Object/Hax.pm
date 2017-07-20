# Copyright (c) 2011-16, Mitchell Cooper
#
# Evented::Object: a simple yet featureful base class event framework.
# https://github.com/cooper/evented-object
#
package Evented::Object::Hax;

use warnings;
use strict;
use 5.010;

use List::Util qw(first);

our $VERSION = '5.65';

# exported import subroutine.
sub import {
    my ($export_pkg, $import_pkg, @import) = (shift, (caller)[0], @_);

    # import each item.
    foreach my $item (@import) {
        my $code = $export_pkg->can($item) or next;
        export_code($import_pkg, $item, $code);
    }

}

# fetch a symbol from package's symbol table.
sub get_symbol {
    my ($package, $variable, $ref) = @_;

    # must start with a sigil.
    return if $variable !~ m/^([@\*%\$])(\w+)$/;
    my ($sigil, $var_name) = ($1, $2);

    my $symbol = $package.q(::).$var_name;
    no strict 'refs';

    # find the symbol.
    if ($sigil eq '$') { return $ref ? \$$symbol : $$symbol }
    if ($sigil eq '@') { return $ref ? \@$symbol : @$symbol }
    if ($sigil eq '*') { return $ref ? \*$symbol : *$symbol }
    if ($sigil eq '%') { return $ref ? \&$symbol : %$symbol }

    return;
}

# fetch a reference to a symbol.
sub get_symbol_ref { get_symbol(@_, 1) }

# set a symbol in package's symbol table.
sub set_symbol {
    my ($package, $variable, @values) = @_;

    # several symbols.
    if (ref $variable && ref $variable eq 'HASH') {
        set_symbol($package, $_, $variable->{$_}) foreach keys %$variable;
        return;
    }

    # must start with a sigil.
    return if $variable !~ m/^([@\*%\$])(\w+)$/;
    my ($sigil, $var_name) = ($1, $2);

    my $symbol = $package.q(::).$var_name;
    no strict 'refs';

    # find the symbol.
    if ($sigil eq '$') { $$symbol = $values[0] }
    if ($sigil eq '@') { @$symbol = @values    }
    if ($sigil eq '*') { *$symbol = $values[0] }
    if ($sigil eq '%') { %$symbol = @values    }

    return;
}

# export a subroutine.
# export_code('My::Package', 'my_sub', \&_my_sub)
sub export_code {
    my ($package, $sub_name, $code) = @_;
    no strict 'refs';
    *{"${package}::$sub_name"} = $code;
}

# delete a subroutine.
sub delete_code {
    my ($package, $sub_name) = @_;
    no strict 'refs';
    undef *{"${package}::$sub_name"};
}

# adds a package to an ISA list if the
# package does not inherit from it already.
# package_make_child('Evented::Person', 'Evented::Object', 1)
sub make_child {
    my ($package, $make_parent, $at_end) = @_;
    my $isa = get_symbol_ref($package, '@ISA');

    # package already inherits directly.
    return 1 if scalar first { $_ eq $make_parent } @$isa;

    # check each class in ISA for inheritance.
    foreach my $parent (@$isa) {
        return 1 if $parent->isa($make_parent);
    }

    # add to ISA.
    unshift @$isa, $make_parent unless $at_end;
    push    @$isa, $make_parent if     $at_end;

    return 1;

}

1;
