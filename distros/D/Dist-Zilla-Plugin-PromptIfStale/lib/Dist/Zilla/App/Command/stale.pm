use strict;
use warnings;
package Dist::Zilla::App::Command::stale;
# vim: set ts=8 sts=4 sw=4 tw=115 et :
# ABSTRACT: print your distribution's prerequisites and plugins that are out of date

our $VERSION = '0.054';

use Dist::Zilla::App -command;

sub abstract { "print your distribution's stale prerequisites and plugins" }

sub opt_spec
{
    [ 'all'   , 'check all plugins and prerequisites, regardless of plugin configuration' ]
    # TODO?
    # [ 'plugins', 'check all plugins' ],
    # [ 'prereqs', 'check all prerequisites' ],
}

sub stale_modules
{
    my ($self, $zilla, $all) = @_;

    my @plugins = grep { $_->isa('Dist::Zilla::Plugin::PromptIfStale') } @{ $zilla->plugins };
    if (not @plugins)
    {
        require Dist::Zilla::Plugin::PromptIfStale;
        push @plugins,
            Dist::Zilla::Plugin::PromptIfStale->new(zilla => $zilla, plugin_name => 'stale_command');
    }

    my @modules;

    # ugh, we need to do nearly a full build to get the prereqs
    # (this really should be abstracted better in Dist::Zilla::Dist::Builder)
    if ($all or do { require List::Util; List::Util->VERSION('1.33'); List::Util::any(sub { $_->check_all_prereqs }, @plugins) })
    {
        $_->before_build for grep { not $_->isa('Dist::Zilla::Plugin::PromptIfStale') }
            @{ $zilla->plugins_with(-BeforeBuild) };
        $_->gather_files for @{ $zilla->plugins_with(-FileGatherer) };
        $_->set_file_encodings for @{ $zilla->plugins_with(-EncodingProvider) };
        $_->prune_files  for @{ $zilla->plugins_with(-FilePruner) };
        $_->munge_files  for @{ $zilla->plugins_with(-FileMunger) };
        $_->register_prereqs for @{ $zilla->plugins_with(-PrereqSource) };

        push @modules, map {
            ( $all || $_->check_all_prereqs ? $_->_modules_prereq : () ),
        } @plugins;
    }

    foreach my $plugin (@plugins)
    {
        push @modules,
            ( $all || $plugin->check_authordeps ? $plugin->_authordeps : () ),
            $plugin->_modules_extra,
            ( $all || $plugin->check_all_plugins ? $plugin->_modules_plugin : () );
    }

    return if not @modules;

    require List::Util; List::Util->VERSION(1.45);
    my ($stale_modules, undef) = $plugins[0]->stale_modules(List::Util::uniq(@modules));
    return @$stale_modules;
}

sub execute
{
    my ($self, $opt) = @_; # $arg

    $self->app->chrome->logger->mute unless $self->app->global_options->verbose;

    require Try::Tiny;
    my $zilla = Try::Tiny::try {
        # parse dist.ini and load, instantiate all plugins
        $self->zilla;
    }
    Try::Tiny::catch {
        my @authordeps;

        # a plugin or bundle tried to loads another module that isn't installed
        if (/^Can't locate (\S+) .+ at \S+ line/
            or /^Compilation failed in require at (\S+) line/)
        {
            my $module = $1 || $2;
            $module =~ s{/}{::}g;
            $module =~ s{\.pm$}{};
            push @authordeps, $module;
        }
        # ...or at the wrong version
        elsif (/^(\S+) version \S+ required--this is only version \S+ at \S+ line/)
        {
            push @authordeps, $1;
        }
        else
        {
            # a plugin was referenced in dist.ini or a bundle
            push @authordeps, $1 if /Required plugin(?: bundle)? \[?(\S+)\]? isn't installed\./;

            # some plugins are not installed; need to run authordeps --missing
            die $_ unless
                m/Run 'dzil authordeps' to see a list of all required plugins/m
                or m/ version \(.+\) (does )?not match required version: /m;
        }

        push @authordeps, $self->_missing_authordeps;

        $self->app->chrome->logger->unmute;
        $self->log(join("\n", sort(List::Util::uniq(@authordeps))));

        if (@authordeps)
        {
            require Term::ANSIColor;
            Term::ANSIColor->VERSION('3.00');
            print STDERR Term::ANSIColor::colored("Some authordeps were missing. Run the stale command again to check for regular dependencies.\n", 'bright_yellow');
            exit 1;
        }

        undef;  # ensure $zilla = undef
    };

    exit 2 if not $zilla;

    my $error;
    my @stale_modules = Try::Tiny::try {
        $self->stale_modules($zilla, $opt->all);
    }
    Try::Tiny::catch {
        $error = $_;

        # if there was an error during the build, fall back to fetching
        # authordeps, in the hopes that we can report something helpful
        $self->_missing_authordeps;
    };

    $self->app->chrome->logger->unmute;
    $self->log(join("\n", @stale_modules)); # this might be just a blank line
    $self->log([ 'got error from stale_modules check: %s', $error ]) if $error and not @stale_modules;
}

# as in Dist::Zilla::App::Command::alldeps
sub _missing_authordeps
{
    my $self = shift;

    require Dist::Zilla::Util::AuthorDeps;
    Dist::Zilla::Util::AuthorDeps->VERSION(5.021);
    my @authordeps = map { (%$_)[0] }
        @{ Dist::Zilla::Util::AuthorDeps::extract_author_deps(
            '.',            # repository root
            1,              # --missing
          )
        };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::App::Command::stale - print your distribution's prerequisites and plugins that are out of date

=head1 VERSION

version 0.054

=head1 SYNOPSIS

  $ dzil stale --all | cpanm

=head1 DESCRIPTION

This is a command plugin for L<Dist::Zilla>. It provides the C<stale> command,
which acts as L<[PromptIfStale]|Dist::Zilla::Plugin::PromptIfStale> would
during the build: compares the locally-installed version of a module(s) with
the latest indexed version, and print all modules that are thus found to be
stale.  You could pipe that list to a CPAN client like L<cpanm> to update all
of the modules in one quick go.

When a L<[PromptIfStale]|Dist::Zilla::Plugin::PromptIfStale> configuration is
present in F<dist.ini>, its configuration is honoured (unless C<--all> is
used); if there is no such configuration, behaviour is as for C<--all>.

=for stopwords thusly

If not everything can be installed in one pass (typically, if a plugin used by
F<dist.ini> is missing), a message will be printed to C<STDERR> and the exit
code will be 1.  This allows you to chain commands thusly:

    dzil stale --all | cpanm && dzil build && dzil test --release

=head1 OPTIONS

=head2 --all

Checks all plugins and prerequisites (as well as any additional modules listed
in a local L<[PromptIfStale]|Dist::Zilla::Plugin::PromptIfStale>
configuration, if there is one).

I have a shell alias: C<alias unstale="dzil stale --all | cpanm"> which I use
quite regularly! You should do this too.

=for Pod::Coverage stale_modules

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla::Plugin::PromptIfStale>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-PromptIfStale>
(or L<bug-Dist-Zilla-Plugin-PromptIfStale@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-PromptIfStale@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
