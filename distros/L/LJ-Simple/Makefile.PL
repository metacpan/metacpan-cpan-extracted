use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

sub MY::postamble {
  return <<EOF;
##
## This will probably break for you; its designed for me to be
## able to update the website which distributes LJ::Simple
##
publish: dist
	set -e ; \\
	umask 022 ; \\
	htdocs="/home/triad/www/source-sites/live-www.bpfh.net" ; \\
	dest="\$\$htdocs/computing/software/LJ::Simple" ; \\
	tar="\$(DISTNAME)-\$(VERSION).tar.gz" ; \\
	if [ ! -d \$\$dest ] ; then \\
	  mkdir -p \$\$dest ; \\
	fi ; \\
	cp \$\$tar \$\$dest ; \\
	pod2html \$(VERSION_FROM) > \$\$dest/\$(VERSION_FROM).htm ; \\
	rm -rf pod2htm* ; \\
	cp Changes \$\$dest/Changes.txt ; \\
	cat index.html | \\
		sed 's/\@VERSION\@/\$(VERSION)/g' | \\
		sed "s/\@TAR\@/\$\$tar/g" | \\
		sed 's/\@MANPAGE\@/\$(VERSION_FROM).htm/g' | \\
		cat > \$\$dest/index.html ; \\
	chmod 644 \$\$dest/* ; \

rebuild-pkg:
	\@if [ -z "\$(BUILD_PKG_RECURSE)" ] ; then \\
	  echo "Rebuilding Makefile" ; \\
	  perl Makefile.PL ; \\
	  \$(MAKE) pkg BUILD_PKG_RECURSE=yes ; \\
	fi

version:
	cat InstallPackage/pkginfo | \\
		sed 's/^VERSION=.*/VERSION=\$(VERSION)/' \\
		> tmp.pkginfo
	mv tmp.pkginfo InstallPackage/pkginfo
	sed 's/^\\(LJ::Simple version \\).*/\\1\$(VERSION)/' README > README.new
	if [ -s README.new ]; then \\
	  mv README.new README ; \\
	else \\
	  echo "Need to update README version"; \\
	  rm README.new ; \\
	  exit 1 ; \\
	fi
##
## Unless you've got the pkg-tools package this will break for you
## as well
##
pkg: rebuild-pkg version manifypods pure_all
	umask 022 ; \\
	mkdir -p InstallPackage/build/usr/local/bin ; \\
	mkdir -p InstallPackage/build/usr/local/man/man1 ; \\
	cp examples/ljpost InstallPackage/build/usr/local/bin ; \\
	chmod 755 InstallPackage/build/usr/local/bin/ljpost ; \\
	pod2man examples/ljpost > InstallPackage/build/usr/local/man/man1/ljpost.1 ; \\
	chmod 644 InstallPackage/build/usr/local/man/man1/ljpost.1
	build-pkg -n %PKG%-v%VERSION%.pkg -K
	mv InstallPackage/*.pkg .

##
## Used for tagging the CVS tree with the current version
##
tag:
	\@currtag=`cvs status -v Makefile.PL | grep '(revision: ' | head -1 | awk '{print \$\$1}'` ; \\
	symtag="v\$(VERSION_SYM)" ; \\
	if [ "\$\${currtag}" = "\$\${symtag}" ]; then \\
	  echo "Tag already at \$\${symtag}"; \\
	  exit 0; \\
	fi ; \\
	/usr/bin/echo "\\nWill tag to \$\${symtag}; are you sure? [Y/N] \\c" ; \\
	read yesno ; \\
	if [ "\$\${yesno}" != "Y" ]; then echo "Aborting" ; exit 255 ; fi ; \\
	cvs update ; \\
	cvs tag \$\${symtag}

EOF
}

WriteMakefile(
    'NAME'		=> 'LJ::Simple',
    'VERSION_FROM'	=> 'Simple.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Simple.pm', # retrieve abstract from module
       AUTHOR     => 'Simon Burr <simes@bpfh.net>') : ()),
);
