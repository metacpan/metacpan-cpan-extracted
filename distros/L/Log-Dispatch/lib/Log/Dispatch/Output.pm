package Log::Dispatch::Output;

use strict;
use warnings;

our $VERSION = '2.70';

use Carp ();
use Try::Tiny;
use Log::Dispatch;
use Log::Dispatch::Types;
use Log::Dispatch::Vars qw( @OrderedLevels );
use Params::ValidationCompiler qw( validation_for );

use base qw( Log::Dispatch::Base );

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    die "The new method must be overridden in the $class subclass";
}

{
    my $validator = validation_for(
        params => {
            level => { type => t('LogLevel') },

            # Pre-PVC we accepted empty strings, which is weird, but we don't
            # want to break back-compat. See
            # https://github.com/houseabsolute/Log-Dispatch/issues/38.
            message => { type => t('Str') },
        },
        slurpy => 1,
    );

    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    sub log {
        my $self = shift;
        my %p    = $validator->(@_);

        my $level_num = $self->_level_as_number( $p{level} );
        return unless $self->_should_log($level_num);

        local $! = undef;
        $p{message} = $self->_apply_callbacks(%p)
            if $self->{callbacks};

        $self->log_message(%p);
    }

    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    sub _log_with_num {
        my $self      = shift;
        my $level_num = shift;
        my %p         = @_;

        return unless $self->_should_log($level_num);

        local $! = undef;
        $p{message} = $self->_apply_callbacks(%p)
            if $self->{callbacks};

        $self->log_message(%p);
    }
    ## use critic
}

{
    my $validator = validation_for(
        params => {
            name => {
                type     => t('NonEmptyStr'),
                optional => 1,
            },
            min_level => { type => t('LogLevel') },
            max_level => {
                type     => t('LogLevel'),
                optional => 1,
            },
            callbacks => {
                type     => t('Callbacks'),
                optional => 1,
            },
            newline => {
                type    => t('Bool'),
                default => 0,
            },
        },

        # This is primarily here for the benefit of outputs outside of this
        # distro which may be passing who-knows-what to this method.
        slurpy => 1,
    );

    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    sub _basic_init {
        my $self = shift;
        my %p    = $validator->(@_);

        $self->{level_names} = \@OrderedLevels;

        $self->{name} = $p{name} || $self->_unique_name();

        $self->{min_level} = $self->_level_as_number( $p{min_level} );

        # Either use the parameter supplied or just the highest possible level.
        $self->{max_level} = (
            exists $p{max_level}
            ? $self->_level_as_number( $p{max_level} )
            : $#{ $self->{level_names} }
        );

        $self->{callbacks} = $p{callbacks} if $p{callbacks};

        if ( $p{newline} ) {
            push @{ $self->{callbacks} }, \&_add_newline_callback;
        }
    }
}

sub name {
    my $self = shift;

    return $self->{name};
}

sub min_level {
    my $self = shift;

    return $self->{level_names}[ $self->{min_level} ];
}

sub max_level {
    my $self = shift;

    return $self->{level_names}[ $self->{max_level} ];
}

sub accepted_levels {
    my $self = shift;

    return @{ $self->{level_names} }
        [ $self->{min_level} .. $self->{max_level} ];
}

sub _should_log {
    my $self      = shift;
    my $level_num = shift;

    return (   ( $level_num >= $self->{min_level} )
            && ( $level_num <= $self->{max_level} ) );
}

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _level_as_name {
    my $self  = shift;
    my $level = shift;

    unless ( defined $level ) {
        Carp::croak 'undefined value provided for log level';
    }

    my $canonical_level;
    unless ( $canonical_level = Log::Dispatch->level_is_valid($level) ) {
        Carp::croak "$level is not a valid Log::Dispatch log level";
    }

    return $canonical_level unless $level =~ /\A[0-7]+\z/;

    return $self->{level_names}[$level];
}
## use critic

my $_unique_name_counter = 0;

sub _unique_name {
    my $self = shift;

    return '_anon_' . $_unique_name_counter++;
}

sub _add_newline_callback {

    # This weird construct is an optimization since this might be called a lot
    # - see https://github.com/autarch/Log-Dispatch/pull/7
    +{@_}->{message} . "\n";
}

1;

# ABSTRACT: Base class for all Log::Dispatch::* objects

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Dispatch::Output - Base class for all Log::Dispatch::* objects

=head1 VERSION

version 2.70

=head1 SYNOPSIS

  package Log::Dispatch::MySubclass;

  use Log::Dispatch::Output;
  use base qw( Log::Dispatch::Output );

  sub new {
      my $proto = shift;
      my $class = ref $proto || $proto;

      my %p = @_;

      my $self = bless {}, $class;

      $self->_basic_init(%p);

      # Do more if you like

      return $self;
  }

  sub log_message {
      my $self = shift;
      my %p    = @_;

      # Do something with message in $p{message}
  }

  1;

=head1 DESCRIPTION

This module is the base class from which all Log::Dispatch::* objects
should be derived.

=head1 CONSTRUCTOR

The constructor, C<new>, must be overridden in a subclass. See L<Output
Classes|Log::Dispatch/OUTPUT CLASSES> for a description of the common
parameters accepted by this constructor.

=head1 METHODS

This class provides the following methods:

=head2 $output->_basic_init(%p)

This should be called from a subclass's constructor. Make sure to
pass the arguments in @_ to it. It sets the object's name and minimum
level from the passed parameters  It also sets up two other attributes which
are used by other Log::Dispatch::Output methods, level_names and level_numbers.
Subclasses will perform parameter validation in this method, and must also call
the superclass's method.

=head2 $output->name

Returns the object's name.

=head2 $output->min_level

Returns the object's minimum log level.

=head2 $output->max_level

Returns the object's maximum log level.

=head2 $output->accepted_levels

Returns a list of the object's accepted levels (by name) from minimum
to maximum.

=head2 $output->log( level => $, message => $ )

Sends a message if the level is greater than or equal to the object's
minimum level. This method applies any message formatting callbacks
that the object may have.

=head2 $output->_should_log ($)

This method is called from the C<log()> method with the log level of
the message to be logged as an argument. It returns a boolean value
indicating whether or not the message should be logged by this
particular object. The C<log()> method will not process the message
if the return value is false.

=head2 $output->_level_as_number ($)

This method will take a log level as a string (or a number) and return
the number of that log level. If not given an argument, it returns
the calling object's log level instead. If it cannot determine the
level then it will croak.

=head2 $output->add_callback( $code )

Adds a callback (like those given during construction). It is added to the end
of the list of callbacks.

=head2 $dispatch->remove_callback( $code )

Remove the given callback from the list of callbacks.

=head1 SUBCLASSING

This class should be used as the base class for all logging objects
you create that you would like to work under the Log::Dispatch
architecture. Subclassing is fairly trivial. For most subclasses, if
you simply copy the code in the SYNOPSIS and then put some
functionality into the C<log_message> method then you should be all
set. Please make sure to use the C<_basic_init> method as described above.

The actual logging implementation should be done in a C<log_message>
method that you write. B<Do not override C<log>!>.

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/houseabsolute/Log-Dispatch/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Log-Dispatch can be found at L<https://github.com/houseabsolute/Log-Dispatch>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
