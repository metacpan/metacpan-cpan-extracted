package Dist::Zilla::Plugin::PERLANCAR::CheckDepDists;

our $DATE = '2016-02-16'; # DATE
our $VERSION = '0.06'; # VERSION

use 5.010001;
use strict;
use warnings;

use Moose;
with (
    'Dist::Zilla::Role::AfterBuild',
);

use App::lcpan::Call qw(call_lcpan_script);
use File::chdir;
use Module::List qw(list_modules);
use Sub::NoRepeat qw(norepeat);
use Term::ANSIColor;

use namespace::autoclean;

sub after_build {
    use experimental 'smartmatch';
    no strict 'refs';

    my $self = shift;

    my $color = "bold cyan";

    norepeat(
        key => __PACKAGE__ . ' ' . $self->zilla->name,
        period => '8h',
        code => sub {

            $self->log_debug(["Listing all ::Lumped & ::Packed/::FatPacked/::DataPacked modules ..."]);
            my $mods = list_modules("", {list_modules=>1, recurse=>1});
            for my $mod (sort keys %$mods) {
                next unless $mod =~ /.+::(Lumped|Packed|FatPacked|DataPacked)$/;
                my $lump = $1 eq 'Lumped';
                $self->log_debug(["Checking against %s", $mod]);
                my $mod_pm = do { local $_ = $mod; s!::!/!g; "$_.pm" };
                require $mod_pm;
                my $dists = \@{"$mod\::" . ($lump ? "LUMPED_DISTS" : "PACKED_DISTS")};
                if ($self->zilla->name ~~ @$dists) {
                    my $dist = $mod; $dist =~ s/::/-/g;
                    say colored([$color], "This distribution also needs to be rebuilt: $dist");
                }
            }

            # XXX some configurability wrt repos directory
            $self->log_debug(["Finding all repos which requires our dist (via .tag-requires-dist) ..."]);
            {
                local $CWD = "..";
                my $tag_filename = ".tag-requires-dist-" . $self->zilla->name;
                for my $repo (grep {-d} <*>) {
                    local $CWD = $repo;
                    if (-f $tag_filename) {
                        say colored([$color], "This repo also needs to be rebuilt: $repo");
                    }
                }
            }

            $self->log_debug(["Finding all Bencher::Scenario repos which requires our dist ..."]);
            {
                my $files = $self->zilla->find_files(':InstallModules');
                my @modules;
                for (@$files) {
                    my $mod = $_->name;
                    $mod =~ s!^lib/!!;
                    $mod =~ s!\.pm$!!;
                    $mod =~ s!/!::!g;
                    push @modules, $mod;
                }
                my $res = call_lcpan_script(argv => ["rdeps", @modules]);

                # our modules are (still) unknown
                last if $res->[0] == 404;

                $self->log_fatal(["Can't lcpan rdeps: %s - %s", $res->[0], $res->[1]])
                    unless $res->[0] == 200;

                for (@{$res->[2]}) {
                    next unless $_->{dist} =~ /^Bencher-Scenarios?-/;
                    say colored([$color], "This Bencher-Scenario repo could also use a rebuild: perl-$_->{dist}");
                }
            }

        },
    );
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Check for dists that depend on the dist you're building

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::PERLANCAR::CheckDepDists - Check for dists that depend on the dist you're building

=head1 VERSION

This document describes version 0.06 of Dist::Zilla::Plugin::PERLANCAR::CheckDepDists (from Perl distribution Dist-Zilla-Plugin-PERLANCAR-CheckDepDists), released on 2016-02-16.

=head1 SYNOPSIS

In C<dist.ini>:

 [PERLANCAR::CheckDepDists]

=head1 DESCRIPTION

This plugin notifies you, in the after_build phase, of dists that might need to
be rebuild too, because those dists depend on the dist you're building.
Currently what it does:

=over

=item *

Search your local installation for all lump dists (via searching all modules
whose name ends with C<::Lumped>). Inside each of these modules, there is a
C<@LUMPED_DISTS> array which lists all the dists that the lump dist includes.
When the current dist you're building is listed in C<@LUMPED_DISTS>, the plugin
will issue a notification that you will also need to rebuild the associated lump
dist.

=item *

Search your local installation for all packed dists (via searching all modules
whose name ends with C<::Packed>, C<::Fatpacked>, C<::DataPacked>). Inside each
of these modules, there is a C<@PACKED_DISTS> array which lists all the dists
that the packed dist includes. When the current dist you're building is listed
in C<@PACKED_DISTS>, the plugin will issue a notification that you will also
need to rebuild the associated packed dist.

=item *

Search C<../> (XXX probably should be configurable) for all repos (dirs) that
contains tag file C<.tag-requires-dist-DISTNAME> where I<DISTNAME> is the
current distribution's name.

=back

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-PERLANCAR-CheckDepDists>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-PERLANCAR-CheckDepDists>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-PERLANCAR-CheckDepDists>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

For more information about lump dists: L<Dist::Zilla::Plugin::Lump>

For more information about packed dists: L<Dist::Zilla::Plugin::Depak>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
