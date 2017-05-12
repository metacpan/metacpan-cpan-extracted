# Copyright (c) 2006 Ondrej Vostal
#
# All rights reserved.  This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

package Debug::Message;

=head1 NAME

Debug::Message - Eases the use of debug print with level, indentation and color.

=head1 SYNOPSIS

    use Debug::Message;
    use Log::Dispatch;
    use Log::Dispatch::Screen;

    my $dispatcher = Log::Dispatch->new;
    $dispatcher->add( Log::Dispatch::Screen->new( name => 'screen',
                                                  min_level => '0' ));

    my $info = Debug::Message->new(1);
    $info->add_dispatcher($dispatcher);
    $info->print("print");
    $info->yellow("warn");
    $info->red("err");
    $info->printcn("error message", 'bold red');

    my $critical = Debug::Message->new(5);
    $critical->add_dispatcher($dispatcher);
    $critical->redn("err");

For disabling the debugging simply do not attach any dispatchers.

    $critical->disable;  # Will detach the attached backend

=head1 DESCRIPTION

There was no module for simple debug messages supporting debug/verbosity levels
and indentation. So this is the one, that is supposed to take this
place.

This module is an art of frontend to Log::Dispatch as Log::Dispatch
itself supports levels, but no colors and the function's calling is
tedious.

There are some methods defined. Each outputs a different color,
optionally it can add a newline after the messaage. They dispatch the
messages to all added dispatchers, but generaly only one will be
needed as the Log::Dispatch itself can have more backends.

=head1 DETAILS

In theory the use is simple. You have to create some Debug::Message
objects. Each of these with different importance level. You connect
them to the same Log::Dispatch.

Then you set the min_level of Log::Dispatch according to the command
line or what ever. Only those messages, wich have enough high level
(larger or equal to the Log::Dispatche's one) are outputed. For more
complicated scenarios refer to Log::Dispatch(3).

=cut

use strict;
use warnings;
use Carp;
use Params::Validate qw(:all);
Params::Validate::validation_options( on_fail => sub { confess $_[0] } );
use Term::ANSIColor;
use SelfLoader;

our $VERSION = '1.00';

__DATA__
###############################################################################
# not exported subroutines
###############################################################################

=head2 Constructors

   use Debug::Message;
   my $debug = Debug::Message->new( $importance );

Will constuct and return new instance of Debug::Message with
importance level set to $importance. The level is a number in range from 0 to 7.

=cut

sub new {
    my $class = shift;
    my $self;
    $self = {};
    $self->{'indent_level'} = 0;
    $self->{'importance'} = shift;
    $self->{'dispatcher'} = '';

    bless($self, $class);
    return $self;
}

# Subroutines

=head2 Output functions

=head3 print( $message, ... );

=head3 printc( $message, ..., $colorspecs );

=head3 COLOR( $message, ... );

=head3 FUNCTIONn( $mssage, ... );

=cut

sub print {
  my $self = shift;
  $self->_begin;
  $self->_send(@_);
}
sub printn {
  my $self = shift;
  push(@_, "\n");
  $self->print(@_);
}

sub printc {
  my $self = shift;
  my $color = pop;
  $self->_begin;
  $self->_send(colored(@_, $color));
}
sub printcn {
  my $self = shift;
  my $color = pop;
  $self->_begin;
  $self->_send(colored(@_, $color));
  $self->_send("\n");
}

sub yellow {
  my $self = shift;
  $self->printc(@_, 'yellow');
}
sub red {
  my $self = shift;
  $self->printc(@_, 'red');
}
sub green {
  my $self = shift;
  $self->printc(@_, 'green');
}
sub blue {
  my $self = shift;
  $self->printc(@_, 'blue');
}
sub magenta {
  my $self = shift;
  $self->printc(@_, 'magenta');
}

sub yellown {
  my $self = shift;
  $self->yellow( @_ );
  $self->_send("\n");
}
sub redn {
  my $self = shift;
  $self->red( @_ );
  $self->_send("\n");
}
sub greenn {
  my $self = shift;
  $self->green( @_ );
  $self->_send("\n");
}
sub bluen {
  my $self = shift;
  $self->blue( @_ );
  $self->_send("\n");
}
sub magentan {
  my $self = shift;
  $self->magenta( @_ );
  $self->_send("\n");
}

=pod

All functions output is effected by the indentation level. The
I<print()> function will output an uncolored string. The I<COLOR>
fuctions output a colorizes string. The COLOR can be one of blue,
magenta, yellow, red, green. The I<FUNCTIONn> (printn, yellown, etc.) 
add a trailing newline to the messgage. And finaly the I<printc()>
function colorizes its message according to $colorspecs.

=over 2

=item B<$message>

Is a string to send to connected dispatcher modules (Log::Dispatch(3)).

=item B<$colorspecs>

Is color according to Term::ANSIColor(3) man page.

=back

=head2 Properties functions

=head3 add_dispatcher( $dispatcher );

Adds an output module to the object.

=over 2

=item B<$dispatcher>

This is the Log::Dispatch(3) object to connect to.

=back

=cut

sub add_dispatcher {           # Do not add the same log more than once!
  my $self = shift;
  my $log  = shift;		# Logger to connect to

  $self->{'dispatcher'} = $log;
}

=head3 disable();

Unsets the dispatcher thus disables the debugging. Returns the former
dispatcher.

=cut

sub disable {
  my $self = shift;
  my $d = $self->{'dispatcher'};
  $self->{'dispatcher'} = '';
  return $d;
}

=head2 Indentation level TODO, BUT WORKING

=head3 level( $level );

Assigns a level $level and returns a new value. If $level is omited
nothing is set and the old value is returned

=cut

sub level {
  my $self = shift;
  if (@_) { $self->{'indent_level'} = shift }
  return $self->{'indent_level'};
}

=head3 inc( $number );

Increases level by $number. If $number is omited the function behaves
as if it was one. The new level value is returned.

=cut

sub inc {
  my $self = shift;
  if (@_) {
    $self->{'indent_level'} = $self->{'indent_level'} + shift;
  }else{
    $self->{'indent_level'} += 1;
  }
  return $self->{'indent_level'};
}

=head3 dec( $number );

Decreases level by $number. If $number is omited the function behaves
as if it was one. The new value of level is returned.

=cut

sub dec {
  my $self = shift;
  if (@_) {
    $self->{'indent_level'} = $self->{'indent_level'} - shift;
  }else{
    $self->{'indent_level'} -= 1;
  }
  return $self->{'indent_level'};
}

###############################################################################
# packages private subroutines
###############################################################################
sub _send {
  my $self = shift;
  if($self->{'dispatcher'}) {
      $self->{'dispatcher'}->log( level => $self->{'importance'},
				  message => join(' ', @_) );
  }
}

# print out the begining of the line coresponding with the form hash and the calling function(the second parameter)
sub _begin {
  my $self = shift;

  my $method  = shift; # stdout/stderr
  my $cont = '  ';
  $self->_send( $cont x ($self->{level}) ); # number of spaces before the line begin...
}

# MAIN

1;

__END__


=head1 TODO

=over

=item *

test and retreve the user's ideas

=item *

somehow connect with a preprocessor to remove the debug-related calls in working environment

=back

=head1 NOTES

The best experience is to copy the initial setup from the synopsis. It
saves a lot of writing. Or from here; the more complicated one.

    ### Set-up debuggung facilities
    use Debug::Message;
    use Log::Dispatch;
    use Log::Dispatch::Screen;

    our $Verbosity_Level = '0';
    my $dispatcher = Log::Dispatch->new;
    $dispatcher->add( Log::Dispatch::Screen->new( name => 'screen',
                                                  min_level => $Verbosity_Level ));
    my $info = Debug::Message->new(2);
    $info->add_dispatcher($dispatcher);
    my $data = Debug::Message->new(0);
    $data->add_dispatcher($dispatcher);
    my $warning = Debug::Message->new(4);
    $warning->add_dispatcher($dispatcher);

=head1 WARNINGS

=head1 BUGS

No known.
The new found please report on <ondra@elfove.cz>

=head1 HISTORY

=item 12.8.2006

Some of the ideas evolved: Colors insted of semantics in function
names. Initial release 0.51.

=item 8.8.2006

Continued writing after a long pause. Rewritten much of the code.

=item 14.10.2003.

I began writing with many nice ideals on mind.

=cut
