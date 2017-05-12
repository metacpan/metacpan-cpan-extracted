package Exobrain::Intent::Beeminder;
use Moose;
use Method::Signatures;

# ABSTRACT: Exobrain intent packet for sending data to Beeminder.
our $VERSION = '1.06'; # VERSION


method summary() {
    my $summary = join(' ', 'Beeminder: Set', $self->goal, 'to', $self->value);
    
    if (my $comment = $self->comment)  {
        $summary .= " ($comment)";
    }

    return $summary;
}

BEGIN { with 'Exobrain::Intent' }

payload goal    => (isa => 'Str');
payload value   => (isa => 'Num');
payload comment => (isa => 'Str', required => 0);

1;

__END__

=pod

=head1 NAME

Exobrain::Intent::Beeminder - Exobrain intent packet for sending data to Beeminder.

=head1 VERSION

version 1.06

=head1 SYNOPSIS

    $exobrain->intent('Beeminder',
        goal    => 'inbox',                     # Mandatory
        value   => 52,                          # Mandatory
        comment => "Submitted via Exobrain",    # Optional
    );

=head1 DESCRIPTION

This intent sends data to Beeminder. It is typically processed by
the L<Exobrain::Agent::Beeminder::Sink> agent.

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
