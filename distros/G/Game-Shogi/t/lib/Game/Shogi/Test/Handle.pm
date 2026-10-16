package Game::Shogi::Test::Handle;

use 5.014;
use strict;
use warnings;

use IO::Handle ();

our $VERSION = '0.01';

# AUTOFLUSHED: the Terminal puts an :encoding(UTF-8) layer on its handle, and
# an encoding layer buffers, so without it a test reads an empty scalar.
sub recorder {
    my ($class) = @_;
    my $buf = '';
    open my $fh, '>', \$buf or die "in-memory handle: $!";
    $fh->autoflush(1);
    return bless { fh => $fh, buf => \$buf }, $class;
}

sub reader {
    my ($class, @lines) = @_;
    my $in = @lines ? join("\n", @lines) . "\n" : '';
    open my $fh, '<', \$in or die "in-memory handle: $!";
    return bless { fh => $fh, buf => \$in }, $class;
}

sub fh   { $_[0]{fh} }
sub text { ${ $_[0]{buf} } }

# The recorded text is UTF-8 bytes; ask for this when a pattern has a kanji.
sub decoded {
    require Encode;
    return Encode::decode('UTF-8', ${ $_[0]{buf} });
}

sub clear { ${ $_[0]{buf} } = ''; return $_[0] }

1;

__END__

=head1 NAME

Game::Shogi::Test::Handle - in-memory handles that record or answer

=head1 SYNOPSIS

    my $out = Game::Shogi::Test::Handle->recorder;
    my $in  = Game::Shogi::Test::Handle->reader('7g7f', 'quit');

=head1 DESCRIPTION

Test support, not shipped as part of the interface.

=cut
