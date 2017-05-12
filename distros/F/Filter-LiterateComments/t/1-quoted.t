use Filter::LiterateComments;

This is a test file for the "Filter::LiterateComments" module,
using the "Test" framework:

> use Test;
> plan tests => 2;

First we make sure that the module is actually loaded:

> ok(Filter::LiterateComments->VERSION);

Then we ensure that the line number is correct:

> ok(__LINE__, 15);

That's it, folks!
