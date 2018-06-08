PREFIX ?= /opt/devkitpro/devkitARM/bin/arm-none-eabi-
CC = $(PREFIX)gcc
OBJCOPY = $(PREFIX)objcopy
CFLAGS = -mthumb-interwork -mthumb -Os -Wall -fno-strict-aliasing
LDFLAGS = -mthumb-interwork -mthumb -specs=gba_mb.specs
RM ?= rm

test.gba: test.elf
	$(OBJCOPY) -v -O binary $< $@
	$(RM) test.elf
	-@gbafix $@

%.elf: %.o
	$(CC) $(LDFLAGS) -o$@ $<

.PHONY: test clean
test: test.gba
	/Applications/visualboyadvance-m.app/Contents/MacOS/visualboyadvance-m $<
clean:
	$(RM) *.o *.gba *.elf
