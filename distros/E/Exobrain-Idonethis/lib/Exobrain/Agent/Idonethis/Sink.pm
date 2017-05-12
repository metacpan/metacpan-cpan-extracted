package Exobrain::Agent::Idonethis::Sink;
use Method::Signatures;
use Moose;

with 'Exobrain::Agent::Idonethis';
with 'Exobrain::Agent::Run';

# ABSTRACT: Send personal log events to iDoneThis
our $VERSION = '1.08'; # VERSION

method run() {
    $self->exobrain->watch_loop(
        class => 'Intent::PersonalLog',
        then  => sub {
            my $event = shift;

            my $text = $event->summary;

            $self->idone->set_done(
                text => $text,
                date => $self->to_ymd( $event->timestamp ),
            );

            # Send low-priority notify that we've logged this.
            $self->exobrain->notify( "Logged (iDoneThis): $text", priority => -1 );
        }
    );
}

1;

__END__

=pod

=head1 NAME

Exobrain::Agent::Idonethis::Sink - Send personal log events to iDoneThis

=head1 VERSION

version 1.08

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
