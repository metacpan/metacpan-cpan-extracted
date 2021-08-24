* ppi_version change $old_version $new_version
* git grep $old_version, update anything remaining
* git commit -a
* git push
* make manifest
* Check MAINFEST for accuracy
* perl Makefile.PL
* make
* make test
* make dist
* cpan-upload Google-RestApi-${new_version}.tar.gz --user $user
* make clean
* rm Google-RestApi-${new_version}.tar.gz
