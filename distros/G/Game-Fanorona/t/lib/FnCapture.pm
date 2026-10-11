package FnCapture;

use strict;
use warnings;
use Symbol ();

# A handle that keeps what is printed to it AS CHARACTERS, in a string.
#
#     my $text = '';
#     my $out = FnCapture->handle(\$text);
#     print {$out} "\x{25CB}";      # $text is now one character long
#
# WHY NOT AN IN-MEMORY HANDLE. The terminal sets an encoding layer on its
# output when it draws the stones as a ring and a disc. A sibling's test opened
# a scalar with that layer and decoded what landed in it, and on one smoker
# (perl 5.14.2, unthreaded, the only FAIL in 94 reports) the first capture of
# the file came back undecoded. It could not be reproduced and no perl version
# predicts it. Nothing here is encoded, so nothing has to be decoded, and there
# is no PerlIO layer to disagree with.

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
