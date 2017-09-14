# Message Extractor Example in Perl

All other examples in this directory make use of the Inline module.
In fact, you could do the same for Perl with "Inline::Perl".  But
we will follow the traditional approach.

This directory contains a wrapper script "xgettext-lines.pl" and
a Perl module "PerlXGettext.pm" that is a fully-functional example.
Please see the source code and `perldoc Locale::XGettext` for
exhaustive documentation.  For an overall image, read the
[description for the Python example](../README.md).

The Perl example does not use a separate module for the sub
class of `Locale::XGettext` because it is assumed that every
Perl programmer knows how to turn it into a proper library.