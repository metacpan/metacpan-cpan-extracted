package Inferno::RegMgr::Lookup;
use 5.010001;
use warnings;
use strict;
use utf8;
use Carp;

our $VERSION = 'v1.0.0';

use Scalar::Util qw( weaken );
use EV;
use Inferno::RegMgr::Utils qw( run_callback );


use constant RETRY => 1;    # sec, delay between re-connections


sub new {
    my ($class, $opt) = @_;
    my $self = {
        attr    => $opt->{attr},
        cb      => $opt->{cb},
        method  => $opt->{method},
        manager => undef,
        io      => undef,
        t       => undef,
    };
    return bless $self, $class;
}

sub START {
    my ($self) = @_;
    $self->{io} = $self->{manager}{registry}->open_find({
        attr    => $self->{attr},
        cb      => $self,
        method  => '_cb_find',
    });
    weaken( $self->{io} );
    return;
}

sub _cb_find { ## no critic(ProhibitUnusedPrivateSubroutines)
    my ($self, $svc, $err) = @_;
    if ($svc) {
        $self->{manager}->detach( $self );
        run_callback( $self->{cb}, $self->{method}, $svc );
    }
    else {
        $self->{t} = EV::timer RETRY, 0, sub { $self->START() };
    }
    return;
}

sub STOP {
    my ($self) = @_;
    if (defined $self->{io}) {
        $self->{io}->close();
    }
    $self->{t} = undef;
    return;
}

sub REFRESH {}


1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

Inferno::RegMgr::Lookup - Search services in OS Inferno's registry(4)


=head1 VERSION

This document describes Inferno::RegMgr::Lookup version v1.0.0


=head1 SYNOPSIS

See L<Inferno::RegMgr> for usage example.


=head1 DESCRIPTION

This module designed as task plugin for Inferno::RegMgr and can't be used without Inferno::RegMgr.

To search for services with some attributes set needed attributes while
creating new() Inferno::RegMgr::Lookup object, then attach() it to Inferno::RegMgr. You only
need to keep reference to Inferno::RegMgr::Lookup object if you will need to
interrupt this search before receiving results using detach().

This module will automatically detach() itself from Inferno::RegMgr before calling
user callback with search results.


=head1 INTERFACE 

=over

=item new()

Create and return Inferno::RegMgr::Lookup object.

Accept HASHREF with options:

 attr       OPTIONAL hash with wanted service attrs
 cb         REQUIRED user callback (CODEREF or CLASS name or OBJECT)
 method     OPTIONAL user callback method (if {cb} is CLASS/OBJECT)

If there will be no option attr or it value will be empty hash - all
services will be returned.

If some attribute value will be '*' then all services which has that
attribute with any value will be returned.

After receiving search results user callback will be called with
parameters (keys in hash are found service names and values are attributes
of these services):

 (\%services)


=back


=head1 DIAGNOSTICS

None.


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/powerman/perl-Inferno-RegMgr/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

L<https://github.com/powerman/perl-Inferno-RegMgr>

    git clone https://github.com/powerman/perl-Inferno-RegMgr.git

=head2 Resources

=over

=item * MetaCPAN Search

L<https://metacpan.org/search?q=Inferno-RegMgr>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/Inferno-RegMgr>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Inferno-RegMgr>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Inferno-RegMgr>

=item * CPANTS: A CPAN Testing Service (Kwalitee)

L<http://cpants.cpanauthors.org/dist/Inferno-RegMgr>

=back


=head1 AUTHOR

Alex Efros E<lt>powerman@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009-2010 by Alex Efros E<lt>powerman@cpan.orgE<gt>.

This is free software, licensed under:

  The MIT (X11) License


=cut
