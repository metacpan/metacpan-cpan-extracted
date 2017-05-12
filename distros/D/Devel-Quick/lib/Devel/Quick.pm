package Devel::Quick;
# ABSTRACT: Write single-step debugger one-liners easily (DB::DB)
$Devel::Quick::VERSION = '0.08';
use strict;
use warnings;

sub import {
	my $class = shift;

	my $strict = 0;
	my $begin = 0;

	my @opts = @_;

	# Parse leading options
	for my $opt (@opts) {
		if ($opt =~ /^-/) {
			if ($opt eq '-s' || $opt eq '-strict') {
				$strict = 1;
				shift @_;
			} elsif ($opt eq '-b' || $opt eq -'begin') {
				$begin = 1;
				shift @_;
			} else {
				require Carp;
				Carp::croak("Unknown switch '$_[0]'");
			}
		} else {
			last;
		}
	}

	# Put back in broken out commas...
	my $code = join(",", @_);

	_gen_db_sub($code, $strict, $begin);
}

sub _gen_db_sub {
	my ($code, $strict, $begin) = @_;

	my $wrapper = <<'DBCODE';
package DB;

use strict;
use warnings;

<<BEGIN>>

sub DB {
	# Get who called us
	my ($package, $filename, $line) = caller(0);

	# Get the rest from the context of who called us
	my (undef, undef, undef,
	    $subroutine, $hasargs, $wantarray,
	    $evaltext, $is_require, $hints,
	    $bitmask, $hinthash) = caller(1);

	return if $package && $package eq 'Devel::Quick';

	my $args = \@_;

	my $code;
	{
		no strict 'refs';
		$code = @{"::_<$filename"}[$line];
	}

	<<NOSTRICT>>

	<<CODE>>
}

1;
DBCODE

	# Leave strict enabled if explicitly asked for
	if ($strict) {
		$wrapper =~ s/<<NOSTRICT>>//;
	} else {
		$wrapper =~ s/<<NOSTRICT>>/no strict;/;
	}

	# Are we stepping as soon as possible? 
	if ($begin) {
		$wrapper =~ s/<<BEGIN>>/\$DB\::single = 1;/;
	} else {
		$wrapper =~ s/<<BEGIN>>//;
	}

	$wrapper =~ s/<<CODE>>/$code/;

	eval $wrapper;

	if (my $err = $@) {
		# Add in line numbers
		my $i = 1;
		$wrapper =~ s/(^|\n)/sprintf("\n%3d:\t", $i++)/ge;

		require Carp;
		Carp::croak("Failed to parse code: $err; code:\n$wrapper");
	}
}

1;

=head1 NAME

Devel::Quick - Write single-step debugger one-liners easily (DB::DB)

=head1 VERSION

version 0.08

=head1 SYNOPSIS

Devel::Trace in one line:

  perl -d:Quick='print ">> $filename:$line $code"' prog.pl

The above, with L<strict> checking enabled (not default):

  perl -d:Quick=-strict,'print ">> $filename:$line $code"' prog.pl

Or shortened:

  perl -d:Quick=-s,'print ">> $filename:$line $code"' prog.pl

The above, but start stepping immediately (look at code in "use ..." 
statements)

  perl -d:Quick=-begin,'print ">> $filename:$line $code"' prog.pl

Or shortened:

  perl -d:Quick=-b,'print ">> $filename:$line $code"' prog.pl

You can combine opts:

  perl -d:Quick=-s,-b,'print ">> $filename:$line $code"' prog.pl

If you need '-' as the first character in your code, use a ';':

  perl -d:Quick='; -1 * 2;' prog.pl

=head1 DESCRIPTION

This module allows you to write simple on-the-fly C<DB::DB> line debuggers 
easily. It injects the following code around the code passed to its import 
method and eval's it in:

  package DB;

  use strict;
  use warnings;

  $DB::single = 1;

  sub DB {
  	# Get who called us
  	my ($package, $filename, $line) = caller(0);
  
  	# Get the rest from the context of who called us
  	my (undef, undef, undef,
  	    $subroutine, $hasargs, $wantarray,
  	    $evaltext, $is_require, $hints,
  	    $bitmask, $hinthash) = caller(1);
  
        return if $package && $package eq 'Devel::Quick';

  	my $args = \@_;
  
  	my $code;
  	{
  		no strict 'refs';
  		$code = @{"::_<$filename"}[$line];
  	}

  	no strict;
  
  	<<CODE>>
  }

By default, warnings are enabled but strict mode is disabled. If you want 
strict, the first argument to import should be C<-s> or C<-strict>.

By default, tracing also starts after compile time. This means that code in
use statements will not be seen. If you want to trace into use statements,
use the C<-b> or C<-begin> flag. 

If you need to pass a C<-> as the first character in the Perl code, you'll need 
to inject a semi-colon (;) before it like so:

  perl -d:Quick='; -1 * 2;' prog.pl

=head2 Available Arguments

A bunch of varibales are provided by default for ease of use, including all 
variables returned by L<perlfunc/"caller">, the source code that's about to be 
executed, and arguments to a subroutine if the code being executed is from one. All 
described below.

=head3 caller() variables

See L<perlfunc/"caller"> for a description of these.

=over 4

=item * B<$package>

=item * B<$filename>

=item * B<$line>

=item * B<$subroutine>

=item * B<$hasargs>

=item * B<$wantarray>

=item * B<$evaltext>

=item * B<$is_require>

=item * B<$hints>

=item * B<$bitmask>

=item * B<$hinthash>

=back

=head3 $code

The variable B<$code> contains the line of source code about to be executed. 
This is provided by C<< @{"_<$filename"} >>. See L<perldebguts> for more 
information.

=head3 $args

B<$args> is simply a reference to C<@_> that the code that is about to be 
executed can see. This is only relevant within subroutines. B<$hasargs> may tell 
you if this is filled in or not, or just check @$args.

Changing the underlying values will affect what the current subroutine sees.

=head1 AUTHOR

Matthew Horsfall (alh) - <WolfSage@gmail.com>

=cut

1;
