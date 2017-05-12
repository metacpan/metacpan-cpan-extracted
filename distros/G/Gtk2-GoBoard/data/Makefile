
SOUNDS = alarm.au move.au warning.au pass.au ring.au connect.au gamestart.au resign.au outoftime.au info.au

%.au: %.wav Makefile
	sox -twav $< -tau -r8000 -c1 -U -b $@ resample || sox -twav $< -tau -r8000 -c1 -U -b $@

all: $(SOUNDS)
