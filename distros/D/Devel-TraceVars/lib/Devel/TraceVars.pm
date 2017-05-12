=head1 NAME

Devel::TraceVars - Print each line of code with variables evaluated

=head1 SYNOPSIS

    $ perl -d:TraceVars[+MODE[OPTIONS]] program [arguments]

Where MODE can be C<modules> or C<custom>.

If C<modules> mode is selected then the output will only include the lines
that are provided by the given modules.

Modules can be added by separating them by commas C<,>. By default the module
C<main> is assumed to be included. Optionally, the wildcard C<*> can be used
to indicate any module that matches the given pattern. Thus, the entry
C<Net::SSH::*> will match all modules that start with Net::SSH.

B<NOTE:> The wild card handling works only if it's used as the last character. 
Using the following pattern I<Net::*::Perl> isn't supported yet.

If C<non-cpan> is used then output will exclude all files that are provided by
CPAN. At present, a module is considered to be provided by CPAN if the module
is loaded from the Perl include path as designated by $Config{installarchlib}.

If no mode is specified then all output lines are printed.

Examples:

C<perl -d:TraceVars script.pl>

Prints all lines.

C<perl -d:TraceVars+modules script.pl>

Defaults to print only all lines of the package C<main> which usually means all
lines in the main program. The package C<main> is the default package used by
perl when no package is specified in the code.

C<perl -d:TraceVars+modules,Net::SSH,Digest::* script.pl>

Prints only information from the module C<Net::SSH>, and from any module whose
name starts with C<Digest>.

C<perl -d:TraceVars+noncpan script.pl>

Prints only lines that are provided by  perl files that aren't stored in the
default folder where all CPAN modules are installed.

=head1 DESCRIPTION

If you run your program with C<perl -d:TraceVars program>, this module
will print the current line of code being executed to standard error
just before each line is executed. The contents of all scalar variables will
be evaluated and displayed as well. All leading and trailing spaces will be
removed from each line.

=cut

package Devel::TraceVars;

use strict;
use Data::Dumper;
use PadWalker qw(peek_my);
use Config;


##
# Variables
##

our $VERSION = '0.03';


#
#
#This is the main closure used to include/exclude modules from the output.
#
#This closure will receive as arguments:
#  $package
#  $filename
#  $line
#
my $ACCEPT_CLOSURE = sub { return 1; };


##
# Methods
##


=head1 METHODS

The following methods are available.

=cut


=head2 import

Called by perl when this module is first loaded.

=cut

sub import {
	my $module = shift;
	
	# Stop if there are no arguments
	return unless @_;
	
	# The execution mode
	my $mode = lc shift;
	
	# Check which Execution mode is requested
	if ($mode eq 'modules') {
		
		# Modules to accept
		my %modules = map { $_ => 1 } ('main', @_);
		
		$ACCEPT_CLOSURE = sub {
			my ($package, $filename, $line) = @_;

			# Keep only if module is in the list of known modules
			return 1 if $modules{$package};
			
			# Try to see if the module starts with one of the accepted prefixes
			my @path = split /::/, $package;
			while (@path) {
				pop @path;
				my $new_package = join '::', @path, '*';
				return 1 if $modules{$new_package};
			}
			
			# Not found
			return 0;
		}
	}
	elsif ($mode eq 'noncpan') {
		my $regexp = qr/(\(eval \d+\)\[)?\Q$Config{installarchlib}\E/;
		$ACCEPT_CLOSURE = sub {
			my ($package, $filename, $line) = @_;

			# Skip if dealing with a perl stock module
			return $filename !~ /^$regexp/;
		}
	}
}


=head2 DB::DB

This is the important part. Perl calls this method before each line is executed.

=cut

sub DB::DB {
  
	# Information about the caller
	my ($caller_package, $caller_filename, $caller_line) = caller;

	# Skip if dealing with a perl stock module
	return unless $ACCEPT_CLOSURE->($caller_package, $caller_filename, $caller_line);
  
	my $code_line;
	{
		no strict 'vars';
		# Get the typeglob that holds a handle to the code being executed
		local *symbol = $main::{"_<" . $caller_filename};
		$code_line = $symbol[$caller_line];
		chomp ($code_line);
	}
	

	# Evaluate all variables in the code
	my $evaluated_code_line = $code_line;
	$evaluated_code_line =~ s/\$(\w+)/evaluate($caller_package, $1)/ge;
	
	# Trim spaces
	foreach my $alias ($code_line, $evaluated_code_line) {
		$alias =~ s/(^\s+|\s+$)//g;
	}
	
	# Output the debug line
	print STDERR ">> $caller_filename $caller_line: $evaluated_code_line\n";
}


=head2 evaluate($package, $variable)

Tries to evaluate the content of the given variable.

=over 4

=item * $package 

The package's scope where the variable was used.

=item * $variable

The variable name to evaluate.

=back

Returns the variable's content.

=cut

sub evaluate {
	
	my ($package, $variable) = @_;

	# Causes segmentation faults some times
	return '$VERSION' if $variable eq 'VERSION';
	
	##
	# Check if the variable is a my variable
	
	# Since this is also a function we need to peek two levels up
	my $peek = peek_my(2);
	
	# See if there is a my variable declared
	my $variable_to_evaluate = sprintf '$%s', $variable;
	if (defined $peek->{$variable_to_evaluate}) {
		my $value = ${ $peek->{$variable_to_evaluate} };
		return $value;
	}
	
	
	##
	# Try a package variable
	# The code to evaluate $PACKAGE::VARIABLE;
	$variable_to_evaluate = sprintf '$%s::%s', $package, $variable;

	# Perform the Evaluation
	# if the variable is not defined yet (probably where are evaluting the declaration)
	# then the variable will be replaced by it's own name including the $
	my $value = eval "defined $variable_to_evaluate ? $variable_to_evaluate : '\$$variable'";

	return $value;
}


# Return a true value
1;


=head1 BUGS

Probably the code won't work with Perl's special variables.
Sometimes perl seems to core dump when using this module.

=head1 SEE ALSO

L<Devel::Trace>.

=head1 AUTHOR

Emmanuel Rodriguez E<lt>potyl@cpan.orgE<gt> based on a shameless copy of
C<Devel::Trace> .

=cut
