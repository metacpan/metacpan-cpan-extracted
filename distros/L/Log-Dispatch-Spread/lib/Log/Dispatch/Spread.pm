package Log::Dispatch::Spread;

use strict;

use Log::Dispatch::Output;
use base qw( Log::Dispatch::Output );

use 5.008000;
use warnings;
no warnings 'uninitialized';
use Spread qw( :SP :ERROR :MESS );
use Carp;
use Params::Validate qw( :all );
use Sys::Hostname qw( hostname );

our $VERSION     = '0.9';

use constant SPREAD_PRIV  => 'jc-' . hostname();
use constant LOG_MSG_TYPE => 11;

1;

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;
  my $self = bless {}, $class;

  my %p = @_;

  validate( @_, {
            name      => { type => SCALAR },
            min_level => { type => SCALAR, default => 'DEBUG' },
            max_level => { type => SCALAR, default => 'FATAL' },
            channels  => { type => ARRAYREF },
            server    => { type => SCALAR },
          } );

  $self->_basic_init(%p);

  ($self->{'mbox'}, $self->{'private_group'} ) = Spread::connect( {
                          spread_name => $p{'server'},
                          private_name => SPREAD_PRIV,
                          group_membership => 0,
                        } );


  if ( $sperrno ) {
    croak "Could not join spread cluster. Error was: " . $sperrno;
  }

  $self->{'joined'} = ();
  ( $self->{'joined'} ) = grep Spread::join($self->{'mbox'}, $_), $p{'channels'};

  # What you need to do here is see if two arrays aer equal
  unless ( $self->{'joined'} ) {
    croak "Could not join spread cluster. Error was: " . $sperrno;
  }

  return $self;

}

sub log_message {
  my $self = shift;
  my %p = @_;
  Spread::multicast( $self->{'mbox'},
                     SAFE_MESS,
                     @{$self->{'joined'}},
                     LOG_MSG_TYPE,
                     $p{message},
                   );

  if ( $sperrno ) {
    carp "Could not send a log message! Error was: " . $sperrno;
    return undef;
  }

  return $self;
}

__END__

=head1 NAME

Log::Dispatch::Spread - Perl extension for logging Log::Dispatch messages to a Spread cluster

=head1 SYNOPSIS

  use Log::Dispatch::Spread;
  my $logobj = Log::Dispatch::Spread->new( 
    name => 'spread',
    min_level => 'debug',
    server => '4803@localhost',
    channels => [ qw( foologs barlogs ) ],
  );

  $logobj->log( level => 'warn', message => "Two plus two equals four\n" );


=head1 DESCRIPTION

This module allows for logging via the Log::Dispatch system to a Spread cluster channel of your choice.

=head1 METHODS

=over 4

=item * new(%p)

This method takes a hash of parameters.  The following options are
valid:

=over 8

=item * name NAME

The name of the object.  Required.

=item * min_level LEVEL

The minimum logging level this object will accept.  See the
Log::Dispatch documentation for more information.  Required.

=item * max_level LEVEL

The maximum logging level this obejct will accept.  See the
Log::Dispatch documentation for more information.  This is not
required.  By default the maximum is the highest possible level (which
means functionally that the object has no maximum).

=item * server PORT@HOST

The Spread server to connect to, specified in Spread.pm's connect string 
format (port@localhost). The 'PORT' portion can be ommitted, in which case
the default (4803) is used.

=item * channels [ 'CHANNELONE', 'CHANNELTWO' ]

The Spread channels to connect to. Must obey Spread's channel naming rules
(See the Spread.pm documentation for details)

=back 

=head1 SEE ALSO

=over 4

=item Log::Dispatch (URL)

=item The Spread Toolkit (including Spread.pm): (URL)

=back

=head1 AUTHOR

Brian Thomas, E<lt>brian.thomas@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Brian Thomas

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
