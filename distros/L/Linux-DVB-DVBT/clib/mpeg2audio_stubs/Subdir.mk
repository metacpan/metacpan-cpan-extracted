mpeg2audio_stubs ?= .

CFLAGS += -I$(mpeg2audio_stubs)

OBJS-mpeg2audio := \
	$(mpeg2audio_stubs)/mpegaudio_stubs.o
