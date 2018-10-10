FETCH = wget -O
TEST_FILES = spec_tests.json tests.json

all: $(TEST_FILES)

clean:
	rm -f $(TEST_FILES)

spec_tests.json:
	$(FETCH) $@ https://raw.githubusercontent.com/json-patch/json-patch-tests/master/spec_tests.json

tests.json:
	$(FETCH) $@ https://raw.githubusercontent.com/json-patch/json-patch-tests/master/tests.json
