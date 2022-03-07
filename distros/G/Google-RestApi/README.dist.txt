* check perlbrew is active on terminal
* ppi_version change $old_version $new_version
* git grep $old_version, update anything remaining
* perl Makefile.PL
* make clean
* make manifest
* make distcheck to check manifest
* git commit -a
* git push
* git tag $new_version
* git push origin $new_version
* make
* make test
* make dist
* perlbrew off
* perlbrew uninstall $perl_version
* perlbrew install $perl_version
* perlbrew swtich $perl_version
* cpanm Google-RestApi-$new_version.tar.gz
* make test again to check that everything installed correctly
* cpan-upload Google-RestApi-${new_version}.tar.gz --user $user
* make clean
* rm Google-RestApi-${new_version}.tar.gz
