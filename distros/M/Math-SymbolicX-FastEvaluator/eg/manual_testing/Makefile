CXXFLAGS += -O2 -I../.. -I.
#CXXFLAGS += -ggdb
#LDFLAGS += -ggdb

EXE=fun
OBJS=$(patsubst %.cc, %.o, $(wildcard ../../*.cc) $(wildcard *.cc))

all: $(EXE)

%.o: %.cc
	$(CXX) -c $(CXXFLAGS) $^ -o $@

fun: $(OBJS)
	$(CXX) $(CXXFLAGS) -o fun $(LDFLAGS) $(OBJS)


clean:
	@rm -f *~ $(EXE) *.o
