#!/usr/bin/env perl

use strict;
use warnings;

use Test::DZil qw(Builder simple_ini);
use Test::More 0.88;
use Test::Differences;

{
    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    'RPM'
                ),
            },
        },
    );

    my $spec = $tzil->plugin_named('RPM')->mk_spec(
        sprintf('%s-%s.tar.gz',$tzil->name,$tzil->version)
    );

    eq_or_diff $spec, <<'EOT', "verify spec file";
Name: DZT-Sample
Version: 0.001
Release: 1
 
Summary: Sample DZ Dist
License: GPL+ or Artistic
Group: Applications/CPAN
BuildArch: noarch
URL: http://dev.perl.org/licenses/
Vendor: E. Xavier Ample
Source: DZT-Sample-0.001.tar.gz
 
BuildRoot: %{_tmppath}/%{name}-%{version}-BUILD
 
%description
Sample DZ Dist
 
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
EOT
}

done_testing;

__END__

