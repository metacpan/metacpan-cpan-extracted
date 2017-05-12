package Error::Pure::Output::Text;

# Pragmas.
use base qw(Exporter);
use strict;
use warnings;

# Modules.
use Readonly;

# Constants.
Readonly::Array our @EXPORT_OK => qw(err_bt_pretty err_bt_pretty_rev err_line
	err_line_all err_print err_print_var);
Readonly::Scalar our $EMPTY_STR => q{};
Readonly::Scalar our $SPACE => q{ };

# Version.
our $VERSION = 0.22;

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
	return $class.$errors[-1]->{'msg'}->[0];
}

# Print error with all variables.
sub err_print_var {
	my @errors = @_;
	my @msg = @{$errors[-1]->{'msg'}};
	my $class = _err_class($errors[-1]);
	my @ret = ($class.(shift @msg));
	push @ret, _err_variables(@msg);
	return wantarray ? @ret : (join "\n", @ret)."\n";
}

# Pretty print one error backtrace helper.
sub _bt_pretty_one {
	my ($error_hr, $l_ar) = @_;
	my @msg = @{$error_hr->{'msg'}};
	my @ret = ('ERROR: '.(shift @msg));
	push @ret, _err_variables(@msg);
	foreach my $i (0 .. $#{$error_hr->{'stack'}}) {
		my $st = $error_hr->{'stack'}->[$i];
		my $ret = $st->{'class'};
		$ret .=  $SPACE x ($l_ar->[0] - length $st->{'class'});
		$ret .=  $st->{'sub'};
		$ret .=  $SPACE x ($l_ar->[1] - length $st->{'sub'});
		$ret .=  $st->{'prog'};
		$ret .=  $SPACE x ($l_ar->[2] - length $st->{'prog'});
		$ret .=  $st->{'line'};
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
		$class .= ': ';
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
	return "#Error [$prog:$stack_ar->[0]->{'line'}] $e\n";
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
			$ret .= ': '.$t;
		}
		push @ret, $ret;
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

Error::Pure::Output::Text - Output subroutines for Error::Pure.

=head1 SYNOPSIS

 use Error::Pure::Output::Text qw(err_bt_pretty err_bt_pretty_rev err_line
         err_line_all err_print err_print_var);
 my $ret = err_bt_pretty(@errors);
 my @ret = err_bt_pretty(@errors);
 my $ret = err_bt_pretty_rev(@errors);
 my @ret = err_bt_pretty_rev(@errors);
 my $ret = err_line(@errors);
 my $ret = err_line_all(@errors);
 my $ret = err_print(@errors);
 my $ret = err_print_var(@errors);
 my @ret = err_print_var(@errors);

=head1 SUBROUTINES

=over 8

=item C<err_bt_pretty(@errors)>

 Returns string with full backtrace in scalar context.
 Returns array of full backtrace lines in array context.
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

=item C<err_bt_pretty_rev(@errors)>

 Reverse version of print for err_bt_pretty().
 Returns string with full backtrace in scalar context.
 Returns array of full backtrace lines in array context.
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

=item C<err_line(@errors)>

 Returns string with error on one line.
 Use last error in @errors structure..
 Format of error is: "#Error [%s:%s] %s\n"
 Values of error are: $program, $line, $message

=item C<err_line_all(@errors)>

 Returns string with errors each on one line.
 Use all errors in @errors structure.
 Format of error line is: "#Error [%s:%s] %s\n"
 Values of error line are: $program, $line, $message

=item C<err_print(@errors)>

 Print first error.
 If error comes from class, print class name before error.
 Returns string with error.

=item C<err_print_var(@errors)>

 Print first error with all variables.
 Returns error string in scalar mode.
 Returns lines of error in array mode.

=back

=head1 EXAMPLE1

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Error::Pure::Output::Text qw(err_bt_pretty);

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

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Error::Pure::Output::Text qw(err_line_all);

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

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Error::Pure::Output::Text qw(err_line);

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

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Error::Pure::Output::Text qw(err_bt_pretty);

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

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Error::Pure::Output::Text qw(err_bt_pretty_rev);

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

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Error::Pure::Output::Text qw(err_print);

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

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Error::Pure::Output::Text qw(err_print);

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

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Error::Pure::Output::Text qw(err_print_var);

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

=head1 DEPENDENCIES

L<Exporter>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Task::Error::Pure>

Install the Error::Pure modules.

=back

=head1 REPOSITORY

L<https://github.com/tupinek/Error-Pure-Output-Text>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2008-2015 Michal Špaček
 BSD 2-Clause License

=head1 VERSION

0.22

=cut
