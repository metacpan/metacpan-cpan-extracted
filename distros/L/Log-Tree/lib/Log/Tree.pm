package Log::Tree;
$Log::Tree::VERSION = '0.18';
our $AUTHORITY = 'cpan:TEX';
# ABSTRACT: lightweight but highly configurable logging class

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;

use English qw( -no_match_vars );
use Log::Dispatch;
use Log::Dispatch::Screen;
use Data::Tree '0.16';
use IO::Interactive::Tiny qw();

has 'dispatcher' => (
    'is'       => 'ro',
    'isa'      => 'Log::Dispatch',
    'required' => 0,
    'lazy'     => 1,
    'builder'  => '_init_dispatcher',
);

has 'filename' => (
    'is'      => 'ro',
    'isa'     => 'Str',
    'lazy'    => 1,
    'builder' => '_init_filename',
);

has 'facility' => (
    'is'       => 'ro',
    'isa'      => 'Str',
    'required' => 1,
);

has 'recipients' => (
    'is'  => 'rw',
    'isa' => 'ArrayRef[Str]',
);

has '_buffer' => (
    'is'      => 'rw',
    'isa'     => 'ArrayRef',
    'default' => sub { [] },
);

has 'prefix_caller' => (
    'is'      => 'rw',
    'isa'     => 'Bool',
    'default' => 1,
);

has 'prefix_ts' => (
    'is'      => 'rw',
    'isa'     => 'Bool',
    'default' => 1,
);

has 'prefix_level' => (
    'is'      => 'rw',
    'isa'     => 'Bool',
    'default' => 1,
);

has 'prefix' => (
    'is'      => 'rw',
    'isa'     => 'Str',
    'default' => q{},
);

has 'suffix' => (
    'is'      => 'rw',
    'isa'     => 'Str',
    'default' => q{},
);

has 'verbosity' => (
    'is'      => 'rw',
    'isa'     => 'Int',
    'default' => 0,
    'trigger' => \&_set_level,
);

has 'loglevels' => (
    'is'      => 'rw',
    'isa'     => 'Data::Tree',
    'lazy'    => 1,
    'builder' => '_init_loglevels',
);

has 'severities' => (
    'is'      => 'ro',
    'isa'     => 'ArrayRef',
    'lazy'    => 1,
    'builder' => '_init_severities',
);

has 'syslog' => (
    'is'    => 'ro',
    'isa'   => 'Bool',
    'default' => 0,
);

has 'config' => (
    'is'    => 'rw',
    'isa'   => 'Config::Yak',
    'required' => 0,
    'trigger' => \&_set_config,
);

sub _init_severities {
    return [qw(debug info notice warning error critical alert emergency)];
}

sub _init_loglevels {
    my $self = shift;

    my $Tree = Data::Tree::->new();
    $Tree->set( '__LEVEL__', 'debug' );

    $self->_update_loglevels();

    return $Tree;
}

sub _update_loglevels {
    my $self = shift;

    return unless $self->config();
    # TODO read config and set apt levels
}

sub _set_level {
    my ( $self, $new_value, $old_value ) = @_;

    if ( $self->dispatcher()->output('Screen') ) {
        $self->dispatcher()->output('Screen')->{'min_level'} = $self->_verbosity_to_level($new_value);
    }

    return;
}

sub _set_config {
    my ( $self, $new_value, $old_value ) = @_;

    $self->_update_loglevels();

    return;
}

sub _verbosity_to_level {
    my $self      = shift;
    my $verbosity = shift;

    my $level         = 7;
    my $default_level = 4;

    $level = ( $default_level - $verbosity );

    if ( $level < 0 ) {
        $level = 0;
    }
    elsif ( $level > 7 ) {
        $level = 7;
    }
    return $level;
}

sub severity_to_level {
    my $self = shift;
    my $sev  = shift;

    # already numeric? so it's a level
    if ( !$sev || $sev =~ m/^\d+$/ ) {
        return $sev;
    }

    if ( $sev =~ m/debug/i ) {
        return 0;
    }
    elsif ( $sev =~ m/info/i ) {
        return 1;
    }
    elsif ( $sev =~ m/notice/i ) {
        return 2;
    }
    elsif ( $sev =~ m/warn(?:ing)?/i ) {
        return 3;
    }
    elsif ( $sev =~ m/err(?:or)?/i ) {
        return 4;
    }
    elsif ( $sev =~ m/crit(?:ical)?/i ) {
        return 5;
    }
    elsif ( $sev =~ m/alert/i ) {
        return 6;
    }
    elsif ( $sev =~ m/emerg(?:ency)/i ) {
        return 7;
    }
    else {
        return 0;
    }
}

sub level_to_severity {
    my $self  = shift;
    my $level = shift;

    # doesn't look like a level ... so bail out
    if ( !$level || $level !~ m/^\d+$/ ) {
        return $level;
    }

    if ( $level < 0 ) {
        return 'debug';
    }
    elsif ( $level > 7 ) {
        return 'emergency';
    }
    else {
        return $self->severities()->[$level];
    }
}

sub get_buffer {
    my $self = shift;
    my $min_level = shift || 0;

    # make sure it's a numeric value
    $min_level = $self->severity_to_level($min_level);

    my @lines = ();
    if ( $min_level < 1 ) {
        @lines = @{ $self->_buffer() };
    }
    else {

        # filter out only those whose severity is important enough
        foreach my $line ( @{ $self->_buffer() } ) {
            if ( $self->severity_to_level( $line->{'level'} ) >= $min_level ) {
                push( @lines, $line );
            }
        }
    }

    return \@lines;
}

sub clear_buffer {
    my $self = shift;
    $self->_buffer( [] );

    return;
}

# clean up after forking
sub forked {
    my $self = shift;

    $self->clear_buffer();

    return 1;
}

sub add_to_buffer {
    my $self = shift;
    my $obj  = shift;

    # make sure the buffer doesn't get too big
    if ( @{ $self->_buffer() } > 1_000_000 ) {
        shift @{ $self->_buffer() };
    }
    push( @{ $self->_buffer() }, $obj );

    return 1;
}

sub _init_filename {
    my $self = shift;

    my $name = lc( $self->facility() );
    $name =~ s/\W/-/g;
    $name =~ s/_/-/g;
    if ( $name !~ m/\.log$/ ) {
        $name .= '.log';
    }
    if ( -w '/var/log/' ) {
        return '/var/log/' . $name;
    }
    else {
        return '/tmp/' . $name;
    }
}

sub _check_filename {
    my $self     = shift;
    my $filename = shift;

    if ( -f $filename ) {
        if ( -w $filename ) {
            return $filename;
        }
        else {
            return $self->_init_filename();
        }
    }
    else {
        my @path = split /\//, $filename;
        pop @path;
        my $basedir = join '/', @path;
        if ( -w $basedir ) {
            return $filename;
        }
        else {
            return $self->_init_filename();
        }
    }
}

sub _init_dispatcher {
    my $self = shift;

    my $log = Log::Dispatch::->new();

    # only log to screen if running interactively
    if(IO::Interactive::Tiny::is_interactive() || $ENV{'LOG_TREE_STDOUT'}) {
        $log->add(
            Log::Dispatch::Screen::->new(
                name      => 'screen',
                min_level => $self->_verbosity_to_level( $self->verbosity() ),
            )
        );
    }

    if ( $self->syslog() && $self->facility() ) {
        require Log::Dispatch::Syslog;
        $log->add(
            Log::Dispatch::Syslog::->new(
                name      => 'syslog',
                min_level => 'warning',
                ident     => $self->facility(),
            )
        );
    }

    if ( $self->filename() ) {
        require Log::Dispatch::File::Locked;
        $log->add(
            Log::Dispatch::File::Locked::->new(
                name      => 'file',
                min_level => 'debug',
                'mode'    => 'append',
                'close_after_write'   => 1,
                filename  => $self->filename(),
            )
        );
    }

    if ( $self->recipients() ) {
        require Log::Dispatch::Email::MailSender;
        $log->add(
            Log::Dispatch::Email::MailSender::->new(
                name      => 'email',
                min_level => 'emerg',
                to        => join( ',', @{ $self->recipients() } ),
                subject   => $self->facility() . ' - EMERGENCY',
            )
        );
    }
    return $log;
}

# DGR: speeeed
## no critic (RequireArgUnpacking)
sub _real_caller {

    # $_[0] -> self
    # $_[1] -> calldepth
    my $max_depth = 255;
    my $min_depth = 2;
    $min_depth += $_[1] if $_[1];

    # 0 is this sub -> not relevant
    # 1 is Logger::log -> not relevant
    # we want to know who called Logger::log (unless its an eval or Try)
    foreach my $i ( 1 .. $max_depth ) {
        my @c = caller($i);
        return caller( $i - 1 ) unless @c;    # no caller information?
        next unless $c[0];
        next if $c[0] eq 'Try::Tiny';         # package Try::Tiny? Skip.
        next unless $c[3];
        next if $c[3] eq 'Log::Tree::log';
        next if $c[3] eq 'Try::Tiny::try';     # calling sub Try::Tiny::try? Skip.
        next if $c[3] eq '(eval)';             # calling sub some kind of eval? Skip.
        next if $c[3] =~ m/__ANON__/;          # calling sub some kind of anonymous sub? Skip.
        return @c;
    }
    return ();
}
## use critic

# DGR: speeeed
## no critic (RequireArgUnpacking)
sub _would_log {

    # $_[0] -> self
    # $_[1] -> caller
    # $_[2] -> level

    my @cp = ();
    if ( $_[1] ) {
        @cp = split /::/, $_[1];
    }

    while (@cp) {
        my $min_sev = $_[0]->loglevels()->get( [ @cp, '__LEVEL__' ] );
        if ($min_sev) {
            my $min_lvl = $_[0]->severity_to_level($min_sev);
            if ( defined($min_lvl) && $_[0]->severity_to_level( $_[2] ) >= $min_lvl ) {
                return 1;
            }
        }
        pop @cp;
    }
    my $min_sev = $_[0]->loglevels()->get('__LEVEL__');
    if ($min_sev) {
        my $min_lvl = $_[0]->severity_to_level($min_sev);
        if ( defined($min_lvl) && $_[0]->severity_to_level( $_[2] ) >= $min_lvl ) {
            return 1;
        }
    }
    return;
}
## use critic

## no critic (ProhibitBuiltinHomonyms RequireArgUnpacking)
sub log {
## use critic
    my $self = shift;

    my %params = ();
    my ( $package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash ) = $self->_real_caller();
    if ( $package eq 'main' && $subroutine eq 'Log::Tree::log' ) {
        $subroutine = q{};
    }

    if ( scalar(@_) % 2 == 0 ) {
        %params = @_;
    }
    else {
        $params{'message'} = 'Incorrect usage of log in ' . $subroutine . '. Args: ' . join( q{ }, @_ );
        $params{'level'} = 'error';
    }

    $params{'ts'} = time();
    $params{'level'} ||= 'debug';

    # skip messages we don't want to log
    return unless $self->_would_log( $subroutine, $params{'level'} );
    $subroutine ||= 'n/a';
    $params{'caller'} = $subroutine unless $params{'caller'};

    # resolve any code ref
    if ( $params{'message'} && ref( $params{'message'} ) eq 'CODE' ) {
        $params{'message'} = &{ $params{'message'} }();
    }

    $self->add_to_buffer( \%params );

    # IMPORTANT: Since we add a hash_REF to the buffer, everything we do to the hash itself affects the buffer, too
    # So if we want to modify the hash given to the dispatcher, but not the one in the buffer we have to create a copy.
    # Otherwise the buffer is cluttered with information we don't want.
    my %params_disp = %params;

    # we use tabs to separated the fields, so remove any tabs already present
    $params_disp{'message'} =~ s/\t/ /g;

    # prepend log level
    if ( $self->prefix_level() ) {
        $params_disp{'message'} = uc( $params_disp{'level'} ) . "\t" . $params_disp{'message'};
    }

    # prepend log message w/ the caller
    if ( $self->prefix_caller() ) {
        $params_disp{'message'} = $params_disp{'caller'} . "\t" . $params_disp{'message'};
    }

    # prepend a user-supplied prefix, e.g. [CHILD 24324/234342]
    if ( $self->prefix() ) {
        $params_disp{'message'} = $self->prefix() . "\t" . $params_disp{'message'};
    }

    # prepend log message w/ a timestamp
    if ( $self->prefix_ts() ) {
        my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime( $params{'ts'} );
        $year += 1900;
        $mon++;
        $params_disp{'message'} = sprintf( '%04i.%02i.%02i-%02i:%02i:%02i', $year, $mon, $mday, $hour, $min, $sec ) . "\t" . $params_disp{'message'};
    }
    
    # append a user-supplied suffix
    if ( $self->suffix() ) {
        $params_disp{'message'} = $params_disp{'message'} . "\t" . $self->suffix();
    }

    $params_disp{'message'} .= "\n";

    return $self->dispatcher()->log(%params_disp);
}

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 && !ref $_[0] ) {
        return $class->$orig( facility => $_[0] );
    }
    else {
        return $class->$orig(@_);
    }
};

sub BUILD {
    my $self = shift;
    my $args = shift;

    if ( $args->{'filename'} ) {
        $self->{'filename'} = $self->_check_filename( $args->{'filename'} );
    }
    else {
        $self->{'filename'} = $self->_init_filename();
    }

    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Tree - lightweight but highly configurable logging class

=head1 SYNOPSIS

    use Log::Tree;

    my $logger = Log::Tree::->new('foo');
    ...

=head1 ATTRIBUTES

=head2 facility

Only mandatory attirbute. Used as the syslog faclity and to auto-construct a suiteable
filename for logging to file.

=head1 METHODS

=head2 add_to_buffer

This method is usually not needed from by callers but may be in some rare ocasions
that's why it's made part of the public API. It just adds the passed data to the
internal buffer w/o logging it in the usual ways.

=head2 clear_buffer

This method clears the internal log buffer.

=head2 forked

This method should be called after it has been fork()ed to clear the internal
log buffer.

=head2 get_buffer

Retrieve those entries from the buffer that are gte the given severity.

=head2 log

Log a message. Takes a hash containing at least "message" and "level".

=head2 BUILD

Call on instatiation to set this class up.

=head2 level_to_severity

Translates a numeric level to severity string.

=head2 severity_to_level

Translates a severity string to a numeric level.

=head1 NAME

Log::Tree - Lightyweight logging w/ a tree based verbosity configuration
similar to Log4perl.

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
