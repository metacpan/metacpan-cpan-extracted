package HTML::TagReader;

use strict;
use vars qw($VERSION @ISA);

require DynaLoader;

@ISA = qw(DynaLoader);
$VERSION = '1.11';

bootstrap HTML::TagReader $VERSION;

1;
__END__
# Below is the documentation for your module. 

=head1 NAME

TagReader - Perl extension module for reading html/sgml/xml files
by tags.

=head1 SYNOPSIS

 use HTML::TagReader;
 # open then file and get an obj-ref:
 my $p=new HTML::TagReader "filename";

 # set to zero or undef to omit warnings about html error:
 $showerr=1; 

 # get only the tags:
 my $tag = $p->gettag($showerr);
   # or
 my ($tag,$linenumber,$column)=$p->gettag($showerr);

 # get the entire file split into tags and text parts:
 my $tagOrText = $p->getbytoken($showerr);
   # or
 my ($tagOrText,$tagtype,$linenumber,$column)=$p->getbytoken($showerr);

 # get the version of HTML::TagReader:
 my $ver=$HTML::TagReader::VERSION;

=head1 DESCRIPTION

The module implements a fast and small object oriented way of
processing any kind of html/sgml/xml files by tag.

The getbytoken(0) is similar to while(<>) but instead of reading lines 
it reads tags or tags and text. 

HTML::TagReader makes it easy to keep track of the line number in a file
even though you are not reading the file by line. This important if you
want to implement error messages about html errors in your code.

Here is a program that list all href tags
in a html file together with line numbers and column:

    use HTML::TagReader;
    my $p=new HTML::TagReader "file.html";
    my @tag;
    while(@tag = $p->gettag(1)){
            if ($tag[0]=~/ href ?=/i){
                    # remove optional space before the equal sign:
                    $tag[0]=~s/ ?= ?/=/g;
                    print "line: $tag[1]: col: $tag[2]: $tag[0]\n";
            }
    }

Here is a program that will read a html file tag
wise:

    use HTML::TagReader;
    my $p=new HTML::TagReader "file.html";
    my @tag;
    while(@tag = $p->getbytoken(1)){
            if ($tag[1] eq ""){
                    print "line: $tag[2]: col: $tag[2]: not a tag (some text), \"$tag[0]\"\n\n";
            }else{
                    print "line: $tag[2]: col: $tag[2]: is a tag, $tag[0]\n\n";
            }
    }

=head2 new HTML::TagReader $file;

Returns a reference to a TagReader object. This reference can
be used with gettag() or getbytoken() to read the next tag.
You might want to test beforehand if the file is readable and
produce your own error message if the file can not be read.
The default HTML::TagReader behavior is to die with "ERROR: Can not 
read file...".

=head2 gettag($showerr);

Returns in an array context tag, line number and character position in the
line (column). In a scalar context just the next tag is returned.
 
An empty string or and empty array is returned if the file contains
no further tags. HTML/XML comments and any tags inside the comments
are ignored.

The returned tag string has all white space (tab, newline...) reduced to just a
single space otherwise upper and lower case, quotes etc are as in the
original file. The line numbers are those where the tags
start.

You must provide 0 (or undef) or 1 as an argument to gettag. 
If 0 is provided then gettag will not print warnings if it finds
a syntax error in the html/sgml/xml code.

Currently only the following warning messages are implemented to
warn about possible html syntax errors:

- A starting '<' was found but no closing '>' after 300 characters

- A single '<' was found which was not followed by [!/a-zA-Z]. Such
a '<' should be written as &lt;

- A single '>' was found outside a tag.

=head2 getbytoken($showerr);

Returns in an array context tag, tagtype (a, br, img,...), line number
and the character position (column) in the line where the tag starts. 
In a scalar context just the next tag is returned.

An empty string or and empty array is returned if the file contains
no further tags. 

getbytoken() should be used to process a HTML file and possibly
modify tags. As opposed to gettag() the getbytoken() does not
remove newline or space from the data. getbytoken() gives you 
access to the entire file and not only to the tags. 
That is: you can process the tags and the text between the tags. 

$tagtype is always lower case. The $tagtype is the string starting
the tag such as "a" in <a href=""> or "!--" in <!-- comment -->.
$tagtype is empty if this is not a tag (normal text or newline).

You must provide 0 (or undef) or 1 as an argument to getbytoken. 
If 0 is provided then getbytoken will not print any warnings if it finds
a syntax error in the html/sgml/xml code.

Currently only the following warning messages are implemented to
warn about possible html syntax errors:

- A starting '<' was found but no closing '>' after 300 characters

- A single '<' was found which was not followed by [!/a-zA-Z]. Such
a '<' should be written as &lt;

- A single '>' was found outside a tag.

=head2 Working without HTML::TagReader

In special cases it is possible to do processing of files by tag in an
efficient way without the HTML::TagReader package. This can be done by
setting the record separator variable in perl ($/). This causes however
problems with faulty HTML code where individual '<'-characters appear in
the middle of the text. An example of such a program written in plain perl
(without HTML::TagReader) is the tr_tagcontentgrep program which is part
of the HTML::TagReader distribution. Think first then write your code!
(HTML::TagReader is in most cases the best choice, not in all ;-)

=head2 Limitations

There are no limitation to the size of the file.

If you need a more sophisticated interface you might want to take a look at
HTML::Parser. HTML:TagReader is fast, generic and straight forward to use.

=head1 COPYRIGHT

Copyright (c) Guido Socher [guido(at)linuxfocus.org]

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

homepage of this program: http://linuxfocus.org/~guido/ 
or http://cpan.org/authors/id/G/GU/GUS/

perl(1) HTML::Parser(3) HTML::TokeParser(3)

=cut

