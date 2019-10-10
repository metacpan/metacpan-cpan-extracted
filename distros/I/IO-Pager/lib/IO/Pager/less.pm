package IO::Pager::less;
our $VERSION = 1.01;

use strict;
use base qw( IO::Pager::Unbuffered );

BEGIN{
  die "Windows is currently unsupported" if $^O =~ /MSWin32/;
  my $PAGER;
  our $BLIB;
  #local $ENV{PATHEXT} .= ";.PL"
  foreach my $lib ( @INC ){
    $PAGER = File::Spec->catfile($lib, 'IO', 'Pager', 'tp');
    if( -e $PAGER ){
      $ENV{PAGER} = $^X.($BLIB?' -Mblib ':' ').$PAGER;
      last;
    }
  }
}

1;

__DATA__
package IO::Pager::less;
our $VERSION = 1.00;

use strict;
use base qw( IO::Pager );
use SelectSaver;
use IO::Pager::Perl;

our %CFG;

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
  use Data::Dumper; print Dumper 'TIED: ', $$, $self;
  CORE::print {$self->{real_fh}} "BOO!";
  { # Truly unbuffered
    my $saver = SelectSaver->new($self->{real_fh});
    $|=1;
  }
  return $self;
}

#Punt to base, preserving FH ($_[0]) for pass by reference to gensym
sub open(;$) { # [FH]
  &new('IO::Pager::procedural', $_[0], 'procedural');
}

sub PRINT {
  my ($self, @args) = @_;
  CORE::print {$self->{LOG}} @args if exists($self->{LOG});
  CORE::syswrite({$self->{real_fh}},
		 join('', @args) ) or die "Could not print to PAGER: $!\n";
}

sub _pipe_to_fork ($) {
    pipe(my $READ, my $WRITE=shift) or die;
    { # Unbuffer!
      my $saver = SelectSaver->new($WRITE);
      $|=1;
    }
    warn "$READ $WRITE"; #XXX
    my $pid = fork();
    die "fork() failed: $!" unless defined $pid;

    #Parent is reader to maintain STDIN/STDOUT
    if( $pid ){
      warn "Parent: $$, Child: $pid";
      close $WRITE;
      my $tmp;
      sysread($READ, $tmp, 1024);
      warn 'WTF? ', $tmp;
      open(STDIN, "<&=" . fileno($READ)) or die $!; }
    else{
      syswrite($WRITE, "MUAHAHAHA\n"); #XXX
      close $READ; }
    $pid;
}

sub TIEHANDLE {
  my ($class, $tied_fh) = @_;
  my($real_fh, $child);

  #Parent is interface, child does work
  if( $child = _pipe_to_fork( $real_fh=Symbol::gensym() ) ){
    my $t = IO::Pager::Perl->new();

    #Customize interfaces
    foreach my $key ( keys(%CFG) ){
      $t->add_func($key, $CFG{$key}) if $key;
    }

    while( eval{ $t->more(RT=>.05) } ){
      my $tmp;
      $t->add_text($tmp) if sysread($real_fh, $tmp, 1024);
    }
    #XXX exit or die?! SIGPIPE?!
  }
  else{
    my $X = bless {
		  'real_fh' => $real_fh,
		  'tied_fh' => "$tied_fh", #Avoid self-reference leak
		  'child'   => $child,     #XXX Actually, we want the parent?!
		  'pager'   => 'IO::Pager::less', #XXX tp
		 }, $class;
    use Data::Dumper; warn Dumper ['BLESSED: ', $$, $X];
    return $X;
  }
}

1;

__END__

=pod

=head1 NAME

IO::Pager::less - No pager? Pipe output to Perl-based pager a TTY

=head1 SYNOPSIS

=cut

  #!!! CURRENT IMPLEMENTATION REQUIRES Term::ReadKey
  ##Required if you want unbuffered output
  use Term::ReadKey;

  {
    #!!! NOT AVAILABLE WITH CURRENT IMPLEMENTATION
    #Configure extra shortcuts, add an embedded shell
    %IO::Pager::less::CFG = ( '!' => sub{ "REPL implementation" } );

=pod

  {
    #Can be instantiated functionally or OO, same as other sub-classes.
    my $token = new IO::Pager::less;

    $token->print("Pure perl goodness...\n") while 1;
  }

=head1 DESCRIPTION

IO::Pager::less is a simple, extensible, perl-based pager.

=cut

If you want behavior similar to IO::Pager::Buffer do not load Term::ReadKey,
and output will be buffered between keypresses.

=pod

See L<IO::Pager> for method details.

=cut

= head1 CONFIGURATION

I<%IO::Pager::less::CFG> elements are passed to Term::Pager's add_func method.
The hash keys are single key shortcut definitions, and values a callback to be
invoked when said key is pressed e.g;

  #Forego default left-right scrolling for more less-like seeking
  %IO::Pager::less::CFG = (
    '<' => \&Term::Pager::to_top,   #not move_left
    '>' => \&Term::Pager::to_bottom #not move_right
  );

Because IO::Pager::less forks, the callback functions must exist prior to
instantiation of the IO::Pager object to work properly.

=pod

=head1 METHODS

All methods are inherited from IO::Pager; except for instantiation and print.

=cut

= head1 CAVEATS

You probably want to do something with SIGPIPE eg;

  eval {
    local $SIG{PIPE} = sub { die };
    local $STDOUT = IO::Pager::open(*STDOUT);

    while (1) {
      # Do something
    }
  }

  # Do something else

=pod

=head1 SEE ALSO

L<IO::Pager>, L<Term::Pager>, L<IO::Pager::Buffered>, L<IO::Pager::Page>,

=head1 AUTHOR

Jerrad Pierce <jpierce@cpan.org>

Florent Angly <florent.angly@gmail.com>

This module was inspired by Monte Mitzelfelt's IO::Page 0.02

Significant proddage provided by Tye McQueen.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003-2018 Jerrad Pierce

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
