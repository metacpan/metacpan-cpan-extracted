package Inline::Interp;

$VERSION = '0.06';

use strict;
use Carp;

sub usage_config { 
	my $key = shift;
	"'$key' is not a valid config option for Inline::Interp\n";
}

sub validate {
}

sub build {
	my $o = shift;
	my $package = ref $o;

	my $code = $o->{API}{code};
	my $pattern = $o->{ILSM}{PATTERN};

	my $funcs = {
		'class'	=> $package,
		'code'	=> '',
	};

	eval "${package}::do_load(\$funcs, \$code);";
	$code = $funcs->{code};
	{
		package Inline::Interp::Loader;
		eval $code;
	}
	croak "Build failed:\n$@" if $@;
	my $path = "$o->{API}{install_lib}/auto/$o->{API}{modpname}";
	my $obj = $o->{API}{location};
	$o->mkpath($path) unless -d $path;
	open FOO_OBJ, "> $obj" or croak "Can't open $obj for output\n$!";
	print FOO_OBJ $code;
	close \*FOO_OBJ;
}

sub add_func {
	my ($funcs, $name, $code) = @_;

	$code =~ s/\|/\\|/g;
	$funcs->{code} .= "sub $name { return Inline::Interp::run('$funcs->{class}', q|$code|, \$_[0]); }\n";
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

sub run {
	my ($class, $code, $data) = @_;

	my @data;
	my $input_callback;
	my $output_callback;
	my $echo = 1;

	if (ref $data eq 'HASH'){
		@data = split(//, ${$data}{input}) if ${$data}{input};
		$input_callback = ${$data}{input_callback} || 0;
		$output_callback = ${$data}{output_callback} || 0;
		$echo = ${$data}{echo} || 0;
	}elsif (defined $data){
		@data = split(//, $data);
	}

	my $io = {
		'echo'			=> $echo,
		'buffer'		=> '',
		'output_callback'	=> $output_callback,
		'input_callback'	=> $input_callback,
		'data'			=> \@data,
	};

	eval "&${class}::do_run(\$code, \$io);";

	return $io->{buffer};
}

sub output_char {
	my ($io, $char) = @_;

	print $char if $io->{echo};
	$io->{buffer} .= $char;
	&{$io->{output_callback}}($char) if $io->{output_callback};
}

sub input_char {
	my ($io) = @_;
	return ($io->{input_callback})?&{$io->{input_callback}}:shift @{$io->{data}};
}

1;

__END__

=head1 NAME

Inline::Interp - Make Inline modules for interpreted languages easily

=head1 SYNOPSIS

  package Inline::Foo;

  require Inline;
  require Inline::Interp;

  @ISA = qw(Inline Inline::Interp);

  sub register {
	return {
		language => 'Foo',
		aliases => ['Foo', 'foo'],
		type => 'interpreted',
		suffix => 'foo',
	};
  }

  sub do_load {
	my ($funcs, $code) = @_;

	while($code =~ m/function(\s+)([a-z0-9_]+)(\s*){(.*?)}/isg){
		Inline::Interp::add_func($funcs, $2, $4);
	}
  }

  sub load {
	Inline::Interp::load(@_);
  }

  sub do_run {
	my ($code, $io) = @_;

	# evaluate $code here

	# output a char
	Inline::Interp::output_char($io, 'A');

	# input a char
	my $in = Inline::Interp::input_char($io);
  }

=head1 DESCRIPTION

This module allows you to easily create an Inline module
for an interpreted language. It handles all the messy
Inline internals for you and provides a simple character
IO layer.

=head1 FUNCTIONS YOU NEED TO IMPLEMENT

=over 4

=item register()

The standard Inline register routine which names your class

=item do_load($funcs,$code)

Called when your class needs to cut up the code (in $code) into
functions. For each function it finds it should call Inline::Interp::add_func,
passing along the $funcs argument.

=item load()

This is just a stub through to Inline::Interp::load. We need this
because Inline doesn't always make object calls so inheritance doesn't
work.

=item do_run($code,$io)

Called when a function should be interpreted. Code is passed in $code.
$io can be used in calls to Inline::Interp::input_char and 
Inline::Interp::output_char.

=back

=head1 FUNCTIONS YOU CAN CALL

=over 4

=item add_func($funcs,$name,$code)

Registers a function. $funcs is the argument passed to do_load(). $name
is the name of the function to register and $code contains the source 
code for the function (in the interpreted langauge, not perl!)

=item input_char($io)

Returns a character from the input stream, or a null character if there
is no more input.

=item output_char($io,$char)

Outputs a character, depending on the IO settings.

=back

=head1 USING AN Inline::Interp FUNCTION

To use a function declared through an Inline::Interp module, just
call it like you would any perl function.

=head2 Passing arguments

The first parameter passed to an Inline::Interp function is converted
to a stream of bytes. This stream is then accessable to the function
via the IO layer.

If you pass a hash instead of a string, then Inline::Interp can change
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

An Inline::Interp function returns it's output buffer as a string. If echo was
enabled, or if it was implicitly on by using the scalar calling method,
then this buffer will have already been echo'd. The buffer is always
returned, regardless of the state of the echo flag or the existence
of an output callback.

=head1 AUTHOR

Copyright (C) 2003, Cal Henderson <cal@iamcal.com>

=head1 SEE ALSO

L<Inline>

=cut
