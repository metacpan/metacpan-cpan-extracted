NAME ?= libeav
VERSION ?= 0.1.0
RELEASE ?= $(NAME) $(VERSION)
SECTION ?= 3
CENTER ?= Library Functions Manual

SOURCES = $(wildcard *.pod)
TARGETS = $(patsubst %.pod, %, $(SOURCES))
GZFILES = $(patsubst %, %.gz, $(TARGETS))


all: $(GZFILES)

$(GZFILES): $(TARGETS)
	# compressing man-pages
	gzip -f $<

%: %.pod
	# converting man-pages
	pod2man -n '$(NAME)' -s $(SECTION) -r '$(RELEASE)' -c '$(CENTER)' $< $@

clean:
	# clean man-pages
	$(RM) $(TARGETS) $(GZFILES)

.PHONY: all clean
