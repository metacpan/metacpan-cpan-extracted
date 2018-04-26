.PHONY: clean dist docker

version = $(shell dzil distversion)
LIBFILES   = $(shell git ls-files lib)
BINFILES   = $(shell git ls-files bin script)
TFILES     = $(shell git ls-files t)
OTHERFILES = cpanfile {{ lc $dist->name =~ s/-/_/gr }}.conf

clean:
	dzil clean
{{ $dist->name }}-%.tar.gz: $(LIBFILES) $(BINFILES) $(TFILES) $(OTHERFILES)
	dzil build
dist: {{ $dist->name }}-$(version).tar.gz
docker: dist
	docker build \
		--build-arg version=`dzil distversion` \
		--build-arg gitrev="`set -x ; git rev-parse HEAD ; git status ; git diff`" \
		-t quay.io/opusvl/{{ lc $dist->name }}:latest .
