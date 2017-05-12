# ABSTRACT: Import Routines By Any Means Necessary
package Extorter;

use 5.10.0;

use strict;
use warnings;

use Import::Into;

our $VERSION = '0.10'; # VERSION

sub import {
    my $class  = shift;
    my $target = caller;

    my @imports = @_ or return;
    $class->extort::into($target, $_) for @imports;

    return;
}

sub extort::into {
    my $class  = shift;
    my $target = shift;

    my @imports = @_ or return;

    @imports = map join('::', $imports[0], $_), @imports[1..$#imports]
        if @imports > 1;

    my %seen;
    for my $import (@imports) {
        my @captures = $import =~ /^(\w.+)(?:\^|::)(.*)/;
           @captures = $import =~ /^\*(.+)/ unless @captures;

        my ($namespace, $argument) = @captures;
        next unless $namespace;

        unless ($argument) {
            $namespace->import::into($target);
            next;
        }

        my $subname;
        if ($argument and $argument =~ /=/) {
            ($argument, $subname) = split /=/, $argument;
        }

        $seen{$namespace}++
            || eval "require $namespace";

        if (!$subname and $argument =~ /\W/) {
            $namespace->import::into($target, $argument);
            next;
        }

        no strict 'refs';
        my %EXPORT_TAGS = %{"${namespace}::EXPORT_TAGS"};
        if (!$subname and $EXPORT_TAGS{$argument}) {
            $namespace->import::into($target, $argument);
            next;
        }

        if ($namespace->can($argument)) {
            no warnings 'redefine';
            $subname //= $argument;
            *{"${target}::${subname}"} = \&{"${namespace}::${argument}"};
            next;
        }

        # fallback
        $namespace->import::into($target, $argument);
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Extorter - Import Routines By Any Means Necessary

=head1 VERSION

version 0.10

=head1 SYNOPSIS

    use Extorter qw(

        *utf8
        *strict
        *warnings

        feature^say
        feature^state

        Carp::croak
        Carp::confess

        Data::Dump::dump

        Digest::SHA1::sha1_hex
        Digest::SHA1::sha1_base64

        Encode::encode_utf8
        Encode::decode_utf8

        IO::All::io

        List::AllUtils::distinct
        List::AllUtils::firstval
        List::AllUtils::lastval
        List::AllUtils::pairs
        List::AllUtils::part
        List::AllUtils::uniq

        Memoize::memoize

        Scalar::Util::blessed
        Scalar::Util::refaddr
        Scalar::Util::reftype
        Scalar::Util::weaken

    );

=head1 DESCRIPTION

The Extorter module allows you to create import lists which extract routines
from the package(s) specified. It will import routines found in the package
variables C<@EXPORT>, C<@EXPORT_OK> and C<%EXPORT_TAGS>, or, extract routines
defined in the package which are not explicitly exported. Otherwise, as a last
resort, Extorter will try to load the package, using a parameterized C<use>
statement, in the event that the package has a custom or magical importer that
does not conform to the L<Exporter> interface.

Extorter accepts a list of fully-qualified declarations. The verbosity of the
declarations are meant to promote explicit, clean, and reasonable import lists.
Extorter has the added bonus of extracting functionality from packages which may
not have originally been designed to be imported. Declarations are handled in
the order in which they're declared, which means, as far as the import and/or
extraction order goes, the last routine declared will be the one available to
your program and any C<redefine> warnings will be suppressed. This is a feature
not a bug. B<NOTE: Any declaration prefixed with an asterisk is assumed to be a
fully-qualified namespace of a package and is imported directly.>

=head1 FEATURES AND VERSIONS

Declaring version requirements and version-specific features is handled a bit
differently. As mentioned in the description, any declaration prefixed with an
asterisk is assumed to be a fully-qualified namespace of a package and is
imported directly. This works for modules as well as pragmas like C<strict>,
C<warnings>, C<utf8>, and others. However, this does not work for declaring a
Perl version or version-specific features. Currently, there is no single
declaration which will allow you to configure Extorter to implement them but
the following approach is equivalent:

    use 5.18.0;

The Perl version requirement will be enforced whenever a scope issuing the
B<use VERSION> declaration is found, i.e. as long as you ensure that declaration
is seen, the version requirement will be enforced for your program. So now we
just need to figure out how to import features into the calling namespace using
Extorter. The following approach works towards that end:

    use 5.18.0;
    use Extorter 'feature^:5.18';

=head1 EXTORTER AND EXPORTER

You can use Extorter with the L<Exporter> module, to create a sophisticated
exporter which implements the Exporter interface. The following is an example:

    package MyApp::Imports;

    use Extorter;
    use base 'Exporter';

    our @EXPORT_OK = qw(
        optional_thing1
        optional_thing2
    );

    our @IMPORT_OK = qw(
        MyApp::Functions::necessary_thing1
        MyApp::Functions::necessary_thing2
    );

    sub optional_thing1 {
        # does stuff
    }

    sub optional_thing2 {
        # does stuff
    }

    sub import {
        my ($class, $target) = (shift, caller);
        $class->extort::into($target, $_) for @IMPORT_OK;
        $class->export_to_level(2, $target);
    }

    1;

=head1 EXTORTION ON-DEMAND

Yet another pattern you could use to have Extorter make importing into your
environment more dynamic and configurable, is by implementing a parameterizable
importer which delegates to the C<extort::into> function. The following is an
example:

    package MyApp::Imports;

    use Extorter;

    my @common = qw(
        *strict
        *warnings
        *utf8::all

        autodie^:all
        feature^:5.18

        *Moo
        Carp::carp
        Carp::croak
        Scalar::Util::reftype
        Scalar::Util::refaddr
    );

    sub import {
        my ($class, $target) = (shift, caller);
        my @arguments = @_;

        $class->extort::into($target, $_) for @common;
        $class->extort::into($target, $_) for @arguments;

        return;
    }

    1;

The example above allows the calling class to import whatever defaults your
application deems appropriate while also giving the calling class the ability to
demand additional features. The following is an example of a class which imports
all of the common declarations defined in the MyApp::Imports module and also
demands two additional imports itself:

    use MyApp::Imports qw(
        MyApp::Functions::necessary_thing1
        MyApp::Functions::necessary_thing2
    );

=head1 FUNCTIONS

=head2 extort::into

The C<into> function declared in the C<extort> package, used as a kind of global
method invokable by any package, is designed to load and import the specified
C<@declarations>, as showcased in the synopsis, into the C<$target> package.

    $package->extort::into($target, $declaration);

    e.g.

    $package->extort::into($target, 'Scalar::Util::refaddr');
    $package->extort::into($target, 'Scalar::Util::reftype');

    $package->extort::into($target, 'List::AllUtils::firstval');
    $package->extort::into($target, 'List::AllUtils::lastval');

Additionally, this function supports a 3-argument version, where the 3rd option
is a list of arguments that will be automatically concatenated with the
C<$target> package to provide the necessary declarations. The following is an
example:

    $package->extort::into($target, $namespace, @arguments);

    e.g.

    my @scalar_utils = 'Scalar::Util' => qw(
        refaddr
        reftype
    );

    my @list_utils = 'List::AllUtils' => qw(
        firstval
        lastval
    );

    $package->extort::into($target, @scalar_utils);
    $package->extort::into($target, @list_utils);

It is also possible to copy a routine from one namespace and install it into a
different namespace using a different name. The following is an example of that:

    $package->extort::into($target, 'Getopt::Long::GetOptions=options');

Given the example, the C<$target> namespace now contains a code reference named
C<options> which references the subroutine C<GetOptions> as defined in the
L<Getopt::Long> package.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
