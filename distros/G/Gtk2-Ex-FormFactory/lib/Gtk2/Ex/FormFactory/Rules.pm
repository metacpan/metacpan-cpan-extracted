package Gtk2::Ex::FormFactory::Rules;

use strict;
use Carp;

use File::Basename;

my %RULES = (
    "empty"			=> sub { $_[0] eq ''			},
    "not-empty"			=> sub { $_[0] ne ''			},

    "alphanumeric"		=> sub { $_[0] =~ /^\w+$/		},
    "identifier"		=> sub { $_[0] =~ /^[a-z_]\w*$/i	},
    "no-whitespace"		=> sub { $_[0] !~ /\s/			},

    "zero"                      => sub { $_[0] =~ /^0(\.0*)?$/		},
    "not-zero"			=> sub { $_[0] !~ /^0(\.0*)?$/		},

    "integer"			=> sub { $_[0] =~ /^[+-]?\d+$/		},
    "positive-integer"		=> sub { $_[0] =~ /^\+?\d+$/ && $_[0] > 0;		},
    "positive-zero-integer"	=> sub { $_[0] =~ /^\+?\d+$/ 		},
    "negative-integer"		=> sub { $_[0] =~ /^-\d+$/		},
    "negative-zero-integer"	=> sub { $_[0] =~ /^(-\d+|0+)$/		},

    "float"			=> sub { $_[0] =~ /^[+-]?\d+(\.\d+)?$/	},
    "positive-float"		=> sub { $_[0] =~ /^\+?\d+(\.\d+)?$/ && $_[0] > 0	},
    "positive-zero-float"	=> sub { $_[0] =~ /^\+?\d+(\.\d+)?$/	},
    "negative-float"		=> sub { $_[0] =~ /^-\d+(\.\d+)?$/	},
    "negative-zero-float"	=> sub { $_[0] =~ /^(-\d+(\.\d+)?|0+)$/	},

    "odd"			=> sub {   $_[0] % 2			},
    "even"			=> sub { !($_[0] % 2)			},
    
    "file-executable"		=> sub { (!-d $_[0] && -x $_[0])	},
    "file-writable"		=> sub { (!-d $_[0] && -w $_[0])	},
    "file-readable"		=> sub { (!-d $_[0] && -r $_[0])	},
    
    "dir-writable"		=> sub { (-d $_[0] && -w $_[0])		},
    "dir-readable"		=> sub { (-d $_[0] && -r $_[0])		},

    "parent-dir-writable"	=> sub { -w dirname($_[0]) 		},
    "parent-dir-readable"	=> sub { -r dirname($_[0])		},

    "executable-command"	=> \&rule_executable_command,

);

my %RULES_MESSAGES = (
    "empty"			=> "{field} is not empty.",
    "not-empty"			=> "{field} is empty.",

    "alphanumeric"		=> "{field} is not alphanumeric.",
    "identifier"		=> "{field} is no identifier.",
    "no-whitespace"		=> "{field} contains whitespace.",

    "zero"			=> "{field} is not zero",
    "not-zero"			=> "{field} is zero",

    "integer"			=> "{field} is no integer.",
    "positive-integer"		=> "{field} is no positive integer.",
    "positive-zero-integer"	=> "{field} is no positive/zero integer.",
    "negative-integer"		=> "{field} is no negative integer.",
    "negative-zero-integer"	=> "{field} is no negative/zero integer.",

    "float"			=> "{field} is no float.",
    "positive-float"		=> "{field} is no positive float.",
    "positive-zero-float"	=> "{field} is no positive/zero float.",
    "negative-float"		=> "{field} is no negative float.",
    "negative-zero-float"	=> "{field} is no negative/zero float.",

    "odd"			=> "{field} is not odd.",
    "even"			=> "{field} is not even.",
    
    "file-executable"		=> "{field} is no file and/or not executable.",
    "file-writable"		=> "{field} is no file and/or not writable.",
    "file-readable"		=> "{field} is no file and/or not readable.",
    
    "dir-writable"		=> "{field} is no directory and/or not writable.",
    "dir-readable"		=> "{field} is no directory and/or not readable.",

    "parent-dir-writable"	=> "{field} has no writable parent directory.",
    "parent-dir-readable"	=> "{field} has no readable parent directory.",
    
    "executable-command"	=> "_rule_result",
);

my $MESSAGE_FORMAT = "Data entered is invalid.\n\n[MESSAGES]\nOld value restored.";

sub get_rules			{ shift->{rules}			}
sub get_rules_messages		{ shift->{rules_messages}		}
sub get_message_format		{ shift->{message_format}		}

sub set_rules			{ shift->{rules}		= $_[1]	}
sub set_rules_messages		{ shift->{rules_messages}	= $_[1]	}
sub set_message_format		{ shift->{message_format}	= $_[1]	}

sub new {
	my $class = shift;
	my %par = @_;
	my  ($rules, $rules_messages, $message_format) =
	@par{'rules','rules_messages','message_format'};

	$rules 		||= {};
	$rules_messages	||= {};
	$message_format ||= $MESSAGE_FORMAT;

	my $self = bless {
		rules		=> $rules,
		rules_messages	=> $rules_messages,
		message_format	=> $message_format,
	}, $class;

	return $self;
}

sub check {
	my $self = shift;
	my ($rules, $field, $value) = @_;

	$field ||= "Value";

	$rules = [ $rules ] unless ref $rules eq 'ARRAY';

	my $messages;
	foreach my $rule ( @{$rules} ) {
		if ( $rule eq 'or-empty' ) {
			return "" if $value eq '';
			next;
		}
		if ( ref $rule eq 'CODE' ) {
			my $msg = &$rule($value);
			$messages .= "$msg\n" if $msg;
			next;
		}
		
		my $coderef = $self->get_rules->{$rule} || $RULES{$rule};
		
		if ( $coderef ) {
			my $rc = &$coderef($value);
			my $message =
				$self->get_rules_messages->{$rule} ||
				$RULES_MESSAGES{$rule};
			warn "Message of rule '$rule' not defined"
				if $message eq '';
			$message ||= "{field} has an unknown error";
			if ( $message eq '_rule_result' ) {
				if ( $rc ne '' ) {
					$messages .= "$rc\n";
				}
			} elsif ( !$rc ) {
				$messages .= "$message\n";
			}
		} else {
			warn "Unknown rule '$rule'. Verification skipped.";
		}
	}

	if ( $messages ) {
		my $format = $self->get_message_format;
		$messages =~ s/\{field\}/$field/g;
		$format =~ s/\[MESSAGES\]/$messages/;
		$messages = $format;
	}

	return $messages;
}

sub rule_executable_command {
	my ($command) = @_;
	
	my ($file) = split (/ /, $command);
	
	if ( not -f $file ) {
		foreach my $p ( split (/:/, $ENV{PATH}) ) {
			$file = "$p/$file",last if -x "$p/$file";
		}
	}
	
	if ( -x $file ) {
		return "";
	} else {
		return "{field} not found" if not -e $file;
		return "{field} not executable";
	}
}

1;

__END__

=head1 NAME

Gtk2::Ex::FormFactory::Rules - Rule checking in a FormFactory framework

=head1 SYNOPSIS

  Gtk2::Ex::FormFactory::Rules->new (
    rules          => Hashref of rules and their implemenation CODEREF's,
    rules_messages => Hashref of the rules' error messages,
    message_format => Format of the "Invalid rules" message thrown
    		      on the GUI,
  );

=head1 DESCRIPTION

This class implements rule checking in a Gtk2::Ex::FormFactory framework.
Each widget can have on or more rules (combined with the locical B<and>
operator, except for the special "or-empty" rule described beyond)
which are checked against the widget's value when the user
changes it. This way you can prevent the user from entering illegal data
at a high level.

Once the user entered illegal data, the old (legal) value is restored
and a corresponding error dialog pops up.

=head1 OBJECT HIERARCHY

  Gtk2::Ex::FormFactory::Rules

=head1 ATTRIBUTES

Attributes are handled through the common get_ATTR(), set_ATTR()
style accessors.

=over 4

=item B<rules> = HASHREF [optional]

This is a hash of user specified rules. A rule has a name
(the hash key) and a CODREF (the hash value) which implements the
rule. The CODEREF has the following prototype:

  $error = &$CODEREF ($value)

If B<$value> doesn't match the rule, B<$error> is the corresponding
error message. B<$error> is undef, if B<$value> is Ok.

=item B<rules_messages> = HASHREF [optional]

This is a hash of the error messages of the user specified rules.
A message should read read as follows:

  {field} is an odd value.

When presented to the user, the {field} place holder is replaced
with the label of the widget in question.

=item B<message_format> = SCALAR [optional]

This is the format string for the error message which is displayed
to the user. The default is:

  Data entered is invalid.\n\n[MESSAGES]\nOld value restored.

where B<[MESSAGES]> is replaced with the actual list of error
messages.

=back

=head1 BUILTIN RULES

This is a verbatim snapshot of the builtin rules and rules_messages
hashes. Please take a look at Gtk2::Ex::FormFactory::Rules' source code
for a recent list of builtin rules:

  my %RULES = (
    "empty"			=> sub { $_[0] eq ''			},
    "not-empty"			=> sub { $_[0] ne ''			},

    "alphanumeric"		=> sub { $_[0] =~ /^\w+$/		},
    "identifier"		=> sub { $_[0] =~ /^[a-z_]\w*$/i	},
    "no-whitespace"		=> sub { $_[0] !~ /\s/			},

    "zero"                      => sub { $_[0] =~ /^0(\.0*)?$/		},
    "not-zero"			=> sub { $_[0] !~ /^0(\.0*)?$/		},

    "integer"			=> sub { $_[0] =~ /^[+-]?\d+$/		},
    "positive-integer"		=> sub { $_[0] =~ /^[+]?\d+$/ 		},
    "negative-integer"		=> sub { $_[0] =~ /^-\d+$/		},

    "float"			=> sub { $_[0] =~ /^[+-]?\d+(\.\d+)?$/	},
    "positive-float"		=> sub { $_[0] =~ /^\+?\d+(\.\d+)?$/	},
    "negative-float"		=> sub { $_[0] =~ /^-\d+(\.\d+)?$/	},

    "odd"			=> sub {   $_[0] % 2			},
    "even"			=> sub { !($_[0] % 2)			},
    
    "file-executable"		=> sub { (!-d $_[0] && -x $_[0])	},
    "file-writable"		=> sub { (!-d $_[0] && -w $_[0])	},
    "file-readable"		=> sub { (!-d $_[0] && -r $_[0])	},
    
    "dir-writable"		=> sub { (-d $_[0] && -w $_[0])		},
    "dir-readable"		=> sub { (-d $_[0] && -r $_[0])		},

    "parent-dir-writable"	=> sub { -w dirname($_[0]) 		},
    "parent-dir-readable"	=> sub { -r dirname($_[0])		},

    "executable-command"	=> "_rule_result",
  );

  my %RULES_MESSAGES = (
    "empty"			=> "{field} is not empty.",
    "not-empty"			=> "{field} is empty.",

    "alphanumeric"		=> "{field} is not alphanumeric.",
    "identifier"		=> "{field} is no identifier.",
    "no-whitespace"		=> "{field} contains whitespace.",

    "zero"			=> "{field} is not zero",
    "not-zero"			=> "{field} is zero",

    "integer"			=> "{field} is no integer.",
    "positive-integer"		=> "{field} is no positive integer.",
    "negative-integer"		=> "{field} is no negative integer.",

    "float"			=> "{field} is no float.",
    "positive-float"		=> "{field} is no positive float.",
    "negative-float"		=> "{field} is no negativ float.",

    "odd"			=> "{field} is not odd.",
    "even"			=> "{field} is not even.",
    
    "file-executable"		=> "{field} is no file and/or not executable.",
    "file-writable"		=> "{field} is no file and/or not writable.",
    "file-readable"		=> "{field} is no file and/or not readable.",
    
    "dir-writable"		=> "{field} is no directory and/or not writable.",
    "dir-readable"		=> "{field} is no directory and/or not readable.",

    "parent-dir-writable"	=> "{field} has no writable parent directory.",
    "parent-dir-readable"	=> "{field} has no readable parent directory.",
  );

=head2 Special "or-empty" rule

There is a special rule called "or-empty". If this rule occurs everywhere
in the list of rules and the actual value is empty, rule checking quits
immediately with a positive result, discarding error states from earlier
rules.

Example: [ "positive-integer", "or-empty" ]

All rules are combined with "and", which is usually sufficient, but without
this special "or-empty" case the common case optionally empty fields 
can't be done.

=head1 AUTHORS

 Jörn Reder <joern at zyn dot de>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2006 by Jörn Reder.

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU Library General Public License as
published by the Free Software Foundation; either version 2.1 of the
License, or (at your option) any later version.

This library is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.

You should have received a copy of the GNU Library General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307
USA.

=cut
