package Gimp::Extension;

use strict;
use Carp qw(croak carp);
use base 'Exporter';
use Gimp::Pod;
require Gimp::Fu;
use autodie;
use Gtk2;

# manual import
sub __ ($) { goto &Gimp::__ }
sub main { goto &Gimp::main; }

our $VERSION = "2.38";
our @EXPORT = qw(podregister main add_listener register_temp podregister_temp);

# this is to avoid warnings from importing main etc from Gimp::Fu AND here
sub import {
   my $p = \%::;
   $p = $p->{"${_}::"} for split /::/, caller;
   map { delete $p->{$_} if defined &{caller."::$_"}; } @_ == 1 ? @EXPORT : @_;
   __PACKAGE__->export_to_level(1, @_);
}

my $TP = 'TEMPORARY PROCEDURES';

my @register_params;
my @temp_procs;
Gimp::on_query {
   Gimp->install_procedure(Gimp::Fu::procinfo2installable(@register_params));
};

sub podregister (&) {
   my @procinfo = fixup_args(('')x9, @_);
   Gimp::register_callback $procinfo[0] => sub {
      warn "$$-Gimp::Extension sub: $procinfo[0](@_)" if $Gimp::verbose >= 2;
      for my $tp (@temp_procs) {
	 my @tpinfo = (
	    @{$tp}[0..2],
	    @procinfo[3..5],
	    @{$tp}[3,4],
	    &Gimp::TEMPORARY,
	    @{$tp}[5..7],
	 );
	 Gimp->install_temp_proc(Gimp::Fu::procinfo2installable(@tpinfo[0..10]));
	 Gimp::register_callback
	    $tpinfo[0] => Gimp::Fu::make_ui_closure(@tpinfo[0..7,9..11]);
      }
      Gimp::gtk_init;
      Gimp->extension_ack;
      Gimp->extension_enable;
      Gimp::Fu::make_ui_closure(@procinfo)->(@_);
   };
   @register_params = (@procinfo[0..7], &Gimp::EXTENSION, @procinfo[8,9]);
}

sub add_listener {
   my ($listen_socket, $handler, $on_accept) = @_;
   Glib::IO->add_watch(fileno($listen_socket), 'in', sub {
      my ($fd, $condition, $fh) = @_;
      my $h = $fh->accept;
      $on_accept->($h) if $on_accept;
      $h->autoflush;
      Glib::IO->add_watch(fileno($h), 'in', sub {
	 my ($fd, $condition, $h) = @_;
	 undef $h if not $handler->(@_);
	 $h ? &Glib::SOURCE_CONTINUE : &Glib::SOURCE_REMOVE;
      }, $h);
      &Glib::SOURCE_CONTINUE;
   }, $listen_socket);
}

sub register_temp ($$$$$$$&) { push @temp_procs, [ @_ ]; }
sub podregister_temp {
   my ($tfunction, $tcallback) = @_;
   my $pod = Gimp::Pod->new;
   my ($t) = grep { /^$tfunction\s*-/ } $pod->sections($TP);
   croak "No POD found for temporary procedure '$tfunction'" unless $t;
   my ($tblurb) = $t =~ m#$tfunction\s*-\s*(.*)#;
   my $thelp = $pod->section($TP, $t);
   my $tmenupath = $pod->section($TP, $t, 'SYNOPSIS');
   my $timagetypes = $pod->section($TP, $t, 'IMAGE TYPES');
   my $tparams =  $pod->section($TP, $t, 'PARAMETERS');
   my $tretvals =  $pod->section($TP, $t, 'RETURN VALUES');
   ($tfunction, $tmenupath, $timagetypes, $tparams, $tretvals) = (fixup_args(
      $tfunction, ('fake') x 5, $tmenupath, $timagetypes,
      ($tparams || '#'), ($tretvals || '#'), 1
   ))[0, 6..9];
   push @temp_procs, [
      $tfunction, $tblurb, $thelp, $tmenupath, $timagetypes,
      $tparams, $tretvals, $tcallback,
   ];
}

1;
__END__

=head1 NAME

Gimp::Extension - Easy framework for Gimp-Perl extensions

=head1 SYNOPSIS

  use Gimp;
  use Gimp::Fu; # necessary for variable insertion and param constants
  use Gimp::Extension;
  podregister {
    # your code
  };
  exit main;
  __END__
  =head1 NAME

  function_name - Short description of the function

  =head1 SYNOPSIS

  <Image>/Filters/Menu/Location...

  =head1 DESCRIPTION

  Longer description of the function...

=head1 DESCRIPTION

This module provides all the infrastructure you need to write Gimp-Perl
extensions.

Your main interface for using C<Gimp::Extension> is the C<podregister>
function. This works in exactly the same way as L<Gimp::Fu/PODREGISTER>,
including declaring/receiving your variables for you.

Before control is passed to your function, these procedures are called:

  Gimp::gtk_init; # sets up Gtk2, ready for event loop
  Gimp->extension_ack; # GIMP hangs till this is called
  Gimp->extension_enable; # adds an event handler in Glib mainloop for
			  # GIMP messages

Your function will then either proceed as if it were a plugin, or call
the Glib/Gtk2 mainloop:

  Gtk2->main;

Values returned by your function will still be returned to a caller,
as with a plugin.

One benefit of being an extension vs a plugin is that you can keep
running, installing temporary procedures which are called by the user.
When they are called, the perl function you have registered will be
called, possibly accessing your persistent data or at least benefiting
from the fact that you have already started up.

Another benefit is that you can respond to events outside of GIMP,
such as network connections (this is how the Perl-Server is implemented).

Additionally, if no parameters are specified, then the extension will
be started as soon as GIMP starts up. Make sure you specify menupath
<None>, so no parameters will be added for you.

If you need to clean up on exit, just register a callback with
C<Gimp::on_quit>. This is how C<Perl-Server> removes its Unix-domain
socket on exit.

=head1 FUNCTIONS AVAILABLE TO EXTENSIONS

These are all exported by default.

=head2 podregister

As discussed above.

=head2 add_listener

This is a convenience wrapper around C<Glib::IO-E<gt>add_watch>. It
takes parameters:

=over 4

=item $listen_socket

This will be an L<IO::Socket> subclass object, a listener socket. When
it becomes readable, its C<accept> method will be called.

=item \&handler

This mandatory parameter is a function that is installed as the new
connection's Glib handler. Its parameters are: C<$fd, $condition, $fh> -
in Glib terms, the file handle will be registered as the "data" parameter.
When it returns false, the socket will be closed.

=item \&on_accept

This optional parameter will, if defined, be a function that is called
one time with the new socket as a parameter, possibly logging and/or
sending an initial message down that socket.

=back

=head2 podregister_temp

  podregister_temp perl_fu_procname => sub {
    ...
  };

  =head1 TEMPORARY PROCEDURES

  =head2 procname - blurb

  Longer help text.

  =head3 SYNOPSIS

  <Image>/File/Label...

  =head3 PARAMETERS

    # params...

Registers a temporary procedure, reading from the POD the SYNOPSIS,
PARAMETERS, RETURN VALUES, IMAGE TYPES, etc, as for L<Gimp::Fu>. As
you can see above, the temporary procedure's relevant information is in
similarly-named sections, but at level 2 or 3, not 1, within the
suitably-named level 2 section. Unlike C<podregister>, it will not
interpolate variables for you.

=head2 register_temp

This is a convenience wrapper around C<Gimp-E<gt>install_temp_proc>,
supplying a number of parameters from information in the extension's
POD. The registration will only happen when the extension's C<on_run>
callback is called. It takes parameters:

=over 4

=item $proc_name

The name of the new PDB procedure.

=item $blurb

=item $help

=item $menupath

=item $imagetypes

=item $params

=item $retvals

All as per L<Gimp/Gimp-E<gt>install_procedure>.

=item \&callback

=back

=head1 AUTHOR

Ed J

=head1 SEE ALSO

perl(1), L<Gimp>, L<Gimp::Fu>.
