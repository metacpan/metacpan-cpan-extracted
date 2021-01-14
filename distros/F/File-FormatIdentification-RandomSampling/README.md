
crazy-fast-media-image-scan

A crazy fast scanner for media image files, useful to pre-sort media from digital estates.

The project is a little research project to evaluate if a random sample based
media type scanner with details on file level is possible.

The ideas are following:

- random sampling to improve scanning (we need very fast, not very accurate results)
- category check (what kind of data could be there in general?)
- filetype identification using bigram based estimation, learned by decision
  tree over files (using format-corpus https://github.com/openpreserve/format-corpus and Mime::Types)

TODO ideas

- plot typebased output (color?) to see distribution over media
- improved autotune to scan only "few seconds"
- scan EWF images, too

This will be the base for an upcoming standalone application.


