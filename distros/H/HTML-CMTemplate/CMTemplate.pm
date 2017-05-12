package HTML::CMTemplate;

use strict;
use vars qw($VERSION);

$VERSION = '0.4.0';

use vars qw($DEBUG $DEBUG_FILE_NAME $DEBUG_FUNCTION_REF);
$DEBUG = 0;
$DEBUG_FILE_NAME = '';
$DEBUG_FUNCTION_REF = undef;

=head1 NAME

HTML::CMTemplate.pm - Generate text-based content from templates.

=head1 SYNOPSIS

  use HTML::CMTemplate;

  $t = new HTML::CMTemplate( path => [ '/path1', '/longer/path2' ] );

  $t->import_template(
    filename => 'file.html.ctpl', # in the paths above
    packagename => 'theTemplate',
    importrefs => { myvar => 'hello' },
    importclean => { myclean => 'clean!' },
    );

  theTemplate::cleanup_namespace();

  print "Content-type: text/html\n\n";
  print theTemplate::output();

  # Template syntax is described below -- see that section to get the real
  # details on how to use this sucker.

=head1 DESCRIPTION

HTML::CMTemplate 0.4.0

A class for generating text-based content from a simple template language.
It was inspired by the (as far as I'm concerned, incomplete) HTML::Template
module, and was designed to make template output extremely fast by
converting a text/html template into a dynamic perl module and then running
code from that module.  Since the parsing happens only once and the template
is converted into Perl code, the output of the template is very fast.

It was designed to work with mod_perl and FastCGI and has been the basis
for all of the dynamic content on the Orangatango site
(http://www.orangatango.com).

First release (version 0.1) was February 15, 2001 and was I<very> quiet
because it was a proprietary version.

As of version 0.2, it is released under the Artistic License.  It's a much
more feature-rich version as well as being Open Source!
For a copy of the Artistic License, see the files that came with your
Perl distribution.

The code was developed during my time at Orangatango.  It has been released
as open source with the blessing of the controlling entities there.

=head1 AUTHOR

Chris Monson, shiblon@yahoo.com

=head2 DEBUG OUTPUT

  You can coerce the template engine into spitting out debugging
  information for every step of the parsing process.  This behavior can be
  controlled by the following variables:

  $HTML::CMTemplate::DEBUG = 1;  # Do this, and debugging will be turned on
  $HTML::CMTemplate::DEBUG_FILE_NAME = 'filename'; # Defaults to STDERR
  $HTML::CMTemplate::DEBUG_FUNCTION_REF = $ref;

  The debug function reference is used for every debug step.  It is passed
  three parameters: the name of the function being debugged, a string,
  and an array ref.  If the array is non-empty, it
  contains the arguments to a function that is being debugged.
  If the string is non-empty, it contains a message.

  Note that this is of dubious utility.  The debug functions are mostly for
  my own internal use to see where the template parser goes wrong.  They 
  do not detect bad template syntax, and they will be of no use to people
  just making use of the template parser.  Really.  My advice is to leave the
  debug parameters alone.  You don't need them.

=head2 TEMPLATE SYNTAX

The template syntax that this parser recognizes has a few tags that look
a little like php or xml syntax, except that they are different.  The tags
all start with <?= and end with ?>.  If the next character after ?> is a
newline, it is also eaten up with the tag, just like in PHP.  This gives you
very fine grained control over the actual template output, and is especially
important when using loops to generate output.

Note that if you want to actually output those symbols in your code, or you
want to access them inside of a tag, I have created two global variables that
contain those strings:  $START_SYM and $END_SYM.  So, to print something
like <?=hello?> inside of your template, you would do this:

    <?=echo $START_SYM?>hello<?=echo $END_SYM?>

Or, if you use the shortcut (all explained below), you would do this:

    <?=$START_SYM?>hello<?=$END_SYM?>

An explanation follows of the different constructs that the engine uses.

I<comment>

The I<comment> construct is just a single tag.  The whole tag is eaten
by the template engine and is never seen again.  This simply serves
as a comment in the template itself.

    <?=comment  This is a comment ?>

I<echo>

The I<echo> construct supports two tags: 

    <?=echo --expression-- ?>
    <?=--expression--?>

The second tag is a handy shortcut for the first, and works like its
corresponding PHP tag.  Both are replaced with the value of the evaluated
expression.  This is by far the most used construct, since usually the
result of an expression simply needs to be inserted into the appropriate place.

Example:

    ...
    <title><?=$document_title?></title>
    ...

This could also be written as

    ...
    <title><?=echo $document_title?></title>
    ...

Both will replace the tag with the contents of the $document_title variable.

But, where does $document_title come from?  Going back to the synopsis, if
you do something like this in your perl script:

    $t->import_template(
        filename => 'thetemplate.html.ctpl',
        packagename => 'theTemplate',
        );

Then you can set the variable in the newly-created package (There is no
need to do a 'use' or a 'require' or anything.  The package is created
when you call the import_template function and is thereafter available).

You create the variable thus:

    $theTemplate::document_title = "My Document Title";

Then to output the template, you would do something like this:

    print "Content-type: text/html\n";
    print "\n";
    print theTemplate::output();

Note that the import_template function does not import the template again
if it detects that the template or any of its includes (see below) have not
changed.  This is an optimization to reduce needless parsing, since once
the template is in memory, you can use it over and over again with new
variables by just changing the variable values in the package namespace.

    NOTE: This behavior can be changed by setting the
    $t->{checkmode} variable to $HTML::CMTemplate::CHECK_NONE.

So, if I wanted to output the template again with a new title, I could simply
do the following:

    $theTemplate::document_title = "My NEW Document Title";
    print "Content-type: text/html\n";
    print "\n";
    print theTemplate::output();

Note that an import_template was not necessary again, since the template
was converted into code and all we wanted to do was change a variable.

Again, if you do call import_template on the same object ($t in the examples)
more than once, it will only actually parse the template once, unless you
change it on disk in between import_template calls.

I<if>

The I<if> construct supports several tags, some of which are reused in the
I<for> construct:

    <?=if --expression-- :?>
    <?=elif --expression-- :?>
    <?=else :?>
    <?=endif?>

These tags do basically what you would expect them to do.  Note that none
of the expressions require surrounding parentheses.  They do require terminating
colons, however.  Whitespace is not important except between the tag name ('if')
and the expression.

So, as an example of how you might do things:

    <?=if $testvar:?>
    TESTVAR set!
    <?=else:?>
    TESTVAR NOT set!
    <?=endif?>

The I<elif> tag works just like an elsif in Perl.

I<for>

The I<for> contruct supports several tags, as well.  It works like Python's
I<for> loop construct and has a similar syntax.  In fact, all of these tags
borrowed some of their syntax from Python.

The supported tags are as follows:

    <?=for --varname-- in --list expression-- :?>
    <?=break?>
    <?=continue?>
    <?=else:?>
    <?=endfor?>

These tags, with the exception of the 'else' tag (since it doesn't exist) do
what you would expect them to do in Perl.  The 'for' and 'else' tags deserve
a little extra explanation since they are not real Perl syntax.

The --varname-- is the name of a variable that will be assigned the value
of the current list item.  The --list expression-- is an expression that
evaluates to a real Perl array (NOT an arrayref).  Each item in the array will
be assigned to --varname-- in order.  Here is an example.  Assume for the sake
of this example that an array of integers 1 thru 10 named '@list' exists in
the package's namespace:

    <table>
    <?=comment
        Note that you can use either 'i' or '$i' here.
        They are equivalent in the for tag.  The echo tag
        MUST use '$i' because it is outputting a perl
        expression and is not specially parsed at all.
    ?>
    <?=for i in @list:?>
    <tr><td>Number <?=echo $i?></td></tr>
    <?=else:?>
    <tr><td>Completed normally</td></tr>
    <?=endfor?>
    </table>

Note that you don't have to output HTML.  Any kind of text can be output,
but HTML is what this was originally designed for.

This will loop on the elements of @list, which contains the numbers 1 thru 10
in order.  It will output the following code:

    <table>
    <tr><td>Number 1</td></tr>
    <tr><td>Number 2</td></tr>
    <tr><td>Number 3</td></tr>
    <tr><td>Number 4</td></tr>
    <tr><td>Number 5</td></tr>
    <tr><td>Number 6</td></tr>
    <tr><td>Number 7</td></tr>
    <tr><td>Number 8</td></tr>
    <tr><td>Number 9</td></tr>
    <tr><td>Number 10</td></tr>
    <tr><td>Completed Normally</td></tr>
    </table>

Note the extra table element at the end that says "Completed Normally".  This
is inserted because of the I<else> tag after the for block.  Like in Python, the
code in the else tag is executed if the I<for> loop is not terminated with a
I<break> tag.  If the for loop is terminated with a I<break> tag, then the
I<else> block will not execute.

The I<break> and I<continue> tags work as you would expect the corresponding
'last' and 'next' keywords to work in Perl.

There are several functions to ease your way in I<for> loops.  They are listed
here:

    for_list( $depth )
    for_index( $depth )
    for_count( $depth )
    for_is_first( $depth )
    for_is_last( $depth )

The for_list function gives you access to an arrayref of the list over which
the loop (or one of its containing loops, if $depth > 0) is iterating.

The for_index function gives you a number from 0 to len-1, depending on where
you are in the actual loop.

The for_count function gives you the number of elements over which you are
iterating.

The for_is_first function tells you whether this is the first element, and the
for_is_last function tells you whether this is the last one.

Note that all of these functions give you the ability to specify a depth.  If
you have nested 'for' tags and you want to access the index, count, or list of
a containing 'for' loop, you can do that by specifying a depth parameter in the
function.  No depth parameter or a value of 0 indicates that you want the
values for the current loop.  A value of 1 would indicate that you want the
values for the immediately enclosing loop, etc.

Example:
    Suppose @xlist = (1, 2, 3) and @ylist = (2, 4, 6):

    <?=for x in @xlist:?>
    <?=for y in @ylist:?>
        <?=$x?>,<?=$y?> :: <?=echo for_index(1)?>,<?=echo for_index()?>
    <?=endfor?>
    <?=endfor?>

    prints:
        1,2 :: 0,0
        1,4 :: 0,1
        1,6 :: 0,2
        2,2 :: 1,0
        2,4 :: 1,1
        2,6 :: 1,2
        3,2 :: 2,0
        3,4 :: 2,1
        3,6 :: 2,2

We can also tell if the current element is the first or last.  Rather than
give an example for that simple case, it is left as an exercise for the reader.
A hint, however, is that you should use for_is_first and for_is_last (functions
that can also take a depth argument).

As a side note, here, I should mention that tabbing loop and conditional
constructs does not work the way that you think it might inside of a template.
Since the only thing that is eaten up in a template is the tag itself, not
the preceding whitespace, usually you want the loop constructs and other
kinds of block constructs to be located all the way to the left side.  This
will ensure that your spacing is really what you think it should be.

I<while>

The tags this loop uses are as follows:

    <?=while --expression--:?>
    <?=endwhile?>

The I<while> construct is a very simple loop that works like a standard
while loop in Perl.  This is useful when you are potentially outputting a large
loop and don't want to get the entire contents of it into memory.  The
expression in the while loop works just as you would expect it to.  A true
value means to keep going, and a false one means to stop.

As with all other block structures, you can put anything you like in the
body of a while construct.

Example (assuming you have created appropriate function references):

    <?=while $items_hanging_around->():?>
    <?=echo $get_next_item->():?>
    <?=endwhile?>

I<def>

The I<def> construct is a very powerful little tool.  It corresponds loosely
to Python's def in that it defines a sort of "template function" which can
be "called".  An example will best illustrate this.

By the way, the tags that are used by this construct are the following:

    <?=def --functionname--( --arglist-- ):?>
    <?=enddef?>
    <?=call --functionname--( --arglist-- )?>

Here is that promised example:

    <?=def tempfunc( a, b, c ): ?>
        a = <?=echo $a?>

        b = <?=echo $b?>

        c = <?=echo $c?>

    <?=enddef?>
    <?=call tempfunc( 1, 2, 3 )?>
    <?=call tempfunc( 4, 5, 6 )?>

This will print the following:

        a = 1
        b = 2
        c = 3
        a = 4
        b = 5
        c = 6

I think it's pretty self-explanatory.  Note that you can embed any number of
recursive constructs inside of not only the I<def> tags, but also I<if> and
I<for> tags, along with their corresponding inner tags.

B<NOTE>: No matter where a template subroutine is defined (def tag), the
subroutine ends up in the global package scope.  All defs are global.  Period.
This is by design and actually required a large amount of work to do, so
don't you go thinking that it's because I'm lazy ;-).

The reasoning behind this is to keep namespace clashes from happening when
one template includes another.  If the functions are treated differently
from other constructs (since Perl treats them differently anyway), namespace
collisions can be detected.  Additionally, if one module includes two others,
each of which include the same module, the functions from that last module
are the same.  Functions in the global scope keep these from wrongly stomping
on each other.

I<exec>

This one is somewhat dangerous, and should be used with great care.
It allows you to execute arbitrary Perl code inside of the tag.

    <?=exec
        $a = 1;
        $b = 2;
        $c = $a + $b;
        print STDERR "Debug this output function!";
    ?>

This will set the variables just as you think it will, but it will
do it in a somewhat strange scope and you might get a bit confused.  Look at
the code that is generated (by calling $t->output_perl()) to see
exactly what goes on.

Note that the package that is created from this template explicitly declares
no strict 'vars', so the exec tag above will actually create global variables
in the package's namespace.  You can also create 'my' variables, which is
really useful inside of loops.

The best uses I have found for this tag are as follows:

    * Creating temporary variables or aliases to complicated variables.
    * Creating 'my' variables inside of loops to improve efficiency.
    * Outputing debug code using print STDERR "stuff" constructs.

Beyond this, I have serious misgivings about the tag.  Just be careful.  Your
code will be inserted as is into the template code.  Don't forget semicolons,
etc.

I<inc>

This includes another template where the tag is located.  It tests for
infinite recursion and does not allow it.  Also, note that this does NOT
take an arbitrary perl expression as a filename.  It only takes strings.
The filename can be quoted with either single or double quotes.

This parses the file just like any other template, looking for tags.  If you
don't want the file parsed, use 'rawinc' instead.

I<rawinc>

Just like 'inc', but it doesn't parse the file.  Simple.

=head2 IMPORTED UTILITIES

You have access to several functions.  Most of the time you will only use
a couple of them, but there are several there for the sake of completeness and
sanity.

I<output()>

This is used to output the code given the current namespace.  Simple.  It
returns a string.

I<import_hashref()>

This is extremely useful for importing the variables from another namespace.
I routinely do the following:

    use CMCONFIG;
     ...
    theTemplate::import_hashref( \%CMCONFIG:: );

You can also set up your own hashref of variables.  This is useful for getting
form elements from CGI stuff:

    theTemplate::import_hashref( \%FORM );
    theTemplate::import_hashref( { myvar => 'value' } );

That would set all of the FORM data to be global variables (PHP style) in
the package, and it would additionally set $myvar to be 'value'.

Note that you can pass an extra parameter (1 or 0) to indicate that you want
the variables imported into the 'clean' namespace.  More on this later.

I<cleanup_namespace()>

This deletes all variables from the package's namespace except those that
are designated 'clean'.  Clean variables are the functions that are
automatically defined and the globals that are used by the package before
anything is done to it.  They are also variables that have been imported and
marked 'clean'.

This function is really important, especially in cases where the template is
being generated with fastcgi or mod_perl, since the modules will have their
variables maintained across page loads.  That means that the previous user's
password (for example) could be available in the page.  Bad, bad things happen
at that point.

So, it is useful to call cleanup_namespace before using the template.  It is
also useful to import things like system-wide configuration parameters into
the clean namespace, since these aren't sensitive to change and can take a
little extra time to import.

I<add_clean_names()>

If you import a ton of variables and want to mark some of them clean, use this
function.

=cut

use FileHandle;
use File::stat;

BEGIN {
    $HTML::CMTemplate::debugline = 1;
}

package _NODE_;
    $_NODE_::prepend = '    ';
    $_NODE_::defprepend = 'ORANTEMPLATE_';

    sub new {
        my $class = shift;
        my $self = {};
        bless $self, $class;
        $self->__init__(@_);
        return $self;
    }

    sub __prepend__ {
        my $self = shift;
        my $depth = shift || 0;
        return ($_NODE_::prepend x $depth);
    }

    sub __init__ {
        my $self = shift;
        $self->parent( shift() );
        $self->type( 'UNKNOWN' );
    }

    sub __var__ {
        # Performance critical, so we don't actually
        # shift anything off.  We also don't copy values around.
        # Just check the length of the argument list.  If it is
        # longer than 2, then we have a value and we set stuff.
        # 0 => self
        # 1 => varname
        # 2 => new value (if specified)
        $_[0]->{$_[1]} = $_[2] if @_==3;
        # Return the value in either case
        $_[0]->{$_[1]}
    }

    sub AUTOLOAD {
        return if $_NODE_::AUTOLOAD =~ /DESTROY$/o;
        # Treat undefined functions as accessors.
        if (@_ > 1) {
            return $_[0]->__var__( $_NODE_::AUTOLOAD, $_[1] );
        }
        else {
            return $_[0]->__var__( $_NODE_::AUTOLOAD );
        }
    }

package _TPL_;
    @_TPL_::ISA = qw(_NODE_);
    sub __init__ {
        my $self = shift;
        $self->parent( shift() );
        $self->type( 'TPL' );
        $self->text( '' );
        # UNDEFINED:
        # blk, tpl
    }

    sub output_perl {
        my $self = shift;
        my %args = @_;
        my $depth = $args{'depth'} || 0;
        my $prepend = $self->__prepend__( $depth );
        my $result = '';

        my $text = $self->text;
        my $blk = $self->blk;
        my $tpl = $self->tpl;
        $text =~ s/\\/\\\\/g; # backslash all backslashes
        $text =~ s/'/\\'/g; # backslash all single ticks
        if (defined($text) && $text ne '') {
            $result .= $prepend . "\$\$_RESULT_ .= '" . $text . "';\n";
        }
        if ($blk) {
            $result .= $blk->output_perl( @_ );
        }
        if ($tpl) {
            $result .= $tpl->output_perl( @_ );
        }

        return $result;
    }

package _IF_;
    @_IF_::ISA = qw(_NODE_);
    sub __init__ {
        my $self = shift;
        $self->parent( shift() );
        $self->type( 'blkIF' );
        $self->expr( '' );
        $self->tpl( _TPL_->new( $self->parent ) );
        # UNDEFINED
        # nextif
    }

    sub output_perl {
        my $self = shift;
        my %args = @_;
        my $depth = $args{'depth'} || 0;
        my $prepend = $self->__prepend__( $depth );
        my $result = '';

        my $nextif = $self->nextif;
        $result .= $prepend . "if (" . $self->expr . ") {\n" 
            . $self->tpl->output_perl( depth => $depth + 1 ) . "$prepend}\n";

        if ($nextif) {
            $result .= $nextif->output_perl( @_ );
        }

        return $result;
    }

package _ELIF_;
    @_ELIF_::ISA = qw(_NODE_);
    sub __init__ {
        my $self = shift;
        $self->parent( shift() );
        $self->type( 'blkELIF' );
        $self->expr( '' );
        $self->tpl( _TPL_->new( $self->parent ) );
        # UNDEFINED
        # nextif
    }

    sub output_perl {
        my $self = shift;
        my %args = @_;
        my $depth = $args{'depth'} || 0;
        my $prepend = $self->__prepend__( $depth );
        my $result = '';

        my $nextif = $self->nextif;
        $result .= $prepend . "elsif (" . $self->expr . ") {\n" .
            $self->tpl->output_perl( depth => $depth + 1 ) . "$prepend}\n";

        if ($nextif) {
            $result .= $nextif->output_perl( @_ );
        }

        return $result;
    }

package _ELSE_;
    @_ELSE_::ISA = qw(_NODE_);
    sub __init__ {
        my $self = shift;
        $self->parent( shift() );
        $self->type( 'blkELSE' );
        $self->tpl( _TPL_->new( $self->parent ) );
    }

    sub output_perl {
        my $self = shift;
        my %args = @_;
        my $depth = $args{'depth'} || 0;
        # If this is not an 'if' block, we need to only print out the
        # template, not the surrounding context.
        my $prepend = $self->__prepend__( $depth );
        my $result = '';

        my $nextif = $self->nextif;
        $result .= $prepend . "else {\n" .
            $self->tpl->output_perl( depth => $depth + 1 ) . "$prepend}\n";

        return $result;
    }

package _FOR_;
    @_FOR_::ISA = qw(_NODE_);
    sub __init__ {
        my $self = shift;
        $self->parent( shift() );
        $self->type( 'blkFOR' );
        $self->varname( '' );
        $self->listexpr( '' );
        $self->tpl( _TPL_->new( $self->parent ) );
        # UNDEFINED
        # default
    }

    sub output_perl {
        my $self = shift;
        my %args = @_;
        my $depth = $args{'depth'} || 0;
        my $prepend = $self->__prepend__( $depth );
        my $result = '';

        my $varname = $self->varname;
        my $listexpr = $self->listexpr;
        my $default = $self->default;

        $result .= $prepend . "push \@for_list, [$listexpr];\n";
        $result .= $prepend . "push \@for_count, scalar(\@{\$for_list[\$#for_list]});\n";
        $result .= $prepend . "push \@for_index, 0;\n";
        $result .= $prepend . "TMPLLOOPBLK: {\n"; # only the loop goes in here
        $result .= $prepend . 
            "foreach my \$$varname (\@{\$for_list[\$#for_list]}) {\n";
        $result .= $self->tpl->output_perl( depth => $depth + 1 );
        $result .= $prepend . "\$for_index[\$#for_index]++;\n";
        $result .= $prepend . "}\n";

        if ($default) {
            # Print out the 'else' block's template, not the else block itself.
            # It is guaranteed to have a template.
            $result .= $default->tpl->output_perl( @_ );
        }
        $result .= $prepend . "}\n"; # end the block first, then do other stuff
        $result .= $prepend . "pop \@for_list;\n";
        $result .= $prepend . "pop \@for_count;\n";
        $result .= $prepend . "pop \@for_index;\n";

        return $result;
    }

package _WHILE_;
    @_WHILE_::ISA = qw(_NODE_);
    sub __init__ {
        my $self = shift;
        $self->parent( shift() );
        $self->type( 'blkWHILE' );
        $self->expr( '' );
        $self->tpl( _TPL_->new( $self->parent ) );
    }

    sub output_perl {
        my $self = shift;
        my %args = @_;
        my $depth = $args{'depth'} || 0;
        my $prepend = $self->__prepend__( $depth );
        my $result = '';

        my $expr = $self->expr;

        $result .= $prepend . "TMPLLOOPBLK: {\n"; # only the loop goes in here
        $result .= $prepend . "while ($expr) {\n";
        $result .= $self->tpl->output_perl( depth => $depth + 1 );
        $result .= $prepend . "}\n";
        $result .= $prepend . "}\n";

        return $result;
    }

package _DEF_;
    @_DEF_::ISA = qw(_NODE_);
    sub __init__ {
        my $self = shift;
        $self->parent( shift() );
        $self->type( 'blkDEF' );
        $self->name( '' );
        $self->argnames( [] );
        $self->tpl( _TPL_->new( $self->parent ) );
    }

    sub output_perl {
        my $self = shift;
        my %args = @_;
        my $depth = $args{'depth'} || 0;
        my $prepend = $self->__prepend__( $depth );
        my $prepend2 = $self->__prepend__( $depth + 1 );
        my $result = '';

        my $name = $self->name;
        my $argnames = $self->argnames;

        # Create a function name that is not entirely intuitive and easy
        # to confuse with others.
        my $funcname = "$_NODE_::defprepend$name";

        # Create the code.
        $result .= $prepend . "sub $funcname {\n";
        $result .= $prepend2 . "my \$_RESULT_ = shift;\n";
        foreach my $vname (@$argnames) {
            $result .= $prepend2 . "my \$$vname = shift;\n";
        }

        # Now print out the template stuff.
        $result .= $self->tpl->output_perl( depth => $depth + 1 );
        $result .= $prepend . "}\n";
    }

package _CALL_;
    @_CALL_::ISA = qw(_NODE_);
    sub __init__ {
        my $self = shift;
        $self->parent( shift() );
        $self->type( 'blkCALL' );
        $self->name( '' );
        $self->argexpr( '' );
    }

    sub output_perl {
        my $self = shift;
        my %args = @_;
        my $depth = $args{'depth'} || 0;
        my $prepend = $self->__prepend__( $depth );
        my $result = '';

        my $name = $self->name;
        my $argexpr = $self->argexpr;

        $result .= $prepend . 
            "$_NODE_::defprepend$name( \$_RESULT_,$argexpr);\n";
    }

package _BREAK_;
    @_BREAK_::ISA = qw(_NODE_);
    sub __init__ {
        my $self = shift;
        $self->parent( shift() );
        $self->type( 'blkBREAK' );
    }

    sub output_perl {
        my $self = shift;
        my %args = @_;
        my $depth = $args{'depth'} || 0;
        my $prepend = $self->__prepend__( $depth );
        my $result = $prepend . "last TMPLLOOPBLK;\n";
        return $result;
    }

package _CONTINUE_;
    @_CONTINUE_::ISA = qw(_NODE_);
    sub __init__ {
        my $self = shift;
        $self->parent( shift() );
        $self->type( 'blkCONTINUE' );
    }

    sub output_perl {
        my $self = shift;
        my %args = @_;
        my $depth = $args{'depth'} || 0;
        my $prepend = $self->__prepend__( $depth );
        my $result = $prepend . "next;\n";
        return $result;
    }

package _ECHO_;
    @_ECHO_::ISA = qw(_NODE_);
    sub __init__ {
        my $self = shift;
        $self->parent( shift() );
        $self->type( 'blkECHO' );
        $self->expr( '' );
    }

    sub output_perl {
        my $self = shift;
        my %args = @_;
        my $depth = $args{'depth'} || 0;
        my $prepend = $self->__prepend__( $depth );
        my $result = $prepend . "\$\$_RESULT_ .= (" . $self->expr . ");\n";
        return $result;
    }

package _EXEC_;
    @_EXEC_::ISA = qw(_NODE_);
    sub __init__ {
        my $self = shift;
        $self->parent( shift() );
        $self->type( 'blkEXEC' );
        $self->expr( '' );
    }

    sub output_perl {
        my $self = shift;
        my %args = @_;
        my $depth = $args{'depth'} || 0;
        my $prepend = $self->__prepend__( $depth );
        my $prepend2 = $self->__prepend__( $depth + 1 );
        my $result = $prepend . "# EXEC BLOCK -- COULD BE DANGEROUS\n";
        $result .= $prepend2 . $self->expr . "\n";
        $result .= $prepend . "# END EXEC BLOCK\n";
        return $result;
    }

package _INC_;
    @_INC_::ISA = qw(_NODE_);
    sub __init__ {
        my $self = shift;
        $self->parent( shift() );
        $self->type( 'blkINC' );
        $self->filename( '' );
    }

    sub output_perl {
        my $self = shift;
        my %args = @_;
        my $depth = $args{'depth'} || 0;
        my $prepend = $self->__prepend__( $depth );

        # Get the template from the global parsed table.  Output the code,
        # but only output the part without functions.
        my $template = $self->parent->__get_parsed__( $self->filename );
        # Don't do the full output_perl function, which adds a package and
        # context.  Just output the code (remember, we are accessing a 
        # template here, not a node).
        return $template->output_perl_code( depth => $depth );
    }

#-------------------------------------------------------------------------------
# INIT
#-------------------------------------------------------------------------------
# Get back into the template package.
package HTML::CMTemplate;
use File::Spec;
use Cwd;

=pod

=head2 FUNCTIONS

I<new( %args )>

Creates an instance of the HTML::CMTemplate class.  Potentially takes several
parameters.

    parent: Template which immediately "owns" this template.  Should only be
        used internally.

    root: Template at the top of the tree.  Also internal use only.

    NOTE: NEVER use parent or root.  NEVER do it!  Don't!  Jerk.

    path: An array ref of file paths.  These paths will be searched when
        non-absolute template filenames are given.  Note that if a string
        is passed in instead of an arrayref, it will be treated as a single
        file path, not as a ':' or ';' delimited list of paths.  If it has
        illegal characters, the search will simply not work.

        NOTE that you do NOT need to include '.' explicitly.  It will always
        be checked FIRST before the listed directories.

    nocwd: 1 or 0.  Tells the path parser to leave cwd out of it.

=cut

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    $self->__debug__;
    $self->__init__(@_);
    return $self;
}

$HTML::CMTemplate::tagStart = '<?=';
$HTML::CMTemplate::tagEnd = '?>';
$HTML::CMTemplate::tagNameDefault = 'echo';

$HTML::CMTemplate::tagStartLen = length($HTML::CMTemplate::tagStart);
$HTML::CMTemplate::tagEndLen = length($HTML::CMTemplate::tagEnd);

$HTML::CMTemplate::CHECK_NONE = 0;
$HTML::CMTemplate::CHECK_STAT = 1;
# others should be added as necessary

sub __init__ {
    my $self = shift;
    $self->__debug__;
    # If this is the root template, it should NOT be passed a parent.  
    # Ever.  Period.  Don't ever, ever call the new function with a parent 
    # parameter.  Let this module do that for includes only.  You have been
    # warned.  Same goes for root.
    my %args = @_;
    $self->{parent} = $args{parent};
    $self->{root} = $args{root};
    $self->__set_path__( $args{path}, $args{nocwd} );

    # Make the path canonical (get rid of duplicates, make sure it is
    # not just a string, add the current working directory, etc).

    # This hashref holds the templates, indexed by module name.  This allows
    # the module to determine whether a template is up to date or not.
    # If the template is not up to date, then it needs to be reloaded.  
    # Otherwise, it should not be reloaded.

    # Note that the behavior of the reload function can be determined by setting
    # a variable in the object.  By default, it checks the stat of the file
    # every time a call is made to import_template.
    $self->{imported} = {};
    $self->{checkmode} = $HTML::CMTemplate::CHECK_STAT; # check file mod date

    # Reset temporary variables (make sure they exist)
    $self->__reset_temp__;
}

# Make sure all paths are absolute and exist.  Eliminate duplicates.  Add cwd.
sub __set_path__ {
    my $self = shift;
    my $path = shift;
    my $nocwd = shift || 0;

    my $r = ref( $path );
    if ($r ne 'ARRAY') {
        $path = (defined($path)) ? [$path] : [];
    }

    # Now we have an arrayref.
    # Go through each entry, making sure all pathnames are absolute.  Ignore
    # any that are not.  TODO: Do we die if they aren't?
    # Make sure the directories exist, dying if not (TODO: Should we die?)
    # Ignore duplicates (definitely do NOT die on duplicates).
    # Push the current working directory onto the front of the list.

    # Remember that
    #   "There is a difference between knowing the path and walking the path."
    #       - Morpheus

    my $rh_used = {}; # used path names
    unless ($nocwd) {
        # add the current working directory at the front.
        unshift @$path, cwd();
    }

    # Add the paths if they make sense.
    foreach my $d (@$path) {
        # Ignore relative paths
        my $canondir = File::Spec->canonpath( $d );
        unless (File::Spec->file_name_is_absolute( $canondir )) {
            warn "Path $canondir is not absolute: Ignoring";
            next;
        }
        # Force existence
        unless (-d $canondir) {
            die "Path $canondir (in path list) is not found.  Aborting.";
        }
        # ignore duplicates
        unless ($rh_used->{$canondir}) {
            # Add to the path list
            push @{$self->{path}}, $canondir;
            $rh_used->{$canondir} = 1;
        }
    }
}

sub __reset_temp__ {
    my $self = shift;
    $self->__debug__;

    # Tokenizing stuff
    $self->{strbuf} = '';
    $self->{parserintag} = 0;
    $self->{bufstart} = 0;
    $self->{buflen} = 0;
    $self->{tagstart} = 0;

    # Parsing stuff
    $self->{parentnode} = _TPL_->new( $self );
    $self->__push__( $self->{parentnode} );
    $self->{clean_defs} = [];
        # table of def tag parse trees.  Since all defs are in the global
        # scope, we put them into a table rather than just leaving
        # them in the tree.
        # This table is local to each template.
    $self->{deftable} = {};
        # global list of all def names
    $self->{deftableglobal} = {};
        # table of parsed templates.  Global and only accessed via __root__
    $self->{parsedtable} = {};

    # File stuff
    $self->{filename} = '';
    $self->{filemodtime} = '';
}

sub __reset_vars__ {
    my $self = shift;
    $self->{vars} = {};
}

sub __exists_file_package__ {
    my $self = shift;
    $self->__debug__(\@_);
    my ($file, $package) = @_;
    $self->__debug__( 
        "File Package Index: " . __file_package_index__( $file, $package ) );
    while (my ($key, $val) = each( %{$self->{imported}} )) {
        $self->__debug__( "$key = $val" );
    }
    return $self->{imported}->{__file_package_index__($file, $package)};
}

sub __add_file_package__ {
    my $self = shift;
    $self->__debug__(\@_);
    my ($file, $package, $includes, $mtime) = @_;
    $self->{imported}->{__file_package_index__( $file, $package )} =
        {mtime => $mtime, includes => $includes};
}

sub __file_package_index__ {
    my ($filename, $packagename) = @_;
    return "$filename:-:$packagename";
}

sub __file_package_rec__ {
    my $self = shift;
    my ($file, $package) = @_;

    return $self->{imported}->{__file_package_index__($file, $package)};
}

sub __file_package_includes__ {
    my $self = shift;
    my ($file, $package) = @_;
    my $rec = $self->__file_package_rec__($file, $package)->{includes};
}

sub __file_package_mtime__ {
    my $self = shift;
    my ($file, $package) = @_;

    my $rec = $self->{imported}->{__file_package_index__($file, $package)};
    return $rec->{mtime};
}

# Get the mtime of an included template file
sub __file_package_include_mtime__ {
    my $self = shift;
    my ($file, $package, $includefile) = @_;

    my $rec = $self->{imported}->{__file_package_index__($file, $package)};
    return $rec->{includes}->{$includefile};
}

sub __add_clean_defs__ {
    my $self = shift;
    my $ra_names = shift;
    my $r = ref($ra_names);
    if (!$r) {
        $ra_names = [$ra_names];
    }
    elsif ($r ne "ARRAY") {
        $self->__debug__( "BAD ref: " . $r );
        die "BAD ref in __add_clean_defs__";
    }
    foreach my $n (@$ra_names) {
        push @{$self->{clean_defs}}, "$_NODE_::defprepend$n";
    }
}

# Return the full path for this file, using the search path to find it.
sub __full_path__ {
    my $self = shift;
    my $filename = shift;

    # If this is an absolute path, just see if it exists.  Otherwise, try
    # to find it in the path.
    if (File::Spec->file_name_is_absolute( $filename )) {
        die "File $filename does not exist" unless -f $filename;
        return $filename;
    }
    # Find the file.  If it isn't in the path, it doesn't exist and we
    # die horrible deaths.
    my $fullpath = '';
    my $total_search_path = [@{$self->{path}}, @{$self->{temporary_path}}];
    foreach my $d (@$total_search_path) {
        my $curpath = File::Spec->catfile( $d, $filename );
        if (-f $curpath) {
            $fullpath = $curpath;
            last;
        }
    }
    if (!$fullpath) {
        die "File $filename not found in path: ".join(":",@$total_search_path);
    }
    return $fullpath;
}

# This creates a secondary path (a temporary one that is easily overwritten).
# Note that we don't have to clean it up because it is just plain set,
# not added to.
sub __temporary_path__ {
    my $self = shift;
    my $path = shift || [];
    $path = [$path] unless (ref($path) eq "ARRAY");
    $self->{temporary_path} = $path;
}

# Removes surrounding quotes.  Note that inner quotes need not be escaped.
sub __unquote_filename__ {
    my $self = shift;
    my $contents = shift;
    if ($contents =~ /^".*"$/) {
        $contents =~ s/^"(.*)"$/$1/; #remove surrounding quotes
    }
    elsif ($contents =~ /^'.*'$/) {
        $contents =~ s/^'(.*)'$/$1/; # remove surrounding quotes
    }
    return $contents;
}

# This checks to see if there is a circular dependency.  The theory here
# is that if one of the parents of this node is the same as this node, we
# have a circular dependency.  Simple.  The root node always returns FALSE
# since it HAS no parents.
sub __is_included__ {
    my $self = shift;
    $self->__debug__(\@_);
    my $filename = shift;

    if ($self->{filename} eq $filename) {
        $self->__debug__( "Self matches!" );
        return 1;
    }
    elsif ($self->__is_root__) {
        $self->__debug__( "No match and root node.  No more searching." );
        return 0;
    }
    else {
        $self->__debug__( "$filename not found, searching upward" );
        return $self->__parent__->__is_included__( $filename );
    }
}

sub __debug__ {
    my $self = shift;
    if ($DEBUG) {
        my $str = shift;
        $str = '*' unless defined($str);

        my $args = [];

        if (ref($str) eq "ARRAY") {
            $args = $str;
            $str = '';
        }
        # Find the stack depth - 1
        my $i = 0;
        while (my @a = caller(++$i)) {}
        $i -= 2; # remove the outside scope altogether ('use' at top level)
        my ($a,$b,$c,$funcname) = caller(1);

        # If a debug function ref has been specified, we just call that hook
        # and don't do anything else.
        if ($DEBUG_FUNCTION_REF) {
            $DEBUG_FUNCTION_REF->($funcname, $str, $args);
            return;
        }
        # Now we do default handling
        # If passed an array reference, this should display arguments.
        if (ref($str) eq "ARRAY") {
            $str = "Args: " . join( ", ", @$str );
        }
        if ($DEBUG_FILE_NAME) {
            open DEBUG_FILE, ">>" . $DEBUG_FILE_NAME;
        }
        else {
            *DEBUG_FILE = *STDERR;
        }
        print DEBUG_FILE (
            sprintf("%05d: ", $HTML::CMTemplate::debugline++) . 
            ". "x$i . "$funcname: " . $str . "\n"
            );
        if ($DEBUG_FILE_NAME) {
            close DEBUG_FILE;
        }
    }
}

# Stack manipulation for parsing
sub __top__ {
    my $self = shift;
    return $self->{nodestack}->[$self->{curframe}];
}

sub __size__ {
    my $self = shift;
    return $self->{curframe} + 1;
}

sub __pop__ {
    my $self = shift;
    pop @{$self->{nodestack}};
    my $ra_stack = $self->{nodestack};
    # make the current frame lookup faster.  This way the calculation is only
    # done once and the tricky reference manipulation is also done once.
    $self->{curframe} = $#$ra_stack;
}

sub __push__ {
    my $self = shift;
    my ($node) = @_;
    $self->{curframe} = push( @{$self->{nodestack}}, $node ) - 1;
}

sub __is_empty__ {
    my $self = shift;
    return $self->{curframe} < 0;
}

sub __end_block__ {
    my $self = shift;
    $self->__debug__;
    my $node = $self->__top__;
    $node->tpl(_TPL_->new( $self ));
    $self->__push__( $node->tpl );
}

# This is a subroutine so that we can avoid self-referential structures.
# We don't want the hassle of dealing with the root template pointing to
# itself, because that will kill the reference counting memory management,
# which is a BAD THING (tm).
# So, if the parent is undef, we return self.  Returning is safe.  Storing
# is not.  Remember that.  Return = Safe.  Store = Not.
sub __parent__ {
    my $self = shift;
    return $self->{parent} || $self;
}

# Similar to __parent__
sub __root__ {
    my $self = shift;
    return $self->{root} || $self;
}

# Is this the root template?
sub __is_root__ {
    return !defined( shift()->{parent} );
}

# Handles the deftable stuff
sub __push_def__ {
    my $self = shift;
    my $defnode = shift;
    $self->{deftable}->{$defnode->name} = $defnode;
    $self->__root__->{deftableglobal}->{$defnode->name} = 1;
}

sub __exists_def__ {
    my $self = shift;
    my $defname = shift;
    return ($self->{deftable}->{$defname}) ? 1 : 0;
}

sub __exists_def_global__ {
    my $self = shift;
    my $defname = shift;
    return $self->__root__->{deftableglobal}->{$defname};
}

sub __get_def__ {
    my $self = shift;
    my $defname = shift;
    return $self->{deftable}->{$defname};
}

# Handles raw include stuff
sub __add_raw__ {
    my $self = shift;
    my $filename = shift;
    my $text = shift;
    my $mtime = shift || 0;

    $self->__root__->{rawtable}->{$filename} = {text => $text, mtime => $mtime};
}

sub __exists_raw__ {
    my $self = shift;
    my $filename = shift;
    return ($self->__root__->{rawtable}->{$filename}) ? 1 : 0;
}

sub __get_raw__ {
    my $self = shift;
    my $filename = shift;
    return $self->__root__->{rawtable}->{$filename};
}
# Handles the parsed table stuff
sub __add_parsed__ {
    my $self = shift;
    my $filename = shift;
    my $template = shift;

    $self->__root__->{parsedtable}->{$filename} = $template;
}

sub __exists_parsed__ {
    my $self = shift;
    my $filename = shift;
    return ($self->__root__->{parsedtable}->{$filename}) ? 1 : 0;
}

sub __get_parsed__ {
    my $self = shift;
    my $filename = shift;
    return $self->__root__->{parsedtable}->{$filename};
}

# Returns the top node.  If it is not a template node, it dies with
# an error.  This is useful for requiring the top node to be a template
# node.  The type that is being added is sent in the argument list.
sub __top_TPL__ {
    my $self = shift;
    my $nodetype = shift || 'UNKNOWN';
    $self->__debug__;
    my $node = $self->__top__;
    return $node if $node->type eq 'TPL';

    my $errormessage = "$nodetype: TPL expected, but " . $node->type .
        " found\n";
    $self->__debug__( $errormessage );
    die( $errormessage );
}

# The next two functions are real work horses.  They do the actual parsing.
# The __process_block__ function is what does the tokenizing.  These guys build
# the parse tree as the tokens come in.
sub __process_tag__ {
    my $self = shift;
    $self->__debug__(\@_);
    my ($name, $contents) = @_;
    
    SWITCH: {
        'if' eq $name && do {
            $self->__onIF__( $contents );
            last SWITCH;
        };
        'elif' eq $name && do {
            $self->__onELIF__( $contents );
            last SWITCH;
        };
        'else' eq $name && do {
            $self->__onELSE__( $contents );
            last SWITCH;
        };
        'endif' eq $name && do {
            $self->__onENDIF__( $contents );
            last SWITCH;
        };
        'for' eq $name && do {
            $self->__onFOR__( $contents );
            last SWITCH;
        };
        'endfor' eq $name && do {
            $self->__onENDFOR__( $contents );
            last SWITCH;
        };
        'while' eq $name && do {
            $self->__onWHILE__( $contents );
            last SWITCH;
        };
        'endwhile' eq $name && do {
            $self->__onENDWHILE__( $contents );
            last SWITCH;
        };
        'def' eq $name && do {
            $self->__onDEF__( $contents );
            last SWITCH;
        };
        'enddef' eq $name && do {
            $self->__onENDDEF__( $contents );
            last SWITCH;
        };
        'call' eq $name && do {
            $self->__onCALL__( $contents );
            last SWITCH;
        };
        'inc' eq $name && do {
            $self->__onINC__( $contents );
            last SWITCH;
        };
        'rawinc' eq $name && do {
            $self->__onRAWINC__( $contents );
            last SWITCH;
        };
        'echo' eq $name && do {
            $self->__onECHO__( $contents );
            last SWITCH;
        };
        'break' eq $name && do {
            $self->__onBREAK__( $contents );
            last SWITCH;
        };
        'continue' eq $name && do {
            $self->__onCONTINUE__( $contents );
            last SWITCH;
        };
        'exec' eq $name && do {
            $self->__onEXEC__( $contents );
            last SWITCH;
        };
        'comment' eq $name && do {
            $self->__onCOMMENT__( $contents );
            last SWITCH;
        };
        $self->__debug__( "Unrecognized tag name: $name" );
        #XXX: Do we want to make the tags default to an echo expression,
        # or do we want to die with an unrecognized tag?  Probably better
        # to make the programmer disambiguate it.
#        $self->__debug__( "Treating $name as an 'echo' expression..." );
#        do {
#            $self->__onECHO__( $contents );
#            last SWITCH;
#        };
        die( "Unrecognized tag: $name\n" );
    }
}

sub __onIF__ {
    my $self = shift;
    $self->__debug__(\@_);
    my $contents = shift;

    my $has_colon = $contents =~ /^(.*):$/s;
    my $expr = $1;
    my $has_contents = $expr =~ /\S/;
    if (!$has_colon) {
        $self->__debug__( 
            "Invalid contents for an IF block (missing colon): $contents" );
        die "Invalid contents for an IF block (missing colon?): '$contents'\n";
    }
    if (!$has_contents) {
        $self->__debug__( 
            "Invalid contents for an IF block (missing expr): $contents" );
        die "Invalid contents for an IF block (missing expr?): '$contents'\n";
    }

    # When we run into one of these, we really need to be inside of
    # a template since it is a beginning block type.
    my $node = $self->__top_TPL__( 'IF' );

    # Create an IF block and stick it in there.  Create a template as well.
    my $ifnode = _IF_->new( $self );
    # Fill it up with stuff.
    $ifnode->expr( $expr );
    # Add it to the current node:
    $node->blk( $ifnode );
    # Push both nodes onto the stack.
    $self->__push__( $ifnode );
    $self->__push__( $ifnode->tpl );
    # Thus we leave expecting a template.
    $self->__debug__( "IF Block added successfully.  Stack size: " . 
        $self->__size__ );
}

sub __onELIF__ {
    my $self = shift;
    $self->__debug__(\@_);
    my $contents = shift;

    my $has_colon = $contents =~ /^(.*):$/s;
    my $expr = $1;
    my $has_contents = $expr =~ /\S/;
    if (!$has_colon) {
        $self->__debug__( 
            "Invalid contents for an ELIF block (missing colon): $contents" );
        die "Invalid contents for an ELIF block (missing colon?): '$contents'\n";
    }
    if (!$has_contents) {
        $self->__debug__( 
            "Invalid contents for an ELIF block (missing expr): $contents" );
        die "Invalid contents for an ELIF block (missing expr?): '$contents'\n";
    }
    # When this tag comes in, we should be inside of a template.
    # The way that things are set up, we could be inside of multiple levels
    # of templates, so we need to pop them off until we get to the parent IF
    # block.  If we get through all of the templates and find that we are not
    # inside of an IF block, it is an error.

    # Pop off all templates.  There should always be at least one.
    my $node = $self->__top__;
    while( !$self->__is_empty__ && ($node->type eq 'TPL') ) {
        $self->__pop__;
        $node = $self->__top__;
    }

    # If the node that is left over is not an IF block (or an ELIF),
    # we have a problem.
    # Otherwise, go ahead and process this elif as a nextif.
    if ($node->type eq 'blkIF' || $node->type eq 'blkELIF') {
        my $elifnode = _ELIF_->new( $self );
        # Fill it up with stuff
        $elifnode->expr( $expr );
        # Add it to the current node.
        $node->nextif( $elifnode );
        # Push both nodes onto the stack.
        $self->__push__( $elifnode );
        $self->__push__( $elifnode->tpl );
        $self->__debug__( "ELIF Block added successfully.  Stack size: " . 
            $self->__size__ );
    }
    else {
        $self->__debug__( 
            'ELIF found with wrong parent block: ' . $node->type);
        die( 'ELIF found with wrong parent block: '. $node->type . "\n");
    }
}

sub __onELSE__ {
    my $self = shift;
    $self->__debug__(\@_);
    my $contents = shift;

    # TODO: Throw an error if there is an expression in this.

    unless ($contents =~ /^(\s*):(\s*)$/s ) {
        $self->__debug__('Invalid contents for an ELSE block (missing colon?)');
        die "Invalid contents for an ELSE block (missing colon?):" .
            "'$contents'\n";
    }
    # When this tag comes in, we should be inside of a template.
    # This template's direct or indirect parent should be an IF, ELIF, or
    # FOR block (since else can come after for).  We pop off all templates
    # until we reach one of these.

    # Pop off all templates.  There should always be at least one.
    my $node = $self->__top__;
    while( !$self->__is_empty__ && ($node->type eq 'TPL') ) {
        $self->__pop__;
        $node = $self->__top__;
    }

    # If the node that is left over is not an IF, ELIF, or FOR block,
    # we have a problem.  Otherwise, go ahead and process this else
    # appropriately.

    if ($node->type eq 'blkIF' || $node->type eq 'blkELIF') {
        $self->__debug__( 'ELSE block inside of IF type block' );
        my $elsenode = _ELSE_->new( $self );
        # Add it to the current node.
        $node->nextif( $elsenode );
        # Push both nodes onto the stack.
        $self->__push__( $elsenode );
        $self->__push__( $elsenode->tpl );
        $self->__debug__( "ELSE Block added to IF.  Stack size: " . 
            $self->__size__ );
    }
    elsif ($node->type eq 'blkFOR') {
        $self->__debug__( 'ELSE block inside of FOR type block' );
        my $elsenode = _ELSE_->new( $self );
        # Add it to the current node.
        $node->default( $elsenode );
        # Push both nodes onto the stack.
        $self->__push__( $elsenode );
        $self->__push__( $elsenode->tpl );
        $self->__debug__( "ELSE Block added to FOR.  Stack size: " . 
            $self->__size__ );
    }
    else {
        $self->__debug__(
            'ELSE found with wrong parent block: ' . $node->type);
        die( 'ELSE found with wrong parent block: ' . $node->type . "\n");
    }
}

sub __onENDIF__ {
    my $self = shift;
    $self->__debug__(\@_);
    my $contents = shift;

    # TODO: Throw an error if there are contents.

    # We should be in a template here.  However, ultimately there should
    # be a blkIF parent.  We just pop stuff off the stack until we get to the
    # parent of that IF block.

    $self->__debug__( "Stack size before removing TPL, blkELSE, and blkELIF: " .
        $self->__size__ );
    my $type = $self->__top__()->type;
    while( $type eq 'TPL' || $type eq 'blkELSE' || $type eq 'blkELIF' ) {
        $self->__pop__;
        $type = $self->__top__()->type;
    }
    $self->__debug__( "Stack size after removal: " . $self->__size__ );

    # Now we should be inside of an IF block.  Pop it off and return.
    if ($type eq 'blkIF') {
        $self->__debug__( "Found and removed the parent IF block: expr=" .
            $self->__top__->expr );
        $self->__pop__;
        # Now we have stripped it down to the parent template.  This template
        # might already have text in it, so we need to add another template
        # to it.  Since the template definition is TEXT + BLK + TPL, and
        # we just finished a block, we add another template and move stuff
        # up.
        $self->__end_block__;
    }
    else {
        $self->__debug__( "ENDIF: Popped all templates and internal IF blocks ".
            "and found a $type block instead of an IF block." );
        die( "ENDIF: No enclosing IF block found.  $type found instead.\n" );
    }
}

sub __onFOR__ {
    my $self = shift;
    $self->__debug__(\@_);
    my $contents = shift;

    # We need to check the contents against the definition of a FOR block.
    # If they are not of the form <varname> in <listexpr> then we can't use it.

    unless( $contents =~ /^\$?(\w+)\s+in\s+(.*):$/s ) {
        $self->__debug__( "Invalid contents for a FOR block: $contents" );
        die( "Invalid contents for a FOR block (missing 'in'?): $contents\n" );
    }
    my ($varname, $listexpr) = ($1, $2);
    $self->__debug__( 
        "Found correct contents: varname=$varname, list=$listexpr" );

    # When we run into one of these, we really need to be inside of
    # a template since it is a beginning block type.
    my $node = $self->__top_TPL__( 'FOR' );
    # Create a FOR block and stick it in there.  Create a template as well.
    my $fornode = _FOR_->new( $self );
    # Fill it up with stuff.
    $fornode->varname( $varname );
    $fornode->listexpr( $listexpr );
    # Add it to the current node:
    $node->blk( $fornode );
    # Push both nodes onto the stack.
    $self->__push__( $fornode );
    $self->__push__( $fornode->tpl );
    # Thus we leave expecting a template.
    $self->__debug__( "FOR block successfully added.  New stack size: " .
        $self->__size__ );
}

sub __onENDFOR__ {
    my $self = shift;
    $self->__debug__(\@_);
    my $contents = shift;

    # TODO: Throw an error if there are contents.

    # We need to pop off all templates and ELSE blocks.  When we are
    # done, we should have reached a FOR block.  If not, it's an error.
    $self->__debug__( "Stack size before removing TPL, and blkELSE: " .
        $self->__size__ );
    my $type = $self->__top__()->type;
    while( $type eq 'TPL' || $type eq 'blkELSE' ) {
        $self->__pop__;
        $type = $self->__top__()->type;
    }
    $self->__debug__( "Stack size after removal: " . $self->__size__ );

    # Now we should be inside of a FOR block.  Pop it off and return.
    if ($type eq 'blkFOR') {
        $self->__debug__( "Found and removed the parent FOR block: " .
            "varname=" . $self->__top__->varname . " list=" .
            $self->__top__->listexpr );
        $self->__pop__;
        # Now we have stripped it down to the parent template.  This template
        # might already have text in it, so we need to add another template
        # to it.  Since the template definition is TEXT + BLK + TPL, and
        # we just finished a block, we add another template and move stuff
        # up.
        $self->__end_block__;
    }
    else {
        $self->__debug__( "ENDFOR: Popped all templates and ELSE blocks ".
            "and found a $type block instead of a FOR block." );
        die( "ENDFOR: No enclosing FOR block found.  $type found instead.\n" );
    }
}

sub __onWHILE__ {
    my $self = shift;
    $self->__debug__(\@_);
    my $contents = shift;

    # We need to check the contents against the definition of a FOR block.
    # If they are not of the form <varname> in <listexpr> then we can't use it.

    unless( $contents =~ /^(.*):$/s ) {
        $self->__debug__( 'Invalid contents for a WHILE block' );
        die( "Invalid contents for a WHILE block: '$contents'\n" );
    }

    my $expr = $1;
    $self->__debug__( "Found correct contents: expr=$expr" );

    # When we run into one of these, we really need to be inside of
    # a template since it is a beginning block type.
    my $node = $self->__top_TPL__( 'WHILE' );
    # Create a WHILE block and stick it in there.  Create a template as well.
    my $whilenode = _WHILE_->new( $self );
    # Fill it up with stuff.
    $whilenode->expr( $expr );
    # Add it to the current node:
    $node->blk( $whilenode );
    # Push both nodes onto the stack.
    $self->__push__( $whilenode );
    $self->__push__( $whilenode->tpl );
    # Thus we leave expecting a template.
    $self->__debug__( "WHILE block successfully added.  New stack size: " .
        $self->__size__ );
}

sub __onENDWHILE__ {
    my $self = shift;
    $self->__debug__(\@_);
    my $contents = shift;

    # TODO: Throw an error if there are contents.

    # We need to pop off all templates and ELSE blocks.  When we are
    # done, we should have reached a FOR block.  If not, it's an error.
    $self->__debug__( "Stack size before removing TPL: " .  $self->__size__ );
    my $type = $self->__top__()->type;
    while( $type eq 'TPL' ) {
        $self->__pop__;
        $type = $self->__top__()->type;
    }
    $self->__debug__( "Stack size after removal: " . $self->__size__ );

    # Now we should be inside of a WHILE block.  Pop it off and return.
    if ($type eq 'blkWHILE') {
        $self->__debug__( "Found and removed the parent WHILE block: " .
            "expr=" . $self->__top__->expr );
        $self->__pop__;
        # Now we have stripped it down to the parent template.  This template
        # might already have text in it, so we need to add another template
        # to it.  Since the template definition is TEXT + BLK + TPL, and
        # we just finished a block, we add another template and move stuff
        # up.
        $self->__end_block__;
    }
    else {
        $self->__debug__( "ENDWHILE: Popped all templates".
            "and found a $type block instead of a WHILE block." );
        die "ENDWHILE: No enclosing WHILE block found.  $type found instead.\n";
    }
}

sub __onDEF__ {
    my $self = shift;
    $self->__debug__(\@_);
    my $contents = shift;

    unless( $contents =~ /^(\w+)\s*\((.*)\)\s*:$/s ) {
        $self->__debug__( 'Invalid contents for a DEF block (needs to be "' .
            'name (arglist):")');
        die "Invalid contents for a DEF block (should be 'name (arglist)'): " .
            "'$contents'\n";
    }
    my ($name, $argexpr) = ($1, $2);
    # Get the argument list into an appropriate format.
    my @args = split( ",", $argexpr );
    foreach my $arg (@args) {
        $arg =~ s/^\s*(\w+)\s*$/$1/;
    }
    # When we run into one of these, we really need to be inside of
    # a template since it is a beginning block type.
    my $node = $self->__top_TPL__( 'DEF' );

    # Create a DEF block and stick it in there.  Create a template as well.
    my $defnode = _DEF_->new( $self );
    # Fill it up with stuff.
    $defnode->name( $name );
    $defnode->argnames( \@args );
    # Add it to the current node:
    $node->blk( $defnode );
    # Push both nodes onto the stack.
    $self->__push__( $defnode );
    $self->__push__( $defnode->tpl );
    # make sure that we add this to the clean names list.
    $self->__add_clean_defs__( $name );
    # Thus we leave expecting a template.
    $self->__debug__( "DEF Block added successfully.  Stack size: " . 
        $self->__size__ );
}

sub __onENDDEF__ {
    my $self = shift;
    $self->__debug__(\@_);
    my $contents = shift;

    # TODO: Throw an error if there are contents.

    # TRICKY STUFF AHEAD!!
    # When se see an enddef tag, we not only pop off all of the templates,
    # but we also remove this subtree from the main parse tree and place
    # it into the local def table.  That keeps the defs separate from the
    # rest of the code, which is as it should be.

    # We need to pop off all templates.  When we are
    # done, we should have reached a DEF block.  If not, it's an error.
    $self->__debug__( "Stack size before removing TPL: " . $self->__size__ );
    my $type = $self->__top__()->type;
    while( $type eq 'TPL' ) {
        $self->__pop__;
        $type = $self->__top__()->type;
    }
    $self->__debug__( "Stack size after removal: " . $self->__size__ );

    # Now we should be inside of a DEF block.  Pop it off, remove
    # it from the tree, and place it in the deftable.
    if ($type eq 'blkDEF') {
        $self->__debug__( "Found and removed the parent DEF block: " .
            "name=" . $self->__top__->name . " argnames=" .
            join( ", ", @{$self->__top__->argnames} ) );
        $self->__pop__;
        # Now we have the parent node of the def.  The def block is the 'blk'
        # parameter of this template node.  Since we don't want defs inside
        # of the main code, we remove the def block and its subtree and
        # place it into the defs table.
        my $defblk = $self->__top__->blk;
        # remove the subtree (undefine it)
        $self->__top__->blk( undef );
        if ($self->__exists_def__( $defblk->name )) {
            $self->__debug__( "DEF " . $defblk->name . 
                " already exists in this template!  Aborting.");
            die "Attempted to redefine def '" . $defblk->name . 
                "' inside of its own template.  Giving up.\n";
        }
        elsif ($self->__exists_def_global__( $defblk->name )) {
            $self->__debug__( "DEF " . $defblk->name .
                " already exists in another template!  Aborting.");
            die "Attempted to redefine def '" . $defblk->name .
                "' inside of " . $self->{filename} . ".  Bad programmer!\n";
        }
        $self->__push_def__( $defblk );
        
        # Now we have stripped it down to the parent template.  This template
        # might already have text in it, so we need to add another template
        # to it.  Since the template definition is TEXT + BLK + TPL, and
        # we just finished a block, we add another template and move stuff
        # up.
        $self->__end_block__;
    }
    else {
        $self->__debug__( "ENDDEF: Popped all templates ".
            "and found a $type block instead of a DEF block." );
        die( "ENDDEF: No enclosing DEF block found.  $type found instead.\n" );
    }
}

sub __onCALL__ {
    my $self = shift;
    $self->__debug__(\@_);
    my $contents = shift;

    unless( $contents =~ /^(\w+)\s*\((.*)\)\s*$/s ) {
        $self->__debug__( "CALL: Improperly formed contents: $contents" );
        die( "CALL: Improperly formed contents: $contents\n" );
    }
    my ($name, $argexpr) = ($1, $2);

    # NOTE: Since this is both a beginning AND ending block, we don't
    # push it onto the stack at all.  We DO, however, push a new template
    # onto the stack, so we call __end_block__.

    # We should be in a template here.  If not, there is a problem.
    my $node = $self->__top_TPL__( 'CALL' );
    # Create a new node and add it to the tree.
    my $callnode = _CALL_->new( $self );
    $callnode->name( $name );
    $callnode->argexpr( $argexpr );
    $node->blk( $callnode );
    # DO NOT push it onto the stack.  Simply call __end_block__ since
    # this tag both begins and ends a block.
    $self->__end_block__;
}

sub __onINC__ {
    my $self = shift;
    $self->__debug__(\@_);
    my $filename = $self->__full_path__($self->__unquote_filename__(shift()));

    # Is this file included by its collective ancestry?  If so, die horribly.
    if ($self->__is_included__($filename)) {
        die "Recursive inclusion detected: $filename eventually"
            . " includes itself\n";
    }

    # Create the include structure and insert it into the tree.
    my $node = $self->__top_TPL__( 'INC' );
    my $incnode = _INC_->new( $self );
    $incnode->filename( $filename );
    $node->blk( $incnode );
    $self->__end_block__; # both beginning and ending tag.

    # Now we check for it already being parsed.
    # If the template has already been parsed, we don't do that again.
    # Otherwise we go ahead and parse it.
    unless ($self->__exists_parsed__( $filename )) {
        my $t = new HTML::CMTemplate(
            parent => $self,
            root => $self->__root__,
            path => $self->{path},
            nocwd => 1, # no need to find cwd again
            );
        $t->open_file( $filename, $self->{temporary_path} );
        # Add it so we don't do it again.
        $self->__add_parsed__( $filename, $t );
    }

    # This node has a filename, which is enough to get at the parsed template,
    # so we are finished, now.
}

sub __onRAWINC__ {
    my $self = shift;
    $self->__debug__(\@_);
    my $filename = $self->__full_path__($self->__unquote_filename__(shift()));

    # Note that because this is a raw file and no includes are parsed,
    # we can just open it, suck out the text, and close it up.  All of it
    # should go into a text tag.

    # Create the include structure and insert it into the tree.
    my $node = $self->__top_TPL__( 'RAWINC' );
    my $rawnode = _TPL_->new( $self );

    my $text = '';
    my $mtime = 0;
    if ($self->__exists_raw__( $filename )) {
        $self->__debug__( 'Raw file $filename already exists: getting it' );
        my $rawrec = $self->__get_raw__( $filename );
        $text = $rawrec->{text};
        $mtime = $rawrec->{mtime};
    }
    else {
        $self->__debug__( 'Raw file $filename has not been read: getting it' );
        # Get the mtime of this file for future reference.
        my $filestat = stat($filename);
        $mtime = $filestat->mtime;
        # Open and suck the text out.
        local( *FILE );
        open FILE, "<$filename" || do {
            $self->__debug__( 'Failed to open raw file $filename: $!' );
            die "Failed to open raw include: $filename\n";
        };
        local $/;
        undef $/;
        $text = <FILE>;
        close FILE;
    }

    $rawnode->text( $text );
    $node->blk( $rawnode );
    # Note that I didn't push anything onto the stack.  This block is
    # just a template with text in it.  That is legal, though unusual (this
    # is the only case where that happens).  I COULD just add to the existing
    # text in the current template node, but I opted to create a separate
    # block and treat it like any other tag for completeness and generality's
    # sake.
    # The __end_block__ thing here inserts a new empty template into this
    # template's tpl variable, enabling us to start looking for text once
    # again.
    $self->__end_block__; # both beginning and ending tag.
    # Keep track of this and only open it again if needed.
    $self->__add_raw__( $filename, $text, $mtime );
}

sub __onECHO__ {
    my $self = shift;
    $self->__debug__(\@_);
    my $contents = shift;

    my $node = $self->__top_TPL__( 'ECHO' );
    my $echonode = _ECHO_->new( $self );
    $echonode->expr( $contents );
    $node->blk( $echonode );
    $self->__end_block__;
}

sub __onBREAK__ {
    my $self = shift;
    $self->__debug__(\@_);
    my $contents = shift;

    my $node = $self->__top_TPL__( 'BREAK' );
    my $breaknode = _BREAK_->new( $self );
    $node->blk( $breaknode );
    $self->__end_block__;
}

sub __onCONTINUE__ {
    my $self = shift;
    $self->__debug__(\@_);
    my $contents = shift;

    my $node = $self->__top_TPL__( 'CONTINUE' );
    my $continuenode = _CONTINUE_->new( $self );
    $node->blk( $continuenode );
    $self->__end_block__;
}

sub __onEXEC__ {
    my $self = shift;
    $self->__debug__(\@_);
    my $contents = shift;
    
    my $node = $self->__top_TPL__( 'EXEC' );
    my $execnode = _EXEC_->new( $self );
    $execnode->expr( $contents );
    $node->blk( $execnode );
    $self->__end_block__;
}

sub __onCOMMENT__ {
    my $self = shift;
    $self->__debug__(\@_);
    my $contents = shift;

    # NOP: Just eat the tag
}

sub __process_cdata__ {
    my $self = shift;
    $self->__debug__(\@_);
    my ($cdata) = @_;

    # If we are in a TPL node, then we should just add the text to the current
    # text in that node.  Otherwise, something went wrong.  We should always
    # be prepared to receive text when it comes.
    my $node = $self->__top_TPL__( 'text' );
    $node->text( $node->text . $cdata );
    $self->__debug__( "New CDATA length: " . length( $node->text ) );
}

# This function takes a chunk of text and decides what to do with it.  It works
# in a similar fashion to expat, which will take text until you quit giving it
# to it.  It simply looks for tags and data in between.  When a complete tag is
# found, it passes the information off to a function to have it processed.
# When cdata is found (character data) it dumps it out.  Note that there is
# no guarantee that the cdata will come back all at once.  This function does
# not do any output buffering on cdata.  If it isn't in a tag, it gives you
# everything that it currently has, whether it is the entire set of text
# or not.
sub __process_block__ {
    my $self = shift;
    $self->__debug__(\@_);
    my $str =  shift;

    # This function only looks for tokens and keeps track of whether or not
    # it is inside of a tag.  Once a complete tag has been found, it will
    # send the name of that tag and all remaining text inside of it to the
    # appropriate function.
    # If it reaches the end of a buffer and is not inside of a tag, it
    # accumulates all text and sends it out to the cdata function.

    # Append to the buffer and continue where we left off.
    $self->{strbuf} .= $str;

    # Note that if we are already inside of a tag, we search from a few
    # characters before the boundary.  Otherwise, we search from the beginning
    # of the unprocessed buffer.
    my $curpos = ($self->{parserintag}) ? 
        $self->{buflen} - $HTML::CMTemplate::tagEndLen + 1: 
        $self->{bufstart};
    $self->__debug__( "Curpos: $curpos" );

    $self->{buflen} += length($str);
    $self->__debug__( "New Buflen: " . $self->{buflen} );
    while ($curpos < $self->{buflen}) {
        # In a tag.  Get the rest of it, if possible, and send it out for
        # processing.
        if ($self->{parserintag}) {
            $self->__debug__( 'STATE: inside of a tag' );
            # Try to find the end of the tag.
            my $pos = index( $self->{strbuf}, $HTML::CMTemplate::tagEnd, $curpos );
            $self->__debug__( "End tag position: $pos" );
            # If we found it, we get all of the stuff inside of the tag and dump
            # it into a function.
            if ($pos > -1) {
                # Found the end tag.  Send it on its way.
                # Get the internals of the tag:
                my $start = $self->{tagstart} + $HTML::CMTemplate::tagStartLen;
                my $tag = substr( $self->{strbuf}, $start, $pos - $start );
                if ($tag =~ m/^(\w+)(\s+(.*?)\s*)?$/s) {
                    # $1 contains the name of the tag
                    # $3 contains the rest of the tag's text, if there is any.
                    # TODO: Make the function call configurable by a hash or
                    # something.
                    $self->__process_tag__($1, (defined($3))?$3:'');
                    # Once the tag is processed, we are no longer in a tag.
                    # Move the current position to where we left off and
                    # continue the loop.
                }
                # Special case for block tags with no expression, like 'else'
                elsif ($tag =~ m/^(\w+)\s*:\s*$/s) {
                    $self->__debug__(
                        "Found an expressionless block tag: $tag" );
                    $self->__process_tag__($1, ':');
                }
                else {
                    # The tag was not of the format <?=name expression?>
                    # So, we take everything inside of the <?= and ?> and
                    # treat it like it was the expression for the default tag.
                    # The default tag is set up to be 'echo' by default.
                    $self->__debug__( "Found a shortcut tag: $tag" );
                    $self->__process_tag__(
                        $HTML::CMTemplate::tagNameDefault, $tag);
                }
                $self->{parserintag} = 0;
                $curpos = $pos + $HTML::CMTemplate::tagEndLen;
                # Check that the next character is not an endline.  If it is,
                # we need to eat it.
                # TODO: What happens on Windows?  Do we need to move it two?
                $curpos++ if (substr($self->{strbuf}, $curpos, 1) eq "\n");
                # Important to move up the bufstart flag.  We have, after all,
                # used up the buffer to this point.
                $self->{bufstart} = $curpos;
            }
            else {
                # No ending tag found.  We need to continue accumulating buffer.
                last;
            }
        }
        # Not in a tag.  Search for a starting tag or something that looks
        # like it might be one.  Send out all text.  If a tag is found,
        # we need to put ourselves into a tag state and set the tagstart
        # index.
        else {
            $self->__debug__( "STATE: Not in a tag" );
            # NOTE: There is a tricky boundary case here.  If the start tag
            # is spanning buffer boundaries (this usually won't happen,
            # especially if the file is read in one line at a time, but it
            # will definitely happen if it is read in arbitrary sized chunks)
            # it could get missed by the parser.  (A full substring match will
            # fail until the entire tag is seen.)  So, when getting ready
            # to spit out text, we need to check back a few characters for
            # the first character of a start tag.  If it is there and it is
            # not escaped somehow, we only send out the text up to that
            # character.  We then defer searching for the start tag until
            # the next section of buffer is read in.
            my $pos = index( $self->{strbuf}, $HTML::CMTemplate::tagStart, $curpos);
            $self->__debug__( "Start tag position: $pos" );
            # If we found a start tag, we need to dump the text out and
            # set the tag state.  TODO: Check for escaped tags!
            if ($pos > -1) {
                # Found the start tag.  Change state and get out.
                $self->{parserintag} = 1;
                $self->{tagstart} = $pos;
                if ($pos > $curpos) {
                    $self->__process_cdata__( 
                        substr( $self->{strbuf}, $curpos, $pos - $curpos )
                        );
                    $curpos = $pos;
                }
                # exhausted our buffer to this point.
                $self->{bufstart} = $curpos;
            }
            else {
                # No start tag found.  Double check that the first character
                # of the tag is not in the end of the buffer somewhere.  If it
                # is, then send out the text up to that character.  Otherwise,
                # send everything out as text.
                my $firstchar = substr( $HTML::CMTemplate::tagEnd, 0, 1 );
                my $fpos = index( 
                    $self->{strbuf},
                    $firstchar,
                    $self->{buflen} - $HTML::CMTemplate::tagEndLen + 1
                    );
                # If nothing like a tag was found, set the position to be
                # the character after the end of the buffer.  Otherwise,
                # use the position of the tag character.
                $fpos = ($fpos > -1) ? $fpos : $self->{buflen};
                $self->__process_cdata__(
                    substr( $self->{strbuf}, $curpos, $fpos - $curpos )
                    );
                $curpos = $fpos;
                $self->{bufstart} = $curpos;
            }
        }
    }

    # We need to do some boundary checking here.  If, for example, the bufstart
    # flag is beyond the end of the buffer, we should just erase the buffer.
    # It's utility is exhausted.
    # Otherwise, we need to determine whether it makes sense to kill off part
    # of the buffer.
    if ($self->{bufstart} > 0) {
        $self->__debug__( "Start of buffer not at the beginning.  Reducing." );
        if ($self->{bufstart} >= $self->{buflen}) {
            $self->__debug__( "Buffer completely exhausted.  Resetting." );
            # Buffer is exhausted.  Reset everyone.
            $self->{bufstart} = 0;
            $self->{strbuf} = '';
            $self->{tagstart} = 0;
            $self->{buflen} = 0;
        }
        else {
            $self->__debug__( "Buffer partially exhausted.  Resetting." );
            # Buffer is at least partially exhausted.  No point in keeping
            # the unused portions around.  XXX: Do we need to hold off on this
            # case?  Should we only kill it if the remaining portion is smaller
            # than the unused portion?  What kind of metric should determine
            # this?
            my $start = $self->{bufstart};
            $self->{bufstart} = 0;
            $self->{buflen} -= ($start + 1);
            $self->{tagstart} -= $start;
            $self->{strbuf} = substr( $self->{strbuf}, $start );
            $self->__debug__( "New buffer length: " . $self->{buflen} );
        }
    }
}
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
# USER SPACE STUFF
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
=pod

I<get_includes()>

Returns an arrayref of included files.

=cut

sub get_includes() {
    my $self = shift;
    my @includes = (keys(%{$self->{parsedtable}}), keys(%{$self->{rawtable}}));
    return \@includes;
}

=pod

I<open_file( $filename, $path )>

Takes one or two parameters.
This function looks for the indicated file and parses it
into an internal structure.  Once this is done, it is capable of outputting
perl code or importing an indicated package with said code in the output
function.  The file is looked for in the path specified during template
creation.

Note that even if a relative filename is passed in (relative to any part
of the path, including '.') the filename will be converted to an absolute path
internally.  This is the way that infinite recursion is detected and
templates are never parsed more than once.

=cut

sub open_file {
    my $self = shift;
    my $filename = shift;
    my $path = shift;

    # Since the path may already be augmented, don't overwrite it
    # by doing it again unless something other than undef was passed
    # in.
    $self->__temporary_path__($path) if defined($path);

    # A new file should not have to share a tree with an old one.
    $self->__reset_temp__;

    my $fullpath = $self->__full_path__( $filename );

    my $sb = stat( $fullpath );
    $self->{filename} = $fullpath;
    $self->{filemodtime} = $sb->mtime;

    # Load the file.
    my $line = 0;
    local(*FILE);
    open( FILE, "<$fullpath" ) || die "Failed to open $fullpath\n";
    while( <FILE> ) {
        ++$line;
        eval {
            $self->__process_block__( $_ );
        };
        if ($@) {
            die "PARSE ERROR in '$filename', line $line:\n\t$@\n";
        }
    }
    close( FILE );
}

=pod

I<import_template( %args )>

Open the file, parse it, and import the indicated variables.
This will leave the client with an imported package that can be used
to generate output.  This does not actually call the output function!  That
would be too confining.

The reason that this function exists is that it is by far the most used
operation.  The most frequent need when dealing with templates is to open
them up and import them into a namespace, including some predefined variables
that are well known.  This allows one function call to replace several.

The arguments to this function are supposed to be named and are as follows:

=over 4

=item *

'filename' => name of file

=item *

'packagename' => name of package into which the code is imported

=item *

'path' => arrayref of directories to add to the main path just for this import

=item *

'warn' => if defined, turns warnings on in the generated module

=item *

'importrefs' => optional arrayref of hashrefs to import into the namespace

=item *

'importclean' => optional arrayref of hashrefs to import into the clean space

=back

=cut
sub import_template {
    my $self = shift;
    $self->__debug__(\@_);
    my %args = @_;
    # Arguments expected:
    # required: filename
    # required: packagename
    # optional: an array of hashrefs to be imported called 'importrefs'
    # optional: an array of hashrefs to be imported called 'importclean'
    # optional: a temporary search path arrayref.

    die "No filename specified" unless defined( $args{'filename'} );
    die "No package name specified" unless defined( $args{'packagename'} );

    $self->__temporary_path__($args{path});

    my $filename = $self->__full_path__($args{'filename'});
    my $packagename = $args{'packagename'};
    my $parent = $args{'parent'};
    my $fstat = stat( $filename ) || die "Failed to stat file $filename";
    my $mtime = $fstat->mtime;

    $self->__debug__( "Stat succeeded for $filename" );

    # Here we check to see that we should actually import this thing.  If
    # the package and filename already exist in our list, we don't import them
    # unless the modified date and time has changed.
    # Check that this file/package combination exists in the list of imported
    # templates.  If it does, then we check different criterion based on the
    # user settings.  If it doesn't, we import it always.
    if ($self->{checkmode} == $HTML::CMTemplate::CHECK_STAT) {
        $self->__debug__( "Mode is CHECK_STAT" );
        if ($self->__exists_file_package__( $filename, $packagename )) {
            $self->__debug__( 
                "Filename/packagename combo exists: $filename, $packagename" );
            my $oldtime = 
                $self->__file_package_mtime__( $filename, $packagename );
            $self->__debug__( "Old mtime: $oldtime" );
            if ($oldtime == $mtime) {
                $self->__debug__( 'root template up-to-date (CHECK_STAT)' );
                # Now we check each of the includes.  If any of them are
                # out of date, we carry on, otherwise, we deem the import
                # unnecessary.
                my $includes =
                    $self->__file_package_includes__($filename, $packagename);
                my $inc_out_of_date = 0;
                while( my ($incname, $oldincmtime) = each (%$includes)) {
                    my $incstat = stat($incname);
                    # Did we find one that's out of date?  If so, reimport.
                    if ($incstat->mtime != $oldincmtime) {
                        $self->__debug__(
                            "Found an include file ($incname) out of date"
                            );
                        $inc_out_of_date = 1;
                        last;
                    }
                }
                return unless $inc_out_of_date; # don't import.  Not needed.
            }
        }
    }
    $self->__debug__( 'Import proceeding (deemed necessary)' );

    # NOTE that we have two kinds of namespaces.  We have a 'dirty'
    # namespace, which can be cleaned up with the cleanup_namespace function,
    # and we have a 'clean' namespace, which is left alone by that function.
    # We can import variables into either namespace, since some will
    # make sense to NOT clean up when we want to remove sensitive information.
    my $ra_cleanref = $args{'importclean'};
    my $ra_dirtyref = $args{'importrefs'};

    # make sure we have an array of hashrefs, not a single hashref.
    # Actually, this makes it possible to pass in a single hashref
    # instead of an array of one hashref in the degenerate case, which
    # will probably be fairly common.
    if (defined( $ra_cleanref ) && (ref( $ra_cleanref ) eq  'HASH')) {
        $ra_cleanref = [$ra_cleanref];
    }
    if (defined( $ra_dirtyref ) && (ref( $ra_dirtyref ) eq  'HASH')) {
        $ra_dirtyref = [$ra_dirtyref];
    }

    # Now, we open the file, import the package, and import the hashrefs.
    $self->open_file( $filename );
    $self->import_package( $packagename, $args{warn} );

    # Import refs into the 'clean' namespace (cannot be cleaned up easily)
    if (defined( $ra_cleanref )) {
        foreach my $rh (@$ra_cleanref) {
            eval( "${packagename}::import_hashref( \$rh, 1 )" );
            if ($@) {
                die "EVAL ERROR: ${packagename}::import_hashref (clean) " .
                    "failed: $@\n";
            }
        }
    }
    # Import refs into the 'dirty' namespace (can be cleaned up)
    if (defined( $ra_dirtyref )) {
        foreach my $rh (@$ra_dirtyref) {
            eval( "${packagename}::import_hashref( \$rh, 0 )" );
            if ($@) {
                die "EVAL ERROR: ${packagename}::import_hashref (dirty) " .
                    "failed: $@\n";
            }
        }
    }

    # Create a table of included mtimes from parsedtable
    my %includes = %{$self->{parsedtable}};
    while (my ($filename, $template) = each (%includes)) {
        $includes{$filename} = $template->{filemodtime};
    }
    # Add the raw files to this table.  Some of them may overwrite
    # the templates, but since we are only worried about mtime, we don't
    # care. (A normal include will have the same mtime as a raw include,
    # since it is the same file -- duh).
    while (my ($filename, $rawrec) = each (%{$self->{rawtable}})) {
        $includes{$filename} = $rawrec->{mtime};
    }
    # Add to the imported hash (or modify the mtime):
    $self->__add_file_package__( $filename, $packagename, \%includes, $mtime );

    # no return value.  This just sets up the template in a module.  The
    # output function of that module still must be called.
}

=pod

I<import_package( $packagename, $warn )>

Once a file has been opened and parsed, the code to generate the template can
be imported into a package of the specified name.  In order to really make
the tempalate useful, the generated code should be imported into a package
so that it can have its own namespace.  Mind you, the template can actually
be imported into the current package, but this is not suggested or encouraged
since it is generating code that might do nasty things to your global variables.

The $warn parameter turns warnings on or off in the generated module.
Leave it out or set to zero for default behavior (off).

=cut
sub import_package {
    my ($self, $package, $warn) = @_;
    #my $perl = $self->output_perl( $package );
    #print STDERR $perl;
    eval( $self->output_perl( packagename => $package, 'warn' => $warn ) );
    if ($@) {
        die "EVAL ERROR in import_package: Generated Perl Code for package " .
            "'$package' failed to compile: $@\n";
    }
}

# Outputs the subroutine definitions for a given template.  These are separate
# from the regular code, so this function allows us to print them all
# out at once.
sub output_perl_defs {
    my $self = shift;
    my %args = @_;
    my $depth = $args{depth};

    my $result = '';
    while (my ($name, $defblk) = each (%{$self->{deftable}}) ) {
        $result .= $defblk->output_perl( depth => $depth );
    }
    return $result;
}

# outputs the list of functions that we have created, with names munged.  This
# allows us to create that pristine_namespace that is so deeply coveted.
sub output_perl_deflist {
    my $self = shift;
    my %args = @_;
    my $depth = $args{depth};
    my $pre = $_NODE_::prepend x $depth;

    my $result = '';
    foreach my $name (keys( %{$self->{deftable}} )) {
        $result .= $pre . "$_NODE_::defprepend$name => 1,\n";
    }
    return $result;
}

=pod

I<output_perl_code( %args )>

Accepts a depth argument.  This just outputs the code without any surrounding
context and no helper functions, including the functions defined in the
template itself.  Just the code.  Just the code.  Remember that: just the code.
If you can't figure out what "just the code" means, call this function and
the output_perl function and do a diff.  It will become immediately obvious to
you.  You may want to consider turning off detection of whitespace in that
diff....

=cut
sub output_perl_code {
    # This merely outputs the perl code for the template, with no surrounding
    # context.  In other words, there is no function definition, no
    # package name, no namespace, nothing!  The only code that is output is the
    # internals of this particular parse tree.
    return shift()->{parentnode}->output_perl( @_ );
}

=pod

I<output_perl( %args )>

This function outputs perl code that will generate the template output.  The
code that is generated turns off strict 'vars'.

The allowed parameters are:

    packagename (required)
    depth
    warn

If the depth is specified, then the code will indent itself that many times at
the top level.  The indentation amount is four spaces by default and cannot
currently be changed.

If warn is specified, the warn variable ($^W) in the generated module
is set to that value.  Default is 0 (off).

This always requires a packagename.  The packagename is used to generate
the surrounding context for the code output.  If you don't want the package,
the surrounding context, and the function definitions, you are really looking
for output_perl_code, which just outputs the code definition for this template
without any surrounding context.

=cut
sub output_perl {
    my $self = shift;
    my %args = @_;
    my $packagename = $args{'packagename'} || '';
    my $depth = $args{'depth'} || 0;
    my $warn = $args{warn} || 0;

    if (!defined($packagename)) {
        die "packagename required for template output_perl";
    }

    my $defined_functions = $self->output_perl_deflist( depth => 1 );
    my $function_defs = $self->output_perl_defs;
    my @templates = values %{$self->{parsedtable}};
    foreach my $t (@templates) {
        $defined_functions .= $t->output_perl_deflist( depth => 1 );
        $function_defs .= $t->output_perl_defs;
    }
    # If the package name is specified, this is the outer level.
    # Ignore $depth and print a package name at the beginning of things.
    my $header =<<"EOSTR";
package $packagename;
# Can't use 'strict vars' because of the need to access global variables 
# without a fully qualified name (the template cannot know what package it is
# in before it is realized).
no strict qw(vars);
BEGIN {
\$^W=$warn; # Set warning level.
}
\$START_SYM = '<?=';
\$END_SYM = '?>';
# Pristine and clean namespaces.  Make sure to add entries here as needed.
\%${packagename}::pristine_namespace = (
    import => 1,

    output => 1,
    import_hashref => 1,
    cleanup_namespace => 1,
    add_clean_names => 1,

    START_SYM => 1,
    END_SYM => 1,

    '^W' => 1,

    pristine_namespace => 1,
    clean_namespace => 1,
    for_count => 1,
    for_index => 1,
    for_list => 1,
    for_is_first => 1,
    for_is_last => 1,

    BEGIN => 1,
    END => 1,

$defined_functions
);
\%${packagename}::clean_namespace = \%${packagename}::pristine_namespace;
\@${packagename}::for_index = ();
\@${packagename}::for_count = ();
\@${packagename}::for_list = ();
sub for_count { \$${packagename}::for_count[\$#${packagename}::for_count - (\$_[0] || 0)] }
sub for_index { \$${packagename}::for_index[\$#${packagename}::for_index - (\$_[0] || 0)] }
sub for_list { \$${packagename}::for_list[\$#${packagename}::for_list - (\$_[0] || 0)] }
sub for_is_first { return for_index(\@_)==0; }
sub for_is_last { return for_index(\@_)>=for_count(\@_)-1; }
sub import_hashref {
    my \$rh_vars = shift;
    # Add these to the definition of a clean namespace?  This means that
    # the variables will NOT be clobbered by cleanup_namespace if this
    # is set.  This allows us to easily import configuration parameters
    # into the file (stuff that doesn't change, that isn't sensitive, etc)
    # and still remove other crap when needed.
    my \$add_to_clean = (shift()) ? 1 : 0;

    while (my (\$key, \$val) = each( \%\$rh_vars )) {
        # Use the symbol table hash \%${packagename}:: to set variables.
        # NOTE: we actually assign the hash values to REFERENCES of
        # the values passed in.  Since the hash values are all type globs,
        # this does some serious magic.  For example, if the variable
        # is never used and is originally a typeglob, the value stored
        # in the package hash is a reference.  If, however, that variable
        # is referenced anywhere, it is dereferenced automatically.  Don't
        # ask me how this works.  It just does.  Additionally, since
        # the package hash expects a typeglob, taking the reference
        # of the variable seems to do the Right Thing (tm) in all cases, 
        # including those where a hashref of scalars is passed in, which
        # turns out to be very important when anything but a namespace is
        # imported.
        if (defined( \$val )) {
            \$${packagename}::{\$key} = \\\$val
                unless \$${packagename}::pristine_namespace{\$key};
                # keeps from clobbering default and immutable stuff.
            \$${packagename}::clean_namespace{\$key} = 1 if \$add_to_clean;
        }
    }
    #print "\$username\\n";
}
# Restores the original namespace (the user functions and module variables
# that are here by default) by clobbering everything that was added by
# the user of the module.  This allows for pages to be displayed without any
# variables (like passwords!) that were there before.  Using things like
# mod_perl or mod_fcgi makes this an especially important feature since
# the module will not be reloaded with every request.
sub cleanup_namespace {
    # Inspect each key of \%${packagename}:: and delete all keys that
    # are not in the clean_namespace.
    my \@k = keys( \%${packagename}:: );
    foreach my \$key (\@k) {
        unless (\$${packagename}::clean_namespace{\$key}) {
            undef \$${packagename}::{\$key} 
        }
    }
}
# This adds variable names to the "clean" namespace.
sub add_clean_names {
    my \$rh_varnames = shift;
    my \@k = keys( \%\$rh_varnames );
    foreach my \$key (\@k) {
        \$${packagename}::clean_namespace{\$key} = 1;
    }
}
#-------------------------------------------------------------------------------
# TEMPLATE FUNCTIONS
$function_defs
#-------------------------------------------------------------------------------
# OUTPUT FUNCTION
sub output {
    # I know that we aren't using strict vars, but I still write the code
    # so that we COULD use them....  Hence the string reference.  It gets
    # used by all functions and is passed into any defined template function.
    my \$RESULT = '';
    my \$_RESULT_ = \\\$RESULT;
EOSTR
    my $footer =<<"EOSTR";
    return \$RESULT;
}

# End of module $packagename
1;
EOSTR
    return $header
        . $self->output_perl_code( depth => 1 )
        . $footer;
}
#-------------------------------------------------------------------------------
# END
#-------------------------------------------------------------------------------

1;

=pod

=head1 FORMAL GRAMMAR DEFINITION

    template :==
        text block template
        | NULL

    text :==
        ANY_CHAR_LITERAL
        | NULL

    block :==
        if_block
        | for_block
        | while_block
        | def_block
        | comment_tag
        | echo_tag
        | call_tag
        | inc_tag
        | rawinc_tag
        | exec_tag
        | break_tag
        | continue_tag
        | NULL


    if_block :==
        if_tag template [ elif_tag template ]* [ else_tag template ]? endif_tag

    for_block :==
        for_tag template [ else_tag template ]? endfor_tag

    while_block :==
        while_tag template endwhile_tag

    def_block :==
        def_tag template enddef_tag


    comment_tag :==
        START_SYMBOL OP_COMMENT WS TEXT WS? end_symbol

    echo_tag :==
        START_SYMBOL OP_ECHO WS simple_expr WS? end_symbol

    if_tag :==
        START_SYMBOL OP_IF WS simple_expr WS? end_symbol_block

    elif_tag :==
        START_SYMBOL OP_ELIF WS simple_expr WS? end_symbol_block

    else_tag :==
        START_SYMBOL OP_ELSE WS? end_symbol_block

    endif_tag :==
        START_SYMBOL OP_ENDIF WS? end_symbol

    for_tag :==
        START_SYMBOL OP_FOR WS var_name WS OP_IN WS simple_expr WS? end_symbol_block

    endfor_tag :==
        START_SYMBOL OP_ENDFOR WS? end_symbol

    while_tag :==
        START_SYMBOL OP_WHILE WS simple_expr WS? end_symbol_block

    endwhile_tag :==
        START_SYMBOL OP_ENDWHILE WS? end_symbol

    break_tag :==
        START_SYMBOL OP_BREAK WS? end_symbol

    continue_tag :==
        START_SYMBOL OP_CONTINUE WS? end_symbol

    def_tag :==
        START_SYMBOL OP_DEF WS def_name def_param_expression WS? end_symbol_block

    enddef_tag :==
        START_SYMBOL OP_ENDDEF WS? end_symbol

    call_tag :==
        START_SYMBOL OP_CALL WS def_name call_param_expression WS? end_symbol

    inc_tag :==
        START_SYMBOL OP_INC WS QUOTE? FILENAME QUOTE? WS? end_symbol

    rawinc_tag :==
        START_SYMBOL OP_INC WS QUOTE? FILENAME QUOTE? WS? end_symbol

    exec_tag :==
        START_SYMBOL OP_EXEC WS expression WS? end_symbol


    var_name :==
        OP_DOLLAR? CHAR_NAME_LITERAL

    def_name :==
        CHAR_NAME_LITERAL

    def_param_expression :==
        OP_OPEN_PAREN WS? def_param_list OP_CLOSE_PAREN

    def_param_list :==
        CHAR_NAME_LITERAL WS? [ OP_LIST_SEP WS? CHAR_NAME_LITERAL WS? ]*

    call_param_expression :==
        OP_OPEN_PAREN WS? call_param_list OP_CLOSE_PAREN

    call_param_list :==
        simple_expr WS? [ OP_LIST_SEP WS? simple_expr WS? ]*

    simple_expr :==
        SINGLE_STATEMENT_EXPR

    expression :==
        MULTI_STATEMENT_EXPR


    end_symbol_block :==
        OP_BLOCK_TERMINAL WS? end_symbol

    end_symbol :==
        END_SYM_TEXT END_SYM_WS?


    WS :== \s+
    END_SYM_WS :== \012\015|\012|\015
    CHAR_NAME_LITERAL :== [a-zA-Z_][a-zA-z0-9_]*
    QUOTE :== ["']

    START_SYMBOL :== '<?='
    END_SYM_TEXT :== '?>'

    OP_BLOCK_TERMINAL :== ':'
    OP_LIST_SEP :== ','

    OP_DOLLAR :== '$'
    OP_OPEN_PAREN :== '('
    OP_CLOSE_PAREN :== ')'
    OP_COMMENT :== 'comment'
    OP_ECHO :== 'echo'
    OP_IF :== 'if'
    OP_ELIF :== 'elif'
    OP_ELSE :== 'else'
    OP_ENDIF :== 'endif'
    OP_FOR :== 'for'
    OP_IN :== 'in'
    OP_ENDFOR :== 'endfor'
    OP_WHILE :== 'while'
    OP_ENDWHILE :== 'endwhile'
    OP_BREAK :== 'break'
    OP_CONTINUE :== 'continue'
    OP_DEF :== 'def'
    OP_ENDDEF :== 'enddef'
    OP_CALL :== 'call'
    OP_INC :== 'inc'
    OP_EXEC :== 'exec'

    SINGLE_STATEMENT_EXPR :==
        Any valid perl expression that is a single statement
        and evaluates to a single return value.  For example, the internals
        of an 'if' statement should evaluate to something akin to a boolean
        and would have the same rules as a normal 'if' statement.

    MULTI_STATEMENT_EXPR :==
        Any valid perl expression that may or may not be multiple expressions.
        This basically leaves the door wide open for a generic eval.

    FILENAME :==
        This is NOT a perl expression, but an actual filename.  The whitespace
        on either end is stripped out.  No quoting is currently allowed, so
        take care to not use filenames with spaces for now.
        Example: <?=inc file.ctpl ?>

    TEXT :==
        This is just text.  No parsing is done.  Just text.

=cut
