#install we generate those files which can be managed by RPM
#N.B. we create the LinkController user (linkcont) so that files
#and directories can have the correct ownership.
mkdir -p $RPM_BUILD_ROOT/etc/cron.{daily,weekly} $RPM_BUILD_ROOT/var/log 
#we should be in the %{packagename}-%{packageversion} directory already
perl ./default-install/default-install.pl --verbose --base-dir $RPM_BUILD_ROOT --all

#install the emacs link-report-dired.el

mkdir -p $RPM_BUILD_ROOT/usr/share/emacs/site-lisp
#we should be in the %{packagename}-%{packageversion} directory already
cp ./emacs/link-report-dired.el $RPM_BUILD_ROOT/usr/share/emacs/site-lisp
#FIXME. We should byte compile in build and install a .elc

