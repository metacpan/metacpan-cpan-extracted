package Language::Nouse;

use strict;
use warnings;

our $VERSION = '0.04';

sub new {
        my $class = shift;
        my $self = bless {}, $class;

        my $options = shift;
        $self->clear();

	$self->{sub_get} = \&NOUSE_DEFAULT_get;
	$self->{sub_put} = \&NOUSE_DEFAULT_put;

        return $self;
}

sub clear {
	my ($self) = @_;
	$self->{ring} = [];
	$self->{stack} = [];
	$self->{ring_pointer} = 0;	
}

sub set_get {
	my ($self, $new) = @_;
	$self->{sub_get} = $new;
}

sub set_put {
	my ($self, $new) = @_;
	$self->{sub_put} = $new;
}

sub NOUSE_DEFAULT_get {
	return getc;
}

sub NOUSE_DEFAULT_put {
	print $_[0];
}

sub load_linenoise {
	my ($self, $input) = @_;

	$self->_reset_ring();

	my $op = qr/[#:<>+?^]/;
	my $mul = qr/[0-9a-z_]/;

	my $not_op = qr/[^#:<>+?^]/;
	my $not_mul = qr/[^0-9a-z_]/;

	while ($input =~ m/$not_op*($op)$not_mul*($mul)/g){

		my $this_op = $1;
		my $this_mul = $2;

		$this_op =~ y/#:<>+?^/0123456/;

		$this_mul = 10 + (ord($this_mul) - ord('a')) if ($this_mul =~ m/[a-z]/);
		$this_mul = 36 if ($this_mul eq '_');

		my $op_code = ($this_mul * 7) + $this_op;

		push @{$self->{ring}}, $op_code;
	}

}

sub load_assembly {
	my ($self, $input) = @_;

	$self->_reset_ring();

	$input =~ s/#(.*?)(\r|\n|$)/$2/g;

	my @tokens = split /[,\n\r]/, $input;

	for my $token(@tokens){
		$token =~ s/\s*(.*?)\s*/$1/;

			if ($token =~ m/(cut|paste|read|write|add|test|swap) (\d+)/i){

				my $op = $1;
				my $mul = $2;

				if ($op eq 'cut'){$op = 0;}
				elsif ($op eq 'paste'){$op = 1;}
				elsif ($op eq 'read'){$op = 2;}
				elsif ($op eq 'write'){$op = 3;}
				elsif ($op eq 'add'){$op = 4;}
				elsif ($op eq 'test'){$op = 5;}
				elsif ($op eq 'swap'){$op = 6;}

				push @{$self->{ring}}, ($mul * 7) + $op;

			}elsif ($token =~ m/(\d+)/){

				push @{$self->{ring}}, $1+0;

			}
	}
}

sub get_linenoise {
	my ($self) = @_;

	$self->_reset_ring();

	my $buffer = '';
	for my $raw(@{$self->{ring}}){
		my $op = $raw % 7;
		my $mul = int($raw / 7);

		$op =~ y/0123456/#:<>+?^/;

		if ($mul == 36){
			$mul = '_';
		}elsif ($mul > 9){
			$mul = chr(ord('a') + ($mul - 10));
		}

		$buffer .= $op.$mul;
	}
	return $buffer;
}

sub get_assembly {
	my ($self, $per_line) = @_;

	$self->_reset_ring();

	$per_line = 4 unless defined $per_line;

	my @ops;

	for my $raw(@{$self->{ring}}){
		my $op = $raw % 7;
		my $mul = int($raw / 7);

		if ($op == 0){
			$op = 'cut';
		}elsif ($op == 1){
			$op = 'paste';
		}elsif ($op == 2){
			$op = 'read';
		}elsif ($op == 3){
			$op = 'write';
		}elsif ($op == 4){
			$op = 'add';
		}elsif ($op == 5){
			$op = 'test';
		}elsif ($op == 6){
			$op = 'swap';
		}			

		push @ops, "$op $mul";
	}

	my $buffer = '';
	while (@ops){
		$buffer .= join(', ', splice @ops, 0, $per_line)."\n";
	}

	return $buffer;
}

sub run {
	my ($self) = @_;

	while(scalar(@{$self->{ring}})){
		$self->step();
	}
}

sub step {
	my ($self) = @_;

	my ($op, $mul, $raw) = $self->_get_op();

	my $skip = scalar(@{$self->{stack}}) * $mul;
	$skip++;

	if ($op == 0){
		# cut
		$self->_skip($skip);
		$self->_push($self->_get_oprand());
		$self->_remove_op();
		$skip--;
	}

	if ($op == 1){
		# paste
		$self->_skip($skip);
		if (scalar(@{$self->{stack}})){
			$self->_insert_op($self->_pop());
		}else{
			$self->_insert_op($self->_get_oprand());
		}
	}

	if ($op == 2){
		# read
		my $in = &{$self->{sub_get}}();
		if (defined $in){
			$self->_push(ord($in) % 256);
		}
	}

	if ($op == 3){
		# write
		if (scalar(@{$self->{stack}})){
			&{$self->{sub_put}}(chr($self->_peek()));
		}
	}

	if ($op == 4){
		# add
		if (scalar(@{$self->{stack}})){
			$self->_skip($skip);
			my $oprand = $self->_get_oprand();
		$oprand += $self->_pop();
			$self->_push($oprand % 256);
		}
	}

	if ($op == 5){
		# test
		if (scalar(@{$self->{stack}})){
			$self->_skip($skip);
			my $oprand = $self->_get_oprand();
			if ($oprand == $self->_peek()){
				$self->_pop();
			}
		}
	}

	if ($op == 6){
		# swap
		$self->_swap();
	}

	$self->_skip($skip);
}

sub _skip {
	my ($self, $by) = @_;
	# skip the ring pointer along by $by places
	$self->{ring_pointer} += $by;

	my $s = scalar(@{$self->{ring}});
	if ($s == 0){
		$self->{ring_pointer} = 0;
		return;
	}

	$self->{ring_pointer} = $self->{ring_pointer} % $s;
}

sub _get_op {
	my ($self) = @_;

	my $raw = $self->_get_oprand();
	my $op = $raw % 7;
	my $mul = int($raw / 7);

	return ($op, $mul, $raw);
}

sub _get_oprand {
	my ($self) = @_;
	die "ARGH: The ring is empty and you're asking for an oprand!" if !scalar(@{$self->{ring}});
	return $self->{ring}->[$self->{ring_pointer}];
}

sub _push {
	my ($self, $value) = @_;
	push @{$self->{stack}}, $value;
}

sub _pop {
	my ($self) = @_;
	return pop @{$self->{stack}};
}

sub _peek {
	my ($self) = @_;
	my $data = $self->_pop();
	$self->_push($data);
	return $data;
}

sub _remove_op {
	my ($self) = @_;
	splice @{$self->{ring}}, $self->{ring_pointer}, 1;
}

sub _insert_op {
	my ($self, $value) = @_;
	splice @{$self->{ring}}, $self->{ring_pointer}, 0, ($value);
}

sub _reset_ring {
	my ($self) = @_;

	my $p = $self->{ring_pointer};
	my $l = scalar(@{$self->{ring}});

	my @new_ring = splice(@{$self->{ring}}, $p, $l-$p);
	push @new_ring, splice(@{$self->{ring}}, 0, $p);

	$self->{ring} = \@new_ring;
	$self->{ring_pointer} = 0;
}

sub _swap {
	my ($self) = @_;

	my @new_ring = @{$self->{stack}};

	my $p = $self->{ring_pointer};
	my $l = scalar(@{$self->{ring}});

	my @new_stack = splice(@{$self->{ring}}, $p, $l-$p);
	push @new_stack, splice(@{$self->{ring}}, 0, $p);

	$self->{stack} = \@new_stack;
	$self->{ring} = \@new_ring;
	$self->{ring_pointer} = 0;
}


sub debug {
	my ($self) = @_;

	print "RING: ".join(',',@{$self->{ring}})."  STACK:".join(',',@{$self->{stack}})."\n";
}

1;

__END__

=head1 NAME

Language::Nouse - Perl interpreter for the nouse language

=head1 SYNOPSIS

  use Language::Nouse;

  # create a new interpreter
  my $nouse = new Language::Nouse;

  # load a linenoise formatted program
  $nouse->load_linenoise( '#0<a>0:0#0>e>0:0#0>f>0>0:0#0^f>0:0#0+4>0:0#0#h>0:0#0^f>0:0#0<g>0:0#0>f' );
  $nouse->load_linenoise( '>0:0#0<e>0:0#0?4>0:0#0^1>0:0#0>1>0:0^0' );

  # display the loaded program in assembly mode, with 5 ops per line
  print $nouse->get_assembly( 5 );

  # clear the ring/stack
  $nouse->clear();

  # load an assembly formatted program
  $nouse->load_assembly( 'read 0, write 6, swap 0, test 2, add 1' );

  # run a single step of the program
  $nouse->step();

  # display the loaded program in linenoise mode
  # NOTE: the previous step() call may have chaged the program in the ring!
  print $nouse->get_linenoise();

  # run the program to completion (until the ring is empty)
  $nouse->run();

=head1 DESCRIPTION

The Language::Nouse module is an interpreter for the "nouse" language. It
allows you to load and save nouse programs in both linenoise and assembly
format, single step and run through code.

IO is handled via two callbacks. By default these simply "print" the output
and "getc" for input, but can be configured to use custom routines.

The internals of the execution engine contain a whole bunch of microcode 
methods with are used to run the interpreter. The more adventurous can use
these methods to finely control the engine and inspect the ring and stack.

=head1 METHODS

=over 4

=item C<new()>

Creates and returns a new interpreter. The ring and stack are both empty and the 
ring pointer is set to zero.


=item C<set_get( $code_ref )>

Sets the IO get routine. This routine must return a character when called, or Undef
for the end of available IO.


=item C<set_put( $code_ref )>

Sets the IO put routine. This routine is passed a single argument containing
a single char to output.


=item C<load_linenoise( $source_code )>

Loads a program into the ring, formatted in linenoise mode. If the ring is not 
empty, the program is appended to the end of the ring (that is, in the position 
just *before* the ring pointer).


=item C<load_assembly( $source_code )>

Loads a program into the ring, formatted in assemblye mode. If the ring is not 
empty, the program is appended to the end of the ring (that is, in the position 
just *before* the ring pointer).


=item C<clear()>

Clears the ring and the stack and resets the ring pointer to zero. After a call
to C<clear()>, the interpreter is in the same state as when it was created.


=item C<get_linenoise()>

Returns a scalar containing the current program, formatted in linenoise mode.


=item C<get_assembly()>

=item C<get_assembly( $ops_per_line )>

Returns a scalar containing the current program, formatted in assembly mode. The
optional argument specifies how many ops to show per line. The code is formatted
with commas to seperate ops and, by default, 4 ops per line, which are seperated
with newlines.


=item C<step()>

Runs the program for a single step - that is, it executes the op currently under
the ring pointer.


=item C<run()>

Calls C<step()> until the ring is empty.


=back

=head1 AUTHOR

Copyright (C) 2003 Cal Henderson, E<lt>cal@iamcal.comE<gt>

=head1 SEE ALSO

L<http://www.geocities.com/qpliu/nouse/nouse.html>

=cut
