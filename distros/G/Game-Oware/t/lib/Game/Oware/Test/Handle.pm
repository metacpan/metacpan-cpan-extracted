package Game::Oware::Test::Handle;

use strict;
use warnings;

our $VERSION = '0.01';

sub TIEHANDLE { my ($class) = @_; return bless {}, $class }

sub PRINT  { die 'the engine printed something' }
sub PRINTF { die 'the engine printed something' }
sub WRITE  { die 'the engine wrote something' }

sub READLINE { die 'the engine read something' }
sub READ     { die 'the engine read something' }
sub GETC     { die 'the engine read something' }
sub EOF      { die 'the engine asked about a handle' }
sub OPEN     { die 'the engine opened something' }

sub BINMODE { return 1 }
sub FILENO  { return -1 }
sub CLOSE   { return 1 }

1;

__END__

=head1 NAME

Game::Oware::Test::Handle - a filehandle that dies if anything touches it

=head1 DESCRIPTION

Tied over C<STDIN> and C<STDOUT> so that a whole game can be played with both
handles rigged to die. That proves the paths the engine actually takes are
clean; the source scan in F<t/21-no-io.t> proves the paths it does not take are
clean too, which a tie cannot.

C<BINMODE>, C<FILENO> and C<CLOSE> are benign, because perl calls them while
tying and untying and a death there would be a death in the harness rather than
in the engine.

=cut
