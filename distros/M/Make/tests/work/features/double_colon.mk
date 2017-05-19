
.PHONY: all
all: result

result:: one
	@echo $^ >>$@
	@echo $^

result:: two
	@echo $^ >>$@
	@echo $^

