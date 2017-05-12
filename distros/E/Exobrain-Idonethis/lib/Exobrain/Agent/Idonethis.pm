package Exobrain::Agent::Idonethis;
use Moose::Role;
use Method::Signatures;
use WebService::Idonethis 0.22;
use POSIX qw(strftime);

with 'Exobrain::Agent';

# ABSTRACT: Roles for to iDonethis agents
our $VERSION = '1.08'; # VERSION


sub component_name { "Idonethis" }


has idone => ( is => 'ro', lazy => 1, builder => '_build_idonethis' );

method _build_idonethis() {
    my $config = $self->config;

    my $user = $config->{user} or die "Can't find Idonethis/user";
    my $pass = $config->{pass} or die "Can't find Idonethis/pass";

    return WebService::Idonethis->new(
        user => $user,
        pass => $pass,
    );
}


method to_ymd($epoch_seconds) {
    return strftime("%Y-%m-%d", localtime( $epoch_seconds )),
}

1;

__END__

=pod

=head1 NAME

Exobrain::Agent::Idonethis - Roles for to iDonethis agents

=head1 VERSION

version 1.08

=head1 SYNOPSIS

    use Moose;
    with 'Exobrain::Agent::Idonethis'

=head1 DESCRIPTION

This role provides useful methods and attributes for agents wishing
to integrate with the iDoneThis web service.

=head1 METHODS

=head2 idone

    $self->idone->set_done( text => '... ');

This returns a L<WebService::Idonethis> object that's already been
constructed and authenticated.

=head2 to_ymd

    my $ymd = $self->to_ymd( time );

Converts a time in epoch seconds to C<YYYY-MM-DD> format in
the local timezone.

=for Pod::Coverage component_name

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
