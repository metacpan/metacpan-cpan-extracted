package Filter::Template;
{
  $Filter::Template::VERSION = '1.043';
}

use strict;

use Carp qw(croak);
use Filter::Util::Call;
use Symbol qw(gensym);

use constant TMP_PARAMETERS   => 0;
use constant TMP_CODE         => 1;
use constant TMP_NAME         => 2; # only used in temporary %template
use constant TMP_FILE         => 3;
use constant TMP_LINE         => 4; # only used in temporary %template

use constant STATE_PLAIN      => 0x0000;
use constant STATE_TEMPL_DEF  => 0x0001;

use constant COND_FLAG        => 0;
use constant COND_LINE        => 1;
use constant COND_INDENT      => 2;

#use constant DEBUG            => 1;
#use constant DEBUG_INVOKE     => 1;
#use constant DEBUG_DEFINE     => 1;
#use constant WARN_DEFINE      => 1;

BEGIN {
	defined &DEBUG        or eval 'sub DEBUG        () { 0 }'; # preprocessor
	defined &DEBUG_INVOKE or eval 'sub DEBUG_INVOKE () { 0 }'; # templ invocs
	defined &DEBUG_DEFINE or eval 'sub DEBUG_DEFINE () { 0 }'; # templ defines
	defined &WARN_DEFINE  or eval 'sub WARN_DEFINE  () { 0 }'; # redefine warning
};

### Start of regexp optimizer.

# text_trie_trie is virtually identical to code in Ilya Zakharevich's
# Text::Trie::Trie function.  The minor differences involve hardcoding
# the minimum substring length to 1 and sorting the output.

sub text_trie_trie {
	my @list = @_;
	return shift if @_ == 1;
	my (@trie, %first);

	foreach (@list) {
		my $c = substr $_, 0, 1;
		if (exists $first{$c}) {
			push @{$first{$c}}, $_;
		}
		else {
			$first{$c} = [ $_ ];
		}
	}

	foreach (sort keys %first) {
		# Find common substring
		my $substr = $first{$_}->[0];
		(push @trie, $substr), next if @{$first{$_}} == 1;
		my $l = length($substr);
		foreach (@{$first{$_}}) {
			$l-- while substr($_, 0, $l) ne substr($substr, 0, $l);
		}
		$substr = substr $substr, 0, $l;

		# Feed the trie.
		@list = map {substr $_, $l} @{$first{$_}};
		push @trie, [$substr, text_trie_trie(@list)];
	}

	@trie;
}

# This is basically Text::Trie::walkTrie, but it's hardcoded to build
# regular expressions.

sub text_trie_as_regexp {
	my @trie   = @_;
	my $num    = 0;
	my $regexp = '';

	foreach (@trie) {
		$regexp .= '|' if $num++;
		if (ref $_ eq 'ARRAY') {
			$regexp .= $_->[0] . '(?:';

			# If the first tail is empty, make the whole group optional.
			my ($tail, $first);
			if (length $_->[1]) {
				$tail  = ')';
				$first = 1;
			}
			else {
				$tail  = ')?';
				$first = 2;
			}

			# Recurse into the group of tails.
			if ($#$_ > 1) {
				$regexp .= text_trie_as_regexp( @{$_}[$first .. $#$_] );
			}
			$regexp .= $tail;
		}
		else {
			$regexp .= $_;
		}
	}

	$regexp;
}

### End of regexp optimizer.

# These must be accessible from outside the current package.
use vars qw(%conditional_stacks %excluding_code %exclude_indent);

sub fix_exclude {
	my $package_name = shift;
	$excluding_code{$package_name} = 0;
	if (@{$conditional_stacks{$package_name}}) {
		foreach my $flag (@{$conditional_stacks{$package_name}}) {
			unless ($flag->[COND_FLAG]) {
				$excluding_code{$package_name} = 1;
				$exclude_indent{$package_name} = $flag->[COND_INDENT];
				last;
			}
		}
	}
}

my (%constants, %templates, %const_regexp, %template);

sub import {
	my $self = shift;
	my %args;
	if(@_ > 1) {
		%args = @_;
	}

	# Outer closure to define a unique scope.
	{
		my $template_name = '';
		my ($template_line, $enum_index);
		my ($package_name, $file_name, $line_number) = (caller)[0,1,2];
		my $const_regexp_dirty = 0;
		my $state = STATE_PLAIN;

		# The following block processes inheritance requests for
		# templates/constants and enums.  added by sungo 09/2001
		my @isas;

		if ($args{isa}) {
			if (ref $args{isa} eq 'ARRAY') {
				foreach my $isa (@{$args{isa}}) {
					push @isas, $isa;
				}
			}
			else {
				push @isas, $args{isa};
			}

			foreach my $isa (@isas) {
				eval "use $isa";
				croak "Unable to load $isa : $@" if $@;

				foreach my $const (keys %{$constants{$isa}}) {
					$constants{$package_name}->{$const} = $constants{$isa}->{$const};
					$const_regexp_dirty = 1;
				}

				foreach my $template (keys %{$templates{$isa}}) {
					$templates{$package_name}->{$template} = (
						$templates{$isa}->{$template}
					);
				}
			}
		}

	$conditional_stacks{$package_name} = [ ];
	$excluding_code{$package_name} = 0;

	my $set_const = sub {
		my ($name, $value) = @_;

		if (
			WARN_DEFINE and
			exists $constants{$package_name}->{$name} and
			$constants{$package_name}->{$name} ne $value
		) {
			warn "const $name redefined at $file_name line $line_number\n";
		}

		$constants{$package_name}->{$name} = $value;
		$const_regexp_dirty++;

		DEBUG_DEFINE and warn(
			",-----\n",
			"| Defined a constant: $name = $value\n",
			"`-----\n"
		);
	};

	# Define the filter sub.
	filter_add(
		sub {
			my $status = filter_read();
			$line_number++;

			### Handle errors or EOF.
			if ($status <= 0) {
				if (@{$conditional_stacks{$package_name}}) {
					die(
						"include block never closed.  It probably started " .
						"at $file_name line " .
						$conditional_stacks{$package_name}->[0]->[COND_LINE] . "\n"
					);
				}
				return $status;
			}

			### Usurp modified Perl syntax for code inclusion.  These
			### are hardcoded and always handled.

			# Only do the conditionals if there's a flag present.
			if (/\#\s*include/) {

				# if (...) { # include
				if (/^(\s*)if\s*\((.+)\)\s*\{\s*\#\s*include\s*$/) {
					my $space = (defined $1) ? $1 : '';
					$_ = (
						$space .
						"BEGIN { push( \@{\$" . __PACKAGE__ .
						"::conditional_stacks{'$package_name'}}, " .
						"[ !!$2, $line_number, '$space' ] ); \&" . __PACKAGE__ .
						"::fix_exclude('$package_name'); }; # $_"
					);
					s/\#\s+/\# /;

					# Dummy line in the template.
					if ($state & STATE_TEMPL_DEF) {
						local $_ = $_;
						s/B/\# B/;
						$template_line++;
						$template{$package_name}->[TMP_CODE] .= $_;
						DEBUG and warn sprintf "%4d M: # mac 1: %s", $line_number, $_;
					}
					else {
						DEBUG and warn sprintf "%4d C: %s", $line_number, $_;
					}

					return $status;
				}

				# } # include
				elsif (/^\s*\}\s*\#\s*include\s*$/) {
					s/^(\s*)/$1\# /;
					pop @{$conditional_stacks{$package_name}};
					&fix_exclude($package_name);

					unless ($state & STATE_TEMPL_DEF) {
						DEBUG and warn sprintf "%4d C: %s", $line_number, $_;
						return $status;
					}
				}

					# } else { # include
					elsif (/^\s*\}\s*else\s*\{\s*\#\s*include\s*$/) {
						unless (@{$conditional_stacks{$package_name}}) {
							die(
								"else { # include ... without if or unless " .
								"at $file_name line $line_number\n"
							);
							return -1;
						}

						s/^(\s*)/$1\# /;
						$conditional_stacks{$package_name}->[-1]->[COND_FLAG] = (
							!$conditional_stacks{$package_name}->[-1]->[COND_FLAG]
						);
						&fix_exclude($package_name);

						unless ($state & STATE_TEMPL_DEF) {
							DEBUG and warn sprintf "%4d C: %s", $line_number, $_;
							return $status;
						}
					}

					# unless (...) { # include
					elsif (/^(\s*)unless\s*\((.+)\)\s*\{\s*\#\s*include\s*$/) {
						my $space = (defined $1) ? $1 : '';
						$_ = (
							$space .
							"BEGIN { push( \@{\$" . __PACKAGE__ .
							"::conditional_stacks{'$package_name'}}, " .
							"[ !$2, $line_number, '$space' ] ); \&" . __PACKAGE__ .
							"::fix_exclude('$package_name'); }; # $_"
						);
						s/\#\s+/\# /;

						# Dummy line in the template.
						if ($state & STATE_TEMPL_DEF) {
							local $_ = $_;
							s/B/\# B/;
							$template_line++;
							$template{$package_name}->[TMP_CODE] .= $_;
							DEBUG and warn sprintf "%4d M: # mac 2: %s", $line_number, $_;
						}
						else {
							DEBUG and warn sprintf "%4d C: %s", $line_number, $_;
						}

						return $status;
					}

					# } elsif (...) { # include
					elsif (/^(\s*)\}\s*elsif\s*\((.+)\)\s*\{\s*\#\s*include\s*$/) {
						unless (@{$conditional_stacks{$package_name}}) {
							die(
								"Include elsif without include if or unless " .
								"at $file_name line $line_number\n"
							);
							return -1;
						}

						my $space = (defined $1) ? $1 : '';
						$_ = (
							$space .
							"BEGIN { \$" . __PACKAGE__ .
							"::conditional_stacks{'$package_name'}->[-1] = " .
							"[ !!$2, $line_number, '$space' ]; \&" . __PACKAGE__ .
							"::fix_exclude('$package_name'); }; # $_"
						);
						s/\#\s+/\# /;

						# Dummy line in the template.
						if ($state & STATE_TEMPL_DEF) {
							local $_ = $_;
							s/B/\# B/;
							$template_line++;
							$template{$package_name}->[TMP_CODE] .= $_;
							DEBUG and warn sprintf "%4d M: # mac 3: %s", $line_number, $_;
						}
						else {
							DEBUG and warn sprintf "%4d C: %s", $line_number, $_;
						}

						return $status;
					}
				}

				### Not including code, so comment it out.  Don't return
				### $status here since the code may well be in a template.
				if ($excluding_code{$package_name}) {
					s{^($exclude_indent{$package_name})?}
					 {$exclude_indent{$package_name}\# };

					# Kludge: Must thwart templates on this line.
					s/\{\%(.*?)\%\}/TEMPLATE($1)/g;

					unless ($state & STATE_TEMPL_DEF) {
						DEBUG and warn sprintf "%4d C: %s", $line_number, $_;
						return $status;
					}
				}

				### Inside a template definition.
				if ($state & STATE_TEMPL_DEF) {

					# Close it!
					if (/^\}\s*$/) {
						$state = STATE_PLAIN;

						DEBUG_DEFINE and warn (
							",-----\n",
							"| Defined template $template_name\n",
							"| Parameters: ",
							@{$template{$package_name}->[TMP_PARAMETERS]}, "\n",
							"| Code: {\n",
							$template{$package_name}->[TMP_CODE],
							"| }\n",
							"`-----\n"
						);

						$template{$package_name}->[TMP_CODE] =~ s/^\s*//;
						$template{$package_name}->[TMP_CODE] =~ s/\s*$//;

						if (
							WARN_DEFINE and
							exists $templates{$package_name}->{$template_name} and
							(
								$templates{$package_name}->{$template_name}->[TMP_CODE] ne
								$template{$package_name}->[TMP_CODE]
							)
						) {
							warn(
								"template $template_name redefined at ",
								"$file_name line $line_number\n"
							);
						}

						$templates{$package_name}->{$template_name} = (
							$template{$package_name}
						);

						$template_name = '';
					}

					# Otherwise append this line to the template.
					else {
						$template_line++;
						$template{$package_name}->[TMP_CODE] .= $_;
					}

					# Either way, the code must not go on.
					$_ = "# mac 4: $_";
					DEBUG and warn sprintf "%4d M: %s", $line_number, $_;

					return $status;
				}

				### Ignore everything after __END__ or __DATA__.  This works
				### around a coredump in 5.005_61 through 5.6.0 at the
				### expense of preprocessing data and documentation.
				if (/^__(END|DATA)__\s*$/) {
					$_ = "# $_";
					return 0;
				}

				### We're done if we're excluding code.
				if ($excluding_code{$package_name}) {
					return $status;
				}

				### Define an enum.
				if (/^enum(?:\s+(\d+|\+))?\s+(.*?)\s*$/) {
					my $temp_line = $_;

					$enum_index = (
						(defined $1)
						? (
							($1 eq '+')
							? $enum_index
							: $1
						)
						: 0
					);
					foreach (split /\s+/, $2) {
						$set_const->($_, $enum_index++);
					}

					$_ = "# $temp_line";

					DEBUG and warn sprintf "%4d E: %s", $line_number, $_;

					return $status;
				}

				### Define a constant.
				if (/^const\s+(\S+)\s+(.+?)\s*$/i) {
					&{$set_const}($1, $2);
					$_ = "# $_";
					DEBUG and warn sprintf "%4d E: %s", $line_number, $_;

					return $status;
				}

				### Begin a template definition.
				if (/^template\s*(\w+)\s*(?:\((.*?)\))?\s*\{\s*$/) {
					$state = STATE_TEMPL_DEF;

					my $temp_line = $_;

					$template_name = $1;
					$template_line = 0;
					my @template_params = (
						(defined $2)
						? split(/\s*\,\s*/, $2)
						: ()
					);

					$template{$package_name} = [
						\@template_params,  # TMP_PARAMETERS
						'',                 # TMP_CODE
						$template_name,     # TMP_NAME
						$file_name,         # TMP_FILE
						$line_number,       # TMP_LINE
					];

					$_ = "# $temp_line";
					DEBUG and warn sprintf "%4d D: %s", $line_number, $_;

					return $status;
				}

				### Perform template substitutions.
				my $substitutions = 0;
				while (/(\{\%\s+(\S+)\s*(.*?)\s*\%\})/gs) {
					my ($name, $params) = ($2, $3);

					# Backtrack to the beginning of the substitution so that
					# the newly inserted text may also be checked.
					pos($_) -= length($1);

					DEBUG_INVOKE and warn(
						",-----\n| template invocation: $name $params\n"
					);

					if (exists $templates{$package_name}->{$name}) {

						my @use_params = split /\s*\,\s*/, $params;
						my @mac_params = (
							@{$templates{$package_name}->{$name}->[TMP_PARAMETERS]}
						);

						if (@use_params != @mac_params) {
							warn(
								"template $name parameter count (",
								scalar(@use_params),
								") doesn't match defined count (",
								scalar(@mac_params),
								") at $file_name line $line_number\n"
							);

							return $status;
						}

						# Build a new bit of code here.
						my $substitution  = $templates{$package_name}->{$name}->[TMP_CODE];
						my $template_file = $templates{$package_name}->{$name}->[TMP_FILE];
						my $template_line = $templates{$package_name}->{$name}->[TMP_LINE];

						foreach my $mac_param (@mac_params) {
							my $use_param = shift @use_params;
							1 while ($substitution =~ s/$mac_param/$use_param/g);
						}

						unless ($^P) {
							my @sub_lines = split /\n/, $substitution;
							my $sub_line = @sub_lines;
							while ($sub_line--) {
								splice(
									@sub_lines, $sub_line, 0,
									"# line $line_number " .
									"\"template $name (defined in $template_file at line " .
									($template_line + $sub_line + 1) . ") " .
									"invoked from $file_name\""
								);
							}
							$substitution = join "\n", @sub_lines;
						}

						substr($_, pos($_), length($1)) = $substitution;
						$_ .= "# line " . ($line_number+1) . " \"$file_name\"\n" unless $^P;

						DEBUG_INVOKE and warn "$_`-----\n";

						$substitutions++;
					}
					else {
						die(
							"template $name has not been defined ",
							 "at $file_name line $line_number\n"
						 );
						last;
					}
				}

				# Only rebuild the constant regexp if necessary.  This
				# prevents redundant regexp rebuilds when defining several
				# constants all together.
				if ($const_regexp_dirty) {
					$const_regexp{$package_name} = text_trie_as_regexp(
						text_trie_trie(keys %{$constants{$package_name}})
					);
					$const_regexp_dirty = 0;
				}

				# Perform constant substitutions.
				if (defined $const_regexp{$package_name}) {
					$substitutions += (
						s[\b($const_regexp{$package_name})\b]
						 [$constants{$package_name}->{$1}]sg
					);
				}

				# Trace substitutions.
				if (DEBUG) {
					if ($substitutions) {
						foreach my $line (split /\n/) {
							warn sprintf "%4d S: %s\n", $line_number, $line;
						}
					}
					else {
						warn sprintf "%4d |: %s", $line_number, $_;
					}
				}

				return $status;
			}
		);
	}
}

# Clear a package's templates.  Used for destructive testing.
sub clear_package {
	my ($self, $package) = @_;
	delete $constants{$package};
	delete $templates{$package};
	delete $const_regexp{$package};
	delete $template{$package};
}

1;

__END__

=head1 NAME

Filter::Template - a source filter for inline code templates (macros)

=head1 VERSION

version 1.043

=head1 SYNOPSIS

	use Filter::Template;

	# use Filter::Template ( isa => 'SomeModule' );

	template max (one,two) {
		((one) > (two) ? (one) : (two))
	}

	print {% max $one, $two %}, "\n";

	const PI 3.14159265359

	print "PI\n";         # Constants are expanded inside strings.
	print "HAPPINESS\n";  # Also expanded due to naive parser.

	enum ZERO ONE TWO
	enum 12 TWELVE THIRTEEN FOURTEEN
	enum + FIFTEEN SIXTEEN SEVENTEEN

	# Prints numbers, due to naive parser.
	print "ZERO ONE TWO TWELVE THIRTEEN FOURTEEN FIFTEEN SIXTEEN SEVENTEEN\n";

	if ($expression) {      # include
		 ... lines of code ...
	}                       # include

	unless ($expression) {  # include
		... lines of code ...
	} elsif ($expression) { # include
		... lines of code ...
	} else {                # include
		... lines of code ...
	}                       # include

=head1 DESCRIPTION

Filter::Template is a Perl source filter that provides simple inline
source code templates.  Inlined source code can be significantly
faster than subroutines, especially for small-scale functions like
accessors and mutators.  On the other hand, they are more difficult to
maintain and use.  Choose your trade-offs wisely.

=head2 Templates

Code templates are defined with the C<template> statement, which looks
a lot like C<sub>.  Because this is a naive source filter, however,
the open brace must be on the same line as the C<template> keyword.
Furthermore, the first closing brace in column zero ends a macro body.

	template oops {
		die "Oops";
	}

Templates are inserted into a program using a simple syntax that was
adapted from other template libraries.  It was chosen to be compatible
with the Perl syntax highlighting of common text editors.

This inserts the body of C<template oops>.

	{% oops %}

Templates can have parameters.  The syntax for template parameters was
based on prototypes for Perl subroutines.  The two main differences
are that parameters are named, and sigils are not used.

	template sum_2 (parameter_0, parameter_1) {
		print( parameter_0 + parameter_1, "\n" );
	}

To insert a template with parameters, simply list the parameters after
the template name.

	{% sum_2 $base, $increment %}

At expansion time, occurrences of the parameter names within the
template are replaced with the source code provided in the template
invocation.  In the previous example, C<sum_2> literally expands to

  print( $base + $increment, "\n" );

and is then compiled by Perl.

=head2 Constants and Enumerations

Filter::Template also defines C<const> and C<enum> keywords.  They are
essentially simplified templates without parameters.

C<const> defines a constant that is replaced before compile time.
Unlike Perl's native constants, these are not demoted to function
calls when Perl is run in debugging or profiling mode.

	const CONSTANT_NAME     'constant value'
	const ANOTHER_CONSTANT  23

Enumerations are like constants but several sequential integers can be
defined in one statement.  Enumerations start from zero by default:

	enum ZEROTH FIRST SECOND

If the first parameter of an enumeration is a number, then the
enumerated constants will start with that value:

	enum 10 TENTH ELEVENTH TWELFTH

Enumerations may not span lines, but they can be continued.  If the
first enumeration parameter is the plus sign, then constants will
start where the previous enumeration left off.

	enum 13 THIRTEENTH FOURTEENTH  FIFTEENTH
	enum +  SIXTEENTH  SEVENTEENTH EIGHTEENTH

=head2 Conditional Code Inclusion (#ifdef)

The preprocessor supports something like cpp's #if/#else/#endif by
usurping a bit of Perl's conditional syntax.  The following
conditional statements will be evaluated at compile time if they are
followed by the comment C<# include>:

	if (EXPRESSION) {      # include
		BLOCK;
	} elsif (EXPRESSION) { # include
		BLOCK;
	} else {               # include
		BLOCK;
	}                      # include

	unless (EXPRESSION) {  # include
		BLOCK;
	}                      # include

The code in each conditional statement's BLOCK will be included or
excluded in the compiled code depending on the outcome of its
EXPRESSION.

Conditional includes are nestable, but else and elsif must be on the
same line as the previous block's closing brace, as they are in the
previous example.

Filter::Template::UseBytes uses conditional code to define different
versions of a {% use_bytes %} macro depending whether the C<bytes>
pragma exists.

=head1 IMPORTING TEMPLATES

Filter::Template can import templates defined by another class.  For
example, this invocation imports the C<use_bytes> template:

	use Filter::Template ( isa => 'Filter::Template::UseBytes' );

Imported templates can be redefined in the current namespace.

Note: If the imported templates require additional Perl modules, any
code which imports them must also C<use> those modules.

=head1 DEBUGGING

Filter::Template has three debugging constants which will only take
effect if they are defined before the module is first used.

To trace source filtering in general, and to see the resulting code
and operations performed on each line, define:

	sub Filter::Template::DEBUG () { 1 }

To trace template invocations as they happen, define:

	sub Filter::Template::DEBUG_INVOKE () { 1 }

To see template, constant, and enum definitions, define:

	sub Filter::Template::DEBUG_DEFINE () { 1 }

To see warnings when a template or constant is redefined, define:

	sub Filter::Template::DEFINE () { 1 }

=head1 CAVEATS

Source filters are line-based, and so is the template language.  The
only constructs that may span lines are template definitions, and
those B<must> span lines.

Filter::Template does not parse perl.  The regular expressions that
detect and replace code are simplistic and may not do the right things
when parsing challenging Perl syntax.  Constants are replaced within
strings, for example.

The regexp optimizer makes silly subexpressions like /(?:|m)/.  That
could be done better as /m?/ or /(?:jklm)?/ if the literal is longer
than a single character.

The regexp optimizer does not optimize (?:x|y|z) as character classes.

The regexp optimizer is based on code in Ilya Zakharevich's
Text::Trie.  Better regexp optimizers were released afterwards, and
Filter::Template should use one of them.

=head1 LINKS

=head2 BUG TRACKER

https://rt.cpan.org/Dist/Display.html?Status=Active&Queue=Filter-Template

=head2 REPOSITORY

http://github.com/rcaputo/filter-template
http://gitorious.org/filter-template

=head2 OTHER RESOURCES

http://search.cpan.org/dist/Filter-Template/

=head1 SEE ALSO

L<Text::Trie>, L<PAR>, L<Filter::Template::UseBytes>.

=head1 AUTHOR & COPYRIGHT

Filter::Template is Copyright 2000-2013 Rocco Caputo.  Some parts are
Copyright 2001 Matt Cashner.  All rights reserved.  Filter::Template
is free software; you may redistribute it and/or modify it under the
same terms as Perl itself.

Filter::Template was previously known as POE::Preprocessor.

=cut
