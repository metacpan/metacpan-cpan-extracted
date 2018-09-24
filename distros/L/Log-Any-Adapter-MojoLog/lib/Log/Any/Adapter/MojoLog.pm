package Log::Any::Adapter::MojoLog;

use strict;
use warnings;

our $VERSION = '0.04';
$VERSION = eval $VERSION;

use Log::Any::Adapter::Util qw(make_method);
use base qw(Log::Any::Adapter::Base);

use Mojo::Log;

sub init {
    my ($self) = @_;
    $self->{logger} ||= Mojo::Log->new;
}

# Create logging methods
#
foreach my $method ( Log::Any->logging_methods ) {
    my $mojo_method = $method;

    # Map log levels down to Mojo::Log levels where necessary
    #
    for ($mojo_method) {
        s/trace/debug/;
        s/notice/info/;
        s/warning/warn/;
        s/critical|alert|emergency/fatal/;
    }

    make_method(
        $method,
        sub {
            my $self = shift;
            return $self->{logger}->$mojo_method(@_);
        }
    );
}

# Create detection methods: is_debug, is_info, etc.
#

my $true = sub { 1 };
foreach my $method ( Log::Any->detection_methods ) {
    my $mojo_method = $method;

    # Map log levels down to Mojo::Log levels where necessary
    #
    for ($mojo_method) {
        s/trace/debug/;
        s/notice/info/;
        s/warning/warn/;
        s/critical|alert|emergency/fatal/;
    }

    my $level;
    if ($mojo_method eq 'is_fatal') {
      # is_fatal has been removed since 6.0, it was always true
      $mojo_method = $true;
    } elsif (eval { require Mojolicious; Mojolicious->VERSION('6.47'); 1 }) {
      # as of 6.47 the is_* methods have been removed in favor of
      # is_level($level)
      ($level = $mojo_method) =~ s/^is_//;
      $mojo_method = 'is_level';
    }

    make_method(
        $method,
        sub {
            my $self = shift;
            return $self->{logger}->$mojo_method($level ? $level : ());
        }
    );
}

1;

__END__

=pod

=head1 NAME

Log::Any::Adapter::MojoLog - Log::Any integration for Mojo::Log

=head1 SYNOPSIS

    use Mojo::Log;
    use Log::Any::Adapter;

    Log::Any::Adapter->set('MojoLog', logger => Mojo::Log->new);

Mojolicious app:

    use Mojo::Base 'Mojolicious';

    use Log::Any::Adapter;

    sub startup {
        my $self = shift;

        Log::Any::Adapter->set('MojoLog', logger => $self->app->log);
    }

Mojolicious::Lite app:

    use Mojolicious::Lite;

    use Log::Any::Adapter;

    Log::Any::Adapter->set('MojoLog', logger => app->log);

=head1 DESCRIPTION

This Log::Any adapter uses L<Mojo::Log> for logging. Mojo::Log must
be initialized before calling I<set>. The parameter logger must
be used to pass in the logging object.

=head1 LOG LEVEL TRANSLATION

Log levels are translated from Log::Any to Mojo::Log as follows:

    trace -> debug
    notice -> info
    warning -> warn
    critical -> fatal
    alert -> fatal
    emergency -> fatal

=head1 SEE ALSO

=over

=item *

L<Log::Any::Adapter::Mojo> - The original release of this codebase

=item *

L<Log::Any>

=item *

L<Log::Any::Adapter>

=item *

L<Mojo::Log>

=back

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Log-Any-Adapter-MojoLog>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 CONTRIBUTORS

Dan Book (Grinnz)

=head1 NOTES

This module was forked from L<Log::Any::Adapter::Mojo> which bears the copyright

Copyright (C) 2011 Henry Tang

and is licensed under the Artistic License version 2.0

This fork began as fixes for L<RT#111631|https://rt.cpan.org/Public/Bug/Display.html?id=111631> and L<RT#101167|https://rt.cpan.org/Public/Bug/Display.html?id=101167>.
However the eventual changes that were made prevented any possibility for keeping a consistent log formatter.
As such I think it is the responsible action to fork the module to release it.
I intend to work with the original author to see how much of these changes can be backported into that codebase without breaking the format.

=head1 COPYRIGHT & LICENSE

Log::Any::Adapter::MojoLog is Copyright (C) 2016 L</AUTHOR> and L</CONTRIBUTORS>.

Log::Any::Adapter::MojoLog is provided "as is" and without any express or
implied warranties, including, without limitation, the implied warranties
of merchantibility and fitness for a particular purpose.

This program is free software, you can redistribute it and/or modify it
under the terms of the Artistic License version 2.0.

=cut
