package HTML::Tempi;

require 5.005_62;
use strict;
use warnings;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Tempi ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(tempi_init parse_block set_var tempi_out tempi_free tempi_reinit
	
);
our $VERSION = '0.01';

bootstrap HTML::Tempi $VERSION;

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

HTML::Tempi - Perl extension for HTML templates

=head1 SYNOPSIS

	use HTML::Tempi;
	tempi_init("template.html");
	set_var("some_var", "i was some_var");
	parse_block("MAIN");
	print tempi_out();
	tempi_free();

=head1 DESCRIPTION

Tempi is a HTML template system. It's is written in C, using a flex
generated scanner. That makes it (That's why it should be) faster than 
pure Perl template systems.

=head1 FUNCTIONS

Tempi gives you access to these functions:

	int tempi_init (template_file);
	int parse_block (block_name);
	int set_var (var_name, var_value);
	scalar *tempi_out (void);
	int tempi_free (void);
	int tempi_reinit (void);	
	
=head2 general note:

All functions are returning 0 if there's an error. The error message is set in
I<$main::!> (I<$!>). Otherwise, they will allways return 1, expect from 
C<tempi_out>.
	
=head2 tempi_init

C<tempi_init> will load the given template file and make it ready for using it.
Calling any functions before C<tempi_init> will result in an error. Calling 
C<tempi_init> again before calling C<tempi_free> will result in an error. You
have to call C<tempi_free> first. It is only possible to handle one template
file at once.

=head2 parse_block

C<parse_block> is used to parse a block, that means the block will become
visibel in the output. C<parse block> is a primary function, that means that
using one block name several times will not work. The result if you do so
is undefined and very probably not what you want.

=head2 set_var

C<set_var> will replace the given var in the template with the given value.
C<set_var> is secondary, that means, that you can use a var name as often you
want, and everywhere it appaers, it will be replaced. Using C<set_var> with
the same name again, will only override the value it had before.

=head2 tempi_out

C<tempi_out> returns a string, containing the parsed data.

=head2 tempi_free

C<tempi_free> cleans up space used by Tempi. It's important to say, that not all
memory is freed. Some data will stay. If you're using normal cgi's you even
don't have to call C<tempi_free>, because if the process is finished, the system will
clean up. But if you're using mod_perl, you have to use C<tempi_free>. The data which 
will stay, is used for the next request. That gives a great performance plus, since 
most time is spent for parsing the template, what so only has to be done when each
process is starting. I suggest that you make allways use of C<tempi_free>. It's cleaner
and you're on the safer side.

=head2 tempi_reinit

C<tempi_reinit> makes it possible to use init with a new template file. Otherwise, the
old one will be used. You have to call C<tempi_free> before you call C<tempi_reinit>.

=head1 TAGS

Tempi knows only a few differnt tags:

	<!--BLOCK:block_name-->	starts a block called block_name
	<!--END:block_name-->	the block ends here
	
	<!--FILE:file_name-->	will include the file file_name
	
	{var_name}	creates a variable called var_name
	
=head2 BLOCKS

A block is a section in a template. This block can be inserted as often as you
want at the place where it is. For example:

	<table>
	<!--BLOCK:row-->
	<tr><td>1. cell</td><td>2. cell</td></tr>
	<!--END:row-->
	</table>
	
could be used to create a table with as many

	<tr><td>1. cell</td><td>2. cell</td></tr>

lines as you wish. To produce 100 of this lines, try this:

	use Tempi;

	tempi_init("template.html");
	for (1..100)
		{
			parse_block("row");
		}
	parse_block("MAIN");
	print tempi_out();
	tempi_free();

As you sure have noticed, there is a C<parse_block("MAIN");> command. That is,
because Tempi puts everthing that isn't in a block, into a block called MAIN
(you should I<not use the name MAIN for a block> yourself, that will crash).

=head2 VARIABLES

To make the example from above really usefull, we will now use variables for
the cells values:

	<table>
	<!--BLOCK:row-->
	<tr><td>{cell1}</td><td>{cell2}</td></tr>
	<!--END:row-->
	</table>
	
	use Tempi;

	tempi_init("template.html");
	for (1..100)
		{
			set_var ("cell1", "This is cell1 in row $_");
			set_var ("cell2", "This is cell2 in row $_");
			parse_block("row");
		}
	parse_block("MAIN");
	print tempi_out();
	tempi_free();
	
=head2 FILES

Files are include with this tag:

	<!--FILE:/usr/indian/temp/chief/coll_page.html-->

This would include the file located in /usr/indian/temp/chief/coll_page.html
at the current position.

=head2 The tags as regex

To make clear, which tags are valid, here are the regex patterns:

	Block start:	"<!--BLOCK:"[[:alnum:]]+"-->"
	Block end:	"<!--END"[[:alnum:]:]*"-->"
	Inlcude file:	"<!--FILE:"[[:alnum:]./_]+"-->
	Variable:	"{"[[:alnum:]]+"}"
	
	where [:alnum:] stands for a-zA-Z0-9.
	
(As you will surely have seen, you can close a block simply with
C<< <!--END--> >>, Tempi will not check that you're closing the blocks
in the right order, that's up to you, but making it possible to 
use C<< <!--END:name--> >> should make it easier.)

If you want to change the patterns, you can do it by editing the
tempi.flex file and then run the whole installation again (C<perl Makefile.PL>
too).

=head1 LICENSE
 
	Tempi - A HTML Template system
Copyright (C) 2002  Roger Faust <roger_faust@bluewin.ch>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=head1 BUGS

There will be a lot, I'm quite sure. Using Tempi for serious things should
not be done yet. This is the first version, I hope to get some echos about
bugs (or that there aren't) so that it could be possible, to declare 
future versions of Tempi as stable.

=head1 AUTHOR

Roger Faust <roger_faust@bluewin.ch>

bugs, tipps, improvments and comments are highly welcome!

=head1 SEE ALSO

HTML::Template

=cut

