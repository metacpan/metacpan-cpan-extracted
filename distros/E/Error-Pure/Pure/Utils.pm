package Error::Pure::Utils;

# Pragmas.
use base qw(Exporter);
use strict;
use warnings;

# Modules.
use Cwd qw(abs_path);
use Readonly;

# Version.
our $VERSION = 0.24;

# Constants.
Readonly::Array our @EXPORT_OK => qw(clean err_get err_helper err_msg err_msg_hr);
Readonly::Scalar my $DOTS => '...';
Readonly::Scalar my $EMPTY_STR => q{};
Readonly::Scalar my $EVAL => 'eval {...}';
Readonly::Scalar my $UNDEF => 'undef';

# Errors array.
our @ERRORS;

# Default initialization.
our $LEVEL = 2;
our $MAX_LEVELS = 50;
our $MAX_EVAL = 100;
our $MAX_ARGS = 10;
our $MAX_ARG_LEN = 50;
our $PROGRAM = $EMPTY_STR;       # Program name in stack information.

# Clean internal structure.
sub clean {
	@ERRORS = ();
	return;
}

# Get and clean processed errors.
sub err_get {
	my $clean = shift;
	my @ret = @ERRORS;
	if ($clean) {
		clean();
	}
	return @ret;
}

# Process error without die.
sub err_helper {
	my @msg = @_;

	# Check to undefined values in @msg and chomp.
	for (my $i = 0; $i < @msg; $i++) {
		if (! defined $msg[$i]) {
			$msg[$i] = $UNDEF;
		} else {
			chomp $msg[$i];
		}
	}

	# When is list blank, add undef.
	if (! @msg) {
		push @msg, $UNDEF;
	}

	# Get calling stack.
	my @stack = _get_stack();

	# Create errors message.
	push @ERRORS, {
		'msg' => \@msg,
		'stack' => \@stack,
	};

	return @ERRORS;
}

# Get first error messages array.
sub err_msg {
	my $index = shift;
	if (! defined $index) {
		$index = -1;
	}
	my @err = err_get();
	my @ret = @{$err[$index]->{'msg'}};
	return @ret;
}

# Get first error message key, value pairs as hash reference.
sub err_msg_hr {
	my $index = shift;
	if (! defined $index) {
		$index = -1;
	}
	my @err = err_get();
	my @ret = @{$err[$index]->{'msg'}};
	shift @ret;
	return {@ret};
}

# Get information about place of error.
sub _get_stack {
	my $max_level = shift || $MAX_LEVELS;
	my @stack;
	my $tmp_level = $LEVEL;
	my ($class, $prog, $line, $sub, $hargs, $evaltext, $is_require);
	while ($tmp_level < $max_level
		&& do { package DB; ($class, $prog, $line, $sub, $hargs,
		undef, $evaltext, $is_require) = caller($tmp_level++); }) {

		# Prog to absolute path.
		if (-e $prog) {
			$prog = abs_path($prog);
		}

		# Sub name.
		if (defined $evaltext) {
			if ($is_require) {
				$sub = "require $evaltext";
			} else {
				$evaltext =~ s/\n;//sm;
				$evaltext =~ s/([\'])/\\$1/gsm;
				if ($MAX_EVAL
					&& length($evaltext) > $MAX_EVAL) {

					substr($evaltext, $MAX_EVAL, -1,
						$DOTS);
				}
				$sub = "eval '$evaltext'";
			}

		# My eval name.
		} elsif ($sub eq '(eval)') {
			$sub = $EVAL;

		# Other transformation.
		} else {
			$sub =~ s/^$class\:\:([^:]+)$/$1/gsmx;
			if ($sub =~ m/^Error::Pure::(.*)err$/smx) {
				$sub = 'err';
			}
			if ($PROGRAM && $prog =~ m/^\(eval/sm) {
				$prog = $PROGRAM;
			}
		}

		# Args.
		my $i_args = $EMPTY_STR;
		if ($hargs) {
			my @args = @DB::args;
			if ($MAX_ARGS && $#args > $MAX_ARGS) {
				$#args = $MAX_ARGS;
				$args[-1] = $DOTS;
			}

			# Get them all.
			foreach my $arg (@args) {
				if (! defined $arg) {
					$arg = 'undef';
					next;
				}
				if (ref $arg) {

					# Force string representation.
					$arg .= $EMPTY_STR;
				}
				$arg =~ s/'/\\'/gms;
				if ($MAX_ARG_LEN && length $arg> $MAX_ARG_LEN) {
					substr $arg, $MAX_ARG_LEN, -1, $DOTS;
				}

				# Quote (not for numbers).
				if ($arg !~ m/^-?[\d.]+$/ms) {
					$arg = "'$arg'";
				}
			}
			$i_args = '('.(join ', ', @args).')';
		}

		# Information to stack.
		$sub =~ s/\n$//ms;
		push @stack, {
			'class' => $class,
			'prog' => $prog,
			'line' => $line,
			'sub' => $sub,
			'args' => $i_args
		};
	}

	# Stack.
	return @stack;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Error::Pure::Utils - Utilities for structured errors.

=head1 SYNOPSIS

 use Error::Pure::Utils qw(clean err_get err_helper err_msg err_msg_hr);
 clean();
 my @errors = err_get($clean);
 my @err_msg = err_msg($index);
 my $err_msg_hr = err_msg_hr($index);
 my @errors = err_helper('This is a fatal error', 'name', 'value');

=head1 SUBROUTINES

=over 8

=item C<clean()>

 Resets internal variables with errors.
 It is exportable.
 Returns undef.

=item C<err_get([$clean])>

 Get and clean processed errors.
 err_get() returns error structure.
 err_get(1) returns error structure and delete it internally.
 It is exportable.
 Returns array of errors.

=item C<err_msg([$index])>

 Get $index error messages array.
 If $index isn't present, use -1 as last message.
 Is is usable in situation >>err 'Error', 'item1', 'item2', 'item3', 'item4'<<.
 Then returns ('Error', 'item1', 'item2', 'item3', 'item4') array.
 See EXAMPLE2.
 It is exportable.
 Returns array of error messages.

=item C<err_msg_hr([$index])>

 Get $index error message key, value pairs as hash reference.
 If $index isn't present, use -1 as last message.
 Is is usable in situation >>err 'Error', 'key1', 'val1', 'key2', 'val2'<<.
 Then returns {'key1' => 'val1', 'key2' => 'val2'} structure.
 See EXAMPLE3.
 It is exportable.
 Returns reference to hash with error messages.

=item C<err_helper(@msg)>

 Subroutine for additional module above Error::Pure.
 @msg is array of messages.
 If last error is undef, rewrite it to 'undef' string.
 If @msg is blank, add 'undef' string.
 Chomp last error.
 It is exportable.
 Returns array of errors.

=back

=head1 VARIABLES

=over 8

=item C<$LEVEL>

Default value is 2.

=item C<$MAX_LEVELS>

Default value is 50.

=item C<$MAX_EVAL>

Default value is 100.

=item C<$MAX_ARGS>

Default value is 10.

=item C<$MAX_ARG_LEN>

Default value is 50.

=item C<$PROGRAM>

 Program name in stack information.
 Default value is ''.

=back

=head1 EXAMPLE1

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Dumpvalue;
 use Error::Pure::Die qw(err);
 use Error::Pure::Utils qw(err_get);

 # Error in eval.
 eval { err '1', '2', '3'; };

 # Error structure.
 my @err = err_get();

 # Dump.
 my $dump = Dumpvalue->new;
 $dump->dumpValues(\@err);

 # In \@err:
 # [
 #         {
 #                 'msg' => [
 #                         '1',
 #                         '2',
 #                         '3',
 #                 ],
 #                 'stack' => [
 #                         {
 #                                 'args' => '(1)',
 #                                 'class' => 'main',
 #                                 'line' => '9',
 #                                 'prog' => 'script.pl',
 #                                 'sub' => 'err',
 #                         },
 #                         {
 #                                 'args' => '',
 #                                 'class' => 'main',
 #                                 'line' => '9',
 #                                 'prog' => 'script.pl',
 #                                 'sub' => 'eval {...}',
 #                         },
 #                 ],
 #         },
 # ],

=head1 EXAMPLE2

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use English qw(-no_match_vars);
 use Error::Pure qw(err);
 use Error::Pure::Utils qw(err_msg);

 # Error in eval.
 eval {
         err 'Error', 'item1', 'item2', 'item3', 'item4';
 };
 if ($EVAL_ERROR) {
         my @err_msg = err_msg();
         foreach my $item (@err_msg) {
                 print "$item\n";
         }
 }

 # Output:
 # Error
 # item1
 # item2
 # item3
 # item4

=head1 EXAMPLE3

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use English qw(-no_match_vars);
 use Error::Pure qw(err);
 use Error::Pure::Utils qw(err_msg_hr);

 # Error in eval.
 eval {
         err 'Error',
                 'key1', 'val1',
                 'key2', 'val2';
 };
 if ($EVAL_ERROR) {
         print $EVAL_ERROR;
         my $err_msg_hr = err_msg_hr();
         foreach my $key (sort keys %{$err_msg_hr}) {
                 print "$key: $err_msg_hr->{$key}\n";
         }
 }

 # Output:
 # Error
 # key1: val1
 # key2: val2

=head1 DEPENDENCIES

L<Cwd>,
L<Exporter>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Task::Error::Pure>

Install the Error::Pure modules.

=back

=head1 REPOSITORY

L<https://github.com/tupinek/Error-Pure>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2008-2015 Michal Špaček
 BSD 2-Clause License

=head1 VERSION

0.24

=cut
