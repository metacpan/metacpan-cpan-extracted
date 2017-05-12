#Module-Specific definitions
%define apache_version 2.2.6
%define mod_name mod_twepl
%define mod_conf TW_%{mod_name}.conf
%define mod_so %{mod_name}.so

Summary:	Add custom header and/or footers for apache
Name:		apache-%{mod_name}
Version:	0.91
Release:	%mkrel 1
Group:		System/Servers
License:	TWINKLE
URL:		http://www.twinkle.tk/
Source:		http://www.twinkle.tk/pub/release/%{mod_name}/%{mod_name}-%{version}.tar.gz
Requires(pre): rpm-helper
Requires(postun): rpm-helper
Requires(pre): apache >= %{apache_version}
Requires:	apache >= %{apache_version}
BuildRequires:  apache-devel >= %{apache_version}
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-buildroot

%description
:-| Powered By HTML::EmbeddedPerl


%prep

%setup -q -n %{mod_name}

%build

perlpath=`perl -MConfig -e 'print $Config::Config{archlib}."\n"'`
%{_sbindir}/apxs -c -I $perlpath/CORE -L $perlpath/CORE -l perl %mod_name.c

%install
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

install -d %{buildroot}%{_libdir}/apache-extramodules
install -d %{buildroot}%{_sysconfdir}/httpd/modules.d

install -m0755 .libs/*.so %{buildroot}%{_libdir}/apache-extramodules/
install -m0644 %{mod_conf} %{buildroot}%{_sysconfdir}/httpd/modules.d/%{mod_conf}

%post
if [ -f %{_var}/lock/subsys/httpd ]; then
    %{_initrddir}/httpd restart 1>&2;
fi

%postun
if [ "$1" = "0" ]; then
    if [ -f %{_var}/lock/subsys/httpd ]; then
        %{_initrddir}/httpd restart 1>&2
    fi
fi

%clean
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

%files
%defattr(-,root,root)
%doc LICENSE
%attr(0644,root,root) %config(noreplace) %{_sysconfdir}/httpd/modules.d/%{mod_conf}
%attr(0755,root,root) %{_libdir}/apache-extramodules/%{mod_so}


%changelog
* Fri May 24 2013 Twinkle Computing <apache at twinkle.tk> 0.91
- Beta build
