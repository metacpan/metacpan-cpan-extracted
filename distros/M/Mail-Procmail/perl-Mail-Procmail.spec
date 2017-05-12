Summary: Mail::Procmail is an email filter tool
%define module Mail-Procmail
%define path   Mail
Name: perl-%{module}
Version: 1.03
Release: 1
Source: http://www.perl.com/CPAN/modules/by-module/%{path}/%{module}-%{version}.tar.gz
Copyright: GPL or Artistic
Group: Mail/Tools
Packager: Johan Vromans <jvromans@squirrel.nl>
BuildRoot: /usr/tmp/%{name}-buildroot
Requires: perl >= 5.6.0
Requires: perl(Mail::Internet) == 1.33
Requires: perl(LockFile::Simple) >= 0.2.5
BuildRequires: perl >= 5.6.0
BuildRequires: perl(Mail::Internet) == 1.33
BuildRequires: perl(LockFile::Simple) >= 0.2.5
BuildArchitectures: noarch

%description
Procmail is one of the most powerful tools in use on Unix systems to
filter incoming email. It is, however, rather complicated and
configuring it can be a pain.

Mail::Procmail is a Perl module that provides procmail-like
tools that you can use to write your own mail filtering program.

%prep
%setup -n %{module}-%{version}

%build
perl Makefile.PL
make all
make test

%install
rm -fr $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/usr
make install PREFIX=$RPM_BUILD_ROOT/usr

# Remove some unwanted files
find $RPM_BUILD_ROOT -name .packlist -exec rm -f {} \;
find $RPM_BUILD_ROOT -name perllocal.pod -exec rm -f {} \;

# Compress manual pages
test -x /usr/lib/rpm/brp-compress && /usr/lib/rpm/brp-compress

# Build distribution list
( cd $RPM_BUILD_ROOT ; find * -type f -printf "/%p\n" ) > files

%files -f files
%doc README CHANGES examples
