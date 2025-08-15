package Log::Any::Adapter::MacOS::OSLog v0.0.4;

## no critic (Documentation::RequirePodAtEnd)

=for stopwords macOS FFI

=head1 NAME

Log::Any::Adapter::MacOS::OSLog - log to macOS' unified logging system

=head1 VERSION

version 0.0.4

=head1 SYNOPSIS

    use Log::Any::Adapter ('MacOS::OSLog',
      subsystem => 'com.example.foo',
    );

    # or

    use Log::Any::Adapter;
    Log::Any::Adapter->set('MacOS::OSLog',
      subsystem => 'org.example.bar',
    );

    # You can override defaults:
    Log::Any::Adapter->set('MacOS::OSLog',
      subsystem   => 'net.example.baz',
      os_category => 'secret',
      private     => 1,
    );

=head1 DESCRIPTION

This L<Log::Any> adapter lets Perl applications log directly to macOS'
L<unified logging system|https://developer.apple.com/documentation/os/logging>
using FFI and C wrappers--no Swift required.

=cut

use 5.018;
use warnings;
use Carp;
use File::Spec::Functions qw(catfile);
use File::Basename;

my $ffi = FFI::Platypus->new( api => 2, lib => [ _find_my_bundle() ] );

$ffi->attach(
    [ os_log_create => '_os_log_create' ] => [ 'string', 'string' ],
    'opaque',
);

my %LOGGING_LEVELS;
my @LOGGING_METHOD_NAMES = logging_methods();
for my $level_num ( 0 .. $#LOGGING_METHOD_NAMES ) {
    $LOGGING_LEVELS{ $LOGGING_METHOD_NAMES[$level_num] } = $level_num;
}
my %LOG_LEVEL_ALIASES = log_level_aliases();
for ( keys %LOG_LEVEL_ALIASES ) {
    $LOGGING_LEVELS{$_} = $LOGGING_LEVELS{ $LOG_LEVEL_ALIASES{$_} };
}

=head1 SUBROUTINES/METHODS

=for stopwords init

=head2 init

This method is not called directly, but rather is passed named arguments
as a hash when setting a L<Log::Any::Adapter>:

=over

=item subsystem

=for stopwords DNS FQDN

Required. Must be a reversed fully-qualified domain name (FQDN), e.g.,
C<com.example.perl>.

=item log_level, min_level, level

These are all synonymous and strings that set the minimum logging level
for the adapter. Whatever level is set, messages for that level and
above will be logged.

Defaults to C<trace> and is affected by various
L<environment variables|/"CONFIGURATION AND ENVIRONMENT">.

=cut

sub _min_level {
    my $self = shift;
    return $ENV{LOG_LEVEL}
        if $ENV{LOG_LEVEL}
        and defined $LOGGING_LEVELS{ $ENV{LOG_LEVEL} };
    return 'trace' if $ENV{TRACE};
    return 'debug' if $ENV{DEBUG};
    return 'info'  if $ENV{VERBOSE};
    return 'error' if $ENV{QUIET};
    return 'trace';
}

=item os_category

Not to be confused with L<Log::Any categories|Log::Any/CATEGORIES>,
this is used to categorize log entries in the unified log. However, just
to keep things simple, it defaults to the name of the category used by
L<Log::Any>.

=item private

Optional, defaults to false. A Boolean value indicating whether logged
messages should be redacted in the macOS unified logging system.

=back

=cut

sub init {
    my $self = shift;
    $self->{os_category} ||= $self->{category};
    $self->{private}     ||= 0;
    $self->{log_level}
        ||= $self->{min_level} || $self->{level} || $self->_min_level;

    # TODO: extract this into a Regexp::Common module
    ## no critic (RegularExpressions::ProhibitComplexRegexes)
    croak 'subsystem must be reversed FQDN'
        if not defined $self->{subsystem}
        and $self->{subsystem} !~ m{^
            (?= .{1,255} $)     # entire string length max 255 chars
            (?:                     # first segment is either
                  [[:alpha:]]{2,63}     # plain
                | xn--                  # or Punycode prefix followed by
                  [[:alnum:]-]{1,59}    # remaining Punycode octets
            )
            (?:                     # subsequent segments
                [.]                     # dot separator
                (?:                     # followed by either
                      [[:alpha:]_]          # plain, can't start with hyphen
                      [[:alnum:]_-]{0,62}
                    | xn--                  # or Punycode prefix followed by
                      [[:alnum:]-]{1,59}    # remaining Punycode octets
                )
            )+                      # repeat one or more times
        $}ix;

    $self->{_os_log}
        //= _os_log_create( @{$self}{qw(subsystem os_category)} );

    return;
}

=head2 L<Log::Any> methods

The following L<Log::Any> methods are mapped to macOS L<os_log(3)>
functions as follows:

=over

=item * trace: L<os_log_debug(3)>

=item * debug: L<os_log_debug(3)>

=item * info (or inform): L<os_log_info(3)>

=item * notice: L<os_log_info(3)>

=item * warning: L<os_log_fault(3)>

=item * error (or err): L<os_log_error(3)>

=for stopwords crit

=item * critical (or crit or fatal): L<os_log(3)>

=item * alert: L<os_log(3)>

=item * emergency: L<os_log(3)>

=back

Formatted methods like C<infof>, C<errorf>, etc., are supported via
L<Log::Any>'s standard interface.

=cut

my @OS_LOG_LEVEL_MAP = qw(
    os_log_debug
    os_log_debug
    os_log_info
    os_log_info
    os_log_fault
    os_log_error
    os_log_default
    os_log_default
    os_log_default
);

# attach each wrapper function
my %UNIQUE_OS_LOG = map { $_ => 1 } @OS_LOG_LEVEL_MAP;
foreach my $function ( keys %UNIQUE_OS_LOG ) {
    for my $variant (qw(public private)) {
        my $name = "${function}_$variant";
        $ffi->attach(
            [ $name => "_$name" ] => [ 'opaque', 'string' ],
            'void',
        );
    }
}

foreach my $method ( keys %LOGGING_LEVELS ) {
    my $log_level            = $LOGGING_LEVELS{$method};
    my $os_log_function_name = $OS_LOG_LEVEL_MAP[$log_level]
        // 'os_log_error';

    make_method(
        $method,
        sub {
            my $self = shift;
            return
                if $log_level < $LOGGING_LEVELS{ $self->{log_level} };

            no strict 'refs';    ## no critic (TestingAndDebugging::ProhibitNoStrict)
            &{ "_${os_log_function_name}_"
                    . ( $self->{private} ? 'private' : 'public' ) }
                ( $self->{_os_log}, join q{}, @_ );
        } );
}

foreach my $method ( detection_methods() ) {
    my $level = $method =~ s/^is_//r;
    make_method(
        $method,
        sub {
            my $self = shift;

            return $LOGGING_LEVELS{$level}
                >= $LOGGING_LEVELS{ $self->{log_level} };
        } );
}

sub _find_my_bundle {
    my @module_parts = split /::/, __PACKAGE__;

    my $module_pm = $INC{ join( q{/}, @module_parts ) . '.pm' }
        or croak 'Cannot find module in @INC for ' . __PACKAGE__;    ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
    my $module_dir = dirname($module_pm);

    my $auto_path
        = catfile( 'auto', @module_parts, "$module_parts[-1].bundle" );
    my $bundle_path = catfile( $module_dir,   $auto_path );
    my $blib_path   = catfile( qw(blib arch), $auto_path );

    return -e $blib_path ? $blib_path : $bundle_path;
}

=head1 DIAGNOSTICS

Using this adapter without specifying a properly-formatted C<subsystem>
argument will throw an exception.

=head1 CONFIGURATION AND ENVIRONMENT

Configure the same as L<Log::Any>.

The following environment variables can set the logging level if no
level is set on the adapter itself:

=over

=item * C<TRACE> sets the minimum level to B<trace>

=item * C<DEBUG> sets the minimum level to B<debug>

=item * C<VERBOSE> sets the minimum level to B<info>

=item * C<QUIET> sets the minimum level to B<error>

=back

In addition, the C<LOG_LEVEL> environment variable may be set to a
string indicating the desired logging level.

=head1 DEPENDENCIES

=over

=item * L<Log::Any::Adapter::Base>

=cut

use base qw(Log::Any::Adapter::Base);

=item * L<Log::Any::Adapter::Util>

=cut

use Log::Any::Adapter::Util qw(
    detection_methods
    log_level_aliases
    logging_methods
    make_method
    numeric_level
);

=item * L<FFI::Platypus> 2.00 or greater

=cut

use FFI::Platypus 2.00;

=item * L<namespace::autoclean>

=cut

use namespace::autoclean;

=back

=cut

1;

__END__

=head1 INCOMPATIBILITIES

Because this module relies on the macOS unified logging system
introduced in macOS Sierra version 10.12, it is incompatible with
earlier versions of OS X, Mac OS X, the classic Mac OS, and all other
non-Apple platforms (Microsoft Windows, Linux, other Unixes, etc.).

=for stopwords iOS iPadOS tvOS watchOS

It could conceivably be built and run on Apple iOS, iPadOS, tvOS, and
watchOS, but you'd have to build and deploy a native version of Perl
itself on those systems.

=head1 BUGS AND LIMITATIONS

Undoubtedly. Open an issue in the tracker.

=head1 SUPPORT

Source code and issue tracker:
L<https://codeberg.org/mjgardner/perl-Log-Any-Adapter-MacOS-OSLog>

=head2 Social media discussion

=over

=item * L<Mastodon|https://mastodon.phoenixtrap.com/@mjg/115008024722465194>

=for stopwords Bluesky

=item * L<Bluesky|https://bsky.app/profile/mjgardner.bsky.social/post/3lw3ueqbrwi2r>

=item * L<Threads|https://www.threads.com/@mjgardner/post/DNMyRNrs-YO>

=for stopwords LinkedIn

=item * L<Facebook|https://www.facebook.com/share/p/1B73cxh5o8/>

=item * L<LinkedIn|https://www.linkedin.com/posts/mjgardner_logging-from-perl-to-macos-unified-log-with-activity-7360513579751522304-wDgy>

=back

=head1 SEE ALSO

=over

=item * For a full write-up on the rationale, implementation, and
        integration details, see
        L<the blog post|https://phoenixtrap.com/2025/08/10/perl-macos-oslog>.

=item * Apple's L<unified logging system developer documentation|https://developer.apple.com/documentation/os/logging>

=for stopwords OSLog

=item * Apple's L<OSLog developer documentation|https://developer.apple.com/documentation/OSLog>

=for stopwords explainer

=item * The Eclectic Light Company's
        L<explainer on macOS logs|https://eclecticlight.co/2021/09/27/explainer-logs/>

=item * The Eclectic Light Company's
        L<explainer on macOS subsystem identifiers|https://eclecticlight.co/2022/08/27/explainer-subsystems/>

=back

=head1 AUTHOR

Mark Gardner <mjgardner@cpan.org>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2025 by Mark Gardner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
