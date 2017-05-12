package Log::Log4perl::Appender::Spread;

use warnings;
use strict;

use vars qw($VERSION);
$VERSION = 0.03;

use Spread 3.17;

sub new {
    my($class, @options) = @_;

    my $self = {
        @options
    };

    # set parameters
    $self->{SpreadGroup} = $self->{SpreadGroup} || 'LOG';
    if ( !defined( $self->{SpreadMailbox} ) ) {
      # not called with an existing spread mailbox, so we need to join spread
      $self->{SpreadName} = $self->{SpreadName} || '4803';
      $self->{SpreadPrivateName} = $self->{SpreadPrivateName} || 'log';
    }

    bless $self, $class;

    $self->spread_join();

    return $self;
}

sub spread_join {
    my($self) = @_;

    if ( !defined( $self->{SpreadMailbox} ) ) {
      # join spread, or die.
      ($self->{mailbox}, $self->{private_group}) = 
	Spread::connect( {
			  spread_name => $self->{SpreadName}, 
			  private_name => $self->{SpreadPrivateName} 
			 } );
      die("$sperrno") if ($sperrno);
    }
    else {
      $self->{mailbox} = $self->{SpreadMailbox};
    }
    # now that connecting is done, join the logging group.
    die("Unable to join the spread group, $self->{SpreadGroup}") 
      unless grep( Spread::join($self->{mailbox}, $_), $self->{SpreadGroup} );
}

sub spread_leave {
    my($self) = @_;
 
    if ( !$sperrno && defined($self->{mailbox}) ) {
        # the mailbox could be dead allready - so ignore errors, they dont make much sense anymore anyway
        Spread::leave($self->{mailbox}, $self->{SpreadGroup});

        if ( !defined($self->{SpreadMailbox}) ) {
            # dont disconnect unless you connected.
            Spread::disconnect($self->{mailbox});
        }
    }
}


sub log {
    my($self, %params) = @_;

    # Send the message to the group joined.	
    return Spread::multicast($self->{mailbox}, SAFE_MESS, $self->{SpreadGroup}, $params{level}, $params{message});
}

sub DESTROY {
    my($self) = @_;

    $self->spread_leave();
}

1;

__END__

=head1 NAME

Log::Log4perl::Appender::Spread - Log to a spread group

=head1 SYNOPSIS

    use Log::Log4perl::Appender::Spread;

    my $app = Log::Log4perl::Appender::Spread->new(
      SpreadGroup => 'SOMELOGGRP',
      SpreadName => '4803@somewhere';
      SpreadPrivateName => 'uniquelogger';
    );

    $app->log(message => "Log me\n", level => INFO);

=head1 DESCRIPTION

This is a simple appender for writing to a spread group.

=head1 METHODS

=head2 new

The C<new()> method takes a few options to tell the module how
to behave. They are:

I<SpreadGroup>. This is the spread group that log messages will
be sent to.

I<SpreadName>. Used to tell the module where spread is running
so that it can connect.

I<SpreadPrivateName>. Used while connecting to spread. The name
should be uniqe on the spread system.

I<SpreadMailbox>. Used when the module wanting to invoke Log4perl
for logging is allready connected to spread with its own mailbox.
When this is set, Log::Log4perl::Appender::Spread will NOT attempt
to connect to spread, and I<SpreadName> and I<SpreadPravateName>
will be ignored.

=head2 log

The C<log()> method takes the level and message parameters. If a 
newline character should terminate the message, it has to be added 
explicitely.

Upon destruction of the object, the appender will leave the
spread group and disconnect from spread.

If you want to switch over to a different spread group at runtime, 
use the C<reconnect({same options as new}> method which will first close 
the old connection and then open a one with the new spread parameters.

Design and implementation of this module has been greatly inspired by
Mike Schillis C<Log::Log4perl::Appenders::File> appender.

=head1 AUTHOR

Jesper Dalberg <jesper@jdn.dk>, 2004

=cut
