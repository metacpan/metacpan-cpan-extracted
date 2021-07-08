* ppi_version change $old_version $new_version
* git grep $old_version, update anything remaining
* git commit -a
* git push
* perl Makefile.PL
* make manifest
* Check MAINFEST for accuracy
* make
* make test
* make dist
* cpan-upload Google-RestApi-${new_version}.tar.gz --user $user
* make clean
