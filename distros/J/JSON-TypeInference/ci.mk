CARTON_EXEC = carton exec --
COVER_IGNORE_RE = ^t/|^local/

test:
	$(CARTON_EXEC) prove t/

cover:
	$(CARTON_EXEC) cover -test -ignore_re '$(COVER_IGNORE_RE)' -make 'make -f ci.mk test'

coveralls: cover
	$(CARTON_EXEC) cover -report coveralls
