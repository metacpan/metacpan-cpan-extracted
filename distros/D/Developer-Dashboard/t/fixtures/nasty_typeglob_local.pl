use strict;
use warnings;

our $value = 3;
our $alias;
*alias = \$value;

sub read_alias {
    local $value = 9;
    return $alias + $value;
}

die "bad typeglob/local" unless read_alias() == 12;
1;

__END__

=head1 NAME

t/fixtures/nasty_typeglob_local.pl - fixture: typeglob aliasing combined with C<local> dynamic scoping

=head1 PURPOSE

Aliases one package variable to another via a typeglob assignment, then uses C<local> to temporarily rebind the aliased variable and confirms the alias still tracks the localized value.

=head1 WHY IT EXISTS

Ported from PAX's own upstream fixture corpus as part of DD-882's vendoring
of the whole PAX compiler into C<Developer::Dashboard::Pax::*>, so the same
narrow edge case PAX's own maintainers already tested against - typeglob aliasing combined with C<local> dynamic scoping -
keeps being exercised against the vendored copy exactly as it was against
the original.

=head1 WHEN TO USE

Change this file only when the specific behavior it captures needs to
change. Add a new, separate fixture for a different edge case rather than
widening this one's scope - each fixture in this directory is deliberately
narrow.

=head1 HOW TO USE

Built and run via C<pax build>/C<pax run> against this file as an
entrypoint, driven from t/183-pax-cli-build-run-contract.t. Self-checking: dies with "bad typeglob/local" unless C<read_alias()> returns 12 once compiled and run, confirming the typeglob alias still resolves to the localized value.

=head1 WHAT USES IT

t/183-pax-cli-build-run-contract.t, exercising the vendored PAX compiler's
handling of this specific case during build and run.

=head1 EXAMPLES

Running it interpreted, the baseline behavior a compiled version must match:

    perl t/fixtures/nasty_typeglob_local.pl

Building and running it through the vendored PAX compiler:

    pax build t/fixtures/nasty_typeglob_local.pl -o /tmp/out && /tmp/out

=cut
