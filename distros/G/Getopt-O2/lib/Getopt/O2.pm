##------------------------------------------------------------------------------
package Getopt::O2;

use 5.010;
use strict;
use warnings;

no if $] >= 5.017011, warnings => 'experimental::smartmatch';

our $VERSION = '1.1.0';
##------------------------------------------------------------------------------
use English '-no_match_vars';
use Readonly;
Readonly my $USAGE_MARGIN => 80;
Readonly my $USAGE_OPTIONS_LENGTH => 29;

use Carp 'confess';
use Scalar::Util 'looks_like_number';
##------------------------------------------------------------------------------
sub new
{
	my $class = ref $_[0] ? ref $_[0] : $_[0];
	my $self = bless {
		shortOptions => {},
		longOptions => {},
		options => {}
	}, $class;

	return $self
}
##------------------------------------------------------------------------------
sub getopt ## no critic (Subroutines::ProhibitExcessComplexity)
{
	my $self = shift;
	my $dest = shift;
	my $args = shift;
	my ($arg,$key,$rule,%context,@arguments);

	$self->{'options'} = {%$dest};
	$self->parse_rules();

	PROCESS_ARGUMENTS: while (@ARGV) {
		$arg = shift @ARGV;

		if (!defined $arg || !length $arg || '-' eq $arg || $arg !~ /^-/) {
			push @arguments, $arg;
			next PROCESS_ARGUMENTS;
		} elsif ('--' eq $arg) {
			push @arguments, @ARGV;
			last PROCESS_ARGUMENTS;
		}

		if ($arg !~ /^--/) {
			$key = (substr $arg, 1, 1);
			$rule = $self->{'shortOptions'}->{$key};
			$self->error('No such option "-%s"', $key)
				unless defined $rule;
			$rule = $self->{'longOptions'}->{$rule};

			if (length $arg > 2) {
				if ($rule->type) { ## no critic (ControlStructures::ProhibitDeepNests)
					unshift @ARGV, (substr $arg, 2);
				} else {
					unshift @ARGV, '-'.(substr $arg, 2);
				}
			}
		} else {
			$key = (substr $arg, 2);

			if (~(index $key, '=')) {
				($key,$arg) = (split /=/, $key, 2);
				unshift @ARGV, $arg;
			}

			$rule = $self->{'longOptions'}->{$key};
			unless (defined $rule) {
				$self->error('No such option "--%s"', $key)
					if 0 != (index $key, 'no-');
				$key = (substr $key, 3);
				$rule = $self->{'longOptions'}->{$key};

				$self->error('No such option "--no-%s" or negatable "--%s"', $key, $key)
					unless defined $rule && $rule->negatable;
				$rule->{'_negate'} = 1;
			}
		}

		if (defined $rule->context) {
			foreach (@{$rule->context->{'need'}}) {
				$self->error('Option "--%s" cannot be used in this context.', $rule->long)
					unless exists $context{$_};
			}

			delete $context{$_} foreach @{$rule->context->{'clear'}};
			$context{$_} = 1 foreach @{$rule->context->{'set'}};
		}

		if ($rule->multiple) {
			$self->{'options'}->{$rule->long} = 0
				unless exists $self->{'options'}->{$rule->long};
			++$self->{'options'}->{$rule->long};
			$rule->mark_used;
			next PROCESS_ARGUMENTS;
		}

		unless (defined $rule->type) {
			$arg = undef;
		} else {
			$arg = $self->get_value();
			$self->error('Option "--%s" requires a value.', $rule->long)
				unless defined $arg;

			delete $self->{'options'}->{$rule->long}
				if $rule->is_unused;

			$self->{'options'}->{$rule->long} = []
				if $rule->is_list && !defined $self->{'options'}->{$rule->long};

			given($rule->type) {
				when('s') {
				}

				when('i') {
					$self->error('Argument "%s" to "--%s" isn\'t numeric', $arg, $rule->long)
						unless looks_like_number($arg);
					$arg = int $arg;
				}

				when('?') {
					$self->error('Value "%s" to argument "--%s" is invalid.', $arg, $rule->long)
						unless $arg ~~ @{$rule->values || []};
				}
			}

			if ($rule->is_list) {
				if ('?' ne $rule->type) { ## no critic (ControlStructures::ProhibitDeepNests)
					push @{$self->{'options'}->{$rule->long}}, $arg;
				} else {
					push @{$self->{'options'}->{$rule->long}}, $arg
						unless ($rule->keep_unique && $arg ~~ @{$self->{'options'}->{$rule->long}});
				}

				$rule->mark_used;
				next PROCESS_ARGUMENTS;
			}
		}

		$rule->mark_used;

		if (defined $rule->action) {
			$arg = $rule->action->($arg, $key, $rule);
		} else {
			$arg = $rule->{'_negate'} ? '' : 1
				unless defined $arg;
		}

		$self->{'options'}->{$rule->long} = $arg;
	}

	$self->check_rule_obligations(%context);

	%$dest = %{$self->{'options'}};
	@$args = @arguments if ref $args;
	$self->{'options'} = {};
	return $self
}
##------------------------------------------------------------------------------
sub error
{
	return shift->usage(1, shift(), @_);
}
##------------------------------------------------------------------------------
# Returns program name for display in usage
sub get_program
{
	my $program = $ENV{_};
	$program =~ s{.*/([^/]+)$}{$1};
	$program = $PROGRAM_NAME if 'perl' eq $program;
	return $program;
}
##------------------------------------------------------------------------------
# Return short program description string; displayed in usage
sub get_program_description
{
	my $class = ref $_[0];
	return qq{another example of this programmer's lazyness: it forgot the description (and should implement ${class}::get_program_description())}
}
##------------------------------------------------------------------------------
sub get_value
{
	return unless @ARGV;
	my $value = $ARGV[0];
	return shift @ARGV
		if !defined $value || !length $value || '-' eq $value || $value !~ /^-/;
	return if $value ne '--';
	shift @ARGV;
	return unless @ARGV;
	$value = shift @ARGV;
	unshift @ARGV, '--';
	return $value;
}
##------------------------------------------------------------------------------
sub get_option_rules
{
	my $self = shift;

	return
		'h|help' => ['Display this help message', sub {$self->usage(0)}],
		'v|verbose+' => 'Increase program verbosity',
	undef
}
##------------------------------------------------------------------------------
sub parse_rules ## no critic (Subroutines::ProhibitExcessComplexity)
{
	my $self = shift;
	my @rules = $self->get_option_rules();

	## Perl Critic false positive on "$}" at the end of the reg-ex
	## no critic (Variables::ProhibitPunctuationVars)
	state $pattern = qr{^
	(?:(?P<negatable>!))?
	(?:(?P<short>[[:alpha:]])[|])?
	(?P<long>[[:alpha:]](?:[[:alpha:]-]*)[[:alpha:]])
	(?:
		(?:=(?P<type>[si?]@?))
		|
		(?P<multiple>[+])
	)?
		$}x;
	## use critic

	my ($arg,$opt,@parsed);

	while (@rules) {
		$arg = shift @rules;
		unless (defined $arg) {
			push @parsed, undef if wantarray;
			next;
		}
		$opt = $arg;
		confess('Not enough rules') unless @rules;
		$arg = shift @rules;

		$arg = [$arg] unless ref $arg;
		confess("Invalid rule pattern '$opt'") if $opt !~ $pattern;
		my $rule = Getopt::O2::Rule->new($arg, %LAST_PAREN_MATCH);

		confess(sprintf q{Option spec '%s' redefines long option '%s'}, $opt, $rule->long)
			if exists $self->{'longOptions'}->{$rule->long};

		if (defined $rule->short) {
			confess(sprintf q{Option spec '%s' redefines short option '%s'}, $opt, $rule->short)
				if exists $self->{'shortOptions'}->{$rule->short};
			$self->{'shortOptions'}->{$rule->short} = $rule->long;
		}

		if (defined $rule->default) {
			$self->{'options'}->{$rule->long} = $rule->default;
		}

		$self->{'longOptions'}->{$rule->long} = $rule;
		push @parsed, $rule if wantarray
	}

	return $self unless wantarray;
	return @parsed;
}
##------------------------------------------------------------------------------
sub show_option_default_values
{
	return 1;
}
##------------------------------------------------------------------------------
sub check_rule_obligations
{
	my $self = shift;
	my %context = @_;
	my @missing = sort grep {
		is_rule_missing($self->{'longOptions'}->{$_}, %context)
	} keys %{$self->{'longOptions'}};

	return $self unless @missing;
	@missing = map {"`$_`"} @missing;
	my $one = 1 == scalar @missing;
	my $missing = $one
		? $missing[0]
		: sprintf '%s and %s', join(', ', @missing[0..$#missing-1]), $missing[-1];

	return $self->usage(1, 'Missing required option%s %s.', $one ? '' : 's', $missing);
}
##------------------------------------------------------------------------------
sub is_rule_missing
{
	my $rule = shift;
	my %context = @_;

	return unless $rule->required;
	return unless $rule->is_unused;
	return 1 unless $rule->context;

	foreach (@{$rule->context->{'need'}}) {
		return 1 if $context{$_};
	}

	return;
}
##------------------------------------------------------------------------------
sub usage ## no critic (Subroutines::ProhibitExcessComplexity)
{
	my $self = shift;
	my ($exitCode,$message,@args) = @_;

	if (defined $message) {
		$message = sprintf "Error: $message", @args;
	} else {
		$message = sprintf '%s - %s', $self->get_program(), $self->get_program_description();
	}

	print STDERR "$_\n"
		foreach wrap_string($message, 0, 8, $USAGE_MARGIN);
	printf STDERR "\nUsage: %s [options...]\n\nValid options:\n\n", $self->get_program();

	## no critic (Variables::ProhibitLocalVars)
	local $self->{'longOptions'} = undef;
	local $self->{'shortOptions'} = undef;
	## use critic

	my @rules = $self->parse_rules();
	my ($rule,$line,$long,$len,$show_default,$have_required);

	$show_default = $self->show_option_default_values();
	$have_required = 0;

	PROCESS_RULES: while (@rules) {
		#@type Getopt::O2::Rule
		$rule = shift @rules;

		unless (defined $rule) {
			print STDERR "\n";
			next PROCESS_RULES;
		}

		$line = '  ';
		$long = $rule->long;
		$long = "(no-)$long" if $rule->negatable;

		unless (defined $rule->short) {
			$long = "--$long";
		} else {
			$long = " [--$long]";
			$line .= '-'.$rule->short;
		}

		$line = "$line$long";
		$line .= ' ARG' if defined $rule->type;

		$line .= ' ' x ($USAGE_OPTIONS_LENGTH - $len)
			if $USAGE_OPTIONS_LENGTH > ($len = length($line) + 2);
		$line = "$line: ";
		print STDERR $line;

		print STDERR "$_\n"
			foreach wrap_string($rule->help($show_default), length $line, $USAGE_OPTIONS_LENGTH, $USAGE_MARGIN);
		$have_required ||= $rule->required;
	}

	print STDERR "\n";
	print STDERR "Options marked with '*' are required options.\n\n" if 0 != $have_required;
	exit $exitCode;
}
##------------------------------------------------------------------------------
sub wrap_string
{
	my ($string,$firstIndent,$leftIndent,$wrapAt) = @_;
	my (@lines,$len,$pos,$nChars);

	for ($nChars = $wrapAt - $firstIndent; length $string; $nChars = $wrapAt - $leftIndent) {
		$len = length $string;

		if ($len < $nChars) {
			push @lines, $string;
			last;
		}

		$pos = strrpos((substr $string, 0, $nChars), ' ');
		if (-1 == $pos) {
			push @lines, (substr $string, 0, $nChars);
			$string = (substr $string, $nChars);
		} else {
			push @lines, (substr $string, 0, $pos);
			$string = (substr $string, $pos + 1);
		}
	}

	if (@lines > 1) {
		my $indent = ' ' x $leftIndent;
		$lines[$_] = "$indent$lines[$_]" foreach (1..$#lines);
	}

	return @lines
}
##------------------------------------------------------------------------------
sub strrpos
{
	my ($string,$find) = @_;
	my ($length) = length $find;

	for (my $pos = length($string) - 1; $pos >= 0; --$pos) {
		return $pos if $find eq (substr $string, $pos, $length);
	}

	return -1
}
##------------------------------------------------------------------------------
package Getopt::O2::Rule; ## no critic (Modules::ProhibitMultiplePackages)

use strict;
use warnings;
use feature ':5.10';

use Carp 'confess';

BEGIN {
	## no critic (TestingAndDebugging::ProhibitNoStrict)
	no strict 'refs';
	foreach my $method (qw(action context default is_list keep_unique long multiple negatable required short type values)) {
		*{__PACKAGE__."::$method"} = sub {shift->{$method}}
	}
	## use critic
}

sub new ## no critic (Subroutines::ProhibitExcessComplexity)
{
	my $class = shift;
	my ($arg, %options) = @_;
	my (%rule);

	$rule{'long'} = $options{'long'};
	$rule{'short'} = $options{'short'} if exists $options{'short'};

	$rule{'negatable'} = $options{'negatable'} // 0;

	if ($options{'multiple'}) {
		$rule{'multiple'} = 1
	} elsif ($options{'type'}) {
		$rule{'type'} = (substr $options{'type'}, 0, 1);
		$rule{'is_list'} = ~(index $options{'type'}, '@');
		$rule{'keep_unique'} = $options{'keep_unique'} // 1
		if $rule{'is_list'};
	}

	$rule{'help'} = shift @$arg;
	$rule{'help'} =~ s/^\s+|\s+$//g;
	$rule{'help'} =~ s/\s+/ /g;
	$rule{'help'} .= '.' if $rule{'help'} !~ /[.]$/;

	if (@$arg) {
		$rule{'action'} = shift @$arg
		if 'CODE' eq ref $arg->[0];
		confess('Invalid rule options; the remainder is a list with uneven members')
		if 0 != (@$arg % 2);
		%rule = (%rule, @$arg);
	}

	$rule{'required'} //= 0;

	if ($rule{'required'}) {
		confess 'A rule cannot be required and have a default value' if exists $rule{'default'};
		confess 'A flag-rule cannot be required' unless exists $rule{'type'};
	}

	if (defined $rule{'context'}) {
		$rule{'context'} = [split /,/, $rule{'context'}];
		$rule{'context'} = {
			set => [map {(substr $_, 1)} grep {/^[+]/} @{$rule{'context'}}],
			clear => [map {(substr $_, 1)} grep {/^-/} @{$rule{'context'}}],
			need => [grep {/^[^+-]/} @{$rule{'context'}}],
		};
	}

	$rule{'_used'} = 0;

	return bless \%rule, $class
}
##------------------------------------------------------------------------------
sub is_unused
{
	return !shift->{'_used'};
}
##------------------------------------------------------------------------------
sub mark_used
{
	my $self = shift;
	$self->{'_used'} = 1;
	return $self;
}
##------------------------------------------------------------------------------
sub help
{
	my $self = shift;
	my $show_default = shift;
	my $obligation_suffix = $self->required ? ' *' : '';
	my $helpstr = $self->{'help'} . $obligation_suffix;

	unless (defined $self->{'type'}) { # flags
		return $helpstr;
	} elsif ('?' ne $self->{'type'}) { # anything but ENUM
		return $helpstr unless $show_default && defined $self->{'default'};

		$helpstr =~ s/\s*[.]\s*$//;
		return sprintf '%s (default: "%s").', $helpstr, $self->{'default'};
	} else {
		my @values = map {qq{"$_"}} @{$self->values};
		my $default_value = ($show_default && defined $self->{'default'})
			? (sprintf ' [default: "%s"]', $self->{'default'})
			: '';
		return $helpstr . (sprintf ' (ARG must be %s or %s)%s',
			(join ', ', @values[0..$#values-1]), $values[-1], $default_value);
	}
}
##------------------------------------------------------------------------------
1;
__END__
##------------------------------------------------------------------------------
=pod

=head1 NAME

Getopt::O2 - Command line argument processing and automated help generation, object oriented

=head1 SYNOPSIS

  package MyPackage;
  use parent 'Getopt::O2';

  # return a short descriptive string about the program (appears in --help)
  sub get_program_description
  {
	  return 'A sample program';
  }

  # return rules about parameters
  sub get_option_rules
  {
	  return shift->SUPER::get_option_rules(),
		  'length=i' => ['A numeric argument', 'default' => 33],
		  'file=s'   => ['A mandatory argument', 'required' => 1],
		  'quiet'    => ['A "flag" argument'];
  }

  # read options
  new MyPackage->getopt(\my %options, \my @values);

=head1 DESCRIPTION

The C<Getopt::O2> module implements an extended C<Getopt> class which
parses the command line from C<@ARGV>, recognizing and removing specified options
and their possible values.

This module adheres to the POSIX syntax for command line options, with GNU
extensions. In general, this means that options have long names instead of
single letters, and are introduced with a double dash "--". Support for
bundling of command line options, as was the case with the more traditional
single-letter approach, is provided.

C<Getopt::O2> stands out for its extensive usage generation feature; anything
printed in its "usage" output is generated from the input options and saves the
users the time to write usage output by themselves.

=head2 Methods

=over 4

=item I<PACKAGE>->getopt(I<HASHREF [, ARRAYREF]>)

Processes command line options and stores their values in the hash reference
passed as its argument. Anything not recognized as parameters or their values is
pushed into the second (optional) C<ARRAYREF>.

=item I<PACKAGE>->get_option_rules()

Returns a list of rules of command line options. The base package provides two
options C<--help> and C<--verbose> by default. The former calls C<usage()>; the
latter is an I<incremental option>. See L</"Writing Rules"> for what your
implementation should return.

=item I<PACKAGE>->get_program()

Returns the program name for display in usage.

=item I<PACKAGE>->get_program_description()

Returns a short descriptive string about the program's functionality. This
string is used as a caption of the generated program usage text and should be
implemented by sub-modules using this module.

=item I<PACKAGE>->usage(I<CODE [, MESSAGE [, LIST ] ]>)

Display program usage summary and exit with status C<CODE>. Without any further
arguments it will show the program's description text. If given, C<MESSAGE> will
be treated as an C<sprintf()>-like formatter string followed by its arguments
and prefixed with "Error: ".

=item I<PACKAGE>->error(I<MESSAGE [, LIST ]>)

This method is called internally when processing or validation of options
failed and does nothing but passing its arguments to C<usage()> (along with an
exit code of C<1>). Override this method if you require other methods of error
handling.

=back

=head2 Writing Rules

Command line options are processed using rules returned the C<getOptionsRules()>
implementation. Rules are expressed much like with L<Getopt::Long>. A rule
expression is followed by the rule's help string and possible options.

The options must be represented as either a string (used as help string) or an
ARRAYREF. The first element of the latter is used as the options' help string.
Its second element can be a CODEREF which is called when the option was seen.
The rest are key-value-pairs that are coerced to a hash.

A single C<undef> can be used to separate option categories by producing an empty
line in C<usage()> output.

=over 4

  # Short variant. Define flag and its help string
  'q|quiet' => 'Suppresses informational program output'

  # Actual implementation of "--help" parameter
  'h|help' => ['Display this help message', sub {
      $self->usage()
  }]

  # Enumeration with allowed values
  'o|output=?' => ['Use ARG as output format', 'values' => [qw(xml html json)]]

  # One or more occurences of a value (result is ARRAYREF)
  'i|input=s@' => 'Create result from input file ARG'

  # Use callback return value as option value
  'l|limit=i' => ['Limit amount of things', sub {
      my ($arg, $key) = @_;
      $arg = 100 if $arg > 100;
      return $arg; # make sure --limit is not larger than 100
  }]

=back

=head2 Rule syntax

=over 4

=item !w|warnings

Defines a I<negatable option>. The value of it will be a "boolean" in the
resulting options hash reference depending on whether C<--warnings> or
C<--no-warnings> was seen on the command line. There's no short negatable
option.

=item v|verbose+

Defines an I<incremental option>. Depending on how often it's seen on the
command line, the option's value will increase in the resulting hashref.

=item q|quiet

Defines a I<flag option>. The flag will be set in the resulting hashref if this
option was seen on the command line.

=item f|filename=s

=item l|list=s@

Defines an I<option with a mandatory value>. The character after the C<=> sign
determines the expected value: C<s> is a generic string, C<i> is a numeric value
(it uses Perl's L<Scalar::Util/"looks_like_number">) and C<?> is an enumeration. If the type
specifier is suffixed with a C<@>, the resulting value will be an ARRAYREF with
all values.

Enumerations must provide a C<values> option which must be an ARRAYREF of valid
values for the option. They may use the C<keep_unique> option which defaults to
being set in order to control whether the resulting list contains unique values
or all given values.

=back

=head2 Contextual rules

Rules can be allowed in a given context and may change the context appropriately.

Consider the following ruleset:

=over 4

  sub get_option_rules
  {
      return
          'q|quiet'     => ['Be quiet', 'context' => '-logging'],
          'v|verbose'   => ['Be verbose', 'context' => '+logging'],
          'l|logfile=s' => ['Log to file ARG', 'context' => 'logging']
  }

=back

The above example would introduce the I<logging> context; an internal state which
makes options appearing outside of that context invalid.

The C<--verbose> flag would activate the context - allowing for the option C<--logfile>,
which would otherwise (without the context) be considered illegal.

Contexts can be comma separated. A context of C<-a,-b,+c,d> would:

=over 4

=item * deactivate both contexts C<a> and C<b>

=item * activate context C<c>

=item * restrict the option to the previously activated context C<d>.

=back

=head1 TODO

=head1 DEPENDENCIES

None special. Uses core perl libraries.

=head1 AUTHOR

Oliver Schieche E<lt>schiecheo@cpan.orgE<gt>

http://perfect-co.de/

=head1 LICENSE AND COPYRIGHT

Copyright 2013-2019 Oliver Schieche.

This software is a free library. You can modify and/or distribute it under the
same terms as Perl itself.

=cut
