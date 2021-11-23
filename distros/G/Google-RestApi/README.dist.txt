* check perlbrew is active on terminal
* ppi_version change $old_version $new_version
* git grep $old_version, update anything remaining
* make manifest
* make distcheck to check manifest
* git commit -a
* git push
* git tag $new_version
* git push origin $new_version
* perl Makefile.PL
* make
* make test
* make dist
* cpan-upload Google-RestApi-${new_version}.tar.gz --user $user
* make clean
* rm Google-RestApi-${new_version}.tar.gz
