# Test data

## CommonMark JSON test suites

The `cmark.tests.json` and `github.tests.json` files are licenced under
[![CC BY-SA licence](cc-by-sa.png)](http://creativecommons.org/licenses/by-sa/4.0/).

Their source can be found respectively at the
[CommonMark Spec website](https://spec.commonmark.org/) and the
[GitHub Flavored Markdown Spec website](https://github.github.com/gfm/).

The JSON files are generated with:

    third_party/commonmark-spec/test/spec_tests.py --dump-tests --spec third_party/commonmark-spec/spec.txt > t/data/cmark.tests.json
    third_party/cmark-gfm/test/spec_tests.py --dump-tests --spec third_party/cmark-gfm/test/spec.txt > t/data/github.tests.json

But first, the examples that are annotated with `example disabled` in the
cmark-gfm spec.txt file are renamed just `example` (otherwise they are skipped
from the output). Note that the cmark-gfm file needs to be processed with the
`spec_text.py` tool from the same repository, otherwise some tests are empty.
