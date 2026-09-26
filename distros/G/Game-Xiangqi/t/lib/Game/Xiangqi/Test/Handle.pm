package Game::Xiangqi::Test::Handle;

use 5.010;
use strict;
use warnings;

use IO::Handle ();       # for autoflush on a lexical handle; core

our $VERSION = '0.01';

# Two handles, and the second one is the interesting one.
#
# `recorder` collects everything written to it, so a test can read the board the
# Terminal drew instead of trusting that it drew one.
#
# `deaf` DIES ON EVERY WRITE. Phase 11's purity test hands it to the Terminal to
# prove that nothing in `Game::Xiangqi`, `::Engine`, `::Notation`, `::Error` or
# `::Bot` prints: if any of them reaches for STDOUT, the test sees a die with this
# file's name in it rather than stray output nobody notices in a passing run.
#
# NOT A TIED HANDLE. A tied handle needs TIEHANDLE, PRINT, PRINTF, WRITE, READLINE,
# GETC, CLOSE and BINMODE to be safe against a caller using any of them, and this
# needs two methods. An in-memory filehandle opened on a scalar ref is core since
# 5.8 and behaves like a file in every respect that matters here.

# AUTOFLUSH, AND WITHOUT IT THIS CLASS LIES.
#
# The Terminal puts an :encoding(UTF-8) layer on the handle it is given, and an
# encoding layer BUFFERS: the scalar stays empty until something flushes. A test
# that wrote a few lines and then read `text` got '' and reported that the Terminal
# had drawn nothing. Worse, a test that wrote a whole game's worth PASSED, because
# it spilled the buffer by accident, so the same bug was a pass in one file and a
# failure in another for reasons neither file mentioned.
sub recorder {
    my ($class) = @_;
    my $buf = '';
    open my $fh, '>', \$buf or die "in-memory handle: $!";
    $fh->autoflush(1);
    return bless { fh => $fh, buf => \$buf }, $class;
}

# A handle that answers a script: `reader` for what the Terminal reads, and the
# recorder for what it writes. Lines are joined with newlines and a final one is
# added, because a Terminal reading a line that never ends waits for ever.
sub reader {
    my ($class, @lines) = @_;
    my $in = @lines ? join("\n", @lines) . "\n" : '';
    open my $fh, '<', \$in or die "in-memory handle: $!";
    return bless { fh => $fh, buf => \$in }, $class;
}

sub deaf {
    my ($class) = @_;
    return bless { fh => Game::Xiangqi::Test::Handle::Deaf->handle, buf => \(my $x) }, $class;
}

sub fh   { $_[0]{fh} }
sub text { ${ $_[0]{buf} } }

# THE RECORDED TEXT IS BYTES, because the Terminal puts an :encoding(UTF-8) layer
# on whatever handle it is given, which is exactly what it must do for a real
# terminal. So a test matching a piece character against `text` compares a
# character to its UTF-8 bytes and fails while the board is perfectly correct.
# Ask for `decoded` when the pattern has a glyph in it.
sub decoded {
    require Encode;
    return Encode::decode('UTF-8', ${ $_[0]{buf} });
}
sub lines { split /\n/, ${ $_[0]{buf} }, -1 }
sub clear { ${ $_[0]{buf} } = ''; return $_[0] }

# ---------------------------------------------------------------------------------

package Game::Xiangqi::Test::Handle::Deaf;

use strict;
use warnings;

use Symbol ();           # core, for gensym

# `Symbol::gensym` AND NOT `my $glob`. The first version of this was
#
#     my $glob;
#     tie *$glob, $class, $self;
#
# which dies with "Can't use an undefined value as a symbol reference": `*$glob` on
# an undefined lexical is a SYMBOLIC dereference, not an anonymous glob.
#
# It sat here unnoticed from phase 10 to phase 11 because `deaf` was written for a
# caller that did not exist yet and nothing ever called it. A helper written one
# phase ahead of its user is untested code that looks tested.
sub handle {
    my ($class) = @_;
    my $self = bless {}, $class;
    my $glob = Symbol::gensym();
    tie *$glob, $class, $self;                       ## no critic
    return $glob;
}

# EVERY WAY IN AND EVERY WAY OUT, because the purity test's whole value is that it
# cannot be walked past. A handle that refused PRINT and allowed READLINE would let
# an engine that blocks on STDIN pass as pure, and `syswrite` would slip through a
# class that only caught PRINT.
#
# BINMODE RETURNS TRUE rather than dying: the Terminal legitimately puts an encoding
# layer on a handle it is given, and that is not I/O.
sub TIEHANDLE { my ($class, $self) = @_; return $self }
sub PRINT     { die "Game::Xiangqi::Test::Handle::Deaf: something PRINTED\n" }
sub PRINTF    { die "Game::Xiangqi::Test::Handle::Deaf: something PRINTF'd\n" }
sub WRITE     { die "Game::Xiangqi::Test::Handle::Deaf: something syswrote\n" }
sub READLINE  { die "Game::Xiangqi::Test::Handle::Deaf: something READ A LINE\n" }
sub READ      { die "Game::Xiangqi::Test::Handle::Deaf: something sysread\n" }
sub GETC      { die "Game::Xiangqi::Test::Handle::Deaf: something took a char\n" }
sub EOF       { die "Game::Xiangqi::Test::Handle::Deaf: something asked for eof\n" }
sub FILENO    { return -1 }
sub BINMODE   { return 1 }
sub OPEN      { die "Game::Xiangqi::Test::Handle::Deaf: something reopened it\n" }
sub CLOSE     { return 1 }

1;

__END__

=head1 NAME

Game::Xiangqi::Test::Handle - handles that record, answer, or refuse

=head1 SYNOPSIS

    my $out = Game::Xiangqi::Test::Handle->recorder;
    my $in  = Game::Xiangqi::Test::Handle->reader('h2e2', 'quit');

    my $t = Game::Xiangqi::Terminal->new(in => $in->fh, out => $out->fh);
    $t->start;
    like($out->text, qr/\Q車\E/, 'it drew a board');

    my $deaf = Game::Xiangqi::Test::Handle->deaf;    # dies if written to

=head1 DESCRIPTION

Test support, not shipped as part of the interface. C<recorder> and C<reader> are
in-memory filehandles; C<deaf> is a tied handle that B<dies on every write> and
exists so that "nothing outside the Terminal prints" is an assertion rather than
a hope.

=cut
