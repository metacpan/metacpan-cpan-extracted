package Getopt::Simple;

# Name:
#	Getopt::Simple.
#
# Documentation:
#	POD-style documentation is at the end. Extract it with pod2html.*.
#
# Tabs:
#	4 spaces || die.
#
# Author:
#	Ron Savage <ron@savage.net.au>
#	Home page: http://savage.net.au/index.html
#
# Licence:
#	Australian copyright (c) 1999-2002 Ron Savage.
#
#	All Programs of mine are 'OSI Certified Open Source Software';
#	you can redistribute them and/or modify them under the terms of
#	The Artistic License, a copy of which is available at:
#	http://www.opensource.org/licenses/index.html

use strict;
no strict 'refs';
use vars qw($fieldWidth $switch @ISA @EXPORT @EXPORT_OK);

use Getopt::Long;

require Exporter;

@ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

@EXPORT      = qw();

@EXPORT_OK   = qw($switch);	# An alias for $$self{'switch'}.

$fieldWidth  = 25;

our $VERSION = '1.52';

# Preloaded methods go here.
# --------------------------------------------------------------------------

sub byOrder
{
	my($self) = @_;

	$$self{'default'}{$a}{'order'} <=> $$self{'default'}{$b}{'order'};
}

# --------------------------------------------------------------------------

sub dumpOptions
{
	my($self) = @_;

	print $self -> pad('Option'), "Value\n";

	for (sort byOrder keys(%{$$self{'switch'} }) )
	{
		if (ref($$self{'switch'}{$_}) eq 'ARRAY')
		{
			print $self -> pad("-$_"), '(', join(', ', @{$$self{'switch'}{$_} }), ")\n";
		}
		else
		{
			print $self -> pad("-$_"), "$$self{'switch'}{$_}\n";
		}
	}

	print "\n";

}	# End of dumpOptions.

# --------------------------------------------------------------------------
# Return:
#	0 -> Error.
#	1 -> Ok.

sub getOptions
{
	push(@_, 0) if ($#_ == 2);	# Default for $ignoreCase is 0.
	push(@_, 1) if ($#_ == 3);	# Default for $helpThenExit is 1.

	my($self, $default, $helpText, $ignoreCase, $helpThenExit) = @_;

	$$self{'default'}	= $default;
	$$self{'helpText'}	= $helpText;

	Getopt::Long::Configure($ignoreCase ? 'ignore_case' : 'no_ignore_case');

	for (keys(%{$$self{'default'} }) )
	{
		push(@{$$self{'type'} }, "$_$$self{'default'}{$_}{'type'}");
	}

	my($result) = GetOptions($$self{'switch'}, @{$$self{'type'} });

	if ($$self{'switch'}{'help'})
	{
		$self -> helpOptions();
		exit(0) if ($helpThenExit);
	}

	for (keys(%{$$self{'default'} }) )
	{
		if (ref($$self{'switch'}{$_}) eq 'ARRAY')
		{
			$$self{'switch'}{$_} = [split(/\s+/, $$self{'default'}{$_}{'default'})] if (! defined $$self{'switch'}{$_});
		}
		else
		{
			$$self{'switch'}{$_} = $$self{'default'}{$_}{'default'} if (! defined $$self{'switch'}{$_});
		}
	}

	$result;

}	# End of getOptions.

# --------------------------------------------------------------------------

sub helpOptions
{
	my($self) = @_;

	print "$$self{'helpText'}\n" if ($$self{'helpText'});

	print $self -> pad('Option'), $self -> pad('Environment var'), "Default\n";

	for (sort byOrder keys(%{$$self{'default'} }) )
	{
		print $self -> pad("-$_"), $self -> pad("$$self{'default'}{$_}{'env'}");

		if (ref($$self{'default'}{$_}{'default'}) eq 'ARRAY')
		{
			print '(', join(', ', @{$$self{'default'}{$_}{'default'} }), ")\n";
		}
		else
		{
			print "$$self{'default'}{$_}{'default'}\n";
		}

		print "\t$$self{'default'}{$_}{'verbose'}\n"
			if (defined($$self{'default'}{$_}{'verbose'}) &&
				$$self {'default'}{$_}{'verbose'} ne '');
	}

	print "\n";

}	# End of helpOptions.

#-------------------------------------------------------------------

sub new
{
	my($class)			= @_;
	$class				= ref($class) || $class;
	my($self)			= {};
	$$self{'default'}	= {};
	$$self{'helpText'}	= '';
	$$self{'switch'}	= {};
	$switch				= $$self{'switch'};	 # An alias for $$self{'switch'}.
	$$self{'type'}		= [];

	return bless $self, $class;

}	# End of new.

# --------------------------------------------------------------------------

sub pad
{
	my($self, $field) = @_;

	sprintf "%-${fieldWidth}s", $field;

}	# End of pad.
# --------------------------------------------------------------------------

# Autoload methods go after =cut, and are processed by the autosplit program.

1;

__END__

=head1 NAME

C<Getopt::Simple> - Provide a simple wrapper around Getopt::Long.

=head1 SYNOPSIS

	use Getopt::Simple;

	# Or ...
	# use Getopt::Simple qw($switch);

	my($options) =
	{
	help =>
		{
		type    => '',
		env     => '-',
		default => '',
#		verbose => '',      # Not needed on every key.
		order   => 1,
		},
	username =>
		{
		type    => '=s',    # As per Getopt::Long.
		env     => '$USER', # Help text.
		default => $ENV{'USER'} || 'RonSavage', # In case $USER is undef.
		verbose => 'Specify the username on the remote machine',
		order   => 3,       # Help text sort order.
		},
	password =>
		{
		type    => '=s',
		env     => '-',
		default => 'password',
		verbose => 'Specify the password on the remote machine',
		order   => 4,
		},
	};

	my($option) = Getopt::Simple -> new();

	if (! $option -> getOptions($options, "Usage: testSimple.pl [options]") )
	{
		exit(-1);	# Failure.
	}

	print "username: $$option{'switch'}{'username'}. \n";
	print "password: $$option{'switch'}{'password'}. \n";

	# Or, after 'use Getopt::Simple qw($switch);' ...
	# print "username: $$switch{'username'}. \n";
	# print "password: $$switch{'password'}. \n";

=head1 DESCRIPTION

C<Getopt::Simple> is a pure Perl module.

The C<Getopt::Simple> module provides a simple way of specifying:

=over 4

=item *

Command line switches

=item *

Type information for switch values

=item *

Default values for the switches

=item *

Help text per switch

=back

=head1 Distributions

This module is available both as a Unix-style distro (*.tgz) and an
ActiveState-style distro (*.ppd). The latter is shipped in a *.zip file.

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing each type of distro.

=head1 Constructor and initialization

new(...) returns a C<Getopt::Simple> object.

This is the class's contructor.

Usage: Getopt::Simple -> new().

This method does not take any parameters.

=head1 The C<dumpOptions()> function

C<dumpOptions()> prints all your option's keys and their current values.

C<dumpOptions()> does not return anything.

=head1 The C<getOptions()> function

The C<getOptions()> function takes 4 parameters:

=over 4

=item *

A hash ref defining the command line switches

The structure of this hash ref is defined in the next section.

This parameter is mandatory.

=item *

A string to display as a help text heading

This parameter is mandatory.

=item *

A Boolean. 0 = (Default) Use case-sensitive switch names. 1 = Ignore case

This parameter is optional.

=item *

A Boolean. 0 = Return after displaying help. 1 = (Default) Terminate with exit(0)
after displaying help

This parameter is optional.

=back

C<getOptions()> returns 0 for failure and 1 for success.

=head1 The hash ref of command line switches

=over 4

=item *

Each key in the hash ref is the name of a command line switch

=item *

Each key points to a hash ref which defines the nature of that command line switch

The keys and values of this nested hash ref are as follows.

=over 4

=item *

default => 'Some value'

This key, value pair is mandatory.

This is the default value for this switch.

Examples:

	default => '/users/home/dir'
	default => $ENV{'REMOTEHOST'} || '127.0.0.1'

=item *

env => '-' || 'Some short help text'

This key, value pair is mandatory.

This is help test, to indicate that the calling program can use an environment
variable to set the default value of this switch.

Use '-' to indicate that no environment variable is used.

Examples:

	env => '-'
	env => '$REMOTEHOST'

Note the use of ' to indicate we want the $ to appear in the output.

=item *

type => 'Types as per Getopt::Long'

This key, value pair is mandatory.

This is the type of the command line switch, as defined by Getopt::Long.

Examples:

	type => '=s'
	type => '=s@',

=item *

verbose => 'Some long help text'

This key, value pair is optional.

This is long, explanatory help text which is displayed below the help containing
the three columns of text: switch name, env value, default value.

Examples:

	verbose => 'Specify the username on the remote machine',
	verbose => 'Specify the home directory on the remote machine'

=item *

order => \d+

This key, value pair is mandatory.

This is the sort order used to force the help text to display the switches in
a specific order down the page.

Examples:

	order => 1
	order => 9

=back

=back

=head1 The C<helpOptions()> function

C<helpOptions()> prints nicely formatted help text.

C<helpOptions()> does not return anything.

=head1 The $$classRef{'switch'} hash reference

Command line option values are accessed in your code by dereferencing
the hash reference $$classRef{'switch'}. Two examples are given above,
under synopsis.

Alternately, you can use the hash reference $switch. See below.

=head1 The $switch hash reference

Command line option values are accessed in your code by dereferencing
the hash reference $switch. Two examples are given above,
under synopsis.

Alternately, you can use the hash reference $$classRef{'switch'}. See above.

=head1 WARNING re Perl bug

As always, be aware that these 2 lines mean the same thing, sometimes:

=over 4

=item *

$self -> {'thing'}

=item *

$self->{'thing'}

=back

The problem is the spaces around the ->. Inside double quotes, "...", the
first space stops the dereference taking place. Outside double quotes the
scanner correctly associates the $self token with the {'thing'} token.

I regard this as a bug.

=head1 AUTHOR

C<Getopt::Simple> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 1997.

=head1 LICENCE

Australian copyright (c) 1997-2002 Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html
