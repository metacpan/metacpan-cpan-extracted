package MarpaX::Languages::SVG::Parser::Actions;

use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.

my($item_count);
my($param_count);

our $logger;

our $VERSION = '1.06';

# ------------------------------------------------

sub boolean
{
	my($hashref, $t1) = @_;
	$t1 = lc $t1;
	$t1 = $t1 eq 'zero' ? 0 : 1;

	return
	{
		count => ++$item_count,
		name  => ++$param_count,
		type  => 'boolean',
		value => $t1,
	};

} # End of boolean.

# ------------------------------------------------

sub command
{
	my($hashref, $t1, @t2) = @_;
	$param_count = 0;

	return
	{
		count => ++$item_count,
		name  => $t1,
		type  => 'command',
		value => [@t2],
	};

} # End of command.

# ------------------------------------------------

sub float
{
	my($hashref, $t1) = @_;

	return
	{
		count => ++$item_count,
		name  => ++$param_count,
		type  => 'float',
		value => $t1,
	};

} # End of float.

# ------------------------------------------------

sub init
{
	$item_count  = 0;
	$param_count = 0;

} # End of init.

# ------------------------------------------------

sub integer
{
	my($hashref, $t1) = @_;

	return
	{
		count => ++$item_count,
		name  => ++$param_count,
		type  => 'integer',
		value => $t1,
	};

} # End of integer.

# --------------------------------------------------

sub log
{
	my($level, $s) = @_;
	$level = 'notice' if (! defined $level);
	$s     = ''       if (! defined $s);

	$logger -> $level($s) if ($logger);

} # End of log.

# ------------------------------------------------

sub string
{
	my($hashref, $t1) = @_;

	return
	{
		count => ++$item_count,
		name  => ++$param_count,
		type  => 'string',
		value => $t1,
	};

} # End of string.

# ------------------------------------------------

1;

=pod

=head1 NAME

C<MarpaX::Languages::SVG::Parser::Actions> - A nested SVG parser, using XML::SAX and Marpa::R2

=head1 Synopsis

See L<MarpaX::Languages::SVG::Parser/Synopsis>.

=head1 Description

Basically just utility routines for L<MarpaX::Languages::SVG::Parser>. Only used indirectly by L<Marpa::R2>.

Specifially, calls to functions are triggered by items in the input stream matching elements of the current
grammar (and Marpa does the calling).

Each action function returns a hashref, which Marpa gathers. The calling code
L<MarpaX::Languages::SVG::Parser::SAXHandler> decodes the result and puts the hashrefs into a stack, described in
the L<MarpaX::Languages::SVG::Parser/FAQ>.

=head1 Installation

See L<MarpaX::Languages::SVG::Parser/Installation>.

=head1 Constructor and Initialization

This class has no constructor. L<Marpa::R2> fabricates an instance, but won't let us get access to it.

So, we use a global variable, C<$logger>, initialized in L<MarpaX::Languages::SVG::Parser::SAXHandler>,
in case we need logging. Details:

=over 4

=item o logger => aLog::HandlerObject

By default, an object of type L<Log::Handler> is created which prints to STDOUT,
but given the default, nothing is actually printed unless the C<maxlevel> attribute of this object is changed
in L<MarpaX::Languages::SVG::Parser>.

Default: anObjectOfTypeLogHandler.

=back

Also, each new parse is preceeded by a call to the L</init()> function, to reset some counters global to this file.

=head1 Methods

None.

=head1 Functions

=head2 boolean($t1)

Returns a hashref identifying the boolean $t1.

=head2 command($t1, @t2)

Returns a hashref identifying the command $t1 and its parameters in @t2.

=head2 float($t1)

Returns a hashref identifying the float $t1.

=head2 init()

Resets some counters global to the file. This must be called at the start of each new parse.

=head2 integer($t1)

Returns a hashref identifying the integer $t1.

=head2 log($level, $s)

Calls $logger -> log($level => $s) if ($logger).

=head2 string($t1)

Returns a hashref identifying the string $t1.

=head1 FAQ

See L<MarpaX::Languages::SVG::Parser/FAQ>.

=head1 Author

L<MarpaX::Languages::SVG::Parser> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2013.

Home page: L<http://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2013, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License 2.0, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
