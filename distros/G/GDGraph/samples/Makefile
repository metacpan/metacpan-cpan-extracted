# This Makefile requires GNU make. If you have anything else, it is very
# likely that you won't be able to use this. Two pieces of advice:
# 
# Get GNU make. It's free, and superior to many others
#
# Run the examples by hand, one by one, or do something like
#
# tcsh> foreach s (*.pl)
# foreach> perl -I. -Mblib -Tw $s
# foreach> end
#
# If you use an old version of GD that exports GIF, you will need to
# have ImageMagick installed, or you need to provide another way to
# convert logo.png to logo.gif.

.SILENT:

PERL = perl
EXTRA_OPTS = 
OPTIONS = -I. -Mblib $(EXTRA_OPTS) -w

EXT := $(shell perl $(OPTIONS) -MGD::Graph \
		-e 'print scalar GD::Graph::export_format')

# Samples
# sample1? : bars
# sample2? : area
# sample3? : points
# sample4? : linespoints
# sample5? : lines
# sample6? : mixed
# sample7? : tricks and test cases
# sample9? : pie

SAMPLES :=  \
    sample11 sample12 sample13 sample14 sample15 \
    sample16 sample17 sample18 sample19 sample1A sample1B \
    sample11-h sample12-h sample13-h sample14-h sample15-h \
    sample16-h sample17-h sample18-h sample19-h sample1A-h sample1B-h\
    sample21 sample22 sample23 \
    sample31 \
    sample41 sample42\
    sample51 sample52 sample53 sample54 sample55 sample56 \
    sample57 sample58 \
    sample61 sample62 sample63 sample64  \
    sample71 sample72 \
    sample91 sample92 sample93 sample94 sample95 sample95-h

IMAGES := $(SAMPLES:%=%.$(EXT))

all: $(IMAGES)
	echo ""
	echo These samples are both examples and test cases. Therefore
	echo some of them might look slightly unrealistic.

info: 
	$(PERL) $(OPTIONS) -le 'print "Perl ", $$]'
	$(PERL) $(OPTIONS) -MGD -le 'print "GD ", $$GD::VERSION'
	$(PERL) $(OPTIONS) -MGD::Text \
	    -le 'print "GD::Text ", $$GD::Text::VERSION'
	$(PERL) $(OPTIONS) -MGD::Graph \
	    -le 'print "GD::Graph ", $$GD::Graph::VERSION'
	$(PERL) $(OPTIONS) -le 'for (@INC) {print}'

%.$(EXT) %-h.$(EXT): %.pl
	$(PERL) $(OPTIONS) $<

# EXPERIMENTAL, for internal use only. Don't try to run this
html: make_index.pl Makefile
	$(PERL) $(OPTIONS) make_index.pl $(EXT)

# Requires ImageMagick to be installed
logo.gif: logo.png
	convert logo.png logo.gif

clean:
	rm -f $(IMAGES) logo.gif

# Other dependencies

sample14.$(EXT): logo.$(EXT)
sample42.$(EXT): sample42.dat
sample54.$(EXT): sample54.dat
sample56.$(EXT): sample54.dat
sample53.$(EXT): rgb.txt

