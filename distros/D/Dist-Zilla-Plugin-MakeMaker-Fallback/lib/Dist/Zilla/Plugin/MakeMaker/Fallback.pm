use strict;
use warnings;
package Dist::Zilla::Plugin::MakeMaker::Fallback; # git description: v0.030-7-gf28e755
# vim: set ts=8 sts=2 sw=2 tw=115 et :
# ABSTRACT: Generate a Makefile.PL containing a warning for legacy users
# KEYWORDS: plugin installer MakeMaker Makefile.PL toolchain legacy ancient backcompat

our $VERSION = '0.031';

use Moose;
extends 'Dist::Zilla::Plugin::MakeMaker::Awesome' => { -version => '0.47' };
with 'Dist::Zilla::Role::AfterBuild' => { -excludes => [qw(dump_config mvp_multivalue_args mvp_aliases)] };

use List::Keywords 0.03 qw(first any);
use version;
use Path::Tiny;
use namespace::autoclean;

has skip_release_testing => (
    is => 'ro',
    isa => 'Bool',
);

around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    my $data = {
        blessed($self) ne __PACKAGE__ ? ( version => $VERSION ) : (),
        skip_release_testing => ($self->skip_release_testing ? 1 : 0),
    };
    $config->{+__PACKAGE__} = $data if keys %$data;

    return $config;
};

sub after_build
{
    my $self = shift;

    # if Makefile.PL is missing, someone removed it (probably a bad thing)
    my $makefile_pl = first { $_->name eq 'Makefile.PL' } @{ $self->zilla->files };
    $self->log_fatal('No Makefile.PL found -- did you remove it!?') if not $makefile_pl;

    my $build_pl = first { $_->name eq 'Build.PL' } @{ $self->zilla->files };
    $self->log_fatal('No Build.PL found to fall back from!') if not $build_pl;

    $self->log('share/ files present: did you forget to include [ShareDir]?')
      if any { path('share')->subsumes($_->name) } @{ $self->zilla->files }
        and not @{ $self->zilla->plugins_with(-ShareDir) };
}

around _build_WriteMakefile_args => sub
{
    my $orig = shift;
    my $self = shift;
    my $WriteMakefile_args = $self->$orig(@_);

    return +{
        PL_FILES => {}, # to avoid Build.PL from slipping in on EUMM < 6.25
        %$WriteMakefile_args,
    };
};

sub __preamble
{
    # this module file gets passed through a template itself at build time, so
    # we need to escape these template markers so they survive

    my $code = <<"CODE"
BEGIN {
my %configure_requires = (
\x7b\x7b  # look, it's a template inside a template!
CODE
. <<'CODE'
    my $configure_requires = $dist->prereqs->as_string_hash->{configure}{requires};
    delete $configure_requires->{perl};

    # prereq specifications don't always provide exact versions - we just weed
    # those out for now, as this shouldn't occur that frequently.  There is no
    # point in using CPAN::Meta, as that wasn't in core in the range of perl
    # versions that is likely to not have satisfied these prereqs.
    delete @{$configure_requires}{ grep !version::is_strict($configure_requires->{$_}), keys %$configure_requires };
    join('', map
            "    '$_' => '$configure_requires->{$_}',\n",
            sort keys %$configure_requires)
CODE
    . "\x7d\x7d);\n" . <<'CODE'

my %errors = map {
    eval "require $_; $_->VERSION($configure_requires{$_}); 1";
    $_ => $@,
} keys %configure_requires;

if (grep $_, values %errors)
{
    warn "Errors from configure prereqs:\n"
        . do {
            require Data::Dumper; Data::Dumper->new([ \%errors ])->Indent(2)->Terse(1)->Sortkeys(1)->Dump;
        };
}

if (not $ENV{PERL_MM_FALLBACK_SILENCE_WARNING})
{
    warn <<'EOW';
CODE
    . join('', <DATA>)
    . <<'CODE';
EOW
    sleep 10 if -t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT));
}
} # end BEGIN
CODE
}

around _build_MakeFile_PL_template => sub
{
    my $orig = shift;
    my $self = shift;

    my $string = $self->$orig(@_);

    # strip out the hard VERSION requirement - be gentle to users that failed
    # to satisfy configure_requires
    $string =~ s/^use ExtUtils::MakeMaker\K[^;]+;$/;/m;

    # splice in our stuff after the preamble bits
    $self->log_fatal('failed to find position in Makefile.PL to munge!')
        if $string !~ m/\{\{ \$header \}\}\n/g;

    return substr($string, 0, pos($string)) . $self->__preamble . substr($string, pos($string));
};

sub build {
    my $self = shift;
    $self->log_debug('doing nothing during build...');
}

sub test
{
    my $self = shift;

    if ($ENV{RELEASE_TESTING} and not $self->skip_release_testing)
    {
        # we are either performing a 'dzil test' with RELEASE_TESTING set, or
        # a 'dzil release' -- the Build.PL plugin will run tests with extra
        # variables set, so as an extra check, we will perform them without.

        local $ENV{RELEASE_TESTING};
        local $ENV{AUTHOR_TESTING};
        local $ENV{PERL_MM_FALLBACK_SILENCE_WARNING} = 1;
        $self->log_debug('performing test with RELEASE_TESTING, AUTHOR_TESTING unset');
        return $self->next::method(@_);
    }
    else
    {
        $self->log_debug('doing nothing during test...');
    }
}

__PACKAGE__->meta->make_immutable;

#pod =pod
#pod
#pod =for Pod::Coverage after_build build test
#pod
#pod =head1 SYNOPSIS
#pod
#pod In your F<dist.ini>, when you want to ship a F<Build.PL> as well as a fallback
#pod F<Makefile.PL> in case the user's C<cpan> client is so old it doesn't recognize
#pod C<configure_requires>:
#pod
#pod     [ModuleBuildTiny]
#pod     [MakeMaker::Fallback]
#pod
#pod =head1 DESCRIPTION
#pod
#pod This plugin is a derivative of C<[MakeMaker]>, generating a F<Makefile.PL> in
#pod your distribution, with an added preamble that is printed when it is run:
#pod
#pod =for stopwords cpanminus mb
#pod
#pod =for comment This section was inserted from the DATA section at build time
#pod
#pod =begin :verbatim
#pod
#pod *** WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING ***
#pod
#pod If you're seeing this warning, your toolchain is really, really old* and
#pod you'll almost certainly have problems installing CPAN modules from this
#pod century. But never fear, dear user, for we have the technology to fix this!
#pod
#pod If you're using CPAN.pm to install things, then you can upgrade it using:
#pod
#pod     cpan CPAN
#pod
#pod If you're using CPANPLUS to install things, then you can upgrade it using:
#pod
#pod     cpanp CPANPLUS
#pod
#pod If you're using cpanminus, you shouldn't be seeing this message in the first
#pod place, so please file an issue on github.
#pod
#pod If you're using a packaging tool through a unix distribution, this issue
#pod should be reported to the package manager.
#pod
#pod If you're installing manually, please retrain your fingers to run Build.PL
#pod when present instead of Makefile.PL.
#pod
#pod This public service announcement was brought to you by the Perl Toolchain
#pod Gang, the irc.perl.org #toolchain IRC channel, and the number 42.
#pod
#pod ----
#pod
#pod * Alternatively, you are doing something overly clever, in which case you
#pod should consider setting the 'prefer_installer' config option in CPAN.pm, or
#pod 'prefer_makefile' in CPANPLUS, to 'mb" and '0' respectively.
#pod
#pod You can also silence this warning for future installations by setting the
#pod PERL_MM_FALLBACK_SILENCE_WARNING environment variable.
#pod
#pod
#pod =end :verbatim
#pod
#pod =for stopwords ModuleBuildTiny
#pod
#pod Additionally, any errors resulting from loading configure-require prerequisites are captured and printed, which
#pod indicates a failure of the user or the tools to read and understand F<META.yml> or F<META.json>.
#pod
#pod It is a fatal error to use this plugin when there is not also another
#pod plugin enabled that generates a F<Build.PL> (such as
#pod L<[ModuleBuildTiny]|Dist::Zilla::Plugin::ModuleBuildTiny>).
#pod
#pod On top of the regular testing that is provided via the F<Build.PL>-producing
#pod plugin, C<dzil test --release> or C<dzil release> will run tests with extra
#pod testing variables B<unset> (C<AUTHOR_TESTING>, C<RELEASE_TESTING>). This is to
#pod weed out test issues that only manifest under these conditions (for example:
#pod bad test count, conditional module loading).
#pod You can prevent this extra testing from happening by setting C<skip_release_testing = 1>
#pod in your configuration or F<dist.ini>.
#pod
#pod =head1 ACKNOWLEDGEMENTS
#pod
#pod =for stopwords Peter Rabbitson ribasushi Matt Trout mst
#pod
#pod Peter Rabbitson (ribasushi), whose concerns that low-level utility modules
#pod were shipping with install tools that did not work out of the box with perls
#pod 5.6 and 5.8 inspired the creation of this module.
#pod
#pod Matt Trout (mst), for realizing a simple warning would be sufficient, rather
#pod than a complicated detection heuristic, as well as the text of the warning
#pod (but it turns out that we still need a I<simple> detection heuristic, so -0.5
#pod for that...)
#pod
#pod =head1 SEE ALSO
#pod
#pod =for :list
#pod * L<Dist::Zilla::Plugin::MakeMaker>
#pod * L<Dist::Zilla::Plugin::ModuleBuildTiny>
#pod * L<Dist::Zilla::Plugin::ModuleBuildTiny::Fallback>
#pod
#pod =cut

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::MakeMaker::Fallback - Generate a Makefile.PL containing a warning for legacy users

=head1 VERSION

version 0.031

=head1 SYNOPSIS

In your F<dist.ini>, when you want to ship a F<Build.PL> as well as a fallback
F<Makefile.PL> in case the user's C<cpan> client is so old it doesn't recognize
C<configure_requires>:

    [ModuleBuildTiny]
    [MakeMaker::Fallback]

=head1 DESCRIPTION

This plugin is a derivative of C<[MakeMaker]>, generating a F<Makefile.PL> in
your distribution, with an added preamble that is printed when it is run:

=for Pod::Coverage after_build build test

=for stopwords cpanminus mb

=for comment This section was inserted from the DATA section at build time

    *** WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING ***

    If you're seeing this warning, your toolchain is really, really old* and
    you'll almost certainly have problems installing CPAN modules from this
    century. But never fear, dear user, for we have the technology to fix this!

    If you're using CPAN.pm to install things, then you can upgrade it using:

    cpan CPAN

    If you're using CPANPLUS to install things, then you can upgrade it using:

    cpanp CPANPLUS

    If you're using cpanminus, you shouldn't be seeing this message in the first
    place, so please file an issue on github.

    If you're using a packaging tool through a unix distribution, this issue
    should be reported to the package manager.

    If you're installing manually, please retrain your fingers to run Build.PL
    when present instead of Makefile.PL.

    This public service announcement was brought to you by the Perl Toolchain
    Gang, the irc.perl.org #toolchain IRC channel, and the number 42.

    ----

    * Alternatively, you are doing something overly clever, in which case you
    should consider setting the 'prefer_installer' config option in CPAN.pm, or
    'prefer_makefile' in CPANPLUS, to 'mb" and '0' respectively.

    You can also silence this warning for future installations by setting the
    PERL_MM_FALLBACK_SILENCE_WARNING environment variable.

=for stopwords ModuleBuildTiny

Additionally, any errors resulting from loading configure-require prerequisites are captured and printed, which
indicates a failure of the user or the tools to read and understand F<META.yml> or F<META.json>.

It is a fatal error to use this plugin when there is not also another
plugin enabled that generates a F<Build.PL> (such as
L<[ModuleBuildTiny]|Dist::Zilla::Plugin::ModuleBuildTiny>).

On top of the regular testing that is provided via the F<Build.PL>-producing
plugin, C<dzil test --release> or C<dzil release> will run tests with extra
testing variables B<unset> (C<AUTHOR_TESTING>, C<RELEASE_TESTING>). This is to
weed out test issues that only manifest under these conditions (for example:
bad test count, conditional module loading).
You can prevent this extra testing from happening by setting C<skip_release_testing = 1>
in your configuration or F<dist.ini>.

=head1 ACKNOWLEDGEMENTS

=for stopwords Peter Rabbitson ribasushi Matt Trout mst

Peter Rabbitson (ribasushi), whose concerns that low-level utility modules
were shipping with install tools that did not work out of the box with perls
5.6 and 5.8 inspired the creation of this module.

Matt Trout (mst), for realizing a simple warning would be sufficient, rather
than a complicated detection heuristic, as well as the text of the warning
(but it turns out that we still need a I<simple> detection heuristic, so -0.5
for that...)

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla::Plugin::MakeMaker>

=item *

L<Dist::Zilla::Plugin::ModuleBuildTiny>

=item *

L<Dist::Zilla::Plugin::ModuleBuildTiny::Fallback>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-MakeMaker-Fallback>
(or L<bug-Dist-Zilla-Plugin-MakeMaker-Fallback@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-MakeMaker-Fallback@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

I am also usually active on irc, as 'ether' at C<irc.perl.org> and C<irc.libera.chat>.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
*** WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING ***

If you're seeing this warning, your toolchain is really, really old* and
you'll almost certainly have problems installing CPAN modules from this
century. But never fear, dear user, for we have the technology to fix this!

If you're using CPAN.pm to install things, then you can upgrade it using:

    cpan CPAN

If you're using CPANPLUS to install things, then you can upgrade it using:

    cpanp CPANPLUS

If you're using cpanminus, you shouldn't be seeing this message in the first
place, so please file an issue on github.

If you're using a packaging tool through a unix distribution, this issue
should be reported to the package manager.

If you're installing manually, please retrain your fingers to run Build.PL
when present instead of Makefile.PL.

This public service announcement was brought to you by the Perl Toolchain
Gang, the irc.perl.org #toolchain IRC channel, and the number 42.

----

* Alternatively, you are doing something overly clever, in which case you
should consider setting the 'prefer_installer' config option in CPAN.pm, or
'prefer_makefile' in CPANPLUS, to 'mb" and '0' respectively.

You can also silence this warning for future installations by setting the
PERL_MM_FALLBACK_SILENCE_WARNING environment variable.
