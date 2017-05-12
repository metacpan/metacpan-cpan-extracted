package Log::Log4perl::Appender::Gearman;

use warnings;
use strict;

use 5.8.8;

use base 'Log::Log4perl::Appender';
use Gearman::Client;

=head1 NAME

Log::Log4perl::Appender::Gearman - Log appender for posting job to gearman

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.29';


=head1 SYNOPSIS

  # in your log4perl config:
  # log4perl.appender.GM          = Log::Log4perl::Appender::Gearman
  # log4perl.appender.GM.job_servers = 127.0.0.1:$port
  # log4perl.appender.GM.jobname = logme
  # log4perl.appender.GM.layout = Log::Log4perl::Layout::PatternLayout
  # log4perl.appender.GM.layout.ConversionPattern=%m

=cut

sub new {
    my ($class, %opt) = @_;
    $opt{job_servers} = [ split /,/, $opt{job_servers} ];
    my $self = bless {
        %opt,
        backlog => [],
    }, $class;
    $self->{gearman_client} = Gearman::Client->new
        ( job_servers => $self->{job_servers},
          prefix => $self->{prefix} );
    return $self;
}

sub log {
    my ($self, %params) = @_;

    # process backblog
    my $defer = 0;
    for (@{$self->{backlog}}) {
        $self->{gearman_client}->dispatch_background( $_ )
            or $defer = 1, last;
    }
    my $msg = join('|', @params{qw(log4p_level log4p_category message)});
    my $task = Gearman::Task->new($self->{jobname}, \$msg );

    if ( $defer ) {
        push @{$self->{backlog}}, $task;
        return;
    }

    unless ( $self->{gearman_client}->dispatch_background( $task ) ) {
        push @{$self->{backlog}}, $task;
        # XXX: or send to some fallback logger and make sure it
        # doesn't create a loop
        warn "unable to send log";
    }
}

=head1 AUTHOR

Chia-liang Kao, C<< <clkao at clkao.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-log-log4perl-appender-gearman at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-Log4perl-Appender-Gearman>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.





=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009-2010 Chia-liang Kao, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;
