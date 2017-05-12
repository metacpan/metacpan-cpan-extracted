#
#Makefile for LabJack
#
#

KDIR := /lib/modules/$(shell uname -r)/build 

obj-m := labjack.o

default:
	$(MAKE) -C $(KDIR) SUBDIRS=$(PWD) modules

clean:
	rm -f *.mod.c *.o *.ko
