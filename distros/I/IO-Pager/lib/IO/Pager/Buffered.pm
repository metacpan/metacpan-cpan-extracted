package IO::Pager::Buffered;
our $VERSION = 0.30;

use strict;
use base qw( IO::Pager );
use SelectSaver;


sub new(;$) {  # [FH], procedural
  my($class, $tied_fh);

  eval { ($class, $tied_fh) = &IO::Pager::_init };
  #We're not on a TTY so...
  if( defined($class) && $class eq '0' or $@ =~ '!TTY' ){
      #...leave filehandle alone if procedural
      return $_[1] if defined($_[2]) && $_[2] eq 'procedural';

      #...fall back to IO::Handle for transparent OO programming
      eval "require IO::Handle" or die $@;
      return IO::Handle->new_from_fd(fileno($_[1]), 'w');
  }
  $!=$@, return 0 if $@ =~ 'pipe';

  tie *$tied_fh, $class, $tied_fh or return 0;
}

#Punt to base, preserving FH ($_[0]) for pass by reference to gensym
sub open(;$) { # [FH]
#  IO::Pager::open($_[0], 'IO::Pager::Buffered');
  &new('IO::Pager::Buffered', $_[0], 'procedural');
}


# Overload IO::Pager methods

sub PRINT {
  my ($self, @args) = @_;
  $self->{buffer} .= join($,||'', @args);
}


sub CLOSE {
  my ($self) = @_;
  # Print buffer and close using IO::Pager's methods
  $self->SUPER::PRINT($self->{buffer}) if exists $self->{buffer};
  $self->SUPER::CLOSE();
}

*DESTROY = \&CLOSE;

sub TELL {
  # Return the size of the buffer
  my ($self) = @_;
  use bytes;
  return exists($self->{buffer}) ? length($self->{buffer}) : 0;
}


sub flush(;*) {
  my ($self) = @_;
  if( exists $self->{buffer} ){
    my $saver = SelectSaver->new($self->{real_fh});
    local $|=1;
    ($_, $self->{buffer}) = ( $self->{buffer}, '');
    $self->SUPER::PRINT($_);
  }
}


1;

__END__

=head1 NAME

IO::Pager::Buffered - Pipe deferred output to PAGER if destination is a TTY

=head1 SYNOPSIS

  use IO::Pager::Buffered;
  {
    local $token = IO::Pager::Buffered::open *STDOUT;
    print <<"  HEREDOC" ;
    ...
    A bunch of text later
    HEREDOC
  }

  {
    # You can also use scalar filehandles...
    my $token = IO::Pager::Buffered::open($FH) or warn($!);
    print $FH "No globs or barewords for us thanks!\n";
  }

  {
    # ...or an object interface
    my $token = new IO::Pager::Buffered;

    $token->print("OO shiny...\n");
  }

=head1 DESCRIPTION

IO::Pager subclasses are designed to programmatically decide whether
or not to pipe a filehandle's output to a program specified in I<PAGER>;
determined and set by IO::Pager at runtime if not yet defined.

This subclass buffers all output for display upon exiting the current scope.
If this is not what you want look at another subclass such as
L<IO::Pager::Unbuffered>. While probably not common, this may be useful in
some cases,such as buffering all output to STDOUT while the process occurs,
showing only warnings on STDERR, then displaying the output to STDOUT after.
Or alternately letting output to STDOUT slide by and defer warnings for later
perusal.

=head1 METHODS

Class-specific method specifics below, others are inherited from IO::Pager.

=head2 open( [FILEHANDLE] )

Instantiate a new IO::Pager to paginate FILEHANDLE if necessary.
I<Assign the return value to a scoped variable>. Output does not
occur until all references to this variable are destroyed eg;
upon leaving the current scope. See L</DESCRIPTION>.

=head2 new( [FILEHANDLE] )

Almost identical to open, except that you will get an L<IO::Handle>
back if there's no TTY to allow for IO::Pager agnostic programming.

=head2 tell( FILEHANDLE )

Returns the size of the buffer in bytes.

=head2 flush( FILEHANDLE )

Immediately flushes the contents of the buffer.

If the last print did not end with a newline, the text from the
preceding newline to the end of the buffer will be flushed but
is unlikely to display until a newline is printed and flushed.

=head1 CAVEATS

If you mix buffered and unbuffered operations the output order is unspecified,
and will probably differ for a TTY vs. a file. See L<perlfunc>.

I<$,> is used see L<perlvar>.

=head1 SEE ALSO

L<IO::Pager>, L<IO::Pager::Unbuffered>, L<IO::Pager::Page>,

=head1 AUTHOR

Jerrad Pierce <jpierce@cpan.org>

Florent Angly <florent.angly@gmail.com>

This module was inspired by Monte Mitzelfelt's IO::Page 0.02

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003-2012 Jerrad Pierce

=over

=item * Thou shalt not claim ownership of unmodified materials.

=item * Thou shalt not claim whole ownership of modified materials.

=item * Thou shalt grant the indemnity of the provider of materials.

=item * Thou shalt use and dispense freely without other restrictions.

=back

Or, if you prefer:

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
