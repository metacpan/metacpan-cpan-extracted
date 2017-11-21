# EXAMPLES

Neaf examples are small snippets showing Neaf usagei
from author's perspective for the most common use cases.

# Running the examples

Use psgi server of choice to run examples:

    plackup examples/run-all.pl

This will create an index page at http://localhost:5000/ so you don't
have to remember URLs.

# How examples are organized

The examples are in form of `nn-foo.pl`, where *nn* is a 2-digit number
and *foo* is a brief symbolic name.

All paths inside each example shall start with `/nn`.

If a special-case view is needed, it should be named like `TTnn` or smth.
Bear in mind other examples running in the same namespace.

