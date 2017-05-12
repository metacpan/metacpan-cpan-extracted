#
# This file is part of EV-Cron
#
# This software is copyright (c) 2012 by Loïc TROCHET.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use strict;
use warnings;

package EV::Cron;
{
  $EV::Cron::VERSION = '0.123600';
}
# ABSTRACT: Add crontab watcher into EV

use feature qw(state);
use EV;
use DateTime;
use DateTime::Event::Cron;
use Params::Validate qw(validate SCALAR CODEREF);

BEGIN
{
    no strict 'refs';
    foreach my $function (qw(cron cron_ns)) { *{ "EV::$function" } = *{ "EV::Cron::$function" }; }
}

my $local_TZ = DateTime::TimeZone::Local->TimeZone();

sub _add_watcher
{
    my %params = validate
                 (
                     @_
                 ,   {
                         start => { type =>  SCALAR }
                     ,   cron  => { type =>  SCALAR }
                     ,   cb    => { type => CODEREF }
                     }    
                 );

    my $ev_call = $params{start}
                ? 'EV::periodic'
                : 'EV::periodic_ns';
    
    no strict 'refs';
    return &$ev_call
           (
               0
           ,   0
           ,   sub #-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
               {
                   my ($watcher, $now) = @_;
                   state $dt_event = DateTime::Event::Cron->new($params{cron});
                   return $dt_event->next(DateTime->from_epoch(epoch => $now, time_zone => $local_TZ))->epoch;
               } #-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
           ,   $params{cb}
           );
}


sub cron
{
    return _add_watcher(start => 1, cron => $_[0], cb => $_[1]);
}


sub cron_ns
{
    return _add_watcher(start => 0, cron => $_[0], cb => $_[1]);
}

1;

__END__

=pod

=head1 NAME

EV::Cron - Add crontab watcher into EV

=head1 VERSION

version 0.123600

=head1 SYNOPSIS

    use 5.010;
    use EV;
    use EV::Cron;
    
    my @watchers;

    push @watchers, EV::cron     '*  * * * *', sub { say                           'Every minute.'; };
    push @watchers, EV::cron     '5  0 * * *', sub { say 'Five minutes after midnight, every day.'; };
    push @watchers, EV::cron_ns '15 14 1 * *', sub { say  'At 2:15pm on the first of every month.'; };
    
    EV::run;

=head1 DESCRIPTION

This module extends L<EV> by adding an easy way to specify event schedules using a crontab line format.

=head1 METHODS

=head2 cron($cronspec, $callback)

Calls the callback when the event schedules using a crontab line format occurs.

=over

=item I<Parameters>

C<$cronspec> - SCALAR - The string in crontab line format L<crontab(5)>.

C<$callback> - CODEREF - The callback.

=item I<Return value>

The newly created watcher.

=back

=head2 cron_ns($cronspec, $callback)

The C<cron_ns> variant doesn't start (activate) the newly created watcher.

=head1 SEE ALSO

L<EV>

=encoding utf8

=head1 AUTHOR

Loïc TROCHET <losyme@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Loïc TROCHET.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
