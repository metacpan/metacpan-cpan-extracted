package Dist::Zilla::Plugin::Acme::CPANLists::Blacklist;

our $DATE = '2017-07-06'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict;
use warnings;

use Moose;
use namespace::autoclean;

use Module::Load;

with (
    'Dist::Zilla::Role::AfterBuild',
);

has author_list => (is=>'rw');
has module_list => (is=>'rw');

sub mvp_multivalue_args { qw(author_list module_list) }

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

    my %blacklisted_authors; # cpanid => {list=>'...', summary=>'...'}
    for my $l (@{ $self->author_list // [] }) {
        my ($ns, $name) = $l =~ /(.+)::(.+)/
            or die "Invalid author_list name '$l', must be 'NAMESPACE::Some name'";
        my $pkg = "Acme::CPANLists::$ns";
        load $pkg;
        my $found = 0;
        for my $ml (@{"$pkg\::Author_Lists"}) {
            next unless $ml->{name} eq $name || $ml->{summary} eq $name;
            $found++;
            for my $ent (@{ $ml->{entries} }) {
                $blacklisted_authors{$ent->{author}} //= {
                    list => $l,
                    summary => $ent->{summary},
                };
            }
            last;
        }
        unless ($found) {
            die "author_list named '$name' not found in $pkg";
        }
    }

    my %blacklisted_modules; # module => {list=>'...', summary=>'...'}
    for my $l (@{ $self->module_list // [] }) {
        my ($ns, $name) = $l =~ /(.+)::(.+)/
            or die "Invalid module_list name '$l', must be 'NAMESPACE::Some name'";
        my $pkg = "Acme::CPANLists::$ns";
        load $pkg;
        my $found = 0;
        for my $ml (@{"$pkg\::Module_Lists"}) {
            next unless
                defined($ml->{name}) && $ml->{name} eq $name ||
                defined($ml->{summary}) && $ml->{summary} eq $name;
            $found++;
            for my $ent (@{ $ml->{entries} }) {
                $blacklisted_modules{$ent->{module}} //= {
                    list => $l,
                    summary => $ent->{summary},
                };
            }
            last;
        }
        unless ($found) {
            die "module_list named '$name' not found in $pkg";
        }
    }

    my @whitelisted_authors;
    my @whitelisted_modules;
    {
        my $whitelist_plugin;
        for my $pl (@{ $self->zilla->plugins }) {
            if ($pl->isa("Dist::Zilla::Plugin::Acme::CPANLists::Whitelist")) {
                $whitelist_plugin = $pl; last;
            }
        }
        last unless $whitelist_plugin;
        @whitelisted_authors = @{ $whitelist_plugin->author // []};
        @whitelisted_modules = @{ $whitelist_plugin->module // []};
    }

    my $prereqs_hash = $self->zilla->prereqs->as_string_hash;

    my @all_prereqs;
    for my $phase (keys %$prereqs_hash) {
        for my $rel (keys %{ $prereqs_hash->{$phase} }) {
            for my $mod (keys %{ $prereqs_hash->{$phase}{$rel} }) {
                push @all_prereqs, $mod
                    unless $mod ~~ @all_prereqs;
            }
        }
    }

    if (keys %blacklisted_authors) {
        $self->log_debug(["Checking against blacklisted authors ..."]);
        require App::lcpan::Call;
        my $res = App::lcpan::Call::call_lcpan_script(argv=>['mods', '--or', '--detail', @all_prereqs]);
        $self->log_fatal(["Can't lcpan mods: %s - %s", $res->[0], $res->[1]])
            unless $res->[0] == 200;
        for my $rec (@{ $res->[2] }) {
            next unless $rec->{name} ~~ @all_prereqs;
            if ($blacklisted_authors{$rec->{author}} &&
                    !($rec->{author} ~~ @whitelisted_authors)) {
                $self->log_fatal(["Module '%s' is released by blacklisted author '%s' (list=%s, summary=%s)",
                                  $rec->{name}, $rec->{author},
                                  $blacklisted_authors{$rec->{author}}{list},
                                  $blacklisted_authors{$rec->{author}}{summary}]);
            }
        }
    }

    if (keys %blacklisted_modules) {
        $self->log_debug(["Checking against blacklisted authors ..."]);
        for my $mod (@all_prereqs) {
            if ($blacklisted_modules{$mod} && !($mod ~~ @whitelisted_modules)) {
                $self->log_fatal(["Module '%s' is blacklisted (list=%s, summary=%s)",
                                  $mod,
                                  $blacklisted_modules{$mod}{list},
                                  $blacklisted_modules{$mod}{summary}]);
            }
        }
    }
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Blacklist prereqs using a CPANList module/author list

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Acme::CPANLists::Blacklist - Blacklist prereqs using a CPANList module/author list

=head1 VERSION

This document describes version 0.03 of Dist::Zilla::Plugin::Acme::CPANLists::Blacklist (from Perl distribution Dist-Zilla-Plugin-Acme-CPANLists-Blacklist), released on 2017-07-06.

=head1 SYNOPSIS

In F<dist.ini>:

 [Acme::CPANLists::Blacklist]
 module_list=PERLANCAR::Modules I'm avoiding

During build, if there is a prereq to a module listed in the above list, the
build process will be aborted.

=head1 DESCRIPTION

C<Acme::CPANLists::*> modules contains various author lists and module lists.
With this plugin, you can specify a blacklist to modules in those lists.

If you specify a module list, e.g.:

 module_list=SomeNamespace::some name

then a module called C<Acme::CPANLists::SomeNamespace> will be loaded, and
C<some name> will be searched inside its C<@Module_Lists> variable. If a list
with such name is found, then all modules listed in that list will be added to
the blacklist. (Otherwise, an error will be thrown if the list is not found.)

To specify more lists, add more C<module_list=> lines.

Later in the build, when a prereq is specified against one of the blacklisted
modules, an error message will be thrown and the build process aborted.

To whitelist a module, list it in the Whitelist configuration in F<dist.ini>:

 [Acme::CPANLists::Whitelist]
 module=Log::Any

To whitelist more modules, add more C<module=> lines.

You can also specify an author list, e.g.:

 author_list=SomeNamespace::some name

in which C<@Author_Lists> variable will be searched instead of C<@Module_Lists>.
And local CPAN mirror database (built using L<lcpan>) will be consulted to
search the authors for all specified prereqs in the build. Then, if an author is
blacklisted, an error message will be thrown and the build process aborted.

As with modules, you can also whitelist some authors:

 [Acme::CPANLists::Whitelist]
 author=PERLANCAR

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-Acme-CPANLists-Blacklist>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-Acme-CPANLists-Blacklist>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Acme-CPANLists-Blacklist>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANLists>

C<Acme::CPANLists::*> modules

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
