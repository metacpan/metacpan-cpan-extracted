package Error::Pure::Output::ANSIColor;

use base qw(Exporter);
use strict;
use warnings;

use Readonly;
use Term::ANSIColor;

Readonly::Array our @EXPORT_OK => qw(err_bt_pretty err_bt_pretty_rev err_die
	err_line err_line_all err_print err_print_var);
Readonly::Scalar our $EMPTY_STR => q{};
Readonly::Scalar our $SPACE => q{ };

our $EPANSI_CLASS_COLOR = 'blue';
our $EPANSI_ERROR_COLOR = 'red';
our $EPANSI_LINE_COLOR = 'yellow';
our $EPANSI_OTHER_COLOR = 'cyan';
our $EPANSI_SCRIPT_COLOR = 'yellow';
our $EPANSI_SUB_COLOR = 'green';

our $VERSION = 0.05;

# Pretty print of backtrace.
sub err_bt_pretty {
	my @errors = @_;
	my @ret;
	my $l_ar = _lenghts(@errors);
	foreach my $error_hr (@errors) {
		push @ret, _bt_pretty_one($error_hr, $l_ar);
	}
	return wantarray ? @ret : (join "\n", @ret)."\n";
}

# Reverse pretty print of backtrace.
sub err_bt_pretty_rev {
	my @errors = @_;
	my @ret;
	my $l_ar = _lenghts(@errors);
	foreach my $error_hr (reverse @errors) {
		push @ret, _bt_pretty_one($error_hr, $l_ar);
	}
	return wantarray ? @ret : (join "\n", @ret)."\n";
}

# Pretty print of classic die.
sub err_die {
	my @errors = @_;
	my $error = join $EMPTY_STR, @{$errors[-1]->{'msg'}};
	if ($error eq 'undef') {
		$error = 'Died';
	}
	my $stack_ar = $errors[-1]->{'stack'};
	my $die = color($EPANSI_ERROR_COLOR).$error.
		color($EPANSI_OTHER_COLOR).' at '.
		color($EPANSI_SCRIPT_COLOR).$stack_ar->[0]->{'prog'}.
		color($EPANSI_OTHER_COLOR).' line '.
		color($EPANSI_LINE_COLOR)."$stack_ar->[0]->{'line'}.".
		color('reset');
	return $die;
}

# Pretty print line error.
sub err_line {
	my @errors = @_;
	return _err_line($errors[-1]);
}

# Pretty print with errors each on one line.
sub err_line_all {
	my @errors = @_;
	my $ret;
	foreach my $error_hr (@errors) {
		$ret .= _err_line($error_hr);
	}
	return $ret;
}

# Print error.
sub err_print {
	my @errors = @_;
	my $class = _err_class($errors[-1]);
	return $class.color($EPANSI_ERROR_COLOR).$errors[-1]->{'msg'}->[0].color('reset');
}

# Print error with all variables.
sub err_print_var {
	my @errors = @_;
	my @msg = @{$errors[-1]->{'msg'}};
	my $class = _err_class($errors[-1]);
	my @ret = ($class.color($EPANSI_ERROR_COLOR).(shift @msg).color('reset'));
	push @ret, _err_variables(@msg);
	return wantarray ? @ret : (join "\n", @ret)."\n";
}

# Pretty print one error backtrace helper.
sub _bt_pretty_one {
	my ($error_hr, $l_ar) = @_;
	my @msg = @{$error_hr->{'msg'}};
	my @ret = (color($EPANSI_OTHER_COLOR).'ERROR: '.
		color($EPANSI_ERROR_COLOR).(shift @msg).color('reset'));
	push @ret, _err_variables(@msg);
	foreach my $i (0 .. $#{$error_hr->{'stack'}}) {
		my $st = $error_hr->{'stack'}->[$i];
		my $ret = color($EPANSI_CLASS_COLOR).$st->{'class'}.color('reset');
		$ret .=  $SPACE x ($l_ar->[0] - length $st->{'class'});
		$ret .=  color($EPANSI_SUB_COLOR).$st->{'sub'}.color('reset');
		$ret .=  $SPACE x ($l_ar->[1] - length $st->{'sub'});
		$ret .= color($EPANSI_SCRIPT_COLOR).$st->{'prog'}.color('reset');
		$ret .=  $SPACE x ($l_ar->[2] - length $st->{'prog'});
		$ret .=  color($EPANSI_LINE_COLOR).$st->{'line'}.color('reset');
		push @ret, $ret;
	}
	return @ret;
}

# Print class if class isn't main.
sub _err_class {
	my $error_hr = shift;
	my $class = $error_hr->{'stack'}->[0]->{'class'};
	if ($class eq 'main') {
		$class = $EMPTY_STR;
	}
	if ($class) {
		$class = color($EPANSI_CLASS_COLOR).$class.
			color($EPANSI_OTHER_COLOR).': '.color('reset');
	}
	return $class;
}

# Pretty print line error.
sub _err_line {
	my $error_hr = shift;
	my $stack_ar = $error_hr->{'stack'};
	my $msg = $error_hr->{'msg'};
	my $prog = $stack_ar->[0]->{'prog'};
	$prog =~ s/^\.\///gms;
	my $e = $msg->[0];
	chomp $e;
	return color($EPANSI_OTHER_COLOR).'#Error ['.color($EPANSI_SCRIPT_COLOR).$prog.
		color($EPANSI_OTHER_COLOR).':'.color($EPANSI_LINE_COLOR).$stack_ar->[0]->{'line'}.
		color($EPANSI_OTHER_COLOR).'] '.color($EPANSI_ERROR_COLOR).$e.color('reset')."\n";
}

# Process variables.
sub _err_variables {
	my @msg = @_;
	my @ret;
	while (@msg) {
		my $f = shift @msg;
		my $t = shift @msg;

		if (! defined $f) {
			last;
		}
		my $ret = $f;
		if (defined $t) {
			chomp $t;
			$ret .= color($EPANSI_OTHER_COLOR).': '.
				color($EPANSI_ERROR_COLOR).$t.color('reset');
		}
		push @ret, color($EPANSI_ERROR_COLOR).$ret.color('reset');
	}
	return @ret;
}

# Gets length for errors.
sub _lenghts {
	my @errors = @_;
	my $l_ar = [0, 0, 0];
	foreach my $error_hr (@errors) {
		foreach my $st (@{$error_hr->{'stack'}}) {
			if (length $st->{'class'} > $l_ar->[0]) {
				$l_ar->[0] = length $st->{'class'};
			}
			if (length $st->{'sub'} > $l_ar->[1]) {
				$l_ar->[1] = length $st->{'sub'};
			}
			if (length $st->{'prog'} > $l_ar->[2]) {
				$l_ar->[2] = length $st->{'prog'};
			}
		}
	}
	$l_ar->[0] += 2;
	$l_ar->[1] += 2;
	$l_ar->[2] += 2;
	return $l_ar;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Error::Pure::Output::ANSIColor - ANSIColor Output subroutines for Error::Pure.

=head1 SYNOPSIS

 use Error::Pure::Output::ANSIColor qw(err_bt_pretty err_bt_pretty_rev err_die err_line
         err_line_all err_print err_print_var);

 my $ret = err_bt_pretty(@errors);
 my @ret = err_bt_pretty(@errors);
 my $ret = err_bt_pretty_rev(@errors);
 my @ret = err_bt_pretty_rev(@errors);
 my $ret = err_die(@errors);
 my $ret = err_line(@errors);
 my $ret = err_line_all(@errors);
 my $ret = err_print(@errors);
 my $ret = err_print_var(@errors);
 my @ret = err_print_var(@errors);

=head1 SUBROUTINES

=head2 C<err_bt_pretty>

 my $ret = err_bt_pretty(@errors);
 my @ret = err_bt_pretty(@errors);

Returns string with full backtrace in scalar context.

Returns array of full backtrace lines in array context.

Both with ANSI sequences for terminals.

Format of error is:

 ERROR: %s
 %s: %s
 ...
 %s %s %s %s
 ...

Values of error are:

 message
 message as key, $message as value
 ...
 sub, caller, program, line
 ...

=head2 C<err_bt_pretty_rev>

 my $ret = err_bt_pretty_rev(@errors);
 my @ret = err_bt_pretty_rev(@errors);

Reverse version of print for L<err_bt_pretty()>.

Returns string with full backtrace in scalar context.

Returns array of full backtrace lines in array context.

Both with ANSI sequences for terminals.

Format of error is:

 ERROR: %s
 %s: %s
 ...
 %s %s %s %s
 ...

Values of error are:

 message
 message as key, $message as value
 ...
 sub, caller, program, line
 ...

=head2 C<err_die(@errors)>

 my $ret = err_die(@errors);

Returns string with error in classic die style with colors with ANSI sequences for terminals.

Format of error line is: "%s at %s line %s".

Values of error line are: $message(s), $program, $line

=head2 C<err_line>

 my $ret = err_line(@errors);

Returns string with error on one line with ANSI sequences for terminals.

Use last error in C<@errors> structure.

Format of error is: "#Error [%s:%s] %s\n"

Values of error are: $program, $line, $message

=head2 C<err_line_all>

 my $ret = err_line_all(@errors);

Returns string with errors each on one line with ANSI sequences for terminals.

Use all errors in C<@errors> structure.

Format of error line is: "#Error [%s:%s] %s\n"

Values of error line are: $program, $line, $message

=head2 C<err_print>

 my $ret = err_print(@errors);

Print first error with ANSI sequences for terminals.

If error comes from class, print class name before error.

Returns string with error.

=head2 C<err_print_var>

 my $ret = err_print_var(@errors);
 my @ret = err_print_var(@errors);

Print first error with all variables with ANSI sequences for terminals.

Returns error string in scalar mode.

Returns lines of error in array mode.

=head1 EXAMPLE1

=for comment filename=err_bt_pretty.pl

 use strict;
 use warnings;

 use Error::Pure::Output::ANSIColor qw(err_bt_pretty);

 # Fictional error structure.
 my $err_hr = {
         'msg' => [
                 'FOO',
                 'KEY',
                 'VALUE',
         ],
         'stack' => [
                 {
                         'args' => '(2)',
                         'class' => 'main',
                         'line' => 1,
                         'prog' => 'script.pl',
                         'sub' => 'err',
                 }, {
                         'args' => '',
                         'class' => 'main',
                         'line' => 20,
                         'prog' => 'script.pl',
                         'sub' => 'eval {...}',
                 }
         ],
 };

 # Print out.
 print scalar err_bt_pretty($err_hr);

 # Output:
 # ERROR: FOO
 # KEY: VALUE
 # main  err         script.pl  1
 # main  eval {...}  script.pl  20

=head1 EXAMPLE2

=for comment filename=err_line_all.pl

 use strict;
 use warnings;

 use Error::Pure::Output::ANSIColor qw(err_line_all);

 # Fictional error structure.
 my @err = (
         {
                 'msg' => [
                         'FOO',
                         'BAR',
                 ],
                 'stack' => [
                         {
                                 'args' => '(2)',
                                 'class' => 'main',
                                 'line' => 1,
                                 'prog' => 'script.pl',
                                 'sub' => 'err',
                         }, {
                                 'args' => '',
                                 'class' => 'main',
                                 'line' => 20,
                                 'prog' => 'script.pl',
                                 'sub' => 'eval {...}',
                         }
                 ],
         }, {
                 'msg' => ['XXX'],
                 'stack' => [
                         {
                                 'args' => '',
                                 'class' => 'main',
                                 'line' => 2,
                                 'prog' => 'script.pl',
                                 'sub' => 'err',
                         },
                 ],
         }
 );

 # Print out.
 print err_line_all(@err);

 # Output:
 # #Error [script.pl:1] FOO
 # #Error [script.pl:2] XXX

=head1 EXAMPLE3

=for comment filename=err_line.pl

 use strict;
 use warnings;

 use Error::Pure::Output::ANSIColor qw(err_line);

 # Fictional error structure.
 my $err_hr = {
         'msg' => [
                 'FOO',
                 'BAR',
         ],
         'stack' => [
                 {
                         'args' => '(2)',
                         'class' => 'main',
                         'line' => 1,
                         'prog' => 'script.pl',
                         'sub' => 'err',
                 }, {
                         'args' => '',
                         'class' => 'main',
                         'line' => 20,
                         'prog' => 'script.pl',
                         'sub' => 'eval {...}',
                 }
         ],
 };

 # Print out.
 print err_line($err_hr);

 # Output:
 # #Error [script.pl:1] FOO

=head1 EXAMPLE4

=for comment filename=err_bt_pretty_eval.pl

 use strict;
 use warnings;

 use Error::Pure::Output::ANSIColor qw(err_bt_pretty);

 # Fictional error structure.
 my @err = (
         {
                 'msg' => [
                         'FOO',
                         'BAR',
                 ],
                 'stack' => [
                         {
                                 'args' => '(2)',
                                 'class' => 'main',
                                 'line' => 1,
                                 'prog' => 'script.pl',
                                 'sub' => 'err',
                         }, {
                                 'args' => '',
                                 'class' => 'main',
                                 'line' => 20,
                                 'prog' => 'script.pl',
                                 'sub' => 'eval {...}',
                         }
                 ],
         }, {
                 'msg' => ['XXX'],
                 'stack' => [
                         {
                                 'args' => '',
                                 'class' => 'main',
                                 'line' => 2,
                                 'prog' => 'script.pl',
                                 'sub' => 'err',
                         },
                 ],
         }
 );

 # Print out.
 print scalar err_bt_pretty(@err);

 # Output:
 # ERROR: FOO
 # BAR
 # main  err         script.pl  1
 # main  eval {...}  script.pl  20
 # ERROR: XXX
 # main  err         script.pl  2

=head1 EXAMPLE5

=for comment filename=err_bt_pretty_rev_eval.pl

 use strict;
 use warnings;

 use Error::Pure::Output::ANSIColor qw(err_bt_pretty_rev);

 # Fictional error structure.
 my @err = (
         {
                 'msg' => [
                         'FOO',
                         'BAR',
                 ],
                 'stack' => [
                         {
                                 'args' => '(2)',
                                 'class' => 'main',
                                 'line' => 1,
                                 'prog' => 'script.pl',
                                 'sub' => 'err',
                         }, {
                                 'args' => '',
                                 'class' => 'main',
                                 'line' => 20,
                                 'prog' => 'script.pl',
                                 'sub' => 'eval {...}',
                         }
                 ],
         }, {
                 'msg' => ['XXX'],
                 'stack' => [
                         {
                                 'args' => '',
                                 'class' => 'main',
                                 'line' => 2,
                                 'prog' => 'script.pl',
                                 'sub' => 'err',
                         },
                 ],
         }
 );

 # Print out.
 print scalar err_bt_pretty_rev(@err);

 # Output:
 # ERROR: XXX
 # main  err         script.pl  2
 # ERROR: FOO
 # BAR
 # main  err         script.pl  1
 # main  eval {...}  script.pl  20

=head1 EXAMPLE6

=for comment filename=err_print_main.pl

 use strict;
 use warnings;

 use Error::Pure::Output::ANSIColor qw(err_print);

 # Fictional error structure.
 my $err_hr = {
         'msg' => [
                 'FOO',
                 'BAR',
         ],
         'stack' => [
                 {
                         'args' => '(2)',
                         'class' => 'main',
                         'line' => 1,
                         'prog' => 'script.pl',
                         'sub' => 'err',
                 }, {
                         'args' => '',
                         'class' => 'main',
                         'line' => 20,
                         'prog' => 'script.pl',
                         'sub' => 'eval {...}',
                 }
         ],
 };

 # Print out.
 print err_print($err_hr)."\n";

 # Output:
 # FOO

=head1 EXAMPLE7

=for comment filename=err_print_class.pl

 use strict;
 use warnings;

 use Error::Pure::Output::ANSIColor qw(err_print);

 # Fictional error structure.
 my $err_hr = {
         'msg' => [
                 'FOO',
                 'BAR',
         ],
         'stack' => [
                 {
                         'args' => '(2)',
                         'class' => 'Class',
                         'line' => 1,
                         'prog' => 'script.pl',
                         'sub' => 'err',
                 }, {
                         'args' => '',
                         'class' => 'mains',
                         'line' => 20,
                         'prog' => 'script.pl',
                         'sub' => 'eval {...}',
                 }
         ],
 };

 # Print out.
 print err_print($err_hr)."\n";

 # Output:
 # Class: FOO

=head1 EXAMPLE8

=for comment filename=err_print_var.pl

 use strict;
 use warnings;

 use Error::Pure::Output::ANSIColor qw(err_print_var);

 # Fictional error structure.
 my $err_hr = {
         'msg' => [
                 'FOO',
                 'KEY1',
                 'VALUE1',
                 'KEY2',
                 'VALUE2',
         ],
         'stack' => [
                 {
                         'args' => '(2)',
                         'class' => 'main',
                         'line' => 1,
                         'prog' => 'script.pl',
                         'sub' => 'err',
                 }, {
                         'args' => '',
                         'class' => 'main',
                         'line' => 20,
                         'prog' => 'script.pl',
                         'sub' => 'eval {...}',
                 }
         ],
 };

 # Print out.
 print scalar err_print_var($err_hr);

 # Output:
 # ERROR: FOO
 # KEY1: VALUE1
 # KEY2: VALUE2

=head1 EXAMPLE9

=for comment filename=err_die.pl

 use strict;
 use warnings;

 use Error::Pure::Output::ANSIColor qw(err_die);

 # Fictional error structure.
 my $err_hr = {
         'msg' => [
                 'FOO',
                 'KEY1',
                 'VALUE1',
                 'KEY2',
                 'VALUE2',
         ],
         'stack' => [
                 {
                         'args' => '(2)',
                         'class' => 'main',
                         'line' => 1,
                         'prog' => 'script.pl',
                         'sub' => 'err',
                 }, {
                         'args' => '',
                         'class' => 'main',
                         'line' => 20,
                         'prog' => 'script.pl',
                         'sub' => 'eval {...}',
                 }
         ],
 };

 # Print out.
 print err_die($err_hr);

 # Output:
 # FOOKEY1VALUE1KEY2VALUE2 at script.pl line 1.

=head1 DEPENDENCIES

L<Exporter>,
L<Readonly>,
L<Term::ANSIColor>.

=head1 SEE ALSO

=over

=item L<Task::Error::Pure>

Install the Error::Pure modules.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Error-Pure-Output-ANSIColor>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2013-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.05

=cut
