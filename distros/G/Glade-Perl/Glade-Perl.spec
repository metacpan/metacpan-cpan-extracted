%define ver     0.61
%define rel     1
%define name    Glade-Perl
%define rlname  %{name}
%define source0 http://www.glade.perl.connectfree.co.uk/%{name}/%{name}-%{ver}.tar.gz
%define url     http://www.glade.perl.connectfree.co.uk/
%define group   Development/Languages
%define copy    GPL or Artistic
%define filelst %{name}-%{ver}-files
%define confdir /etc
%define prefix  /usr
%define arch    noarch

Summary: Perl module to generate Gtk-Perl apps from a Glade file.

Name: %name
Version: %ver
Release: %rel
Copyright: %{copy}
Packager: Dermot Musgrove <dermot@glade.perl.connectfree.co.uk>
Source: %{source0}
URL: %{url}
Group: %{group}
BuildArch: %{arch}
BuildRoot: /var/tmp/%{name}-%{ver}

%description
Glade-Perl will read a Glade-Interface XML file, build the UI and/or
write the perl source to create the UI later and handle signals. 
It also creates an 'App' and a 'Subclass' that you can edit.

The current version of Glade-Perl is available on CPAN or on the 
project website at

   http://www.glade.perl.connectfree.co.uk/

Glade-Perl can generate AUTOLOAD type OO code with subclasses or even
Libglade apps.

%prep
%setup -n %{rlname}-%{ver}

%build
if [ $(perl -e 'print index($INC[0],"%{prefix}/lib/perl");') -eq 0 ];then
    # package is to be installed in perl root
    inst_method="makemaker-root"
    CFLAGS=$RPM_OPT_FLAGS perl Makefile.PL PREFIX=%{prefix}
else
    # package must go somewhere else (eg. /opt), so leave off the perl
    # versioning to ease integration with automatic profile generation scripts
    # if this is really a perl-version dependant package you should not omiss
    # the version info...
    inst_method="makemaker-site"
    CFLAGS=$RPM_OPT_FLAGS perl Makefile.PL PREFIX=%{prefix} LIB=%{prefix}/lib/perl5
fi

echo $inst_method > inst_method

# get number of processors for parallel builds on SMP systems
numprocs=`cat /proc/cpuinfo | grep processor | wc | cut -c7`
if [ "x$numprocs" = "x" -o "x$numprocs" = "x0" ]; then
  numprocs=1
fi

make "MAKE=make -j$numprocs"

%install
rm -rf $RPM_BUILD_ROOT

if [ "$(cat inst_method)" = "makemaker-root" ];then
   make UNINST=1 PREFIX=$RPM_BUILD_ROOT%{prefix} install
elif [ "$(cat inst_method)" = "makemaker-site" ];then
   make UNINST=1 PREFIX=$RPM_BUILD_ROOT%{prefix} LIB=$RPM_BUILD_ROOT%{prefix}/lib/perl5 install
fi

%__os_install_post
find $RPM_BUILD_ROOT -type f -print|sed -e "s@^$RPM_BUILD_ROOT@@g" > %{filelst}

%files -f %{filelst}
%defattr(-, root, root)
%doc Documentation/*

%clean
rm -rf $RPM_BUILD_ROOT

%changelog
* Fri Jun 22 2001 Dermot Musgrove <dermot@glade.perl.connectfree.co.uk>
  Simplified for pure Perl use

* Tue Apr 09 2001 Dermot Musgrove <dermot@glade.perl.connectfree.co.uk>
  Edited from George.spec by Frank de Lange <frank@unternet.org>
