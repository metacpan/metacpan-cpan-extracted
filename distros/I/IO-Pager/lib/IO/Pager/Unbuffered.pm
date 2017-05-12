package IO::Pager::Unbuffered;
our $VERSION = 0.31;

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

  my $self = tie *$tied_fh, $class, $tied_fh or return 0;
  { # Truly unbuffered
    my $saver = SelectSaver->new($self->{real_fh});
    $|=1;
  }
  return $self;
}

#Punt to base, preserving FH ($_[0]) for pass by reference to gensym
sub open(;$) { # [FH]
#  IO::Pager::open($_[0], 'IO::Pager::Unbuffered');
  &new('IO::Pager::procedural', $_[0], 'procedural');
}


1;

__END__

=head1 NAME

IO::Pager::Unbuffered - Pipe output to PAGER if destination is a TTY

=head1 SYNOPSIS

  use IO::Pager::Unbuffered;
  {
    local $STDOUT = IO::Pager::Unbuffered::open *STDOUT;
    print <<"  HEREDOC" ;
    ...
    A bunch of text later
    HEREDOC
  }

  {
    # You can also use scalar filehandles...
    my $token = IO::Pager::Unbuffered::open($FH) or warn($!);
    print $FH "No globs or barewords for us thanks!\n";
  }

  {
    # ...or an object interface
    my $token = new IO::Pager::Unbuffered;

    $token->print("OO shiny...\n");
  }

=head1 DESCRIPTION

IO::Pager subclasses are designed to programmatically decide whether
or not to pipe a filehandle's output to a program specified in I<PAGER>;
determined and set by IO::Pager at runtime if not yet defined.

See L<IO::Pager> for method details.

=head1 METHODS

All methods are inherited from IO::Pager; except for instantiation.

=head1 CAVEATS

You probably want to do something with SIGPIPE eg;

  eval {
    $SIG{PIPE} = sub { die };
    local $STDOUT = IO::Pager::open(*STDOUT);

    while (1) {
      # Do something
    }
  }

  # Do something else

=head1 SEE ALSO

L<IO::Pager>, L<IO::Pager::Buffered>, L<IO::Pager::Page>,

=head1 AUTHOR

Jerrad Pierce <jpierce@cpan.org>

Florent Angly <florent.angly@gmail.com>

This module was inspired by Monte Mitzelfelt's IO::Page 0.02

Significant proddage provided by Tye McQueen.

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
