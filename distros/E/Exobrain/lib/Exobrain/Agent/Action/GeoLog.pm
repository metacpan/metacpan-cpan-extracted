package Exobrain::Agent::Action::GeoLog;
use Exobrain;
use Moose;

with 'Exobrain::Agent::Run';
with 'Exobrain::Agent::Depends';

# ABSTRACT: Log our own check-ins to a personal log (such as idonethis).
our $VERSION = '1.08'; # VERSION

method depends() { return qw(Measurement::Geo Intent::PersonalLog) }

method run() {
    $self->exobrain->watch_loop(
        class  => 'Measurement::Geo',
        filter => sub { $_->is_me },
        then   => sub {
            $self->exobrain->intent("PersonalLog",
                message => $_->summary
            );
        },
    );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Exobrain::Agent::Action::GeoLog - Log our own check-ins to a personal log (such as idonethis).

=head1 VERSION

version 1.08

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
