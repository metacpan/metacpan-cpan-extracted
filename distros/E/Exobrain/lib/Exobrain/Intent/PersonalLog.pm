package Exobrain::Intent::PersonalLog;

use v5.10.0;

use Moose;
use Method::Signatures;

# ABSTRACT: Signal an intent to record a personal log event
our $VERSION = '1.08'; # VERSION


method summary() { return $self->message; }

BEGIN { with 'Exobrain::Intent'; }

payload 'message' => ( isa => 'Str' );

1;

__END__

=pod

=head1 NAME

Exobrain::Intent::PersonalLog - Signal an intent to record a personal log event

=head1 VERSION

version 1.08

=head1 SYNOPSIS

    my $msg = $exobrain->intent( 'PersonalLog',
        message => "Wrote some awesome code",
    );

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
