LD_LIBRARY_PATH=$(FXCONNECT_HOME)/lib
LIBS=-L$(FXCONNECT_HOME)/lib
INCS=-I$(FXCONNECT_HOME)/include
SOURCES=test.cpp ../ForexConnectWrapper.cpp ../Listener.cpp ../Session.cpp ../ILog.cpp ../TableListener.cpp
HEADERS=../ForexConnectWrapper.h ../Listener.h ../Session.h ../ILog.h ../TableListener.h

test: $(SOURCES) $(HEADERS)
	gcc $(INCS) $(LIBS) -Wall -O2 -lm -lForexConnect -lfxmsg -lstdc++ -o test $(SOURCES)

clean:
	rm -f test
