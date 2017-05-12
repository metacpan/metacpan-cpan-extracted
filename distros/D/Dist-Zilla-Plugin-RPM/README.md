#Dist-Zilla-Plugin-RPM

Dist::Zilla::Plugin::RPM - Build an RPM from your Dist::Zilla release

##DESCRIPTION

This plugin is a Releaser for Dist::Zilla that builds an RPM of your distribution.

##SYNOPSIS
In your dist.ini:

	[RPM]
	spec_file = build/dist.spec
	sign = 1
	ignore_build_deps = 0

    push_packages = 0
    push_command = rhnpush -s
    push_ignore_packages = .src.rpm$

After adding the [RPM] section to the dist.ini file, the `mkrpmspec` command will be available. Running this command allow you to make the dzil.spec file from the template. Then `dzil release` will make the RPM file.

If push_packages is set to 1, it will execute the `push_command` on the generated RPMs. By default the source packages will be excluded.

##ATTRIBUTES

###spec_file (default: "build/dist.spec")

The spec file to use to build the RPM.

The spec file is run through Text::Template before calling rpmbuild, so you can substitute values from Dist::Zilla into the final output. The template uses <% %> tags (like Mason) as delimiters to avoid conflict with standard spec file markup.

Two variables are available in the template:

- $zilla

The main Dist::Zilla object

- $archive

The filename of the release tarball

###sign (default: False)

If set to a true value, rpmbuild will be called with the --sign option.

###ignore_build_deps (default: False)

If set to a true value, rpmbuild will be called with the --nodeps option.

##SAMPLE SPEC FILE TEMPLATE

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

##SUPPORT AND DOCUMENTATION

You can find documentation for this module with the perldoc command.

    perldoc Dist::Zilla::Plugin::RPM

For reporting bugs, please use the github bugtracker

    https://github.com/SkySymbol/perl-dist-zilla-plugin-rpm/issues

You can also look for information at:

###RT, CPAN's request tracker

http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-Plugin-RPM

###AnnoCPAN, Annotated CPAN documentation

http://annocpan.org/dist/http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-Plugin-RPM

###CPAN Ratings

    http://cpanratings.perl.org/d/Dist-Zilla-Plugin-RPM

###Search CPAN

    http://search.cpan.org/dist/Dist-Zilla-Plugin-RPM

##NOTE

This module was written by Stephen Clouse, I'm taking over the
development.

##LICENSE AND COPYRIGHT

Copyright (C) 2016 Vincent Lequertier

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


