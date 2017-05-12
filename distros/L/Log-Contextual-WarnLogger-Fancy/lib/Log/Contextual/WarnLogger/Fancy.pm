use 5.006;    # our
use strict;
use warnings;

package Log::Contextual::WarnLogger::Fancy;

our $VERSION = '0.002000';

use Carp qw( croak );
use Term::ANSIColor qw( colored );

delete $Log::Contextual::WarnLogger::Fancy::{$_}
  for qw( croak colored );    # namespace clean

delete $Log::Contextual::WarnLogger::Fancy::{$_}
  for qw( _gen_level_sub _gen_is_level_sub _name_sub _can_name_sub _elipsis )
  ;                           # not for external use cleaning

BEGIN {
    # Lazily find the best XS Sub naming implementation possible.
    # Preferring an already loaded implementation where possible.
    #<<< Tidy Guard
    my $impl = ( $INC{'Sub/Util.pm'}           and defined &Sub::Util::set_subname )  ? 'SU'
             : ( $INC{'Sub/Name.pm'}           and defined &Sub::Name::subname     )  ? 'SN'
             : ( eval { require Sub::Util; 1 } and defined &Sub::Util::set_subname )  ? 'SU'
             : ( eval { require Sub::Name; 1 } and defined &Sub::Name::subname     )  ? 'SN'
             :                                                                          '';
    *_name_sub = $impl eq 'SU'   ? \&Sub::Util::set_subname
               : $impl eq 'SN'   ? \&Sub::Name::subname
               :                   sub { $_[1] };
    #>>>
    *_can_name_sub = $impl ? sub() { 1 } : sub () { 0 };
}

_gen_level($_) for (qw( trace debug info warn error fatal ));

# Hack Notes: Custom levels are not currently recommended, but doing the following *should* work:
#
# Log::Contextual::WarnLogger::Fancy::_gen_level('custom');
# $logger->{levels} = [ @{ $logger->{levels}, 'custom' ];
# $logger->{level_nums}->{ 'custom' } = 1;
# $logger->{level_labels}->{ 'custom' } = 'custo';

sub new {
    my ( $class, @args ) = @_;

    my $args = ( @args == 1 && ref $args[0] ? { %{ $args[0] } } : {@args} );

    my $self = bless {}, $class;

    $self->{env_prefix} = $args->{env_prefix}
      or croak 'no env_prefix passed to ' . __PACKAGE__ . '->new';

    for my $field (qw( group_env_prefix default_upto label label_length )) {
        $self->{$field} = $args->{$field} if exists $args->{$field};
    }
    if ( defined $self->{label} and length $self->{label} ) {
        $self->{label_length} = 16 unless exists $args->{label_length};
        $self->{effective_label} =
          _elipsis( $self->{label}, $self->{label_length} );
    }
    my @levels       = qw( trace debug info warn error fatal );
    my %level_colors = (
        trace => [],
        debug => ['blue'],
        info  => ['white'],
        warn  => ['yellow'],
        error => ['magenta'],
        fatal => ['red'],
    );

    $self->{levels} = [@levels];
    @{ $self->{level_nums} }{@levels} = ( 0 .. $#levels );
    for my $level (@levels) {
        $self->{level_labels}->{$level} = sprintf "%-5s", $level;
        if ( @{ $level_colors{$level} || [] } ) {
            $self->{level_labels}->{$level} =
              colored( $level_colors{$level}, $self->{level_labels}->{$level} );
        }
    }

    unless ( exists $self->{default_upto} ) {
        $self->{default_upto} = 'warn';
    }
    return $self;
}

# TODO: Work out how to savely use Unicode \x{2026}, and then elipsis_width
# becomes 1. Otherwise utf8::encode() here after computing width might have to do.
my $elipsis_char  = chr(166);               #"\x{183}";
my $elipsis_width = length $elipsis_char;

sub _elipsis {
    my ( $text, $length ) = @_;
    return sprintf "%" . $length . "s", $text if ( length $text ) <= $length;

 # Because the elipsis doesn't count for our calculations because its logically
 # "in the middle". Subsequent math should be done assuming there is no elipsis.
    my $pad_space = $length - $elipsis_width;
    return '' if $pad_space <= 0;

    # Doing it this way handles a not entirely balanced case automatically.
    #   trimming   asdfghij to length 6 with a 1 character elipis
    #   ->  "....._"
    #   ->  ".._..."
    # so left gets a few less than the right here to have room for elipsis.
    #
    # When pad_space is even, it all works out in the end due to int truncation.
    my $lw = int( $pad_space / 2 );
    my $rw = $pad_space - $lw;

    return sprintf "%s%s%s", ( substr $text, 0, $lw ), $elipsis_char,
      ( substr $text, -$rw, $rw );
}

sub _log {
    my $self    = shift;
    my $level   = shift;
    my $message = join( "\n", @_ );
    $message .= qq[\n] unless $message =~ /\n\z/;
    my $label = $self->{level_labels}->{$level};

    $label .= ' ' . $self->{effective_label} if $self->{effective_label};
    warn "[${label}] $message";
}

sub _gen_level_sub {
    my ( $level, $is_name ) = @_;
    return sub {
        my $self = shift;
        return unless $self->$is_name;
        $self->_log( $level, @_ );
    };
}

sub _gen_is_level_sub {
    my ($level) = @_;
    my $ulevel = '_' . uc $level;

    return sub {
        my $self = shift;

        # All ENV vars are just treated as an ordered list.
        #
        # "env_prefix" comes first, then group_env_prefix comes second as a
        # fallback.
        # group_env_prefix can be an arrayref itself ordered by
        # narrowest-to-broadest.

        my (@prefixes) = ( $self->{env_prefix} );
        if ( defined $self->{group_env_prefix} ) {
            if ( ref $self->{group_env_prefix} ) {
                push @prefixes, @{ $self->{group_env_prefix} };
            }
            else {
                push @prefixes, $self->{group_env_prefix};
            }
        }

        # If Any of ${PREFIX}_${LEVEL} is explicitly defined in ENV, it takes
        # precendence over anythingthing else, returning true/false based on
        # whether or not those values are true or false

        for my $env_var ( map { $_ . $ulevel } @prefixes ) {
            return !!$ENV{$env_var} if defined $ENV{$env_var};
        }

        # If Any of ${PREFIX}_UPTO is explicitly defined in ENV,
        # it falls back from ${PREFIX_LEVEL} but again, the "narrowest"
        # scope wins.

        my $upto;
        for my $env_var ( map { $_ . '_UPTO' } @prefixes ) {
            if ( defined $ENV{$env_var} ) {
                $upto = lc $ENV{$env_var};
                croak "Unrecognized log level '$upto' in \$ENV{$env_var}"
                  if not defined $self->{level_nums}->{$upto};
                last;
            }
        }

        # If there is no UPTO in env and there's no default, then we can't be
        # considered.
        return 0 if not defined $upto and not defined $self->{default_upto};

        # Defaults however are considered where possible.
        $upto = $self->{default_upto} if not defined $upto;

        return $self->{level_nums}->{$level} >= $self->{level_nums}->{$upto};
    };
}

sub _gen_level {
    my ($level) = @_;
    my $is_name = "is_$level";

    my $level_sub = _gen_level_sub( $level, $is_name );
    my $is_level_sub = _gen_is_level_sub($level);

    _can_name_sub and _name_sub( "$level",   $level_sub );
    _can_name_sub and _name_sub( "$is_name", $is_level_sub );

    no strict 'refs';
    *{$level}   = $level_sub;
    *{$is_name} = $is_level_sub;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Log::Contextual::WarnLogger::Fancy - A modernish default lightweight logger

=head1 DESCRIPTION

Log::Contextual::WarnLogger::Fancy is a re-implementation of L<Log::Contextual::WarnLogger> with a few conveniences added.

=over 4

=item * L<Group Prefixes|/Group Prefixes>

=item * L<< Default C<upto> level|/Default upto level. >>

=item * L<ANSI Colors|/ANSI Colors>

=item * L<< Padded Log Level Labels|/Padded Log Level Labels >>

=item * L<< Per Logger Origin Labels|/Per Logger Origin Labels >> with padding/shortening.

=back

=head1 FEATURES NOT IN C<::WarnLogger>

=head2 Group Prefixes

  package My::Project::Package;

  my $logger = Log::Contextual::WarnLogger::Fancy->new(
    env_prefix       => 'MY_PROJECT_PACKAGE',   # control this level only
    group_env_prefix => 'MY_PROJECT',           # shared control for all components
  );

This allows adding targeted granular debug tracing to selected packages within a project,
or within all packages in a project, without having to resort to heavyweight loggers.

  MY_PROJECT_UPTO=debug           # debug the whole project
  MY_PROJECT_PACKAGE_UPTO=trace   # trace level on ::Package

Since C<0.002000>, C<group_env_prefix> can be an C<ArrayRef> ordered by "narrowest" to "broadest" inclusion.

  my $logger = Log::Contextual::WarnLogger::Fancy->new(
    env_prefix       => 'MY_PROJECT_PACKAGE',     # control this level only
    group_env_prefix => [ 'MY_PROJECT', 'MY' ],   # shared control for all components
  );

=head2 Default C<upto> level.

Because it seems like you'd want to make C<log_warn> and C<log_fatal> visible on the controlling terminal,
its useful not to need to set C<MY_PROJECT_UPTO=> in your environment just to get some useful output.

Instead, by default, C<::Fancy> assumes a default C<upto> value of C<warn>, and you can adjust this via

  my $logger = Log::Contextual::WarnLogger::Fancy->new(
    ...
    default_upto     => 'info',
  );

And from then on, you can use C<log_warn { ... }> with the same convenience as C<warn ...> and know that
your user will see it, and that if they bolt on some advanced logging system, that those warnings will flow
nicely into it.

=head2 ANSI Colors

In order to make log output faster to visually scan, ANSI Colour codes are used to indicate various log levels.

  trace => plain
  debug => blue
  info  => white
  warn  => yellow
  error => magenta
  fatal => red

=head2 Padded Log Level Labels

Because some of us are anal as hell, the following just looks messy:

  [trace] message
  [info] message
  [fatal] message

So C<level> labels are constantly padded to 5 characters.

  [trace] message
  [info ] message  # Aaaaah. (~˘▾˜)/
  [fatal] message

=head2 Per Logger Origin Labels

Because the recommended usage of C<::WarnLogger::Fancy> results in creating
a logger instance per package, each logger instance can be customized with a
prefix to give more context when used in bulk.

  my $logger = Log::Contextual::WarnLogger::Fancy->new(
    label         => __PACKAGE__
    label_length  => 16,
  );

...

  [trace    Some::Package] A trace message
  [info    Other::Package] An info message
  [warn     Some::Package] A warning
  [fatal My::Oth¦:Package] A fatal warning

Additionally, Origin Labels are constant-sized where specified, defaulting to
C<16> characters long, either left-padded to meet that length, or C<infix>
condensed to C<16> characters.

Currently, the C<infix> character of choice is C<¦> ( C<chr(166)> U+00A6 BROKEN BAR )
which may be superficially similar to C<|> ( C<chr(124)> U+007C VERTICAL LINE )

Chosen as such because its the only character I could find that

=over 4

=item * Is unlikely to be in common usage

=item * Will be visually distinct

=item * Will be likely to be understood in its context without elaborate explanation

=item * Will likely render as intended on all output terminals

=item * Won't require magic with turning on UTF8 Support

=back

C<¦> is the same in both C<UTF-8>, C<ISO-8859-1> and C<Windows-1252>, with only C<CP437> being an outlier
with C<FEMININE ORDINAL INDICATOR> ( Equiv of U+00AA )

I'd have ideally used C<…> ( U+2026 HORIZONTAL ELLIPSIS ), but getting C<UTF-8> magic is filled with challenges.

( It however still might be implemented this way in future )

=head1 INTENTIONALLY MISSING FEATURES

=head2 Custom Logging Levels

C<::WarnLogger> has one feature that adds a bit of complexity, and there's additional
implementation confusion for me in mapping/understanding the existing code.

Specifically with regards to C<AUTOLOAD> and how it implements custom logging levels
differently from stock levels.

The plumbing is in place to implement it in a similar way, but its not clear to me if
this feature is a "Good idea" or not at this time.

So the glue is in place for people who are sure they need it, but its intentionally obscure
to serve as a disincentive. ( Please file a bug/contact me somehow if you are sure this is a good idea,
preferably with explanations on how you plan on using it with example code )

=head1 AUTHOR

Kent Fredric C<kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Kent Fredric

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
