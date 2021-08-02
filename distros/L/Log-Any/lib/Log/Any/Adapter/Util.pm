use 5.008001;
use strict;
use warnings;

package Log::Any::Adapter::Util;

# ABSTRACT: Common utility functions for Log::Any
our $VERSION = '1.710';

use Exporter;
our @ISA = qw/Exporter/;

my %LOG_LEVELS;
BEGIN {
    %LOG_LEVELS = (
        EMERGENCY => 0,
        ALERT     => 1,
        CRITICAL  => 2,
        ERROR     => 3,
        WARNING   => 4,
        NOTICE    => 5,
        INFO      => 6,
        DEBUG     => 7,
        TRACE     => 8,
    );
}

use constant \%LOG_LEVELS;

our @EXPORT_OK = qw(
  cmp_deeply
  detection_aliases
  detection_methods
  dump_one_line
  log_level_aliases
  logging_aliases
  logging_and_detection_methods
  logging_methods
  make_method
  numeric_level
  read_file
  require_dynamic
);

push @EXPORT_OK, keys %LOG_LEVELS;

our %EXPORT_TAGS = ( 'levels' => [ keys %LOG_LEVELS ] );

my ( %LOG_LEVEL_ALIASES, @logging_methods, @logging_aliases, @detection_methods,
    @detection_aliases, @logging_and_detection_methods );

BEGIN {
    %LOG_LEVEL_ALIASES = (
        inform => 'info',
        warn   => 'warning',
        err    => 'error',
        crit   => 'critical',
        fatal  => 'critical'
    );
    @logging_methods =
      qw(trace debug info notice warning error critical alert emergency);
    @logging_aliases               = keys(%LOG_LEVEL_ALIASES);
    @detection_methods             = map { "is_$_" } @logging_methods;
    @detection_aliases             = map { "is_$_" } @logging_aliases;
    @logging_and_detection_methods = ( @logging_methods, @detection_methods );
}

#pod =sub logging_methods
#pod
#pod Returns a list of all logging method. E.g. "trace", "info", etc.
#pod
#pod =cut

sub logging_methods               { @logging_methods }

#pod =sub detection_methods
#pod
#pod Returns a list of detection methods.  E.g. "is_trace", "is_info", etc.
#pod
#pod =cut

sub detection_methods             { @detection_methods }

#pod =sub logging_and_detection_methods
#pod
#pod Returns a list of logging and detection methods (but not aliases).
#pod
#pod =cut

sub logging_and_detection_methods { @logging_and_detection_methods }

#pod =sub log_level_aliases
#pod
#pod Returns key/value pairs mapping aliases to "official" names.  E.g. "err" maps
#pod to "error".
#pod
#pod =cut

sub log_level_aliases             { %LOG_LEVEL_ALIASES }

#pod =sub logging_aliases
#pod
#pod Returns a list of logging alias names.  These are the keys from
#pod L</log_level_aliases>.
#pod
#pod =cut

sub logging_aliases               { @logging_aliases }

#pod =sub detection_aliases
#pod
#pod Returns a list of detection aliases.  E.g. "is_err", "is_fatal", etc.
#pod
#pod =cut

sub detection_aliases             { @detection_aliases }

#pod =sub numeric_level
#pod
#pod Given a level name (or alias), returns the numeric value described above under
#pod log level constants.  E.g. "err" would return 3.
#pod
#pod =cut

sub numeric_level {
    my ($level) = @_;
    my $canonical =
      exists $LOG_LEVEL_ALIASES{ lc $level } ? $LOG_LEVEL_ALIASES{ lc $level } : $level;
    return $LOG_LEVELS{ uc($canonical) };
}

#pod =sub dump_one_line
#pod
#pod Given a reference, returns a one-line L<Data::Dumper> dump with keys sorted.
#pod
#pod =cut

# lazy trampoline to load Data::Dumper only on demand but then not try to
# require it pointlessly each time
*dump_one_line = sub {
    require Data::Dumper;

    my $dumper = sub {
        my ($value) = @_;

        return Data::Dumper->new( [$value] )->Indent(0)->Sortkeys(1)->Quotekeys(0)
        ->Terse(1)->Useqq(1)->Dump();
    };

    my $string = $dumper->(@_);
    no warnings 'redefine';
    *dump_one_line = $dumper;
    return $string;
};

#pod =sub make_method
#pod
#pod Given a method name, a code reference and a package name, installs the code
#pod reference as a method in the package.
#pod
#pod =cut

sub make_method {
    my ( $method, $code, $pkg ) = @_;

    $pkg ||= caller();
    no strict 'refs';
    *{ $pkg . "::$method" } = $code;
}

#pod =sub require_dynamic (DEPRECATED)
#pod
#pod Given a class name, attempts to load it via require unless the class
#pod already has a constructor available.  Throws an error on failure. Used
#pod internally and may become private in the future.
#pod
#pod =cut

sub require_dynamic {
    my ($class) = @_;

    return 1 if $class->can('new'); # duck-type that class is loaded

    unless ( defined( eval "require $class; 1" ) )
    {    ## no critic (ProhibitStringyEval)
        die $@;
    }
}

#pod =sub read_file (DEPRECATED)
#pod
#pod Slurp a file.  Does *not* apply any layers.  Used for testing and may
#pod become private in the future.
#pod
#pod =cut

sub read_file {
    my ($file) = @_;

    local $/ = undef;
    open( my $fh, '<:utf8', $file ) ## no critic
      or die "cannot open '$file': $!";
    my $contents = <$fh>;
    return $contents;
}

#pod =sub cmp_deeply (DEPRECATED)
#pod
#pod Compares L<dump_one_line> results for two references.  Also takes a test
#pod label as a third argument.  Used for testing and may become private in the
#pod future.
#pod
#pod =cut

sub cmp_deeply {
    my ( $ref1, $ref2, $name ) = @_;

    my $tb = Test::Builder->new();
    $tb->is_eq( dump_one_line($ref1), dump_one_line($ref2), $name );
}

# 0.XX version loaded Log::Any and some adapters relied on this happening
# behind the scenes.  Since Log::Any now uses this module, we load Log::Any
# via require after compilation to mitigate circularity.
require Log::Any;

1;


# vim: ts=4 sts=4 sw=4 et tw=75:

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::Adapter::Util - Common utility functions for Log::Any

=head1 VERSION

version 1.710

=head1 DESCRIPTION

This module has utility functions to help develop L<Log::Any::Adapter>
subclasses or L<Log::Any::Proxy> formatters/filters.  It also has some
functions used in internal testing.

=head1 SUBROUTINES

=head2 logging_methods

Returns a list of all logging method. E.g. "trace", "info", etc.

=head2 detection_methods

Returns a list of detection methods.  E.g. "is_trace", "is_info", etc.

=head2 logging_and_detection_methods

Returns a list of logging and detection methods (but not aliases).

=head2 log_level_aliases

Returns key/value pairs mapping aliases to "official" names.  E.g. "err" maps
to "error".

=head2 logging_aliases

Returns a list of logging alias names.  These are the keys from
L</log_level_aliases>.

=head2 detection_aliases

Returns a list of detection aliases.  E.g. "is_err", "is_fatal", etc.

=head2 numeric_level

Given a level name (or alias), returns the numeric value described above under
log level constants.  E.g. "err" would return 3.

=head2 dump_one_line

Given a reference, returns a one-line L<Data::Dumper> dump with keys sorted.

=head2 make_method

Given a method name, a code reference and a package name, installs the code
reference as a method in the package.

=head2 require_dynamic (DEPRECATED)

Given a class name, attempts to load it via require unless the class
already has a constructor available.  Throws an error on failure. Used
internally and may become private in the future.

=head2 read_file (DEPRECATED)

Slurp a file.  Does *not* apply any layers.  Used for testing and may
become private in the future.

=head2 cmp_deeply (DEPRECATED)

Compares L<dump_one_line> results for two references.  Also takes a test
label as a third argument.  Used for testing and may become private in the
future.

=head1 USAGE

Nothing is exported by default.

=head2 Log level constants

If the C<:levels> tag is included in the import list, the following numeric
constants will be imported:

    EMERGENCY => 0
    ALERT     => 1
    CRITICAL  => 2
    ERROR     => 3
    WARNING   => 4
    NOTICE    => 5
    INFO      => 6
    DEBUG     => 7
    TRACE     => 8

=head1 AUTHORS

=over 4

=item *

Jonathan Swartz <swartz@pobox.com>

=item *

David Golden <dagolden@cpan.org>

=item *

Doug Bell <preaction@cpan.org>

=item *

Daniel Pittman <daniel@rimspace.net>

=item *

Stephen Thirlwall <sdt@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jonathan Swartz, David Golden, and Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
