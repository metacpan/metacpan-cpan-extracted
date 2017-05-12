# Devel::SizeMe

[![Build Status](https://secure.travis-ci.org/timbunce/devel-sizeme.png)](http://travis-ci.org/timbunce/devel-sizeme)

Devel::SizeMe is a variant of Devel::Size that can stream out detailed
information about the size of individual data-structures and the links
between them.

It can do this for the entire perl interpreter internals as well as your own
perl data structures.

It comes with scripts for storing this data in a database and visualizing it in
various forms, including graphs and an interactive treemap.

Current implementation is alpha and somewhat hackish in places.

For more info see http://blog.timbunce.org/2012/10/05/introducing-develsizeme-visualizing-perl-memory-use/
and http://blog.timbunce.org/tag/sizeme/

There's an #sizeme IRC channel on irc.perl.org and the devel-size@googlegroups.com
mailing list (also at https://groups.google.com/d/forum/devel-size)
