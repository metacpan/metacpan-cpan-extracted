use strict;
use warnings;

package Dist::Zilla::Plugin::Test::UnusedVars; # git description: v2.001000-2-g97f4bf1
# ABSTRACT: Release tests for unused variables

our $VERSION = '2.001001';

use Path::Tiny;
use Moose;
use Sub::Exporter::ForMethods 'method_installer';
use Data::Section 0.004 { installer => method_installer }, '-setup';
use namespace::autoclean;

with qw(
    Dist::Zilla::Role::FileGatherer
    Dist::Zilla::Role::TextTemplate
    Dist::Zilla::Role::PrereqSource
);

has files => (
    is  => 'ro',
    isa => 'Maybe[ArrayRef[Str]]',
    predicate => 'has_files',
);

sub mvp_multivalue_args { return qw/ files / }
sub mvp_aliases { return { file => 'files' } }

sub gather_files {
    my $self = shift;
    my $file = 'xt/release/unused-vars.t';

    require Dist::Zilla::File::InMemory;
    $self->add_file(
        Dist::Zilla::File::InMemory->new({
            name    => $file,
            content => $self->fill_in_string(
                ${ $self->section_data($file) },
                {
                    has_files => $self->has_files,
                    files => ($self->has_files
                        ? [ map path($_)->relative('lib')->stringify, @{ $self->files } ]
                        : []
                    ),
                }
            ),
        })
    );
};

sub register_prereqs {
    my $self = shift;

    $self->zilla->register_prereqs(
        {
            phase => 'develop',
            type  => 'requires',
        },
        'Test::Vars' => 0,
    );
}

__PACKAGE__->meta->make_immutable;
1;

#pod =pod
#pod
#pod =for Pod::Coverage mvp_multivalue_args mvp_aliases gather_files register_prereqs
#pod
#pod =head1 SYNOPSIS
#pod
#pod In your F<dist.ini>:
#pod
#pod     [Test::UnusedVars]
#pod
#pod Or, give a list of files to test:
#pod
#pod     [Test::UnusedVars]
#pod     file = lib/My/Module.pm
#pod     file = bin/verify-this
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the
#pod following file:
#pod
#pod     xt/release/unused-vars.t - a standard Test::Vars test
#pod
#pod =cut

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Test::UnusedVars - Release tests for unused variables

=head1 VERSION

version 2.001001

=head1 SYNOPSIS

In your F<dist.ini>:

    [Test::UnusedVars]

Or, give a list of files to test:

    [Test::UnusedVars]
    file = lib/My/Module.pm
    file = bin/verify-this

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the
following file:

    xt/release/unused-vars.t - a standard Test::Vars test

=for Pod::Coverage mvp_multivalue_args mvp_aliases gather_files register_prereqs

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Test-UnusedVars>
(or L<bug-Dist-Zilla-Plugin-Test-UnusedVars@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-Test-UnusedVars@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

=head1 AUTHORS

=over 4

=item *

Marcel Grünauer <marcel@cpan.org>

=item *

Mike Doherty <doherty@cpan.org>

=back

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Mike Doherty Marcel Gruenauer Kent Fredric

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Mike Doherty <doherty@cs.dal.ca>

=item *

Mike Doherty <mike@mikedoherty.ca>

=item *

Marcel Gruenauer <hanekomu@gmail.com>

=item *

Kent Fredric <kentfredric@gmail.com>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2010 by Mike Doherty.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
___[ xt/release/unused-vars.t ]___
use Test::More 0.96 tests => 1;
use Test::Vars;

subtest 'unused vars' => sub {
{{
$has_files
    ? 'my @files = (' . "\n"
        . join(",\n", map q{    '}.$_.q{'}, map { s{'}{\\'}g; $_ } @files)
        . "\n" . ');' . "\n"
        . 'vars_ok($_) for @files;'
    : 'all_vars_ok();'
}}
};
