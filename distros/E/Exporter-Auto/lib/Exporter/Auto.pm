package Exporter::Auto;
use strict;
use warnings;
use 5.008005;
our $VERSION = '0.04';

use Sub::Identify qw(stash_name);
use B::Hooks::EndOfScope;
use Exporter;

sub import {
    my $klass = caller(0);

    no strict 'refs';
    unshift @{"${klass}::ISA"}, 'Exporter';

    on_scope_end {
        my %hash = %{"${klass}::"};
        while (my ($k, $v) = each %hash) {
            next if $k =~ /^(?:BEGIN|CHECK|END|INIT|UNITCHECK)$/;
            next if $k =~ /^_/;
            next unless *{"${klass}::${k}"}{CODE};
            next if $klass ne stash_name($klass->can($k));
            push @{"${klass}::EXPORT"}, $k;
        }
    };
}

1;
__END__

=encoding utf8

=head1 NAME

Exporter::Auto - export all public functions from your package

=head1 SYNOPSIS

    package Foo;
    use Exporter::Auto;

    sub foo { }

    package main;
    use Foo;
    foo();  # <= this function was exported!

=head1 DESCRIPTION

Exporter::Auto is a simple replacement for L<Exporter> that will export
all public functions from your package. If you want all functions to be
exported from your module by default, then this might be the module for you.
If you only want some functions exported, or want tags, or to export variables,
then you should look at one of the other Exporter modules (L</"SEE ALSO">).

Let's say you have a library module with three functions, all of which
you want to export by default. With L<Exporter>, you'd write something like:

    package MyLibrary;
    use parent 'Exporter';
    our @EXPORT = qw/ foo bar baz /;
    sub foo { ... }
    sub bar { ... }
    sub baz { ... }
    1;

Every time you add a new function,
you must remember to add it to C<@EXPORT>.
Not a big hassle, but a small inconvenience.

With C<Exporter::Auto> you just write:

    package MyLibrary;
    use Exporter::Auto;
    sub foo { ... }
    sub bar { ... }
    sub baz { ... }
    1;

When you C<use Exporter::Auto> it automatically adds an C<import> function
to your package, so you don't need to declare your package as a subclass.

That's it. If you want anything more fancy than this,
it's time for another module.

=head1 REPOSITORY

L<https://github.com/tokuhirom/Exporter-Auto>

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 DEPENDENCIES

This module uses magical L<B::Hooks::EndOfScope>.
If you think this module is too clever, please try L<Module::Functions> instead.

=head1 SEE ALSO

L<Exporter> is the grandaddy of all Exporter modules, and bundled with Perl
itself, unlike the rest of the modules listed here.

L<Sub::Exporter> is a "sophisticated exporter for custom-built routines";
it lets you provide generators that can be used to customise what
gets imported when someone uses your module.

L<Exporter::Tiny> provides the same features as L<Sub::Exporter>,
but relying only on core dependencies.

L<Exporter::Declare> provides Moose-style functions used to define
what your module exports in a declarative way.

L<Exporter::Lite> is a lightweight exporter module, falling somewhere
between C<Exporter::Auto> and L<Exporter>.

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno <TOKUHIROM @ GMAIL COM

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
