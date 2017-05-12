#############################

Name: perl-JSON-API
Version: %{_version}
Release: %{_release}
License: proprietary
Summary: Module to interact with a JSON API

Source: %{_dist}.tar.gz
BuildArch: noarch
BuildRequires: perl(JSON), perl-libwww-perl, perl(Test::Pod::Coverage), perl(Test::Fake::HTTPD), perl(IO::Capture), perl(Module::Build), perl(URI::Encode)
Requires: perl(JSON), perl-libwww-perl, perl(URI::Encode)

%description
JSON::API abstracts interactions with a remote API into simple methods for requesting
and sending data, returning native perl datastructures from decoded JSON responses.

#############################

%prep
%setup -q -n %{_dist}

%build
%{__perl} Build.PL INSTALLDIRS=vendor
./Build && ./Build test

%install
# recreate build root
[ %{buildroot} != '/' ] && rm -rf %{buildroot}
mkdir -p %{buildroot}

#install into build root
./Build destdir=%{buildroot}/ install

# remove silly files
find %{buildroot} -name 'perllocal.pod' -o -name '.packlist' | xargs -r rm

# force compression of man pages
/usr/lib/rpm/brp-compress

# generate files list
find %{buildroot} -type f | sed -e "s@%{buildroot}/@/@" > .rpm_files

%clean
./Build realclean


#############################

%files -f .rpm_files
%defattr(-, root, root)

# vim:ft=spec
