#!/usr/bin/perl

package Mail::Summary::Tools;

our $VERSION = "0.06";

__PACKAGE__;

__END__

=pod

=head1 NAME

Mail::Summary::Tools - Tools for mailing list summarization.

=head1 SYNOPSIS
	
	# create a summary from anything Mail::Box can open.
	# you may also programatically create summary objects and serialize
	# them if you don't have the threads in a standard mail format.

	% mailsum create --dates --posters --clean -i foo.mbox -o summary.yaml


	# edit the text in your editor, if you don't like YAML files

	% mailsum edit --skip --dates --posters --links --archive gmane summary.yaml


	# create pretty outputs

	% mailsum totext --shorten -a google summary.yaml > summary.txt
	% mailsum tohtml --archive google summary.yaml > summary.html

=head1 DESCRIPTION

This distribution contains numerous classes useful for creating summaries, and
an L<App::Cmd> based frontend to those classes.

The main usage is illustrated in the L</SYNOPSIS> section.

=head1 WORKFLOW

In the first step L<Mail::Summary::Tools> takes a mail box of any sort as
input, and creates a YAML file for the summary. This file contains a hierarchal
structure whereby every thread belongs to exactly one list (cross posts should
not be summarized twice), and lots of meta data is also maintained.

This file may be hand edited if you're comfortable with YAML, but typically you
use the flat file format, exposed using the C<edit> command to alter the
summary texts, hide threads, assign threads to a different list, etc. This can
be done either interactively (with L<Proc::InvokeEditor>) or using --save and
--load.

If any updating of the summary is necessary you should load all the changes you
have using the edit command, and run C<create --update> (it needs a better
name). Out of date threads will be marked as long as you use the --dates option
(if a thread is summarized and it's end date is extended by the update then it
is marked out of date).

When you are done you can emit using C<totext> and C<tohtml>. The default
outputs assume that the summary text is written in the markdown language. This
translates well to HTML, and looks pretty good as-is in plain text.

=head1 SAMPLE FILES

=head2 YAML Summary

The YAML summary will look something like this:

	---
	title: Mailing list summary
	extra:
	  header:
	    - title: A Header Section
          body: fooo bar gorch
	  see_also:
	    - name: Foo
	      uri:  http://www.example.com/
	    - name: The Perl Foundation
	      uri:  http://www.example.com/
	lists:
	  - name: oink
	    title: The Oink Mailing list
	    threads:
	      - message_id: 69d3ac770606131947r55708fc0g139242e5a989ae4e@mail.gmail.com
	      posters:
	        - email: user@example.com
	          name: User One
	        - email: user2@example.com
	          name: User Two
	        - email: user3@example.com
	          name: User Three
	      subject: 'The Message Subject'
	      summary: >-
	        Somebody asked whether or not monkeys like to eat cheese, at which
	        points the monkey subscribed to the list said that they did not
	        like cheese at all where he lives, but that he eats it anyway.

Most fields are optional. The summary bodies should be written in the Markdown
language.

=head2 Flat File

The flat file format can be generated using the C<edit> command. It's optimized
for ease of editing. The basic structure is a list of threads separated by the
string C<\n---\n>. Right after the separator is some YAML for meta data, and
then an ignored paragraph, and then the summary data:

	The first chunk is ignored, and has instructions

	---
	message_id: foo@bar.com
	subject: Moose
	hidden: 0 # can be used to omit a thread from the output
	out_of_date: 1 # added by create --update
	thread_uri: http://..../ # hard code a link to a different archive than the default

	# these lines are ignored, and are provided for the summarizers
	# convenience, including random links, posters names, the thread's date
	# range, etc
	<rt://perl/1234>
	Some Guy
	Some Other Guy

	In the thread Titled Moose, Some Guy conjectured on the nature of Some
	Other Guy's mother's profession. Some Other Guy then replied with a witty
	retort. A flamewar ensued.

=head2 Text Output

The above summary converted to text (using the C<totext> command) should look
like this:

	Mailing list summary

	 A Header Section

	    fooo bar gorch

	 The Oink Mailing List

	  The Message Subject <http://xrl.us/moose>

	    Somebody asked whether or not monkeys like to eat cheese, at which
	    points the monkey subscribed to the list said that they did not
	    like cheese at all where he lives, but that he eats it anyway.

	 See Also

	     * Foo <http://www.example.com>>
	     * The Perl Foundation <http://www.example.com/>

The text is emitted in utf8.

Example output can be seen here:
http://groups.google.com/group/perl.perl6.announce/msg/7d65491507dda589
(autolinkified by google)

=head2 HTML Output

HTML output is also available using the C<tohtml> command.

A real summary is probably a better example, since HTML source is not easily
readable: http://pugs.blogs.com/pugs/2006/08/perl_6_mailing__2.html#more

The HTML is ASCII, with all non ascii characters escaped by HTML::Entities.

C<< <divs> >> are emitted for easy restructuring of the file, and the heading
tags are customizable. For example, for use.perl.org Ann emits with C<--h2 p,b
--h3 p,i> since h tags are not allowed, and the C<< <divs> >> are stripped by
L<HTML::Element> to keep the size down.

=head1 COMPONENTS

These are the main components of this distribution:

=head2 L<Mail::Summary::Tools::Summary>

The model for summary objects

=head2 L<Mail::Summary::Tools::FlatFile>

Export and load L<Mail::Summary::Tools::Summary> fields from a convenient
flatfile format.

=head2 L<Mail::Summary::Tools::Output>

The various output formats, like plain text, HTML.

=head2 L<Mail::Summary::Tools::CLI>

The L<App::Cmd> based components

=head2 L<Mail::Summary::Tools::ArchiveLink>

Classes for creating links to mailing list archives (google groups, gmane,
etc).

=head1 FUTURE DIRECTIONS

Here are a few possible extensions to this project which we may or may not get
around to:

=over 4

=item *

Long term persistence of thread status - what has been summarised, what needs
revisiting, etc, based on a config + state file per mailing list.

=item *

Archive downloading tools, for backlogging, possibly based on L<Net::NNTP> or
L<WWW::Google::Groups>.

This is important for offline viewing.

=item *

A local running webapp to streamline summarization.

=item *

Posting interface - Atom (for blogs), use.perl.org, and to various mailing
lists.

=item 

=back

=head1 SEE ALSO

L<Mail::Box>, L<App::Cmd>, L<Template>, L<Proc::InvokeEditor>, L<YAML>, L<YAML::Syck>.

=head1 VERSION CONTROL

This module is maintained using Darcs. You can get the latest version from
L<http://nothingmuch.woobling.org/Mail-Summary-Tools/>, and use C<darcs send>
to commit changes.

=head1 AUTHORS

Yuval Kogman, E<lt>nothingmuch@woobling.orgE<gt>

Ann Barcomb

=head1 COPYRIGHT & LICENSE

Copyright 2006 by Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>, Ann Barcomb

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=cut

