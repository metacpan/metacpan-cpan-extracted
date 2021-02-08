package Log::Dispatch;

use 5.006;

use strict;
use warnings;

our $VERSION = '2.70';

use Carp ();
use Log::Dispatch::Types;
use Log::Dispatch::Vars qw( %CanonicalLevelNames %LevelNamesToNumbers );
use Module::Runtime qw( use_package_optimistically );
use Params::ValidationCompiler qw( validation_for );

use base qw( Log::Dispatch::Base );

BEGIN {
    for my $l ( keys %CanonicalLevelNames ) {
        my $level_num = $LevelNamesToNumbers{$l};
        my $sub       = sub {
            my $self = shift;
            $self->_log_with_num(
                $level_num,
                level   => $CanonicalLevelNames{$l},
                message => @_ > 1 ? "@_" : $_[0],
            );
        };

        ## no critic (TestingAndDebugging::ProhibitNoStrict)
        no strict 'refs';
        *{$l} = $sub;
    }
}

{
    my $validator = validation_for(
        params => {
            outputs => {
                type     => t('ArrayRef'),
                optional => 1,
            },
            callbacks => {
                type     => t('Callbacks'),
                optional => 1,
            },
        },
    );

    sub new {
        my $class = shift;
        my %p     = $validator->(@_);

        my $self = bless {}, $class;

        $self->{callbacks} = $p{callbacks}
            if $p{callbacks};

        if ( my $outputs = $p{outputs} ) {
            if ( ref $outputs->[1] eq 'HASH' ) {

                # 2.23 API
                # outputs => [
                #   File => { min_level => 'debug', filename => 'logfile' },
                #   Screen => { min_level => 'warning' }
                # ]
                while ( my ( $class, $params ) = splice @$outputs, 0, 2 ) {
                    $self->_add_output( $class, %$params );
                }
            }
            else {

                # 2.24+ syntax
                # outputs => [
                #   [ 'File',   min_level => 'debug', filename => 'logfile' ],
                #   [ 'Screen', min_level => 'warning' ]
                # ]
                for my $arr ( @{$outputs} ) {
                    die "expected arrayref, not '$arr'"
                        unless ref $arr eq 'ARRAY';
                    $self->_add_output( @{$arr} );
                }
            }
        }

        return $self;
    }
}

sub clone {
    my $self = shift;

    my %clone = (
        callbacks => [ @{ $self->{callbacks} || [] } ],
        outputs   => { %{ $self->{outputs}   || {} } },
    );

    return bless \%clone, ref $self;
}

sub _add_output {
    my $self  = shift;
    my $class = shift;

    my $full_class
        = substr( $class, 0, 1 ) eq '+'
        ? substr( $class, 1 )
        : "Log::Dispatch::$class";

    use_package_optimistically($full_class);

    $self->add( $full_class->new(@_) );
}

sub add {
    my $self   = shift;
    my $object = shift;

    # Once 5.6 is more established start using the warnings module.
    if ( exists $self->{outputs}{ $object->name } && $^W ) {
        Carp::carp(
            'Log::Dispatch::* object ', $object->name,
            ' already exists.'
        );
    }

    $self->{outputs}{ $object->name } = $object;
}

sub remove {
    my $self = shift;
    my $name = shift;

    return delete $self->{outputs}{$name};
}

sub outputs {
    my $self = shift;

    return values %{ $self->{outputs} };
}

sub callbacks {
    my $self = shift;

    return @{ $self->{callbacks} };
}

## no critic (Subroutines::ProhibitBuiltinHomonyms)
sub log {
    my $self = shift;
    my %p    = @_;

    my $level_num = $self->_level_as_number( $p{level} );
    return unless defined $level_num;

    return $self->_log_with_num( $level_num, %p );

}
## use critic

sub _log_with_num {
    my $self      = shift;
    my $level_num = shift;
    my %p         = @_;

    return unless $self->_would_log($level_num);

    $p{message} = $self->_prepare_message(%p);
    $_->_log_with_num( $level_num, %p ) for values %{ $self->{outputs} };

    return;
}

sub _prepare_message {
    my $self = shift;
    my %p    = @_;

    $p{message} = $p{message}->()
        if ref $p{message} eq 'CODE';

    $p{message} = $self->_apply_callbacks(%p)
        if $self->{callbacks};

    return $p{message};
}

sub _log_to_outputs {
    my $self = shift;
    my %p    = @_;

    for ( values %{ $self->{outputs} } ) {
        $_->log(%p);
    }
}

sub log_and_die {
    my $self = shift;
    my %p    = @_;

    $p{message} = $self->_prepare_message(%p);

    $self->_log_to_outputs(%p) if $self->would_log( $p{level} );

    $self->_die_with_message(%p);
}

sub log_and_croak {
    my $self = shift;

    $self->log_and_die(@_);
}

sub _die_with_message {
    my $self = shift;
    my %p    = @_;

    my $msg = $p{message};

    local $Carp::CarpLevel = ( $Carp::CarpLevel || 0 ) + $p{carp_level}
        if exists $p{carp_level};

    Carp::croak($msg);
}

sub log_to {
    my $self = shift;
    my %p    = @_;

    $p{message} = $self->_apply_callbacks(%p)
        if $self->{callbacks};

    $self->_log_to(%p);
}

sub _log_to {
    my $self = shift;
    my %p    = @_;
    my $name = $p{name};

    if ( exists $self->{outputs}{$name} ) {
        $self->{outputs}{$name}->log(@_);
    }
    elsif ($^W) {
        Carp::carp(
            "Log::Dispatch::* object named '$name' not in dispatcher\n");
    }
}

sub output {
    my $self = shift;
    my $name = shift;

    return unless exists $self->{outputs}{$name};

    return $self->{outputs}{$name};
}

sub would_log {
    my $self  = shift;
    my $level = shift;

    my $level_num = $self->_level_as_number($level);
    return 0 unless defined $level_num;

    return $self->_would_log($level_num);
}

sub _would_log {
    my $self      = shift;
    my $level_num = shift;

    for ( values %{ $self->{outputs} } ) {
        return 1 if $_->_should_log($level_num);
    }

    return 0;
}

sub is_debug     { $_[0]->would_log('debug') }
sub is_info      { $_[0]->would_log('info') }
sub is_notice    { $_[0]->would_log('notice') }
sub is_warning   { $_[0]->would_log('warning') }
sub is_warn      { $_[0]->would_log('warn') }
sub is_error     { $_[0]->would_log('error') }
sub is_err       { $_[0]->would_log('err') }
sub is_critical  { $_[0]->would_log('critical') }
sub is_crit      { $_[0]->would_log('crit') }
sub is_alert     { $_[0]->would_log('alert') }
sub is_emerg     { $_[0]->would_log('emerg') }
sub is_emergency { $_[0]->would_log('emergency') }

1;

# ABSTRACT: Dispatches messages to one or more outputs

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Dispatch - Dispatches messages to one or more outputs

=head1 VERSION

version 2.70

=head1 SYNOPSIS

  use Log::Dispatch;

  # Simple API
  #
  my $log = Log::Dispatch->new(
      outputs => [
          [ 'File',   min_level => 'debug', filename => 'logfile' ],
          [ 'Screen', min_level => 'warning' ],
      ],
  );

  $log->info('Blah, blah');

  # More verbose API
  #
  my $log = Log::Dispatch->new();
  $log->add(
      Log::Dispatch::File->new(
          name      => 'file1',
          min_level => 'debug',
          filename  => 'logfile'
      )
  );
  $log->add(
      Log::Dispatch::Screen->new(
          name      => 'screen',
          min_level => 'warning',
      )
  );

  $log->log( level => 'info', message => 'Blah, blah' );

  my $sub = sub { my %p = @_; return reverse $p{message}; };
  my $reversing_dispatcher = Log::Dispatch->new( callbacks => $sub );

=head1 DESCRIPTION

This module manages a set of Log::Dispatch::* output objects that can be
logged to via a unified interface.

The idea is that you create a Log::Dispatch object and then add various
logging objects to it (such as a file logger or screen logger). Then you
call the C<log> method of the dispatch object, which passes the message to
each of the objects, which in turn decide whether or not to accept the
message and what to do with it.

This makes it possible to call single method and send a message to a
log file, via email, to the screen, and anywhere else, all with very
little code needed on your part, once the dispatching object has been
created.

=head1 METHODS

This class provides the following methods:

=head2 Log::Dispatch->new(...)

This method takes the following parameters:

=over 4

=item * outputs( [ [ class, params, ... ], [ class, params, ... ], ... ] )

This parameter is a reference to a list of lists. Each inner list consists of
a class name and a set of constructor params. The class is automatically
prefixed with 'Log::Dispatch::' unless it begins with '+', in which case the
string following '+' is taken to be a full classname. e.g.

    outputs => [ [ 'File',          min_level => 'debug', filename => 'logfile' ],
                 [ '+My::Dispatch', min_level => 'info' ] ]

For each inner list, a new output object is created and added to the
dispatcher (via the C<add()> method).

See L</"OUTPUT CLASSES"> for the parameters that can be used when creating an
output object.

=item * callbacks( \& or [ \&, \&, ... ] )

This parameter may be a single subroutine reference or an array
reference of subroutine references. These callbacks will be called in
the order they are given and passed a hash containing the following keys:

 ( message => $log_message, level => $log_level )

In addition, any key/value pairs passed to a logging method will be
passed onto your callback.

The callbacks are expected to modify the message and then return a
single scalar containing that modified message. These callbacks will
be called when either the C<log> or C<log_to> methods are called and
will only be applied to a given message once. If they do not return
the message then you will get no output. Make sure to return the
message!

=back

=head2 $dispatch->clone()

This returns a I<shallow> clone of the original object. The underlying output
objects and callbacks are shared between the two objects. However any changes
made to the outputs or callbacks that the object contains are not shared.

=head2 $dispatch->log( level => $, message => $ or \& )

Sends the message (at the appropriate level) to all the output objects that
the dispatcher contains (by calling the C<log_to> method repeatedly).

The level can be specified by name or by an integer from 0 (debug) to 7
(emergency).

This method also accepts a subroutine reference as the message
argument. This reference will be called only if there is an output
that will accept a message of the specified level.

=head2 $dispatch->debug (message), info (message), ...

You may call any valid log level (including valid abbreviations) as a method
with a single argument that is the message to be logged. This is converted
into a call to the C<log> method with the appropriate level.

For example:

 $log->alert('Strange data in incoming request');

translates to:

 $log->log( level => 'alert', message => 'Strange data in incoming request' );

If you pass an array to these methods, it will be stringified as is:

 my @array = ('Something', 'bad', 'is', 'here');
 $log->alert(@array);

 # is equivalent to

 $log->alert("@array");

You can also pass a subroutine reference, just like passing one to the
C<log()> method.

=head2 $dispatch->log_and_die( level => $, message => $ or \& )

Has the same behavior as calling C<log()> but calls
C<_die_with_message()> at the end.

You can throw exception objects by subclassing this method.

If the C<carp_level> parameter is present its value will be added to
the current value of C<$Carp::CarpLevel>.

=head2 $dispatch->log_and_croak( level => $, message => $ or \& )

A synonym for C<$dispatch->log_and_die()>.

=head2 $dispatch->log_to( name => $, level => $, message => $ )

Sends the message only to the named object. Note: this will not properly
handle a subroutine reference as the message.

=head2 $dispatch->add_callback( $code )

Adds a callback (like those given during construction). It is added to the end
of the list of callbacks. Note that this can also be called on individual
output objects.

=head2 $dispatch->remove_callback( $code )

Remove the given callback from the list of callbacks. Note that this can also
be called on individual output objects.

=head2 $dispatch->callbacks()

Returns a list of the callbacks in a given output.

=head2 $dispatch->level_is_valid( $string )

Returns true or false to indicate whether or not the given string is a
valid log level. Can be called as either a class or object method.

=head2 $dispatch->would_log( $string )

Given a log level, returns true or false to indicate whether or not
anything would be logged for that log level.

=head2 $dispatch->is_C<$level>

There are methods for every log level: C<is_debug()>, C<is_warning()>, etc.

This returns true if the logger will log a message at the given level.

=head2 $dispatch->add( Log::Dispatch::* OBJECT )

Adds a new L<output object|/"OUTPUT CLASSES"> to the dispatcher. If an object
of the same name already exists, then that object is replaced, with
a warning if C<$^W> is true.

=head2 $dispatch->remove($)

Removes the output object that matches the name given to the remove method.
The return value is the object being removed or undef if no object
matched this.

=head2 $dispatch->outputs()

Returns a list of output objects.

=head2 $dispatch->output( $name )

Returns the output object of the given name. Returns undef or an empty
list, depending on context, if the given output does not exist.

=head2 $dispatch->_die_with_message( message => $, carp_level => $ )

This method is used by C<log_and_die> and will either die() or croak()
depending on the value of C<message>: if it's a reference or it ends
with a new line then a plain die will be used, otherwise it will
croak.

=head1 OUTPUT CLASSES

An output class - e.g. L<Log::Dispatch::File> or
L<Log::Dispatch::Screen> - implements a particular way
of dispatching logs. Many output classes come with this distribution,
and others are available separately on CPAN.

The following common parameters can be used when creating an output class.
All are optional. Most output classes will have additional parameters beyond
these, see their documentation for details.

=over 4

=item * name ($)

A name for the object (not the filename!). This is useful if you want to
refer to the object later, e.g. to log specifically to it or remove it.

By default a unique name will be generated. You should not depend on the
form of generated names, as they may change.

=item * min_level ($)

The minimum L<logging level|/"LOG LEVELS"> this object will accept. Required.

=item * max_level ($)

The maximum L<logging level|/"LOG LEVELS"> this object will accept. By default
the maximum is the highest possible level (which means functionally that the
object has no maximum).

=item * callbacks( \& or [ \&, \&, ... ] )

This parameter may be a single subroutine reference or an array
reference of subroutine references. These callbacks will be called in
the order they are given and passed a hash containing the following keys:

 ( message => $log_message, level => $log_level )

The callbacks are expected to modify the message and then return a
single scalar containing that modified message. These callbacks will
be called when either the C<log> or C<log_to> methods are called and
will only be applied to a given message once. If they do not return
the message then you will get no output. Make sure to return the
message!

=item * newline (0|1)

If true, a callback will be added to the end of the callbacks list that adds
a newline to the end of each message. Default is false, but some
output classes may decide to make the default true.

=back

=head1 LOG LEVELS

The log levels that Log::Dispatch uses are taken directly from the
syslog man pages (except that I expanded them to full words). Valid
levels are:

=over 4

=item debug

=item info

=item notice

=item warning

=item error

=item critical

=item alert

=item emergency

=back

Alternately, the numbers 0 through 7 may be used (debug is 0 and emergency is
7). The syslog standard of 'err', 'crit', and 'emerg' is also acceptable. We
also allow 'warn' as a synonym for 'warning'.

=head1 SUBCLASSING

This module was designed to be easy to subclass. If you want to handle
messaging in a way not implemented in this package, you should be able to add
this with minimal effort. It is generally as simple as subclassing
Log::Dispatch::Output and overriding the C<new> and C<log_message>
methods. See the L<Log::Dispatch::Output> docs for more details.

If you would like to create your own subclass for sending email then
it is even simpler. Simply subclass L<Log::Dispatch::Email> and
override the C<send_email> method. See the L<Log::Dispatch::Email>
docs for more details.

The logging levels that Log::Dispatch uses are borrowed from the standard
UNIX syslog levels, except that where syslog uses partial words ("err")
Log::Dispatch also allows the use of the full word as well ("error").

=head1 RELATED MODULES

=head2 Log::Dispatch::DBI

Written by Tatsuhiko Miyagawa. Log output to a database table.

=head2 Log::Dispatch::FileRotate

Written by Mark Pfeiffer. Rotates log files periodically as part of
its usage.

=head2 Log::Dispatch::File::Stamped

Written by Eric Cholet. Stamps log files with date and time
information.

=head2 Log::Dispatch::Jabber

Written by Aaron Straup Cope. Logs messages via Jabber.

=head2 Log::Dispatch::Tk

Written by Dominique Dumont. Logs messages to a Tk window.

=head2 Log::Dispatch::Win32EventLog

Written by Arthur Bergman. Logs messages to the Windows event log.

=head2 Log::Log4perl

An implementation of Java's log4j API in Perl. Log messages can be limited by
fine-grained controls, and if they end up being logged, both native Log4perl
and Log::Dispatch appenders can be used to perform the actual logging
job. Created by Mike Schilli and Kevin Goess.

=head2 Log::Dispatch::Config

Written by Tatsuhiko Miyagawa. Allows configuration of logging via a
text file similar (or so I'm told) to how it is done with log4j.
Simpler than Log::Log4perl.

=head2 Log::Agent

A very different API for doing many of the same things that
Log::Dispatch does. Originally written by Raphael Manfredi.

=head1 SEE ALSO

L<Log::Dispatch::ApacheLog>, L<Log::Dispatch::Email>,
L<Log::Dispatch::Email::MailSend>, L<Log::Dispatch::Email::MailSender>,
L<Log::Dispatch::Email::MailSendmail>, L<Log::Dispatch::Email::MIMELite>,
L<Log::Dispatch::File>, L<Log::Dispatch::File::Locked>,
L<Log::Dispatch::Handle>, L<Log::Dispatch::Output>, L<Log::Dispatch::Screen>,
L<Log::Dispatch::Syslog>

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/houseabsolute/Log-Dispatch/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Log-Dispatch can be found at L<https://github.com/houseabsolute/Log-Dispatch>.

=head1 DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that B<I am not suggesting that you must do this> in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time (let's all have a chuckle at that together).

To donate, log into PayPal and send money to autarch@urth.org, or use the
button at L<https://www.urth.org/fs-donation.html>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 CONTRIBUTORS

=for stopwords Anirvan Chatterjee Carsten Grohmann Doug Bell Graham Knop Ollis Gregory Oschwald hartzell Joelle Maslak Johann Rolschewski Jonathan Swartz Karen Etheridge Kerin Millar Kivanc Yazan Konrad Bucheli Michael Schout Olaf Alders Olivier Mengué Rohan Carly Ross Attrill Salvador Fandiño Sergey Leschenko Slaven Rezic Steve Bertrand Whitney Jackson

=over 4

=item *

Anirvan Chatterjee <anirvan@users.noreply.github.com>

=item *

Carsten Grohmann <mail@carstengrohmann.de>

=item *

Doug Bell <doug@preaction.me>

=item *

Graham Knop <haarg@haarg.org>

=item *

Graham Ollis <plicease@cpan.org>

=item *

Gregory Oschwald <goschwald@maxmind.com>

=item *

hartzell <hartzell@alerce.com>

=item *

Joelle Maslak <jmaslak@antelope.net>

=item *

Johann Rolschewski <jorol@cpan.org>

=item *

Jonathan Swartz <swartz@pobox.com>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Kerin Millar <kfm@plushkava.net>

=item *

Kivanc Yazan <kivancyazan@gmail.com>

=item *

Konrad Bucheli <kb@open.ch>

=item *

Michael Schout <mschout@gkg.net>

=item *

Olaf Alders <olaf@wundersolutions.com>

=item *

Olivier Mengué <dolmen@cpan.org>

=item *

Rohan Carly <se456@rohan.id.au>

=item *

Ross Attrill <ross.attrill@gmail.com>

=item *

Salvador Fandiño <sfandino@yahoo.com>

=item *

Sergey Leschenko <sergle.ua@gmail.com>

=item *

Slaven Rezic <srezic@cpan.org>

=item *

Steve Bertrand <steveb@cpan.org>

=item *

Whitney Jackson <whitney.jackson@baml.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
