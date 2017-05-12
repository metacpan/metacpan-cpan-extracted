# NAME

HTML::FormatNroff - Format HTML as nroff man page

# SYNOPSIS

```perl
use HTML::FormatNroff;
my $html = parse_htmlfile("test.html");
my $formatter = HTML::FormatNroff->new(name => 'trial', project => 'MyProject');
print $formatter->format($html);
```

# DESCRIPTION

The HTML::FormatNroff is a formatter that outputs nroff source
for the nroff text processor, using man macros, and tbl commands for table
processing.

The result of using the formatter must be processed as follows, when directing
output to the screen (assume output is in the file "text.nroff"):

```
tbl -TX text.nroff | nroff -man | col
```

If the output is to be printed, on an laser printer for example, a command
similar to the following must be used:

```
tbl -TX text.nroff | nroff -man -Tlj | lpr
```

Meta tags may be placed in the HTML so that portions of the HTML
will be ignored and not processed. Content between the tags

```
<META NAME="nroff-control" CONTENT="ignore_start">
<META NAME="nroff-control" CONTENT="ignore_end">
```

will be ignored. In the BODY META is not supported, but DIV may be used
as follows:

```
<DIV TYPE="NROFF_IGNORE">
</DIV>
```

In both the META and DIV uses, case is ignored.

# METHODS

## dt\_start();

Start a definition term `<DT>`,
using a temporary indent and vertical space.

## dd\_start();

Start a data definition, `<DD>`, using a temporary indent.

## configure($arg);

Configure the nroff formatter, setting the attributes passed in the
$arg attribute (hash reference)

## begin();

Begin HTML formatting.

## end();

End HTML formatting.

## html\_start();

Process `<HTML>` start tag. Create the man page header based
on saved attributes, unless the attribute
$format\_nroff->{'man\_header'} is not set. This generates the following header:

```
.TH "name" section "date" "project"
```

## font\_start($font);

Start the font specified by the $font character (e.g. B, or I).
The font is remembered so nested fonts are handled correctly.

## font\_end();

End the current font, returning to the previous one.

## i\_start();

Process `<I>` tag.

## i\_end();

Process `</I>` tag.

## b\_start();

Process `<B>` tag.

## b\_end();

Process `</B>` tag.

## table\_start($node);

Process `<TABLE>`, start table processing. $node
is the current html\_parser node.

```
Pass on the $format_nroff->{'page_width'} to FormatTableNroff
```

## tr\_start($node);

Process `<TR>`, add table row.

## tr\_end();

End the table row `</TR>`

## a\_start();

`<A>` is ignored.

## a\_end();

`</A>` is ignored.

## td\_start($node);

Process `<TD>`, add table cell

## td\_end();

Process `</TD>`, end table cell

## th\_start($node);

Process `<TH>`, add table header cell

## th\_end();

Process `</TH>`, end table header cell

## table\_end();

Process `</TABLE>`. Actually output entire table.

## p\_start();

Process `<P>`.

## p\_end();

Process `</P>` by doing nothing.

## goto\_lm()

goto\_lm does nothing.

## br\_start();

Process `<BR>`.

## hr\_start();

Process `<HR>`

## header\_start();

Process `<H?>` simply using .SH

## header\_end();

Process `</H?>` simply outputing newline

## out($text);

Output text.

## pre\_out($pre);

Output `<PRE>` text.

## nl($cnt);

Output newline.

## adjust\_lm($indent);

adjust indent (left margin)

## adjust\_rm();

not used.

## bullet($tag);

output the bullet, using a temporary indent and the $tag

## textflow($node);

Output text or add it to table if currently inside a table
If centered add .ce unless inside a table, if underlined add .ul,
if the left margin is adjusted use a .ti for every new line.

## blockquote\_start($node);

Start `<BLOCKQUOTE>`, by making a new paragraph, and indenting.

## blockquote\_end($node);

`</BLOCKQUOTE>`, by ending indent, and making a new paragraph

## div\_start($node);

Process DIV

```perl
<DIV TYPE="NROFF_IGNORE">
    is used to ignore all subsequent content until the next
</DIV>
```

This allows HTML to be used which is not to be converted to HTML
(such as navigation controls). Case is ignored in the type.

In the header you probably should use

```perl
<META NAME="nroff-control" CONTENT="ignore_start">
    is used to ignore all subsequent content until the next
<META NAME="nroff-control" CONTENT="ignore_end">
```

## meta\_start($node);

Process `<META>` tag.

```perl
<META NAME="nroff-control" CONTENT="ignore_start">
    is used to ignore all subsequent content until the next
<META NAME="nroff-control" CONTENT="ignore_end">
```

This allows HTML to be used which is not to be converted to HTML
(such as navigation controls). Case is ignored.

Strictly speaking META is only allowed in the HTML HEAD, so this
META. In the body, you should use:

```
<DIV TYPE="NROFF_IGNORE">
</DIV>
```

# SEE ALSO

[HTML::Formatter](https://metacpan.org/pod/HTML::Formatter)

# COPYRIGHT

Copyright (c) 1997 Frederick Hirsch. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

# AUTHORS

Frederick Hirsch <f.hirsch@opengroup.org>

Stefan G. <minimal@cpan.org>
