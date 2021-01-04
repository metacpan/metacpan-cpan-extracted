package Dist::Mgr::FileData;

use warnings;
use strict;

use Exporter qw(import);
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    _changes_file

    _ci_github_file

    _git_ignore_file

    _module_section_ci_badges
    _module_template_file

    _makefile_section_meta_merge
    _makefile_section_bugtracker
    _makefile_section_repo

    _manifest_skip_file

    _unwanted_filesystem_entries
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

sub _changes_file {
    my ($module) = @_;

    die "_changes_file() needs module param" if ! defined $module;

    $module =~ s/::/-/g;

    return (
        qq{Revision history for $module},
        qq{},
        qq{0.01 UNREL},
        qq{    - Auto generated distribution with Dist::Mgr},
    );
}

sub _ci_github_file {
    my ($os) = @_;

    if (! defined $os) {
        $os = [qw(l w m)];
    }

    my %os_matrix_map = (
        l => qq{ubuntu-latest},
        w => qq{windows-latest},
        m => qq{macos-latest},
    );

    my $os_matrix = "[ ";
    $os_matrix .= join(', ', map { $os_matrix_map{$_} } @$os);
    $os_matrix .= " ]";

    return (
        qq{name: CI},
        qq{on:},
        qq{  push:},
        qq{    branches: [ master ]},
        qq{  pull_request:},
        qq{    branches: [ master ]},
        qq{  workflow_dispatch:},
        qq{jobs:},
        qq{  build:},
        qq{    runs-on: \${{ matrix.os }}},
        qq{    strategy:},
        qq{      matrix:},
        qq{        os: $os_matrix},
        qq{        perl: [ '5.32', '5.24', '5.18', '5.14', '5.10' ]},
        qq{        include:},
        qq{          - perl: '5.32'},
        qq{            os: ubuntu-latest},
        qq{            coverage: true},
        qq{    name: Perl \${{ matrix.perl }} on \${{ matrix.os }}},
        qq{    steps:},
        qq{      - uses: actions/checkout\@v2},
        qq{      - name: Set up perl},
        qq{        uses: shogo82148/actions-setup-perl\@v1},
        qq{        with:},
        qq{          perl-version: \${{ matrix.perl }}},
        qq{      - run: perl -V},
        qq{      - run: cpanm ExtUtils::PL2Bat},
        qq{      - run: cpanm ExtUtils::MakeMaker},
        qq{      - run: cpanm --installdeps .},
        qq{      - name: Run tests (no coverage)},
        qq{        if: \${{ !matrix.coverage }}},
        qq{        run: prove -lv t},
        qq{      - name: Run tests (with coverage)},
        qq{        if: \${{ matrix.coverage }}},
        qq{        env:},
        qq{          GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}},
        qq{        run: |},
        qq{          cpanm -n Devel::Cover::Report::Coveralls},
        qq{          cover -test -report Coveralls},
    );
}

sub _git_ignore_file {
    return (
        q{Makefile},
        q{*~},
        q{*.bak},
        q{*.swp},
        q{*.bak},
        q{.hg/},
        q{.git/},
        q{MYMETA.*},
        q{*.tar.gz},
        q{_build/},
        q{blib/},
        q{Build/},
        q{META.json},
        q{META.yml},
        q{*.old},
        q{*.orig},
        q{pm_to_blib},
        q{.metadata/},
        q{.idea/},
        q{*.debug},
        q{*.iml},
        q{*.bblog},
        q{BB-Pass/},
        q{BB-Fail/},
    );
}

sub _module_section_ci_badges {
    my ($author, $repo) = @_;

    return (
        qq{},
        qq{=for html},
        qq{<a href="https://github.com/$author/$repo/actions"><img src="https://github.com/$author/$repo/workflows/CI/badge.svg"/></a>},
        qq{<a href='https://coveralls.io/github/$author/$repo?branch=master'><img src='https://coveralls.io/repos/$author/$repo/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>},
        qq{},
    );
}
sub _module_template_file {
    my ($module, $author, $email) = @_;

    if (! defined $module || ! defined $author || ! defined $email) {
        die "_module_template_file() requires 'module', 'author' and 'email' parameters";
    }

    my ($email_user, $email_domain);

    if ($email =~ /(.*)\@(.*)/) {
        $email_user   = $1;
        $email_domain = $2;
    }

    my $year = (localtime)[5] + 1900;

    return (
        qq{package $module;},
        qq{},
        qq{use strict;},
        qq{use warnings;},
        qq{},
        qq{our \$VERSION = '0.01';},
        qq{},
        qq{sub __placeholder {}},
        qq{},
        qq{1;},
        qq{__END__},
        qq{},
        qq{=head1 NAME},
        qq{},
        qq{$module - One line description},
        qq{},
        qq{=head1 SYNOPSIS},
        qq{},
        qq{=head1 DESCRIPTION},
        qq{},
        qq{=head1 METHODS},
        qq{},
        qq{=head2 name},
        qq{},
        qq{Description.},
        qq{},
        qq{I<Parameters>:},
        qq{},
        qq{    \$bar},
        qq{},
        qq{I<Mandatory, String>: The name of the thing with the guy and the place.},
        qq{},
        qq{I<Returns>: C<0> upon success.},
        qq{},
        qq{=head1 AUTHOR},
        qq{},
        qq{$author, C<< <$email_user at $email_domain> >>},
        qq{},
        qq{=head1 LICENSE AND COPYRIGHT},
        qq{},
        qq{Copyright $year $author.},
        qq{},
        qq{This program is free software; you can redistribute it and/or modify it},
        qq{under the terms of the the Artistic License (2.0). You may obtain a},
        qq{copy of the full license at:},
        qq{},
        qq{L<http://www.perlfoundation.org/artistic_license_2_0>},
    );
}

sub _makefile_section_meta_merge {
    return (
        "    META_MERGE => {",
        "        'meta-spec' => { version => 2 },",
        "        resources   => {",
        "        },",
        "    },"
    );
}
sub _makefile_section_bugtracker {
    my ($author, $repo) = @_;

    return (
        "            bugtracker => {",
        "                web => 'https://github.com/$author/$repo/issues',",
        "            },"
    );

}
sub _makefile_section_repo {
    my ($author, $repo) = @_;

    return (
        "            repository => {",
        "                type => 'git',",
        "                url => 'https://github.com/$author/$repo.git',",
        "                web => 'https://github.com/$author/$repo',",
        "            },"
    );

}

sub _manifest_skip_file {
    return (
        q{~$},
        q{^blib/},
        q{^pm_to_blib/},
        q{.old$},
        q{.orig$},
        q{.tar.gz$},
        q{.bak$},
        q{.swp$},
        q{^test/},
        q{.hg/},
        q{.hgignore$},
        q{^_build/},
        q{^Build$},
        q{^MYMETA\.yml$},
        q{^MYMETA\.json$},
        q{^README.bak$},
        q{^Makefile$},
        q{.metadata/},
        q{.idea/},
        q{pm_to_blib$},
        q{.git/},
        q{.debug$},
        q{.gitignore$},
        q{^\w+.pl$},
        q{.ignore.txt$},
        q{.travis.yml$},
        q{.iml$},
        q{examples/},
        q{build/},
        q{^\w+.list$},
        q{.bblog$},
        q{.base$},
        q{BB-Pass/},
        q{BB-Fail/},
        q{cover_db/},
        q{scrap\.pl},
    );
}

sub _unwanted_filesystem_entries {
    return qw(
        xt/
        ignore.txt
        README
    );
}

sub __placeholder {}

1;
__END__

=head1 NAME

Dist::Mgr::FileData - Fetch pre-written contents for various distribution files.

=head1 DESCRIPTION

This module returns arrays of pre-written file contents that can be used to
insert into various files.

=head1 SYNOPSIS

use Dist::Mgr::FileData qw(:all);

=head1 EXPORT_OK

We export nothing by default. See the L</FUNCTIONS> section for everything that
can be imported individually, or with the C<:all> tag.

All functions are quasi-private and mainly used for development, but I've
decided to advertise them anyway.

=head1 FUNCTIONS

=head2 _changes_file($module)

Returns an array of the lines of a default custom C<Changes> file.

=head2 _ci_github_file($os)

Return an array of the file contents of a custom Github Actions CI configuration
file.

Send in the parameters within an array reference. Each entry signifies the OS of
the system the build will run on. The three options mapped to how we handle them
internally.

        l => qq{ubuntu-latest},
        w => qq{windows-latest},
        m => qq{macos-latest},

=head2 _git_ignore_file()

Returns an array of the contents of a populated C<.gitignore> file.

=head2 _module_section_ci_badges($author, $repo)

Returns an array of the lines required to add CI and coverage badges. C<$author>
is your Github username, and C<$repo> should be self-explanitory.

=head2 _module_template_file($module, $author, $email)

Returns an array of the file lines of our default module file. Parameters are
the same as if you were running C<module-starter> at the command line.

=head2 _makefile_section_meta_merge()

Return an array of the skeleton contents of a C<Makefile.PL> C<META_MERGE>
section. We put repository and bugtracer information in here.

=head2 _makefile_section_bugtracker($author, $repo)

Returns an array of the contents that make up the bugtracker section of a
C<Makefile.PL> file.

=head2 _makefile_section_repo($author, $repo)

Returns an array of the contents that make up the repository section of a
C<Makefile.PL> file.

=head2 _manifest_skip_file()

Returns an array of the file lines that make up a default C<MANIFEST.SKIP> file.

=head2 _unwanted_filesystem_entries()

Returns an array of files and directories we remove from the base, stock
distribution after it's been initialized.

=head1 Adding New File Contents

Read through the various functions to get an idea of how things hang together.

Manage any required variables.

The C<dev/quote_file_contents.pl> script takes a file name as an argument, and
will generate and print to C<STDOUT> the quoted contents that can be dropped
into an array and returned from your new function.

Change the quote type within the script if required.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2020 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2020 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>
