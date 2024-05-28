package Dist::Zilla::Tutorial 6.032;
# ABSTRACT: how to use this "Dist::Zilla" thing

use Dist::Zilla::Pragmas;

use Carp ();
Carp::confess "you're not meant to use the tutorial, just read it!";
1;

#pod =head1 SYNOPSIS
#pod
#pod B<BEFORE YOU GET STARTED>:  Maybe you should be looking at the web-based
#pod tutorial instead.  It's more complete.  L<https://dzil.org/tutorial/start.html>
#pod
#pod Dist::Zilla builds distributions to be uploaded to the CPAN.  That means that
#pod the first thing you'll need is some code.
#pod
#pod Once you've got that, you'll need to configure Dist::Zilla.  Here's a simple
#pod F<dist.ini>:
#pod
#pod   name    = Carbon-Dating
#pod   version = 0.003
#pod   author  = Alan Smithee <asmithee@example.org>
#pod   license = Perl_5
#pod   copyright_holder = Alan Smithee
#pod
#pod   [@Basic]
#pod
#pod   [Prereqs]
#pod   App::Cmd          = 0.013
#pod   Number::Nary      = 0
#pod   Sub::Exporter     = 0.981
#pod
#pod The topmost section configures Dist::Zilla itself.  Here are some of the
#pod entries it expects:
#pod
#pod   name     - (required) the name of the dist being built
#pod   version  - (required) the version of the dist
#pod   abstract - (required) a short description of the dist
#pod   author   - (optional) the dist author (you may have multiple entries for this)
#pod   license  - (required) the dist license; must be a Software::License::* name
#pod
#pod   copyright_holder - (required) the entity holding copyright on the dist
#pod
#pod Some of the required values above may actually be provided by means other than
#pod the top-level section of the config.  For example,
#pod L<VersionProvider|Dist::Zilla::Role::VersionProvider> plugins can
#pod set the version, and a line like this in the "main module" of the dist will set
#pod the abstract:
#pod
#pod   # ABSTRACT: a totally cool way to do totally great stuff
#pod
#pod The main modules is the module that shares the same name as the dist, in
#pod general.
#pod
#pod Named sections load plugins, with the following rules:
#pod
#pod If a section name begins with an equals sign (C<=>), the rest of the section
#pod name is left intact and not expanded.  If the section name begins with an at
#pod sign (C<@>), it is prepended with C<Dist::Zilla::PluginBundle::>.  Otherwise,
#pod it is prepended with C<Dist::Zilla::Plugin::>.
#pod
#pod The values inside a section are given as configuration to the plugin.  Consult
#pod each plugin's documentation for more information.
#pod
#pod The "Basic" bundle, seen above, builds a fairly normal distribution.  It
#pod rewrites tests from F<./xt>, adds some information to POD, and builds a
#pod F<Makefile.PL>.  For more information, you can look at the docs for
#pod L<@Basic|Dist::Zilla::PluginBundle::Basic> and see the plugins it includes.
#pod
#pod =head1 BUILDING YOUR DIST
#pod
#pod Maybe we're getting ahead of ourselves, here.  Configuring a bunch of plugins
#pod won't do you a lot of good unless you know how to use them to build your dist.
#pod
#pod Dist::Zilla ships with a command called F<dzil> that will get installed by
#pod default.  While it can be extended to offer more commands, there are two really
#pod useful ones:
#pod
#pod   $ dzil build
#pod
#pod The C<build> command will build the distribution.  Say you're using the
#pod configuration in the SYNOPSIS above.  You'll end up with a file called
#pod F<Carbon-Dating-0.004.tar.gz>.  As long as you've done everything right, it
#pod will be suitable for uploading to the CPAN.
#pod
#pod Of course, you should really test it out first.  You can test the dist you'd be
#pod building by running another F<dzil> command:
#pod
#pod   $ dzil test
#pod
#pod This will build a new copy of your distribution and run its tests, so you'll
#pod know whether the dist that C<build> would build is worth releasing!
#pod
#pod =head1 HOW BUILDS GET BUILT
#pod
#pod This is really more of a sketchy overview than a spec.
#pod
#pod First, all the plugins that perform the
#pod L<BeforeBuild|Dist::Zilla::Role::BeforeBuild> perform their C<before_build>
#pod tasks.
#pod
#pod The build root (where the dist is being built) is made.
#pod
#pod The L<FileGatherer|Dist::Zilla::Role::FileGatherer>s gather and inject files
#pod into the distribution, then the L<FilePruner|Dist::Zilla::Role::FilePruner>s
#pod remove some of them.
#pod
#pod All the L<FileMunger|Dist::Zilla::Role::FileMunger>s get a chance to muck about
#pod with each file, possibly changing its name, content, or installability.
#pod
#pod Now that the distribution is basically set up, it needs an install tool, like a
#pod F<Makefile.PL>.  All the
#pod L<InstallTool|Dist::Zilla::Role::InstallTool>-performing plugins are used to
#pod do whatever is needed to make the dist installable.
#pod
#pod Everything is just about done.  The files are all written out to disk and the
#pod L<AfterBuild|Dist::Zilla::Role::AfterBuild> plugins do their thing.
#pod
#pod =head1 RELEASING YOUR DIST
#pod
#pod By running C<dzil release>, you'll test your
#pod distribution, build a tarball of it, and upload it to the CPAN.  Plugins are
#pod able to do things like check your version control system to make sure you're
#pod releasing a new version and that you tag the version you've just uploaded.  It
#pod can also update your Changelog file, too, making sure that you don't need to
#pod know what your next version number will be before releasing.
#pod
#pod The final CPAN release process is implemented by the
#pod L<UploadToCPAN|Dist::Zilla::Plugin::UploadToCPAN> plugin. However you can
#pod replace it by your own to match your own (company?) process.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<dzil>
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Tutorial - how to use this "Dist::Zilla" thing

=head1 VERSION

version 6.032

=head1 SYNOPSIS

B<BEFORE YOU GET STARTED>:  Maybe you should be looking at the web-based
tutorial instead.  It's more complete.  L<https://dzil.org/tutorial/start.html>

Dist::Zilla builds distributions to be uploaded to the CPAN.  That means that
the first thing you'll need is some code.

Once you've got that, you'll need to configure Dist::Zilla.  Here's a simple
F<dist.ini>:

  name    = Carbon-Dating
  version = 0.003
  author  = Alan Smithee <asmithee@example.org>
  license = Perl_5
  copyright_holder = Alan Smithee

  [@Basic]

  [Prereqs]
  App::Cmd          = 0.013
  Number::Nary      = 0
  Sub::Exporter     = 0.981

The topmost section configures Dist::Zilla itself.  Here are some of the
entries it expects:

  name     - (required) the name of the dist being built
  version  - (required) the version of the dist
  abstract - (required) a short description of the dist
  author   - (optional) the dist author (you may have multiple entries for this)
  license  - (required) the dist license; must be a Software::License::* name

  copyright_holder - (required) the entity holding copyright on the dist

Some of the required values above may actually be provided by means other than
the top-level section of the config.  For example,
L<VersionProvider|Dist::Zilla::Role::VersionProvider> plugins can
set the version, and a line like this in the "main module" of the dist will set
the abstract:

  # ABSTRACT: a totally cool way to do totally great stuff

The main modules is the module that shares the same name as the dist, in
general.

Named sections load plugins, with the following rules:

If a section name begins with an equals sign (C<=>), the rest of the section
name is left intact and not expanded.  If the section name begins with an at
sign (C<@>), it is prepended with C<Dist::Zilla::PluginBundle::>.  Otherwise,
it is prepended with C<Dist::Zilla::Plugin::>.

The values inside a section are given as configuration to the plugin.  Consult
each plugin's documentation for more information.

The "Basic" bundle, seen above, builds a fairly normal distribution.  It
rewrites tests from F<./xt>, adds some information to POD, and builds a
F<Makefile.PL>.  For more information, you can look at the docs for
L<@Basic|Dist::Zilla::PluginBundle::Basic> and see the plugins it includes.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 BUILDING YOUR DIST

Maybe we're getting ahead of ourselves, here.  Configuring a bunch of plugins
won't do you a lot of good unless you know how to use them to build your dist.

Dist::Zilla ships with a command called F<dzil> that will get installed by
default.  While it can be extended to offer more commands, there are two really
useful ones:

  $ dzil build

The C<build> command will build the distribution.  Say you're using the
configuration in the SYNOPSIS above.  You'll end up with a file called
F<Carbon-Dating-0.004.tar.gz>.  As long as you've done everything right, it
will be suitable for uploading to the CPAN.

Of course, you should really test it out first.  You can test the dist you'd be
building by running another F<dzil> command:

  $ dzil test

This will build a new copy of your distribution and run its tests, so you'll
know whether the dist that C<build> would build is worth releasing!

=head1 HOW BUILDS GET BUILT

This is really more of a sketchy overview than a spec.

First, all the plugins that perform the
L<BeforeBuild|Dist::Zilla::Role::BeforeBuild> perform their C<before_build>
tasks.

The build root (where the dist is being built) is made.

The L<FileGatherer|Dist::Zilla::Role::FileGatherer>s gather and inject files
into the distribution, then the L<FilePruner|Dist::Zilla::Role::FilePruner>s
remove some of them.

All the L<FileMunger|Dist::Zilla::Role::FileMunger>s get a chance to muck about
with each file, possibly changing its name, content, or installability.

Now that the distribution is basically set up, it needs an install tool, like a
F<Makefile.PL>.  All the
L<InstallTool|Dist::Zilla::Role::InstallTool>-performing plugins are used to
do whatever is needed to make the dist installable.

Everything is just about done.  The files are all written out to disk and the
L<AfterBuild|Dist::Zilla::Role::AfterBuild> plugins do their thing.

=head1 RELEASING YOUR DIST

By running C<dzil release>, you'll test your
distribution, build a tarball of it, and upload it to the CPAN.  Plugins are
able to do things like check your version control system to make sure you're
releasing a new version and that you tag the version you've just uploaded.  It
can also update your Changelog file, too, making sure that you don't need to
know what your next version number will be before releasing.

The final CPAN release process is implemented by the
L<UploadToCPAN|Dist::Zilla::Plugin::UploadToCPAN> plugin. However you can
replace it by your own to match your own (company?) process.

=head1 SEE ALSO

L<dzil>

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
