# NAME

Dist::Zilla::Plugin::RPM - Build an RPM from your Dist::Zilla release

# VERSION

version 0.016

# SYNOPSIS

In your dist.ini:

    [RPM]
    spec_file = build/dist.spec
    sign = 1
    ignore_build_deps = 0

    push_packages = 0
    push_command = rhnpush -s
    push_ignore_packages = .src.rpm$

After adding the \[RPM\] section to the dist.ini file, the mkrpmspec command will be available. Running this command allow you to make the dzil.spec file from the template. Then dzil release will build the RPM file.

It keeps track of build RPM files and can be used to push generated
packages into a repository.

# DESCRIPTION

This plugin is a Releaser for Dist::Zilla that builds an RPM of your
distribution.

# ATTRIBUTES

- spec\_file (default: "build/dist.spec")

    The spec file to use to build the RPM.

    The spec file is run through [Text::Template](https://metacpan.org/pod/Text%3A%3ATemplate) before calling
    rpmbuild, so you can substitute values from Dist::Zilla into the final output.
    The template uses <% %> tags (like [Mason](https://metacpan.org/pod/Mason)) as delimiters to avoid
    conflict with standard spec file markup.

    Two variables are available in the template:

    - $zilla

        The main Dist::Zilla object

    - $archive

        The filename of the release tarball

- sign (default: False)

    If set to a true value, rpmbuild will be called with the --sign option.

- ignore\_build\_deps (default: False)

    If set to a true value, rpmbuild will be called with the --nodeps option.

- push\_packages (default: false)

    This allowes you to specify a command to push your generated RPM packages to a
    repository.  RPM filenames are writen one-per-line to stdin. If push\_packages
    is set to 1, it will execute the push\_command on the generated RPMs. By default
    the source packages will be excluded.

- push\_command (default: rhnpush -s)

    Command used to push packages.

- push\_ignore\_packages (default: .src.rpm$)

    A regular expression for packages which should NOT be pushed.

# SAMPLE SPEC FILE TEMPLATE

    Name: <% $zilla->name %>
    Version: <% (my $v = $zilla->version) =~ s/^v//; $v %>
    Release: 1

    Summary: <% $zilla->abstract %>
    License: GPL+ or Artistic
    Group: Applications/CPAN
    BuildArch: noarch
    URL: <% $zilla->license->url %>
    Source: <% $archive %>
    
    BuildRoot: %{_tmppath}/%{name}-%{version}-BUILD
    
    %description
    <% $zilla->abstract %>
    
    %prep
    %setup -q
    
    %build
    perl Makefile.PL
    make test
    
    %install
    if [ "%{buildroot}" != "/" ] ; then
        rm -rf %{buildroot}
    fi
    make install DESTDIR=%{buildroot}
    find %{buildroot} | sed -e 's#%{buildroot}##' > %{_tmppath}/filelist
    
    %clean
    if [ "%{buildroot}" != "/" ] ; then
        rm -rf %{buildroot}
    fi
    
    %files -f %{_tmppath}/filelist
    %defattr(-,root,root)

# SEE ALSO

[Dist::Zilla](https://metacpan.org/pod/Dist%3A%3AZilla)

# AUTHOR

Vincent Lequertier <vi.le@autistici.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Vincent Lequertier, Stephen Clouse.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
