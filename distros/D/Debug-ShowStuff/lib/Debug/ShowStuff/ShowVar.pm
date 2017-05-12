package Debug::ShowStuff::ShowVar;
use strict;
use Filter::Util::Call;
# use Debug::ShowStuff ':all';
# use re 'taint';
use vars qw($VERSION $debug);

# version
$VERSION = '0.11';



=head1 NAME

Debug::ShowStuff::ShowVar - shortcuts for Debug::ShowStuff

=head1 SYNOPSIS

 use Debug::ShowStuff ':all';
 use Debug::ShowStuff::ShowVar;
 
 # output the name of the variable followed by the value of the variable
 showvar $myvar;

 ## outputs this line with println
 
 ##- outputs this line with prinhr
 
 ##i indents using indent

=head1 DESCRIPTION

Debug::ShowStuff::ShowVar is a preprocessor that provides shortcuts for a few
Debug::ShowStuff commands.  This module modifies your code so that some simple
commands are translated into longer Debug::ShowStuff commands.

Debug::ShowStuff::ShowVar is a B<filter>, so it requires very simple syntax for
it to understand your code.  Don't get fancy, this module won't understand it.

=head1 Commands

=head2 showvar

showvar translates a line into a println that shows the name of a variable and
its value.  So, for example, this line:

 showvar $myvar;

translates into this line

 println '$myvar: ', $myvar;

=head2 ##

A double hash followed by text gets translated into a println statement of that
text.  So, for example, this code:

 ## my text

is translated into

 println 'my text';

Note that there must be exactly two hash marks.  Three or more will not be
translated.

## is handy for when you don't want to repeat yourself documenting code.
For examle, this redundant code:

 # open a file
 println 'open a file';
 open_file();

can be written more concisely as

 ## open a file
 open_file();

=head2 ##- and ##=

##- and ##= work like ##, except that a printhr statement is created instead of
println.  ##- creates a horizontal rule using dashes (-). ##= creates a
horizontal rule using equals (=).

=head2 ##i

##i translates into an indent command, including a variable to hold the lexical
indent variable.  For example, suppose you want to output a value with println,
then indent the rest of the scope.  With just Debug::ShowStuff commands you
would do this:

 println 'begin';
 my $indent = indent();

Instead, you can put ##i at the beginning of the first line and get the indent.
So the following line accomplishes the same thing as above:

 println 'begin'; ##i

=cut



#------------------------------------------------------------------
# new
#
sub new {
	my ($class, %opts) = @_;
	my $self = bless({}, $class);
	
	# return object
	return $self;
}
#
# new
#------------------------------------------------------------------


#------------------------------------------------------------------
# import routine: creates filter object and adds it
# to the filters array
#
sub import {
	my ($class, %opts) = @_;
	
	# add filter if set to do so
	if ( defined($opts{'filter_add'}) ? $opts{'filter_add'} : 1 ) {
		filter_add($class->new(%opts));
	}
}
#
# import routine
#------------------------------------------------------------------


#------------------------------------------------------------------
# filter: this sub is run for every line in the calling script
#
sub filter {
	my $self = shift;
	my $status = filter_read();
	my $line = $_;
	
	# printhr with -
	# change to printhr if line starts with a double hash then dash (##-)
	# followed by non whitespace that isn't a hash
	if ($line =~ s|^\s*\#\#\-\s*([^\#]+)|$1|s) {
		$line =~ s|[\n\r]+$||s;
		$line =~ s|'|\\'|gs;
		$line = "printhr '$line';\n";
	}
	
	# printhr with =
	# change to printhr if line starts with a double hash then dash (##=)
	# followed by non whitespace that isn't a hash
	elsif ($line =~ s|^\s*\#\#\=\s*([^\#]+)|$1|s) {
		$line =~ s|[\n\r]+$||s;
		$line =~ s|'|\\'|gs;
		$line = "printhr title=>'$line', dash=>'=';\n";
	}
	
	# indent
	# change to an indentation if line ends with ##i
	elsif ($line =~ s|\#\#i\s*$||s) {
		my (@chars, $varname);
		
		# initialize $varname to empty string
		$varname = '';
		
		# set of variable characters
		@chars = ('a' .. 'z', 'A' .. 'Z');
		
		# generate random variable name
		for (1 .. 10) {
			my ($char);
			$char = rand();
			
			$char = int( $char * ($#chars + 1) );
			$char = $chars[$char];
			
			$varname .= $char;
		}
		
		$line .= ";my \$$varname = indent();\n";
	}
	
	# println
	# change to println if line starts with a double hash (##)
	# followed by non whitespace that isn't a hash
	elsif ($line =~ s|^\s*\#\#\s*([^\#]+)|$1|s) {
		$line =~ s|[\n\r]+$||s;
		$line =~ s|'|\\'|gs;
		$line = "println '$line';\n";
	}
	
	# showvar
	elsif ($line =~ s|^\s*showvar (\$\S+\s*);.*|$1|si) {
		my $var_name = $line;
		$line =~ s|[\n\r]+$||s;
		$line =~ s|'|\\'|gs;
		$line = "println '$line: ', $var_name;\n";
	}
	
	# set line and return value
	$_= $line;
	$status;
}
#
# filter
#------------------------------------------------------------------


# return true
1;

__END__

=head1 TERMS AND CONDITIONS

Copyright (c) 2013 by Miko O'Sullivan.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it under the
same terms as Perl itself. This software comes with B<NO WARRANTY> of any kind.

=head1 AUTHORS

Miko O'Sullivan
F<miko@idocs.com>

=head1 VERSION

=over

=item Version 0.10    March 17, 2013

Initial public release.

=item Version 0.11    March 19, 2013

Small but important fix to documentation.

=back

=cut