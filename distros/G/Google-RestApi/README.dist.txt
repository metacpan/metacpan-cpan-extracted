* cpanm PPI::App::ppi_version
* ppi_version change $old_version $new_version
* git grep $old_version, update anything remaining
* update Changes file with a summary of what's been done for this release
* perl -MPod::Markdown -e 'Pod::Markdown->new->filter(@ARGV)' lib/Google/RestApi.pm > README.md
* perl Makefile.PL
* make manifest
* make distcheck to check manifest
* git commit -a
* git push
* git tag $new_version
* git push origin $new_version
* ensure git workflow passes on configured perl releases
* make
* make test
* make dist
* cpanm Google-RestApi-$new_version.tar.gz
* cpan-upload Google-RestApi-${new_version}.tar.gz --user $user
* make clean
* rm Google-RestApi-${new_version}.tar.gz
