get-schema:
	wget -O spec/swagger.json https://raw.githubusercontent.com/kubernetes/kubernetes/master/api/openapi-spec/swagger.json

gen-classes:
	rm -rf auto-lib
	carton exec build-bin/build-kubernetes-api

reset-autolib:
	rm -rf auto-lib
	git checkout auto-lib

test:
	carton exec -- prove -v -I lib -I auto-lib t/

dist:
	cpanm -n -l dzil-local Dist::Zilla
	PATH=$(PATH):dzil-local/bin PERL5LIB=dzil-local/lib/perl5 dzil authordeps --missing | cpanm -n -l dzil-local/
	PATH=$(PATH):dzil-local/bin PERL5LIB=dzil-local/lib/perl5 dzil build

