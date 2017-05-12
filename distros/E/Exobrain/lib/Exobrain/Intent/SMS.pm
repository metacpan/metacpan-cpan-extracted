package Exobrain::Intent::SMS;

use 5.010;
use Moose;
use Method::Signatures;
use Exobrain::Types qw(SmsStr PhoneNum);

# ABSTRACT: Send an SMS intent via Exobrain
our $VERSION = '1.08'; # VERSION


method summary() { return 'SMS to ' . join(" : ", $self->to, $self->text); }

BEGIN { with 'Exobrain::Intent'; }

payload text     => ( isa => SmsStr   );
payload to       => ( isa => PhoneNum );

1;

__END__

=pod

=head1 NAME

Exobrain::Intent::SMS - Send an SMS intent via Exobrain

=head1 VERSION

version 1.08

=head1 SYNOPSIS

    $exobrain->intent('SMS',
        to   => $your_number,
        text => 'Hello World!',
    );

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
