package Log::Any::Adapter::Coderef;
# ABSTRACT: Provide stacktrace and other information to generic Log::Any handlers

use strict;
use warnings;

our $VERSION = '0.002';
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

=encoding utf8

=head1 NAME

Log::Any::Adapter::Coderef - arbitrary code handlers for L<Log::Any> messages

=head1 SYNOPSIS

 use JSON::MaybeUTF8 qw(:v1);
 use Log::Any::Adapter qw(Coderef) => sub {
  my ($data) = @_;
  STDERR->print(encode_json_utf8($data) . "\n");
 };

=head1 DESCRIPTION

Provides support for sending log messages through a custom C<sub>, for cases when
you want to do something that isn't provided by existing adapters.

Currently takes a single C<$code> parameter as a callback. This will be
called for every log message, passing a hashref which has the following keys:

=over 4

=item * C<epoch> - current time, as a floating-point epoch value

=item * C<severity> - log level, e.g. C<info> or C<debug>

=item * C<message> - the formatted log message

=item * C<host> - current hostname

=item * C<pid> - current process ID (L<perlvar/$$>)

=item * C<stack> - arrayref of stacktrace entries, see L<caller>

=back

Additional keys may be added in future, for example structured data.

=cut

use parent qw(Log::Any::Adapter::Base);

use Log::Any::Adapter::Util;
use Time::HiRes;
use Sys::Hostname;

my $trace_level = Log::Any::Adapter::Util::numeric_level('trace');

sub new {
    my ( $class, $code, %args ) = @_;
    $args{code} = $code;
    $args{log_level} //= $trace_level;
    return $class->SUPER::new(%args);
}

sub init {
    my $self = shift;
    if ( exists $self->{log_level} && $self->{log_level} =~ /\D/ ) {
        my $numeric_level = Log::Any::Adapter::Util::numeric_level( $self->{log_level} );
        if ( !defined($numeric_level) ) {
            require Carp;
            Carp::carp( sprintf 'Invalid log level "%s". Defaulting to "%s"', $self->{log_level}, 'trace' );
        }
        $self->{log_level} = $numeric_level;
    }
    if ( !defined $self->{log_level} ) {
        $self->{log_level} = $trace_level;
    }
}

my $host = Sys::Hostname::hostname();
foreach my $method ( Log::Any::Adapter::Util::logging_methods() ) {
    no strict 'refs';
    my $method_level = Log::Any::Adapter::Util::numeric_level( $method );
    *{$method} = sub {
        my ( $self, $text ) = @_;
        return if $method_level > $self->{log_level};
        my $depth = 3;
        my @stack;
        while(my @caller = caller($depth)) {
            my %frame;
            @frame{qw(package file line method)} = @caller;
            # Don't repeat the package name - it's _usually_ going to be the same as
            # $frame{package}, and the cases where it isn't aren't too important for us
            # right now.
            $frame{method} =~ s{^.*::}{};
            push @stack, \%frame;
        } continue {
            ++$depth;
        }

        # Put the information in both $_ and @_
        $self->{code}->($_) for +{
            epoch    => Time::HiRes::time(),
            severity => $method,
            message  => $text,
            host     => $host,
            pid      => $$,
            stack    => \@stack,
        };
      }
}

foreach my $method ( Log::Any::Adapter::Util::detection_methods() ) {
    no strict 'refs';
    my $base = substr($method,3);
    my $method_level = Log::Any::Adapter::Util::numeric_level( $base );
    *{$method} = sub {
        return !!(  $method_level <= $_[0]->{log_level} );
    };
}

1;

__END__

=head1 AUTHOR

Tom Molesworth C<< <TEAM@cpan.org> >>.

=head1 LICENSE

Copyright Tom Molesworth 2020-2021. Licensed under the same terms as Perl itself.

