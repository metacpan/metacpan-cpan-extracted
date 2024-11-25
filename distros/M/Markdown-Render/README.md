# Table of Contents

* [README](#readme)
* [Installation](#installation)
  * [Prerequisites](#prerequisites)
  * [Building and Deploying](#building-and-deploying)
  * [Building an rpm](#building-an-rpm)
  * [Building from CPAN](#building-from-cpan)
* [Usage](#usage)
* [Tips & Tricks](#tips--tricks)
  * [&#64;DATE(format)&#64;](#dateformat)
  * [&#64;GIT_EMAIL&#64;](#git_email)
  * [&#64;GIT_USER&#64;](#git_user)
  * [&#64;TOC&#64;](#toc)
  * [&#64;TOC_BACK(optional text)&#64;](#toc_backoptional-text)
  * [Custom TOC Title](#custom-toc-title)
  * [Prevent heading from being included in table of contents](#prevent-heading-from-being-included-in-table-of-contents)
* [Rendering](#rendering)
* [Credits](#credits)

__Updated 2024-11-24__ by Rob Lauer <rlauer6@comcast.net>

# README

A quick search regarding how to get a table of contents into my
markdown yielded only a few hits or projects that seemed a little weighty
to me, so here's a little Perl script with just a few
dependencies that you might find useful.  See [Usage](#usage) for more
information.

The script will render your markdown as HTML using either the [GitHub
API](https://docs.github.com/en/rest/markdown) or the Perl module [Text::Markdown::Discount](https://metacpan.org/pod/Text::Markdown::Discount)

A default stylesheet will be applied but you can provide your own
style sheet as well.

# Installation

## Prerequisites

The script has been tested with these versions, but others might work
too.

| Module                   | Version |
|--------------------------|---------|
| `Class::Accessor::Fast`  | 0.51  |
| `Date::Format`           | 2.24  |
| `HTTP::Request`          | 6.00  |
| `IO::Scalar`             | 2.113 |
| `JSON`                   | 4.03  |
| `LWP::UserAgent`         | 6.36  |
| `Readonly`               | 2.05  |

## Building and Deploying

```
git clone https://github.com/rlauer6/markdown-utils.git
make
sudo ln -s $(pwd)/markdown-utils/md-utlils.pl /usr/bin/md-utils
```

## Building an rpm

If you want to build an rpm for a RedHat Linux based system, install
the `rpm-build` tools.

```
make rpm
sudo yum install 'perl(Markdown::Render)'
```

[Back to Top](#table-of-contents)


## Building from CPAN

```
cpanm -v Markdown::Render
```

# Usage

```
usage: md-utils options [markdown-file]

Utility to add a table of contents and other goodies to your GitHub
flavored markdown.

 - Add @TOC@ where you want to see your TOC.
 - Add @TOC_BACK@ to insert an internal link to TOC
 - Add @DATE(format-str)@ where you want to see a formatted date
 - Add @GIT_USER@ where you want to see your git user name
 - Add @GIT_EMAIL@ where you want to see your git email address
 - Use the --render option to render the HTML for the markdown

Examples:
---------
 md-utils README.md.in > README.md

 md-utils -r README.md.in

Options
-------
-B, --body     default is to add body tag, use --nobody to prevent    
-b, --both     interpolates intermediate file and renders HTML
-c, --css      css file
-e, --engine   github, text_markdown (default: github)
-h             help
-i, --infile   input file, default: STDIN
-m, --mode     for GitHub API mode is 'gfm' or 'markdown' (default: markdown)
-n, --no-titl  do not print a title for the TOC
-o, --outfile  outfile, default: STDOUT
-r, --render   render only, does NOT interpolate keywords
-R, --raw      return raw HTML from engine
-t, --title    string to use for a custom title, default: "Table of Contents"
-v, --version  version
-N, --nocss    no css

Tips
----
* Use !# to prevent a header from being include in the table of contents.
  Add your own custom back to TOC message @TOC_BACK(Back to Index)@

* Date format strings are based on format strings supported by the Perl
  module 'Date::Format'.  The default format is %Y-%m-%d if not format is given.

* use the --nobody tag to return the HTML without the <html><body></body></html>
  wrapper. --raw mode will also return HTML without wrapper
```

# Tips & Tricks

1. Add &#64;TOC&#64; somewhere in your markdown
1. Use !# to prevent heading from being part of the table of contents
1. Finalize your markdown...
   ```
   cat README.md.in | md-utils.pl > README.md
   ```
1. ...or...kick it old school with a `Makefile` if you like
   ```
   FILES = \
       README.md.in

   MARKDOWN=$(FILES:.md.in=.md)
   HTML=$(MARKDOWN:.md=.html)
   
   # interpolate the custom markdown keywords
   $(MARKDOWN): % : %.in
       md-utils $< > $@
   
   $(HTML): $(MARKDOWN)
       md-utils -r $< > $@
   
   all: $(MARKDOWN) $(HTML)
   
   markdown: $(MARKDOWN)
   
   html: $(HTML)
   
   clean:
       rm -f $(MARKDOWN) $(HTML)
   ```
1. ...and then...
    ```
    make all
    ```

## &#64;DATE(format)&#64;

Add the current date using a custom format.  Essentially calls the
Perl function `time2str`.  See `perldoc Date::Format`.

If no format is present the default is %Y-%m-%d (YYYY-MM-DD).

_Best practice would be to use a `Makefile` to generate your final
`README.md` from your `README.md.in` template as shown
[above](#usage) and generate your `README.md` as the last step before
pushing your branch to a repository._

Example:

&#64;`DATE(%Y-%m-%d)`&#64;

## &#64;GIT_EMAIL&#64;
## &#64;GIT_USER&#64;

If you've done something like:

```
git config --global user.name "Fred Flintstone"
git config --global user.email "fflintstone@bedrock.org"
```

or

```
git config --local user.name "Fred Flintstone"
git config --local user.email "fflintstone@bedrock.org"
```

...then you can expect to see those in your markdown, otherwise don't
use the tags.

[Back to Top](#table-of-contents)

## &#64;TOC&#64;

Add this tag anywhere in your markdown in include a table of contents.

## &#64;TOC_BACK(optional text)&#64;

Add &#64;TOC_BACK&#64; anywhere in your markdown template to insert an
internal link back to the table of contents.

@`TOC_BACK`@

@`TOC_BACK(Back to Index)`@

[Back to Top](#table-of-contents)

## Custom TOC Title

Use the `--no-title` option if you don't want the script to insert a
header for the TOC.
Use the `--title` option if you want a custom header for the TOC.

## Prevent heading from being included in table of contents

Precede the heading level with bang (!) and that heading will not be
included in the table of contents.

[Back to Top](#table-of-contents)

# Rendering

Using the [GiHub rendering
API](https://developer.github.com/v3/markdown/), you can create HTML
pretty easily. So if you want to preview your markdown...you might try:

```
jq --slurp --raw-input '{"text": "\(.)", "mode": "markdown"}' < README.md | \
  curl -s --data @- https://api.github.com/markdown
```

__...but alas you might find that your internal links don't work in
that rendered HTML...__

Never fear...the `--render` option of this utility will go ahead and set that right for
you and munge the HTML so that internal links really work...or at
least they do for me.

```
md-utils --render README.md > README.html
```

[Back to Top](#table-of-contents)

# Credits

Rob Lauer - <rlauer6@comcast.net>

[Back to Top](#table-of-contents)
