package Dist::Zilla::Plugin::Acme::CPANModules::Blacklist;

our $DATE = '2018-01-09'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Moose;
use namespace::autoclean;

use Module::Load;

with (
    'Dist::Zilla::Role::AfterBuild',
);

has module => (is=>'rw');

sub mvp_multivalue_args { qw(module) }

sub _prereq_check {
    my ($self, $prereqs_hash, $mod, $wanted_phase, $wanted_rel) = @_;

    #use DD; dd $prereqs_hash;

    my $num_any = 0;
    my $num_wanted = 0;
    for my $phase (keys %$prereqs_hash) {
        for my $rel (keys %{ $prereqs_hash->{$phase} }) {
            if (exists $prereqs_hash->{$phase}{$rel}{$mod}) {
                $num_any++;
                $num_wanted++ if
                    (!defined($wanted_phase) || $phase eq $wanted_phase) &&
                    (!defined($wanted_rel)   || $rel   eq $wanted_rel);
            }
        }
    }
    ($num_any, $num_wanted);
}

sub _prereq_only_in {
    my ($self, $prereqs_hash, $mod, $wanted_phase, $wanted_rel) = @_;

    my ($num_any, $num_wanted) = $self->_prereq_check(
        $prereqs_hash, $mod, $wanted_phase, $wanted_rel,
    );
    $num_wanted == 1 && $num_any == 1;
}

sub _prereq_none {
    my ($self, $prereqs_hash, $mod) = @_;

    my ($num_any, $num_wanted) = $self->_prereq_check(
        $prereqs_hash, $mod, 'whatever', 'whatever',
    );
    $num_any == 0;
}

sub after_build {
    use experimental 'smartmatch';
    no strict 'refs';

    my $self = shift;

    my %blacklisted; # module => {acmemod=>'...', summary=>'...'}
    for my $mod (@{ $self->module // [] }) {
        my $pkg = "Acme::CPANModules::$mod";
        load $pkg;
        my $found = 0;
        my $list = ${"$pkg\::LIST"};
        for my $ent (@{ $list->{entries} }) {
            $blacklisted{$ent->{module}} //= {
                acmemod => $mod,
                summary => $ent->{summary},
            };
        }
    }

    my @whitelisted;
    {
        my $whitelist_plugin;
        for my $pl (@{ $self->zilla->plugins }) {
            if ($pl->isa("Dist::Zilla::Plugin::Acme::CPANModules::Whitelist")) {
                $whitelist_plugin = $pl; last;
            }
        }
        last unless $whitelist_plugin;
        @whitelisted = @{ $whitelist_plugin->module // []};
    }

    my $prereqs_hash = $self->zilla->prereqs->as_string_hash;

    my @all_prereqs;
    for my $phase (grep {!/x_/} keys %$prereqs_hash) {
        for my $rel (grep {!/x_/} keys %{ $prereqs_hash->{$phase} }) {
            for my $mod (keys %{ $prereqs_hash->{$phase}{$rel} }) {
                push @all_prereqs, $mod
                    unless $mod ~~ @all_prereqs;
            }
        }
    }

    if (keys %blacklisted) {
        $self->log_debug(["Checking against blacklisted modules ..."]);
        for my $mod (@all_prereqs) {
            if ($blacklisted{$mod} && !($mod ~~ @whitelisted)) {
                $self->log_fatal(["Module '%s' is blacklisted (acmemod=%s, summary=%s)",
                                  $mod,
                                  $blacklisted{$mod}{acmemod},
                                  $blacklisted{$mod}{summary}]);
            }
        }
    }
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Blacklist prereqs using an Acme::CPANModules module

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Acme::CPANModules::Blacklist - Blacklist prereqs using an Acme::CPANModules module

=head1 VERSION

This document describes version 0.001 of Dist::Zilla::Plugin::Acme::CPANModules::Blacklist (from Perl distribution Dist-Zilla-Plugin-Acme-CPANModules-Blacklist), released on 2018-01-09.

=head1 SYNOPSIS

In F<dist.ini>:

 [Acme::CPANModules::Blacklist]
 module=PERLANCAR::Avoided

During build, if there is a prereq to a module listed in the above
L<Acme::CPANModules::PERLANCAR::Avoided>, the build process will be aborted.

Currently prereqs with custom phase (/^x_/) or custom relationship are ignored.

=head1 DESCRIPTION

C<Acme::CPANModules::*> modules contains lists of modules. With this plugin, you
can specify a blacklist to modules in those lists.

If you specify a module, e.g.:

 module=SomeName

then a module called C<Acme::CPANModules::SomeName> will be loaded, and all
modules listed in the module's C<$LIST> will be added to the blacklist.

To specify more Acme::CPANModules modules, add more C<module=> lines.

Later in the build, when a prereq is specified against one of the blacklisted
modules, an error message will be thrown and the build process aborted.

To whitelist a module, list it in the Whitelist configuration in F<dist.ini>:

 [Acme::CPANModules::Whitelist]
 module=Log::Any

To whitelist more modules, add more C<module=> lines.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-Acme-CPANModules-Blacklist>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-Acme-CPANModules-Blacklist>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Acme-CPANModules-Blacklist>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules>

C<Acme::CPANModules::*> modules

L<Dist::Zilla::Plugin::CPANModules::Whitelist>

L<Dist::Zilla::Plugin::CPANAuthors::Blacklist>

L<Dist::Zilla::Plugin::CPANAuthors::Whitelist>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
