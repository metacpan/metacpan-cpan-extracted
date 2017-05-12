package HTML::SimpleTemplate;

# (C)1998-2003 Andrew Crawford
#
# A quicker (for the programmer!) and simpler template system for
# people who like simple things.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

use strict;
use Symbol;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# We don't need no stinkin' exports

$VERSION = '1.00';

sub new
{
	my $type = shift;
	my $class = ref($type) || $type;
	my $filepath=shift;
	my $self={"FILEPATH"=>$filepath};
	bless ($self,$class);
	return $self;
}

sub Display
{
	my $self = shift;
	my $filename = shift;
	my @ifstate=(1);
	my $fh = Symbol::gensym();
	my $blockelse;

	if ($self->{FILEPATH})
	{
		open ($fh,$self->{FILEPATH}."/$filename") || return;
	} else {
		open ($fh,"$filename") || return;
	}

	my $bundle = shift; # a reference to the hash with the variables in

	${$bundle}{TemplatePath} = $self->{FILEPATH}; 

	while(<$fh>) # for each line of the template file...
	{

		# # some comment not sent to output
		if (/^\#/) # skip it if it's a comment
		{
			next;
		}    
    

    
		# ?$ShowImage
		if (/^\?\$(\S+)/)	# Simple if clause
	      	{

			if (!$ifstate[0])
			{
				$blockelse++;
				next;
			}
	
			if (${$bundle}{$1})
			{
		  		unshift @ifstate,1;
			} else {
				unshift @ifstate,0;
			}

 			next;
      		 }

		# ?($name=~/Bishop/)
		if (/^\?\((.+)\)$/)	# Complex if clause
		{

			if (!$ifstate[0])
			{
				$blockelse++;
				next;
			}

			my $cond=$1; 	# the condition

			$cond=~s/\$(\w+)/\$\{\$bundle\}\{$1\}/g;
					# interpolate string
				
			if(eval($cond))
			{
				unshift @ifstate,1 ;
			} else {
				unshift @ifstate,0 ;
			}

			next;
		}

		# ?!$ShowImage
		if(/^\?\!\$(\S+)/)  # Simple if NOT clause
		{
  	  		if (${$bundle}{$1})
  	  		{
   	    			unshift @ifstate,0;
		  	} else {
		    		unshift @ifstate,1;
	  		}  

			next;
		}

		# ?else
		if (/^\?else/) # ELSE command - swap ifstate
		{
			if ($blockelse)
			{
				next;
			}
			
			if ($ifstate[0]==0)
			{
				$ifstate[0]=1;
			} else {
				$ifstate[0]=0;
			}
	    		next;
		}

		# ?exit
		if (/^\?exit/) # EXIT command - quit processing
		{
			if ($ifstate[0])
			{
				close($fh);
				return;
			}
		}

		if (/^\?end/)	# End of an if block
      		{	
			if ($blockelse)
			{
				$blockelse--;
				next;
			}

			shift(@ifstate);

			if (!defined @ifstate)
			{
				# Allow for too many ?ends
				@ifstate=(1);
			}
			next;
      		}



		# Add callbacks to perl procedures
		# &SomeFunc($a,3)
		if (/^\&([^\)]+)\(([^\)]+)/)
		{
			my $params=$2;
			my $command=$1;
	
			$params=~s/\$(\w+)/${$bundle}{$1}/g;
			$command=~s/\$(\w+)/${$bundle}{$1}/g;

			$params=~s/\"/\\\"/g;

			eval"$command($params);";
			next;
		}
    
    
	    	# Substitute template variables where ever found

		s/\$(\w+)/${$bundle}{$1}/g;
		s/\$\{(\w+)\}/${$bundle}{$1}/g;

		# !another.tpl
		if (/^\!(\S+)/)	# Include other tpl file
		{
			if ($ifstate[0])
			{
				Display($self,$1,$bundle);
			    	next;
	  		}
      		}

		# Print the processed line if appropriate

		if ($ifstate[0])
		{
		 	print;
		}

	}

	close($fh);
}


# Preloaded methods go here.
# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

HTML::SimpleTemplate - Quick and simple template library for Perl

=head1 SYNOPSIS

  use HTML::SimpleTemplate;

  # A template object referencing a particular directory
  my $adminpages=new HTML::SimpleTemplate("/templates/admin");

  # A template object referencing files in this directory
  my $localpages=new HTML::SimpleTemplate;

  # Display this template file, passing no parameters
  $localpages->Display("welcome.tpl");

  # Display this template file, passing the %account hash
  $localpages->Display("account.tpl",\%account);

  # Display this template file, with a-la-carte parameter
  $localpages->Display("order.tpl",{product=>"Perl mug"});

=head1 DESCRIPTION

=head2 DISPLAY METHOD

	Display($file,[\%variables]);

The Display method parses the specified file according to the rules
specified below. It can optionally be passed a second parameter, a reference
to a hash, containing the variables used in the template.

When the SimpleTemplate object is created a template path can optionally be
specified. If this is absent filenames specified to Display are relative to
the current directory.

=head2 TEMPLATE SYNTAX

	Hello $name!
	?($name eq "George")
	?$rude
	..you old fool!
	?end
	It's too late at night to think of witty examples!
	?end

A template is a text file which may contain certain variable references and
special commands. Variables are referenced by prefixing their name with the
dollar symbol, as in Perl itself. Variable names must be alphanumeric, and
must be followed by a non-alphanumeric character (including spaces and
newlines) so the module knows where the name ends.

There area very small number of special commands, which all involve either a
? or an ! in the first column of the line.

=head2 CONDITIONALS

	?$SomeVariable
	The variable evaluated as true
	?else
	No it didn't
	?end

	?($Any=~/perl evaluation that doesn't contain brackets/)
	It was
	?else
	It wasn't (else is optional by the way!)
	?end

You may nest conditionals to your hearts content, but the layout makes it
confusing if you have more than two or three. Anyway that kind of complex
logic belongs in Perl, not in HTML.

=head2 INCLUDES

	!header.tpl

	!common/header.tpl

	!errors/$ErrorType.tpl

When you include another template all of the variables in your current
template remain available.

=head2 CALLBACKS

	&InsertContent($fish)

Yes, you can call Perl inside your template. You can, of course, then call
templates from inside that Perl. Very powerful, potentially very
confusing...

=head2 COMMENTS

Saving the best for last, you can now put sensible comments in your HTML -
and the page viewer doesn't get to see it!

	# This section for stupid people only
	?NameError
	It appears you have failed to enter your name.
	# You freakin' numbskull!
	?end

=head2 NOTES

Clearly you cannot embed conditionals, callbacks etc in the middle of a
line. You also can't have any plain content following a command. However,
for HTML, which this is primarily designed for, that just isn't an issue.

By the way, if you're creating an HTML page, it works quite nicely to put
that Content-type: text/html in the template if it makes you happy having it
there.

=head1 AUTHOR

A Crawford, acrawford@ieee.org

=head1 SEE ALSO

HTML::Template

=cut
