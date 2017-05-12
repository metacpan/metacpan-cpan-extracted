package Eesh;

=head1 NAME

Eesh - Enlightenment Window Manager IPC Library

=head1 SYNOPSIS

  ## Long form:
  use Eesh qw( e_open e_send e_recv ) ;

  e_open() ;
  print e_recv( 'window_list' ) ;
  e_send( 'restart' ) ;

  ## Short form
  use Eesh qw( :all ) ;
  e_open() ;
  print "$_\n" for ( e_window_list ) ;

  my $win_id = (grep { /Terminal/ } e_window_list)[0] ;
  e_win_op( $win_id, 'raise' ) ;

  ## For non-blocking receives:
  my $hmmm = e_recv( { non_blocking => 1 } ) ;

=head1 DESCRIPTION

Eesh.pm provides simple wrappers around the routines from eesh (included).

This code is in alpha mode, please let me know of any improvements,
and patches are especially welcome.

=cut

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );
use Carp ;

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);

@EXPORT_OK = qw(
   e_open
   e_send
   e_recv
   e_fileno

   e_backgrounds
   e_background
   e_delete_background
   e_set_background

   e_internal_list
   e_list_class
   e_list_themes
   e_modules
   e_remember
   e_focused
   e_set_focus
   e_win_op
   e_window_list
);
%EXPORT_TAGS = ( all => \@EXPORT_OK ) ;
$VERSION = '0.3';

bootstrap Eesh $VERSION;

sub _clip_ids {
   map { m/^\s*([0-9a-fA-F]+).*/ } @_ ;
}

=head2 Basic Communications Functions

=over

=item e_open

Opens communications with E.

=item e_send

Sends to E.

=item e_recv

Receives from E, blocking until data is received.

Can send strings first and then wait for the result:

   my @windows = split( /^/m, e_recv( 'window_list' ) ) ;

Can be called non-blocking:

   e_send( 'window_list' ) ;
    
   my $hmmm ;
   $hmmm = e_recv( { non_blocking => 1 } ) until defined $hmmmm ;

=cut

sub e_recv {
   my $options = @_ && ref $_[-1] eq 'HASH' ? pop : {} ;

   my @bad = grep { $_ ne 'non_blocking' } keys %$options ;
   if ( @bad ) {
      my $s = @bad > 1 ? 's' : '' ;
      croak "Unrecognized option$s: " . join( ', ', map { "'$_'" } @bad ) ;
   }

   e_send( $_ ) for ( @_ ) ;

   return e_recv_nb( $options->{non_blocking} ? 0 : 1 ) ;
}

=item e_fileno

Returns the file number of the connection to E, useful for select loops.

=back

=head2 High level functions

These are simple functions that wrap around E IPC commands.  The really
simple commands aren't wrapped, since it wouldn't save much typing
(though they would provide varying levels of mispeled option detection):

   e_send( 'advanced_focus new_window_focus on' ) ;

vs.

   e_enable_advanced_focus_new_window_focus() ;
   e_advanced_focus_new_window_focus( 'on' ) ;
   e_advanced_focus( 'new_window_focus', 'on' ) ;
   e_enable( 'advanced_focus', 'new_window_focus' ) ;

Perhaps we could provide something like:

   e_enable_new_window_focus() ;

which would be a savings and allow for safer programming (since a mispelling
would show up under 'use strict').  But that's only viable so long as
no identifier is used more than once in the entire command set, which I
can't guarantee.

If you don't 
see a function here that you need, ask for it or send a patch.  See the
eesh help command for more documentation on these.

=over

=item e_backgrounds

Returns a list of all background ids, one per element.

=cut

sub e_backgrounds(;$) {
   return split( /\n/, e_recv( 'background' ) ) ;
}

=item e_delete_background

Deletes a background

=cut

sub e_delete_background($) {
   e_send( "background $_[0]" ) ;
}


=item e_background

Returns a hash reference to the values defined for a particular background:

   print e_background( shift e_backgrounds )->{'bg.solid'}, "\n" ;

=cut

sub e_background($) {
   my ( $bg ) = @_ ;
   croak "background id may not contain whitespace" if $bg =~ /\s/ ;
   for ( e_recv( "background $bg ?" ) ) {
      croak $_ if /^Error:/ ;
      $bg = quotemeta $bg ;
      s{\s*$bg\s*}{} ;
      return {
         map {
	    s/^\s*(.*?)\s*/$1/ ;
	    /^(ref_count)\s+(\S+)/
	       ? ( $1, $2 )
	       : $_
	 } split /(?:\s*[\t\n]+)\s*/
      } ;
   }
}

=item e_set_background

Takes a background id and either a hash or a list of key/value pairs and sets
them:

   e_set_background( $bg_id, 'bg.file' => $filename ) ;

=cut

sub e_set_background( $@ ) {
   my $bg_id = shift ;
   my @args = @_ == 1 && ref $_[0] eq 'HASH'
      ? map { ( $_, $_[0]->{$_} ) } keys %{$_[0]}
      : @_ ;
   unless ( @args ) {
      carp "Nothing to do" ;
      return ;
   }
   croak "Odd number of arguments in list of values to set" if @args % 2 ;
   croak "Empty or all-whitespace string in arguments"
      if grep { /^\s*$/ } @args ;
   while ( @args ) {
      my ( $type, $value ) = splice @args, 0, 2 ;
      e_send( "background $bg_id $type $value" ) ;
   }
}


=item e_focused

A short form of e_set_focus( '?' ) :

   my $win_id = e_focused() ;

=cut

sub e_focused() {
   my $v = e_recv( 'set_focus ?' ) ;
   $v =~ s{^[a-z]:\s*(\S*)\s*}{$1} ;
   return $v ;
}


=item e_internal_list

Returns the requested list:

   e_internal_list( 'menus' ) ;

might yield:

   ('1400509','14000f9')

Note that spaces and newlines are stripped, and that these are strings,
not numbers.


=cut

sub e_internal_list($) {
   my ( $type ) = @_ ;
   return map {
      chomp ;
      s/^\s*(.*?)\s*$/$1/ ;
      $_
   } split /^/m, e_recv( "internal_list $type" ) ;
}


=item e_list_class

Returns a list of the supplied class.

   e_list_class( 'backgrounds' ) ;

should return the same list as e_backgrounds().

=cut

sub e_list_class($) {
   my ( $class ) = @_ ;
   return map {
      chomp ;
      $_
   } split /^/m, e_recv( "list_class $class" ) ;
}


=item e_list_themes

Returns a list of themes.

=cut

sub e_list_themes() {
   return map {
      chomp ;
      $_
   } split /^/m, e_recv( "list_themes" ) ;
}


=item e_modules

Returns a list of modules.  Don't ask me why this isn't "list_modules" or
"modules_list".

=cut

sub e_modules() {
   return map {
      chomp ;
      $_
   } split /^/m, e_recv( "module list" ) ;
}


=item e_remember

Takes a window ID and a parameter.  The window ID may be the full item
returned from e_window_list(), or just the ID portion.

=cut

sub e_remember($$) {
   my ( $id, $param ) = @_ ;
   ( $id ) = _clip_ids( $id ) ;
   e_send( "remember $id $param" ) ;
}


=item e_set_focus

Can take a window ID, the full ID returned from window_list().

See e_focused() for a short form of e_set_focus( '?' ).

=cut

sub e_set_focus($) {
   return e_focused() if $_[0] eq '?' ;
   my ( $id ) = _clip_ids( @_ ) ;
   e_send( "set_focus $id" ) ;
}


=item e_win_op

Takes a window ID, or one of the values returned by e_window_list() and
performs a win_op on it.

If used in a non-void context, this will block and return any data
received.  So don't do that if you might not get anything back.

=cut

sub e_win_op($$;$) {
   my ( $id, $op, @args ) = @_ ;

   ( $id ) = _clip_ids( $id ) ;

   e_send( join( ' ', "win_op $id $op", @args ) ) ;
   e_recv if defined wantarray ;
}


=item e_window_list

Returns a list of strings containing window IDs and titles:

   (
      '2400006 : Terminal',
      '3c00080 : VIM - ~/src/Eesh/Eesh.pm',
      ...
   )

The leading whitespace and trailing newlines are trimmed.

These may be passed in anywhere a window ID is needed, such as e_win_op()
or e_iconify().

=cut

sub e_window_list {
   return map { s/^\s*// ; chomp ; $_ } split( /^/m, e_recv( 'window_list' ) ) ;
}


=back

=head1 LICENSE

Copyright (C) 2000 Barrie Slaymaker, Carsten Haitzler, Geoff Harrison
and various contributors 
 
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to
deal in the Software without restriction, including without limitation the
rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
  
The above copyright notice and this permission notice shall be included in
all copies of the Software, its documentation and marketing & publicity 
materials, and acknowledgment shall be given in the documentation, materials
and software packages that this Software was used.
   
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER 
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=head1 AUTHORS

Eesh: Barrie Slaymaker <barries@slaysys.com>

eesh: Carsten Haitzler, Geoff Harrison and various contributors 

=head1 SEE ALSO

eesh

=cut

1;

__END__
