package Graphite::Enumerator;

use 5.14.1;
use Carp qw/croak/;
use LWP::UserAgent;
use JSON;
use Scalar::Util 'reftype';

our $VERSION = '0.03';

# Recognized constructor options:
# - host (base URL)
# - basepath (top-level metric to scan)
# - lwp_options (hashref)

sub new {
    my ($class, %args) = @_;
    $args{host} or croak "No host provided";
    $args{host} =~ m{^https?://} or $args{host} = "http://".$args{host};
    $args{host} =~ m{/$} or $args{host} .= '/';
    if (defined $args{basepath}) {
        $args{basepath} =~ /\.$/ or $args{basepath} .= '.';
    }
    else {
        $args{basepath} = '';
    }
    $args{_finder} = $args{host} . 'metrics/find?format=completer&query=';
    $args{_ua} = LWP::UserAgent->new( %{ $args{lwp_options} || {} } );
    bless \%args, $class;
}

sub enumerate {
    my ($self, $callback, $path, $level) = @_;
    if (reftype $callback ne "ARRAY") {
        $callback = [ $callback ];
    }
    $path //= $self->{basepath};
    $level //= 0;
    my $url = $self->{_finder} . $path;
    $url .= '.' if $url !~ /[*.]$/;
    $url .= '*' if $url =~ /\.$/;
    my $res = $self->{_ua}->get($url);
    if ($res->is_success) {
        my $completer_answer = eval { decode_json($res->content) };
        if (!$completer_answer) {
            $self->log_warning("URL <$url>: Couldn't decode JSON string: <" . $res->content . ">: $@");
            return 0;
        }
        return 0 if !$completer_answer->{metrics};
        my $count = 0;
        for my $metric (@{ $completer_answer->{metrics} }) {
            next if ($callback->[1] && $callback->[1]($metric->{path}, $level));
            if ($metric->{is_leaf}) {
                $callback->[0]($metric->{path}, $level);
                ++$count;
            }
            else {
                $count += $self->enumerate($callback, $metric->{path}, $level + 1);
            }
        }
        return $count;
    }
    else {
        $self->log_warning("Can't get <$url>: " . $res->status_line);
        return 0;
    }
}

sub host {
    my ($self) = @_;
    return $self->{host};
}

sub ua {
    my ($self) = @_;
    return $self->{_ua};
}

sub log_message {
    my ($self, $message) = @_;
    print $message, "\n";
}

sub log_warning {
    my ($self, $message) = @_;
    warn $message, "\n";
}

1;

=head1 NAME

Graphite::Enumerator - Utility module to recursively enumerate graphite metrics

=head1 SYNOPSIS

    my $gren = Graphite::Enumerator->new(
        host => 'https://graphite.example.com',
        basepath => 'general.metrics',
        lwp_options => {
            env_proxy => 1,
            keep_alive => 1,
        },
    );
    $gren->enumerate(sub {
        my ($path) = @_;
        print "Found metric $path !\n";
    });

=head1 METHODS

=head2 Graphite::Enumerator->new(%args)

The constructor recognizes 3 arguments:

  host => host name (in that case, the protocol defaults to http) or base URL
  basepath => top-level metric namespace to scan
  lwp_options => hash of options to initialize LWP::UserAgent internally

=head2 $g->enumerate($coderef)

=head2 $g->enumerate([ $coderef, $filter_coderef ])

Calls C<$coderef> for each metric under the basepath, with two parameters:
1. the metric name as a string; 2. the depth level of the metric relative
to the base path (starting at 0).

If an array reference of 2 coderefs is provided, the second coderef will be
used as an input filter called with the same parameters as above. This will
allow, for instance, to stop recursion on a given path by providing a regex, or
to stop recursion past a certain level. The code should return false to allow
further processing, and true, indicating a match, to prevent further processing
along that path.

enumerate() returns the number of metrics found (or 0 on error).

=head2 $g->host

Returns the host passed to the constructor (with eventually
C<http://> prepended).

=head2 $g->ua

Returns the internal LWP::UserAgent object.

=head2 $g->log_message($message)

Prints the C<$message> to STDOUT.

=head2 $g->log_warning($message)

Warns about the C<$message>.

=head1 ACKNOWLEDGMENT

This module was originally developed for Booking.com.
With approval from Booking.com, this module was generalized
and put on CPAN, for which the author would like to express
his gratitude.

=head1 AUTHOR

Rafael Garcia-Suarez, E<lt>rgs@consttype.orgE<gt>

This code is available under the same license as Perl version 5.10.1 or higher.

A git repository for this module is available at L<https://github.com/rgs/Graphite-Enumerator>.

=cut
