#
# This file is part of Dist-Zilla-Plugin-RemovePrereqsMatching
#
# This software is Copyright (c) 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Dist::Zilla::Plugin::RemovePrereqsMatching;
{
  $Dist::Zilla::Plugin::RemovePrereqsMatching::VERSION = '0.002';
}

# ABSTRACT: A more flexible prereq remover

use Moose;
use namespace::autoclean;
use MooseX::AttributeShortcuts;

with 'Dist::Zilla::Role::PrereqSource';

# debugging...
#use Smart::Comments '###';

has remove_matching => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => 1,

    handles => {
        has_prereqs_to_remove => 'count',
    },
);
sub _build_remove_matching { [ ] }

sub mvp_multivalue_args { 'remove_matching' }


sub register_prereqs {
    my ($self) = @_;

    my $prereqs = $self->zilla->prereqs;
    my $raw     = $prereqs->as_string_hash;

    my $regexes = $self->remove_matching;

    for my $p (keys %$raw) {
        for my $t (keys %{$raw->{$p}}) {
            for my $mod (keys %{$raw->{$p}->{$t}}) {

                RX:
                for my $rx (@$regexes) {

                    next RX unless $mod =~ /$rx/;

                    $prereqs
                        ->requirements_for($p, $t)
                        ->clear_requirement($mod)
                        ;
                    last RX;
                }
            }
        }
    }

    return;
}

__PACKAGE__->meta->make_immutable;
!!42;


=pod

=encoding utf-8

=for :stopwords Chris Weyl

=head1 NAME

Dist::Zilla::Plugin::RemovePrereqsMatching - A more flexible prereq remover

=head1 VERSION

This document describes version 0.002 of Dist::Zilla::Plugin::RemovePrereqsMatching - released June 18, 2012 as part of Dist-Zilla-Plugin-RemovePrereqsMatching.

=head1 SYNOPSIS

    ; in your dist.ini
    [RemovePrereqsMatching]
    remove_matching = ^Template::Whatever::.*$
    remove_matching = ^Dist::Zilla.*$

=head1 DESCRIPTION

This plugin builds on L<Dist::Zilla::Plugin::RemovePrereqs> to allow
prerequisites to be removed by regular expression, rather than string
equality.  This can be useful when you have a C<DPAN> package consisting of a
bunch of modules under a common namespace, whose installation can be handled
by one common prerequisite specification.

=head1 METHODS

=head2 register_prereqs

We implement this method to scan the list of prerequisites assembled to date,
and remove any tat match any of the expressions given to us.

=for Pod::Coverage mvp_multivalue_args

=head1 OPTIONS

=head2 remove_matching

This option defines a regular expression that will be used to test
prerequisites for removal.  We may be specified multiple times to define
multiple expressions to test prerequisites against; a prerequisite needs to
match at least one expression to be excluded.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Zilla::Plugin::RemovePrereqs>

=back

=head1 SOURCE

The development version is on github at L<http://github.com/RsrchBoy/dist-zilla-plugin-removeprereqsmatching>
and may be cloned from L<git://github.com/RsrchBoy/dist-zilla-plugin-removeprereqsmatching.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/RsrchBoy/dist-zilla-plugin-removeprereqsmatching/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut


__END__

