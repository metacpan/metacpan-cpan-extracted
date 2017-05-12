package Inline::SMITH;

$VERSION = '0.03';
require Inline;
@ISA = qw(Inline);
use strict;
use Carp;

sub register {
	return {
		language => 'SMITH',
		aliases => ['Smith', 'smith'],
		type => 'interpreted',
		suffix => 'smt',
	};
}

sub usage_config { 
	my $key = shift;
	"'$key' is not a valid config option for Inline::SMITH\n";
}

sub validate {
}

sub build {
	my $o = shift;
	my $code = $o->{API}{code};
	my $pattern = $o->{ILSM}{PATTERN};
	$code = smith_load($code);
	{
		package Inline::SMITH::Loader;
		eval $code;
	}
	croak "Brainfuck build failed:\n$@" if $@;
	my $path = "$o->{API}{install_lib}/auto/$o->{API}{modpname}";
	my $obj = $o->{API}{location};
	$o->mkpath($path) unless -d $path;
	open FOO_OBJ, "> $obj" or croak "Can't open $obj for output\n$!";
	print FOO_OBJ $code;
	close \*FOO_OBJ;
}

sub load {
	my $o = shift;
	my $obj = $o->{API}{location};
	open FOO_OBJ, "< $obj" or croak "Can't open $obj for output\n$!";
	my $code = join '', <FOO_OBJ>;
	close \*FOO_OBJ;
	eval "package $o->{API}{pkg};\n$code";
	croak "Unable to load Foo module $obj:\n$@" if $@;
}

sub info {
	my $o = shift;
}


sub smith_load {
	my ($code) = @_;
	my $out = "";

	while($code =~ m/function(\s+)([a-z0-9_]+)(\s*){{(.*?)}}/isg){
		my $func_name = $2;
		my $func_code = $4;
		# print "loaded function $func_name\n";
		$func_code =~ s/\|/\\|/g;
		$out .= "sub $func_name { return Inline::SMITH::smith_run(q|$func_code|, \$_[0]); }\n";
	}

	return $out;
}

sub smith_run {
	my ($code, $data) = @_;

	my $buffer = "";
	my @data;
	my $input_callback;
	my $output_callback;
	my $echo = 1;

	if (ref $data eq 'HASH'){
		@data = split(//, ${$data}{input}) if ${$data}{input};
		$input_callback = ${$data}{input_callback} || 0;
		$output_callback = ${$data}{output_callback} || 0;
		$echo = ${$data}{echo} || 0;
	}else{
		@data = split(//, $data);
	}

	my $mem = [];
	my $reg = [];
	my $debug = 0;
	my $cont = 0;
	my $quiet = 0;
	my $pause = 0;
	my ($ggg, $hhh);

	#
	# load the code into $mem
	#

	my @lines = split(/\r?\n/, $code);
	my $line = '';
	my $i = 0;
	for $line(@lines){
		$line = $' if $line =~ /^\s*/;
		$line = $` if $line =~ /\s*$/;
		$line =~ s/\s*;.*?$//;
		$line =~ s/\*/$i/ge;
		if ($line =~ /^\S+/){
			my $reps = 1;
			my $j;
			if ($line =~ /^REP\s*(\d+)\s*/){
				$line = $';
				$reps = $1;
			}
			for($j = 0; $j < $reps; $j++){
				$mem->[$i] = $line;
				# print "Load $i = $mem->[$i]\n" if $showload;
				$i++;
			}
		}
	}

	#
	# run the code
	#

	my $pc = 0;
	while($mem->[$pc] ne 'STOP') {

		if ($mem->[$pc] =~ /^MOV\s*R(\d+)\s*,\s*\#?(\d+)$/) {			# MOV reg, imm
			$reg->[$1] = $2;
		} elsif ($mem->[$pc] =~ /^MOV\s*R(\d+)\s*,\s*R(\d+)$/) {		# MOV reg, reg
			$reg->[$1] = $reg->[$2];
		} elsif ($mem->[$pc] =~ /^MOV\s*R\[R(\d+)\]\s*,\s*R(\d+)$/) {		# MOV [reg], reg
			$reg->[$reg->[$1]] = $reg->[$2];
		} elsif ($mem->[$pc] =~ /^MOV\s*R(\d+)\s*,\s*R\[R(\d+)\]$/) {		# MOV reg, [reg]
			$reg->[$1] = $reg->[$reg->[$2]];
		} elsif ($mem->[$pc] =~ /^MOV\s*R\[R(\d+)\]\s*,\s*\"(.*?)\"$/) {	# MOV [reg], "string"
			my $i = $reg->[$1];
			my $s = $2;
			while($i < ($reg->[$1] + length($s))) {
				$reg->[$i] = ord(substr($s, ($i-$reg->[$1]), 1));
				$i++;
			}
		} elsif ($mem->[$pc] =~ /^MOV\s*R(\d+)\s*,\s*PC$/) {			# MOV reg, PC
			$reg->[$1] = $pc;
		} elsif ($mem->[$pc] =~ /^MOV\s*TTY\s*,\s*R(\d+)$/) {			# MOV TTY, reg
			print chr($reg->[$1]) if $echo;
			$buffer .= chr($reg->[$1]);
			&{$output_callback}(chr($reg->[$1])) if $output_callback;
		} elsif ($mem->[$pc] =~ /^MOV\s*TTY\s*,\s*R\[R(\d+)\]$/) {		# MOV TTY, [reg]
			print chr($reg->[$reg->[$1]]) if $echo;
			$buffer .= chr($reg->[$reg->[$1]]);
			&{$output_callback}(chr($reg->[$reg->[$1]])) if $output_callback;
		} elsif ($mem->[$pc] =~ /^MOV\s*R(\d+)\s*,\s*TTY$/) {			# MOV reg, TTY
			$reg->[$1] = ($input_callback)?&{$input_callback}:shift @data;
			if ($reg->[$1]) {
				$reg->[$1] = ord($reg->[$1]);					
			} else {
				$reg->[$1] = 0;
			}
		} elsif ($mem->[$pc] =~ /^MOV\s*R\[R(\d+)\]\s*,\s*TTY$/) {		# MOV [reg], TTY
			$reg->[$reg->[$1]] = ($input_callback)?&{$input_callback}:shift @data;
			if ($reg->[$reg->[$1]]) {
				$reg->[$reg->[$1]] = ord($reg->[$reg->[$1]]);
			} else {
				$reg->[$reg->[$1]] = 0;
			}
		} elsif ($mem->[$pc] =~ /^SUB\s*R(\d+)\s*,\s*\#?(\d+)$/) {		# SUB reg, imm
			$reg->[$1] -= $2;
		} elsif ($mem->[$pc] =~ /^SUB\s*R(\d+)\s*,\s*R(\d+)$/) {		# SUB reg, reg
			$reg->[$1] -= $reg->[$2];
		} elsif ($mem->[$pc] =~ /^MUL\s*R(\d+)\s*,\s*\#?(\d+)$/) {		# MUL reg, imm
			$reg->[$1] *= $2;
		} elsif ($mem->[$pc] =~ /^MUL\s*R(\d+)\s*,\s*R(\d+)$/) {		# MUL reg, reg
			$reg->[$1] *= $reg->[$2];
		} elsif ($mem->[$pc] =~ /^NOT\s*R(\d+)$/) {				# NOT reg
			if($reg->[$1] != 0) {
				$reg->[$1] = 0;
			} else {
				$reg->[$1] = 1;
			}
		} elsif ($mem->[$pc] =~ /^COR\s*([-+]\d+)\s*,\s*([-+]\d+)\s*,\s*R(\d+)\s*$/) {		# COR imm, imm, reg
			my $dst = 0+$pc+$1;
			my $src = 0+$pc+$2;
			my $lrg = 0+$3;
			my $i;
			{
				for ($i = 0; $i < $reg->[$lrg]; $i++) {
					$mem->[$dst+$i] = $mem->[$src+$i];
					$ggg = $dst + $i;
					$hhh = $src + $i;
				}
			}
		} elsif ($mem->[$pc] =~ /^COR\s*([-+]\d+)\s*,\s*R(\d+)\s*,\s*R(\d+)\s*$/) {		# COR imm, reg, reg
			my $dst = 0+$pc+$1;
			my $src = 0+$pc+$reg->[$2];
			my $lrg = 0+$3;
			my $i;
			{
				for ($i = 0; $i < $reg->[$lrg]; $i++) {
					$mem->[$dst+$i] = $mem->[$src+$i];
					$ggg = $dst + $i;
					$hhh = $src + $i;
				}
			}
		} elsif ($mem->[$pc] =~ /^BLA\s*([-+]\d+)\s*,\s*(\w+)\s*,\s*R(\d+)\s*$/) {		# BLA imm, OPC, reg
			my $dst = 0+$pc+$1;
			my $src = $2;
			my $lrg = 0+$3;
			my $i;
			{
				for ($i = 0; $i < $reg->[$lrg]; $i++) {
					$mem->[$dst+$i] = $src;
					$ggg = $dst + $i;
				}
			}
		} elsif ($mem->[$pc] =~ /^NOP$/) {						# NOP
			# Nothing happens here.
		} else {
			print "Invalid instruction $mem->[$pc]!\n";
			$pc = $#{$mem} + 1 if not $cont;
		}
		$pc++;
		$mem->[$pc] = 'STOP' if $pc > $#{$mem};
	}

	#
	# we're done
	#

	return $buffer;
}

1;

__END__


=head1 NAME

Inline::SMITH - write Perl subs in SMITH


=head1 SYNOPSIS

    use Inline SMITH => <<EOF;
 
    function ascii_table {{

      ; Print ASCII table in descending order in SMITH v1
      ; (relatively easy)

      MOV R0, 126       ; Initialize register with top character
      MOV TTY, R0       ; -> Print character to terminal
      SUB R0, 1         ; -> Decrement character
      MOV R1, R0        ; -> Is character zero?
      NOT R1            ; -> Boolean NOT it twice to find out
      NOT R1            ; -> Result is 1 if true, 0 if false
      MUL R1, 7         ; -> Multiply result by seven instructions
      COR +1, -6, R1    ; -> Copy that many instructions forward
    
    }}

    EOF

    ascii_table();

=head1 DESCRIPTION

The C<Inline::SMITH> module allows you to put SMITH source code
directly "inline" in a Perl script or module.


=head1 USING Inline::SMITH

Using C<Inline::SMITH> will seem very similar to using a another
Inline language, thanks to Inline's consistent look and feel.

For more details on C<Inline>, see C<perldoc Inline>.


=head2 Feeding Inline with your code

The recommended way of using Inline is the following:

    use Inline SMITH => <<EOF;

      smith source code here

    EOF

    ...

But there are many more ways to use Inline. You'll find them in
C<perldoc Inline>.


=head2 Defining functions

Functions are defined in the following form:

function function_name {{
}}

The function name can contain letters, numbers and underscores. It
is published into the main perl namespace, so choose something that

a) you haven't used for your own perl functions
b) perl doesn't use for one of it's own functions


=head2 Passing arguments

The first parameter passed to an Inline::SMITH function is converted
to a stream of bytes. This stream is then accessable using the TTY
command in SMITH.

If you pass a hash instead of a string, then Inline::SMITH can change
it's IO behavoir. The following keys are recognised:

=over 4

=item input

A plain old input buffer (a string)

=item echo

Set to 1 to enable echoing of output to the screen. It is turned off
by default when passing a hash.

=item input_callback

A function ref which is called each time a character of input is needed.
The function should return a 0 to indicate end of input.

=item output_callback

A function ref which is called whenever a byte needs outputting.
The byte is passed as a single character string in the first argument.

=back

=head2 Return values

A SMITH function returns it's output buffer as a string. If echo was
enabled, or if it was implicitly on by using the scalar calling method,
then this buffer will have already been echo'd. The buffer is always
returned, regardless of the state of the echo flag or the existence
of an output callback.


=head1 AUTHOR

Cal Henderson, E<lt>cal@iamcal.comE<gt>


=head1 ACKNOWLEDGEMENTS

Thanks to:

=over 1

=item Brian Ingerson, for writing the C<Inline> module.

=item Chris Pressey, for creating SMITH and the perl interpreter this module is based on and suggesting IO callbacks.

=back

=head1 SEE ALSO

=over 1

=item L<perl>

=item L<Inline>

=item http://www.catseye.mb.ca/esoteric/smith/

=back

=cut

