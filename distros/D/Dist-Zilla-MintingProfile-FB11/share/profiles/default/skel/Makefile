.PHONY: clean dist docker
{{ $dockername = lc $dist->name; '' }}
version = $(shell dzil distversion)
rcversion = $(shell dzil distversion --rc)
lastrcversion = $(shell dzil distversion --rc | perl -lpe 's/(\d)+$$/$$1-1/e')
LIBFILES   = $(shell git ls-files lib)
BINFILES   = $(shell git ls-files bin script)
TFILES	   = $(shell git ls-files t)
OTHERFILES = cpanfile {{ lc $dist->name =~ s/-/_/gr }}.yml

clean:
	dzil clean
{{ $dist->name }}-%.tar.gz: $(LIBFILES) $(BINFILES) $(TFILES) $(OTHERFILES)
	dzil build
dist: {{ $dist->name }}-$(version).tar.gz
docker: dist
	docker build \
		--build-arg version=`dzil distversion` \
		--build-arg gitrev="`set -x ; git rev-parse HEAD ; git status ; git diff`" \
		-t quay.io/opusvl/{{ $dockername }}:latest .
rc: docker
	docker tag quay.io/opusvl/{{ $dockername }}:latest quay.io/opusvl/{{ $dockername }}:v$(rcversion)
	docker push quay.io/opusvl/{{ $dockername }}:v$(rcversion)
	git tag v$(rcversion)
	git push origin v$(rcversion)
release:
	- @echo "If this fails, make sure you pushed the last image you built"
	docker pull quay.io/opusvl/{{ $dockername }}:v$(lastrcversion)
	- [ `docker run --rm -u root quay.io/opusvl/{{ $dockername }}:v$(lastrcversion) head -n1 /opt/fb11/{{ $dist->name }}-gitrev` = `git rev-parse HEAD` ] \
			|| echo "Ensure your git repository is on the commit from which the latest image was built (or rebuild and retest)."
	dzil release
	- docker tag quay.io/opusvl/{{ $dockername }}:latest quay.io/opusvl/{{ $dockername }}:v$(version)
	- docker push quay.io/opusvl/{{ $dockername }}:v$(version)
{{# I don't know whether to try configuring the quay URLs, or to let anyone who uses this just fix their own Makefile
}}
