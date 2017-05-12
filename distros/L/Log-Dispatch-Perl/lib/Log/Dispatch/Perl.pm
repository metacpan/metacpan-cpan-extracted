package Log::Dispatch::Perl;
use base 'Log::Dispatch::Output';

$VERSION= '0.04';

# be as strict and verbose as possible
use strict;
use warnings;

# initialize level name / number conversion hashes
my %LEVEL2NUM;
my %NUM2LEVEL;
do {
    my @level2num= (
     debug      => 0,
     info       => 1,
     notice     => 2,
     warning    => 3,
     error      => 4,
     err        => 4, # MUST be after "error"
     critical   => 5,
     crit       => 5, # MUST be after "critical"
     alert      => 6,
     emergency  => 7,
     emerg      => 7, # MUST be after "emergency"
    );
    %LEVEL2NUM= @level2num;
    %NUM2LEVEL= reverse @level2num; # order fixes double assignments
};

# hide ourselves from Carp
my $havecarp= defined $Carp::VERSION;
unless ( $] < 5.008 ) {
    $Carp::Internal{$_}= 1 foreach ( 'Log::Dispatch', 'Log::Dispatch::Output' );
}

#  action to actual code hash
my %ACTION2CODE;
%ACTION2CODE= (
  ''      => sub { undef },

  carp    => $havecarp
               ? \&Carp::carp
               : sub {
                     $havecarp ||= require Carp;
                     $ACTION2CODE{carp}= \&Carp::carp;
                     goto &Carp::carp;
                 },

  cluck   => $] < 5.008
               ? sub {
                     $havecarp ||= require Carp;
                     ( my $m= Carp::longmess() )
                       =~ s#\s+Log::Dispatch::[^\n]+\n##sg;
                     return CORE::warn $_[0] . $m;
                 }
               : sub {
                     $havecarp ||= require Carp;
                     return CORE::warn $_[0] . Carp::longmess();
                 },

  confess => $] < 5.008
               ? sub {
                     $havecarp ||= require Carp;
                     ( my $m = Carp::longmess() )
                       =~ s#\s+Log::Dispatch::[^\n]+\n##sg;
                     return CORE::die $_[0] . $m;
                 }
               : sub {
                     $havecarp ||= require Carp;
                     return CORE::die $_[0] . Carp::longmess();
                 },

  croak   => $havecarp
               ? \&Carp::croak
               : sub {
                     $havecarp ||= require Carp;
                     $ACTION2CODE{croak}= \&Carp::croak;
                     goto &Carp::croak;
                 },

  die     => sub { CORE::die @_ },

  warn    => sub { CORE::warn @_ },
);

# satisfy require
1;

#-------------------------------------------------------------------------------
#
# Class methods
#
#-------------------------------------------------------------------------------
# new
#
# Required by Log::Dispatch::Output.  Creates a new Log::Dispatch::Perl
# object
#
#  IN: 1 class
#      2..N parameters as a hash
# OUT: 1 instantiated object

sub new {
    my ( $class, %param )= @_;

    # do the basic initializations
    my $self= bless {}, ref $class || $class;
    $self->_basic_init( %param );

    # we have specific actions specified
    my @action;
    if ( my $actions= $param{action} ) {

        # check all actions specified
        foreach my $level ( keys %{$actions} ) {
            my $action= $actions->{$level};
            $level= $NUM2LEVEL{$level} if exists $NUM2LEVEL{$level};

            # sanity check, store if ok
            my $warn;
            warn qq{"$level" is an unknown logging level, ignored\n"}, $warn++
              if !exists $LEVEL2NUM{ $level || '' };
            warn qq{"$action" is an unknown Perl action, ignored\n"}, $warn++
              if !exists $ACTION2CODE{$action};
            $action[$LEVEL2NUM{$level}]= $ACTION2CODE{$action}
              if !$warn;
        }
    }

    # set the actions that have not yet been specified
    $action[0] ||= $ACTION2CODE{''};
    $action[1] ||= $ACTION2CODE{''};
    $action[2] ||= $ACTION2CODE{warn};
    $action[3] ||= $ACTION2CODE{warn};
    $action[4] ||= $ACTION2CODE{die};
    $action[5] ||= $ACTION2CODE{die};
    $action[6] ||= $ACTION2CODE{confess};
    $action[7] ||= $ACTION2CODE{confess};

    # save this setting
    $self->{action}= \@action;

    return $self;
} #new

#-------------------------------------------------------------------------------
#
# Instance methods
#
#-------------------------------------------------------------------------------
# log_message
#
# Required by Log::Dispatch.  Log a single message.
#
#  IN: 1 instantiated Log::Dispatch::Perl object
#      2..N hash with parameters as required by Log::Dispatch

sub log_message {
    my ( $self, %param )= @_;

    # huh?
    my $level= $param{level};
    return if !exists $LEVEL2NUM{$level} and !exists $NUM2LEVEL{$level};

    # obtain level number
    my $num= $LEVEL2NUM{$level};
    $num= $level if !defined $num;  # //=

    # set message
    my $message= $param{message};
    $message .= "\n" if substr( $message, -1, 1 ) ne "\n";
    @_= ($message);

    # log it the right way
    goto &{$self->{action}->[$num]};
} #log_message

#-------------------------------------------------------------------------------

__END__

=head1 NAME

Log::Dispatch::Perl - Use core Perl functions for logging

=head1 SYNOPSIS

 use Log::Dispatch::Perl ();

 my $dispatcher = Log::Dispatch->new;
 $dispatcher->add( Log::Dispatch::Perl->new(
  name      => 'foo',
  min_level => 'info',
  action    => { debug     => '',
                 info      => '',
                 notice    => 'warn',
                 warning   => 'warn',
                 error     => 'die',
                 critical  => 'die',
                 alert     => 'croak',
                 emergency => 'croak',
               },
 ) );

 $dispatcher->warning( "This is a warning" );

=head1 VERSION

This documentation describes version 0.04.

=head1 DESCRIPTION

The "Log::Dispatch::Perl" module offers a logging alternative using standard
Perl core functions.  It allows you to fall back to the common Perl
alternatives for logging, such as "warn" and "cluck".  It also adds the
possibility for a logging action to halt the current environment, such as
with "die" and "croak".

=head1 POSSIBLE ACTIONS

The following actions are currently supported (in alphabetical order):

=head2 (absent or empty string or undef)

Indicates no action should be executed.  Default for log levels "debug" and
"info".

=head2 carp

Indicates a "carp" action should be executed.  See L<Carp/"carp">.  Halts
execution.

=head2 cluck

Indicates a "cluck" action should be executed.  See L<Carp/"cluck">.  Does
B<not> halt execution.

=head2 confess

Indicates a "confess" action should be executed.  See L<Carp/"confess">.  Halts
execution.

=head2 croak

Indicates a "croak" action should be executed.  See L<Carp/"croak">.  Halts
execution.

=head2 die

Indicates a "die" action should be executed.  See L<perlfunc/"die">.  Halts
execution.

=head2 warn

Indicates a "warn" action should be executed.  See L<perlfunc/"warn">.  Does
B<not> halt execution.

=head1 REQUIRED MODULES

 Log::Dispatch (1.16)

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 COPYRIGHT

Copyright (c) 2004, 2012 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
