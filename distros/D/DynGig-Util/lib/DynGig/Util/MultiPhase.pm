=head1 NAME

DynGig::Util::MultiPhase - A multi-phase task launcher.

=cut
package DynGig::Util::MultiPhase;

use warnings;
use strict;
use Carp;

use threads;
use Thread::Queue 2.11;

use YAML::XS;
use Time::HiRes qw( sleep );

use constant { MAX_THR => 256, OK => 0, ERROR => 1 };

=head1 SYNOPSIS

 use DynGig::Util::MultiPhase;

 my $mp = DynGig::Util::MultiPhase->new
 (
     src => \@src,
     dst => \@dst,
     retry => 3,
     timeout => 100,
     code => sub { .. },
     param => { .. },
     weight => sub { return int .. },
 );

 $mp->run( log => $handle );

=cut
sub new
{
    my ( $class, %config ) = @_;

    my $src = $config{src} ||= [];
    my $dst = $config{dst} ||= [];
    my $retry = $config{retry} ||= 0;
    my $thread = $config{thread} ||= MAX_THR;
    my $timeout = $config{timeout} ||= 0;
    my $weight = $config{weight} ||= sub { 0 };
    
    $config{src} = [ $src ] unless ref $src;
    $config{dst} = [ $dst ] unless ref $src;
    $config{code} ||= sub { };
    $config{param} ||= +{};

    my %ref =
    (
        retry => '',
        thread => '',
        timeout => '',
        dst => 'ARRAY',
        src => 'ARRAY',
        code => 'CODE',
        param => 'HASH',
        weight => 'CODE',
    );

    map { croak "Invalid $_ definition.\n"
        if ref $config{$_} ne $ref{$_} } keys %ref;

    map { croak "Invalid $_ definition.\n" if $config{$_} !~ /^\d+$/
        || $config{$_} < 0 } qw( retry thread timeout );

    my %src = map { $_ => &$weight( $_ ) } @$src;
    my %dst = map { $_ => &$weight( $_ ) } grep { ! $src{$_} } @$dst;

    $config{thread} = MAX_THR if $thread > MAX_THR;
    $config{src} = \%src;
    $config{dst} = \%dst;

    my $this = bless \%config, ref $class || $class;

    return $this;
}

=head1 DESCRIPTION

=head2 run()

Launch task.

=cut
sub run
{
    my ( $this, %param ) = @_;
    my ( %busy, %retry, %error, %thread );
    my $retry = $this->{retry};
    my $thread = $this->{thread};
    my %dst = %{ $this->{dst} };
    my %src = %{ $this->{src} };
    my $queue = Thread::Queue->new();
    my $handle = $param{log} || *STDERR;

    while ( %dst || threads->list() || $queue->pending() )
    {
        while ( $queue->pending() )
        {
            my ( $status, $src, $dst, $result ) = $queue->dequeue( 4 );

            if ( $status == ERROR )
            {
                $retry{$dst} ||= 0;

                if ( $retry{$dst} < $retry )
                {
                    $dst{$dst} = $busy{$dst};
                    $retry{$dst} ++;
                }
                else
                {
                    $error{$dst} = $result;
                }
            }
            else
            {
                $src{$dst} = $busy{$dst};
            }

            $src{$src} = $busy{$src};

            delete $busy{$src};
            delete $busy{$dst};

            $thread{$src}{$dst}->join();

            print $handle "$src => $dst $result";
        }

        for my $i ( 1 .. $thread - threads->list() )
        {
            last unless keys %src && keys %dst;

            my ( $src, $dst ) = $this->_select( \%src, \%dst );

            $busy{$src} = $src{$src};
            $busy{$dst} = $dst{$dst};

            delete $src{$src};
            delete $dst{$dst};

            $thread{$src}{$dst} = threads::async
            { 
                my ( $status, $result ) = $this->_eval( $src, $dst );
                $queue->enqueue( $status, $src, $dst, $result );
            };

        }

        sleep 1;
    }

    $this->{error} = %error ? \%error : undef;
}

=head2 error()

Return errors as a HASH if any or undef

=cut
sub error
{
    my $this = shift @_;

    return $this->{error};
}

sub _select
{
    my ( $this, $src, $dst ) = @_;
    my ( $s, $w ) = each %$src;

    my %dst = map { $_ => abs( $dst->{$_} - $w ) } keys %$dst;
    my ( $d ) = sort { $dst{$a} <=> $dst{$b} } keys %dst;

    return $s, $d;
}

sub _eval
{
    my ( $this, $src, $dst ) = @_;
    my ( $status, @result ) = OK;

    eval
    {
        my $code = $this->{code};
        my $param = $this->{param};
        my $timeout = $this->{timeout};

        local $SIG{ALRM} = sub { die "timeout after $timeout seconds\n" };

        alarm $timeout;
        @result = &$code( %$param, src => $src, dst => $dst );
        alarm 0;
    };

    if ( $@ )
    {
        $status = ERROR;
        @result = $@;
    }

    return $status, YAML::XS::Dump \@result;
}

=head1 NOTE

See DynGig::Util

=cut

1;

__END__
