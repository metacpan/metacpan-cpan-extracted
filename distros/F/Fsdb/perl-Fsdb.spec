Summary: A set of commands for manipulating flat-text databases from the shell
Name: perl-Fsdb
Version: 2.66
Release: 1%{?dist}
License: GPLv2
URL: http://www.isi.edu/~johnh/SOFTWARE/FSDB/
Source0: http://www.isi.edu/~johnh/SOFTWARE/FSDB/Fsdb-%{version}.tar.gz
BuildArch: noarch
BuildRequires: perl
BuildRequires: perl-generators
BuildRequires: perl(Carp)
BuildRequires: perl(Config)
BuildRequires: perl(Exporter)
BuildRequires: perl(ExtUtils::MakeMaker)
BuildRequires: perl(File::Copy)
BuildRequires: perl(Getopt::Long)
BuildRequires: perl(IO::File)
BuildRequires: perl(IO::Handle)
BuildRequires: perl(IO::Uncompress::AnyUncompress)
BuildRequires: perl(Pod::Usage)
BuildRequires: perl(Pod::Html)
BuildRequires: perl(strict)
BuildRequires: perl(Test::More)
BuildRequires: perl(utf8)
BuildRequires: perl(warnings)
BuildRequires:  perl(XML::Simple)
BuildRequires:  perl(YAML::XS)
# following BRs are maybe not required?
BuildRequires:  perl(IO::Compress::Bzip2)
BuildRequires:  perl(IO::Compress::Gzip)
BuildRequires:  perl(IO::Compress::Xz)
# next two are needed to run test suites and are not autodetected
BuildRequires:       perl(HTML::Parser)
BuildRequires:       perl(Text::CSV_XS)
# next two are needed to run build README, see https://bugzilla.redhat.com/show_bug.cgi?id=1163149
BuildRequires: groff-base
BuildRequires: perl-podlators
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
# next two are needed to run test suites and are not autodetected
Requires:       perl(HTML::Parser)
Requires:       perl(Text::CSV_XS)
Requires:       perl(IO::Compress::Bzip2)
Requires:       perl(IO::Compress::Gzip)
Requires:       perl(IO::Compress::Xz)
Requires:  perl(XML::Simple)
Requires:  perl(YAML::XS)


%description
FSDB is a package of commands for manipulating flat-ASCII databases from
shell scripts.  FSDB is useful to process medium amounts of data (with
very little data you'd do it by hand, with megabytes you might want a
real database).  FSDB is very good at doing things like:

        - extracting measurements from experimental output
        - re-examining data to address different hypotheses
        - joining data from different experiments
        - eliminating/detecting outliers
        - computing statistics on data (mean, confidence intervals,
                correlations, histograms)
        - reformatting data for graphing programs

Rather than hand-code scripts to do each special case, FSDB provides
higher-level functions than one gets with raw perl or shell scripts.
(Some features:  control uses names instead of column numbers,
it is self-documenting, and is robust with good error and memory handling.)

%prep
%setup -q -n Fsdb-%{version}

%build
%{__perl} Makefile.PL INSTALLDIRS=vendor
make %{?_smp_mflags}

%install
# buildroot removal left in for EPEL 5
rm -rf $RPM_BUILD_ROOT
make pure_install DESTDIR=$RPM_BUILD_ROOT
find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} ';'
# fix up g+s getting set on directories, and executables being 0555
# (*I* think those are ok, but not rpmlint.)
find $RPM_BUILD_ROOT -type d -exec chmod g-s {} ';'
# find $RPM_BUILD_ROOT -executable -exec chmod 0755 {} ';'
%{_fixperms} %{buildroot}/*


%check
make test


%files
# next line deprecated since rpm 4.4, I'm told.
# -was-percent-defattr(-,root,root,-)
# -was-percent-doc COPYING Fsdb.spec META.json MYMETA.json MYMETA.yml programize_module README README.html update_modules
%doc README COPYING
%{_bindir}/*
%{perl_vendorlib}/Fsdb.pm
%{perl_vendorlib}/Fsdb/
%{_mandir}/man1/*.1*
%{_mandir}/man3/*.3pm*


%changelog
* Thu Dec 20 2018 John Heidemann <johnh@isi.edu> 2.66-1
- See http://www.isi.edu/~johnh/SOFTWARE/FSDB/
