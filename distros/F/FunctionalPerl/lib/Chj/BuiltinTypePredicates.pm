#
# Copyright (c) 2015-2020 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::BuiltinTypePredicates

=head1 SYNOPSIS

=head1 DESCRIPTION

Predicates that are useful/needed outside of the `FP` namespace
tree. Also, to avoid circular dependency on Chj::TEST.

=head1 SEE ALSO

L<FP::Predicates>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package Chj::BuiltinTypePredicates;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT      = qw(is_filehandle);
our @EXPORT_OK   = qw();
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use Scalar::Util 'reftype';
use FP::Carp;

# for tests, see FP::Predicates

sub is_filehandle {
    @_ == 1 or fp_croak_arity 1;
    my ($v) = @_;

    # NOTE: never returns true for strings, even though plain strings
    # naming globals containing filehandles in their IO slot will work
    # for IO, too! Let's just leave that depreciated and
    # 'non-working', ok?

    # NOTE 2: also this only returns true for *references* to globs,
    # not globs themselves (which could also be used as in
    # `(*STDOUT)->print( "Huh\n")`). Let's just leave bare globs as
    # buckets for any of the variable types perl has, and not assume
    # it's meant to be a filehandle, ok? (Or is that inconsistent with
    # treating `\*STDOUT` as filehandle? But there's no way around
    # this one, as that's what `open my $out, ..` gives, and we do
    # check that the IO slot is actually set in this case.) (hm could
    # take reference to the bare glob and treat it the same then,
    # though; but still.)

    if (defined(my $rt = reftype($v))) {
        (($rt eq "GLOB" and *{$v}{IO}) or $rt eq "IO") ? 1 : '';

        # explicitely return '' instead of undef
    } else {
        ''
    }
}

1
