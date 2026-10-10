package Capture;

use 5.010;
use strict;
use warnings;
use Symbol ();

# A handle that keeps what is printed to it AS CHARACTERS, in a string.
#
#     my $text = '';
#     my $out = Capture->handle(\$text);
#     print {$out} "\x{250c}";      # $text is now one character long
#
# WHY NOT AN IN-MEMORY HANDLE. t/32 used to open '>:encoding(UTF-8)' on a
# scalar and utf8::decode what landed in it. That is two layers and a decode
# between the terminal and the assertion, and on one smoker (perl 5.14.2,
# unthreaded, 0.01's only FAIL in 94 reports) the first capture of the file
# came back undecoded: the box-drawing tiles were on the screen, in the
# report, as bytes, and the pattern looking for them as characters did not
# match. The same file's later captures decoded, and the same tester's
# 5.14.0, .1, .3, .4 and threaded 5.14.2 all passed, so it is not something a
# perl version predicts. It could not be reproduced here.
#
# So the test no longer depends on it. Nothing here is encoded, so nothing has
# to be decoded, and there is no PerlIO layer to disagree with.

sub handle {
	my ($class, $buffer) = @_;
	my $glob = Symbol::gensym();
	tie *{$glob}, $class, $buffer;
	return $glob;
}

sub TIEHANDLE {
	my ($class, $buffer) = @_;
	return bless { buffer => $buffer }, $class;
}

sub PRINT {
	my ($self, @text) = @_;
	${ $self->{buffer} } .= join(defined $, ? $, : '', @text) . (defined $\ ? $\ : '');
	return 1;
}

sub PRINTF {
	my ($self, $format, @text) = @_;
	${ $self->{buffer} } .= sprintf $format, @text;
	return 1;
}

sub BINMODE { return 1 }
sub FILENO  { return undef }
sub CLOSE   { return 1 }

1;
