package Dunce::Files;

use strict;
use vars qw($VERSION @EXPORT);
$VERSION = '0.04';

use base qw(Exporter);

=pod

=head1 NAME

Dunce::Files - Protects against sloppy use of files.


=head1 SYNOPSIS

  use Dunce::Files;

  # open() warns you that you forgot to check if it worked.
  open(FILE, $filename);
  while( <FILE> ) {
      chop;     # chop() warns you to use chomp() instead
      print;
  }
  exit;

  # *FILE will warn you that you forgot to close it.


=head1 DESCRIPTION

One of the most common programming mistakes is failing to check if an
open() worked.  Same goes for other file and system operations.  The
world outside your program is a scary, unreliable place, and things
you try to do with it might not always work.

Dunce::Files makes trick versions of all file functions which do some
basic sanity checking.

If used in void context (ie. you didn't check to see if it worked),
they will throw a warning.  If the function returns a filehandle (like
open() and readdir()) that filehandle will complain if its never
closed, or if its never used.

This module is useful for automated code auditing.  Its also useful as
a dunce cap to place on junior programmers, make sure they're not
making silly mistakes.

The list of overridden functions is:

             chdir
             chmod
             chop
             chown
             chroot
             dbmopen
             flock
             link
             mkdir
             open
             opendir
             read
             rename
             rmdir
             seek
             seekdir
             symlink
             syscall
             sysseek
             system
             syswrite
             truncate
             unlink
             write

=cut

# Commonly abused file functions.
use vars qw(@File_Functions);
@File_Functions= qw(
                    chdir
                    chmod
                    chown
                    chroot
                    dbmopen
                    flock
                    link
                    mkdir
                    open
                    opendir
                    read
                    rename
                    rmdir
                    seek
                    seekdir
                    symlink
                    syscall
                    sysseek
                    syswrite
                    truncate
                    unlink
                    write
                   );
@EXPORT = (@File_Functions, 'chop');

use Function::Override;
use Carp;
foreach my $func (@File_Functions) {
    override($func, sub { 
                       my $wantarray = (caller(1))[5];
                       carp "You didn't check if $func() succeeded"
                         unless defined $wantarray;
                    }
            );
}


=pod

A few functions have some additional warnings:

=over 4

=item B<chmod>

Often, people will gratuitiously grant files more permissions than
they really need causing unnecessary security problems.  Making
non-program files executable is a common mistake.  Unnecessarily
giving world write permission is another.  Dunce::Files will throw a
warning if either is detected.

I<Note: It may be worthwhile to split this out into a seperate module>

=cut

override('chmod', 
         sub {
             my $mode = $_[0];
             carp "Don't make files executable without a good reason"
               if $mode & 0111;
             carp "Don't make files writable by others without a good reason"
               if $mode & 0003;

             my $wantarray = (caller(1))[5];
             carp "You didn't check if chmod() succeeded"
               unless defined $wantarray;
         }
        );

=pod

=item B<chop>

chop() works a little differently.  Using it in void context is fine,
but if it looks like you're using it to strip newlines it will throw a
warning reminding you about chomp().

B<NOTE> chop() was non-overridable before 5.7.0, so this feature will
only work on that perl or newer.

=cut

# Alas, chop often isn't overridable.
if( prototype("CORE::chop") ) {
    override('chop',
         sub {
             # Hmm, should this be \n or (\012|\015)?
             if( grep { /\n$/s } @_ ? @_ : $_ ) {
                 carp "Looks like you're using chop() to strip newlines.  ".
                      "Use chomp() instead.\n";
             }
         }
        );
}

=pod

=item B<dbmopen>

dbmopen() will warn you if the hash argument you gave it already
contains data.

=cut

override('dbmopen',
         sub {
             my $hash = $_[0];
             carp "Hash given to dbmopen() already contains data"
               if keys %$hash;

             my $wantarray = (caller(1))[5];
             carp "You didn't check if chmod() succeeded"
               unless defined $wantarray;
         }
        );

=pod

=item B<open>

I<NOT YET IMPLEMENTED>

open() will warn you if you don't close its filehandle explicitly
before the program ends.  It will also warn if you give it an already
open filehandle.

XXX I'd also like to have made sure $! is checked, but $! can't be
usefully tied. :(

=pod

#'#
# Waiting on postamble callbacks in Function::Override.

=cut

=item B<opendir>

I<NOT YET IMPLEMENTED>

Same as open().

=back


=head1 CAVEATS

Because of the way perl compiles, the following code will produce a
'Name main::FILE used only once: possible typo' where it shouldn't.

    use Dunce::Files;
    open(FILE, $filename) or die $!;
    print <FILE>;

Because open() is really Dunce::Files::open() and not the real open,
Perl doesn't realize that FILE is the filehandle *FILE, so it thinks
its only being used once.

Turns out this is a useful feature.  If you close FILE the warning
will go away, and you should have closed it in the first place.


=head1 TODO

Make a flag to have Dunce::Files die instead of just warning.

Complete Function::Override so I can finish open() and opendir().


=head1 AUTHOR

Michael G Schwern <schwern@pobox.com> with help from crysflame and
Simon Cozens.  Thanks to Jay A. Kreibich for the chop() idea.


=head1 SEE ALSO

L<Function::Override>

=cut

1;
