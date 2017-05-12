package Inferno::RegMgr::Monitor;
use 5.010001;
use warnings;
use strict;
use utf8;
use Carp;

our $VERSION = 'v1.0.0';

use Scalar::Util qw( weaken );
use Inferno::RegMgr::Utils qw( run_callback );

use Inferno::RegMgr::Lookup;


sub new {
    my ($class, $opt) = @_;
    my $self = {
        lookup      => undef,
        cb_add      => $opt->{cb_add},
        cb_del      => $opt->{cb_del},
        cb_mod      => $opt->{cb_mod},
        method_add  => $opt->{method_add},
        method_del  => $opt->{method_del},
        method_mod  => $opt->{method_mod},
        manager     => undef,
        cur         => {},
    };
    bless $self, $class;
    weaken( my $this = $self );
    $self->{lookup} = Inferno::RegMgr::Lookup->new({
        attr    => $opt->{attr},
        cb      => sub { $this->_cb_monitor(@_) },
    });
    return $self;
}

sub START {
    my ($self) = @_;
    $self->{manager}->attach( $self->{lookup} );
    return;
}

sub _cb_monitor {
    my ($self, $svc) = @_;
    my @prev = keys %{ $self->{cur} };
    for my $name (@prev) {
        if (exists $svc->{ $name }) {
            my $attr = delete $svc->{ $name };
            if (_is_differ($self->{cur}{ $name }, $attr)) {
                $self->{cur}{ $name } = $attr;
                if (defined $self->{cb_mod}) {
                    run_callback( $self->{cb_mod}, $self->{method_mod}, $name => $attr );
                }
            }
        }
        else {
            my $attr = delete $self->{cur}{ $name };
            if (defined $self->{cb_del}) {
                run_callback( $self->{cb_del}, $self->{method_del}, $name => $attr );
            }
        }
    }
    for my $name (keys %{ $svc }) {
        my $attr = $svc->{ $name };
        $self->{cur}{ $name } = $attr;
        if (defined $self->{cb_add}) {
            run_callback( $self->{cb_add}, $self->{method_add}, $name => $attr );
        }
    }
    return;
}

sub _is_differ {
    my ($h1, $h2) = @_;
    return 1 if keys %{ $h1 } != keys %{ $h2 };
    for my $key (keys %{ $h1 }) {
        return 1 if !exists $h2->{ $key };
        return 1 if $h1->{ $key } ne $h2->{ $key };
    }
    return 0;
}

sub STOP {
    my ($self) = @_;
    # Inferno::RegMgr::Lookup may already detach itself (after finishing search).
    if ($self->{lookup}{manager}) {
        $self->{manager}->detach( $self->{lookup} );
    }
    return;
}

sub REFRESH {
    my ($self) = @_;
    $self->STOP();
    $self->START();
    return;
}


1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

Inferno::RegMgr::Monitor - Monitor services in OS Inferno's registry(4)


=head1 VERSION

This document describes Inferno::RegMgr::Monitor version v1.0.0


=head1 SYNOPSIS

See L<Inferno::RegMgr> for usage example.


=head1 DESCRIPTION

This module designed as task plugin for Inferno::RegMgr and can't be used without Inferno::RegMgr.

To monitor services with some attributes set needed attributes and callbacks
while creating new() Inferno::RegMgr::Monitor object, then attach() it to Inferno::RegMgr.
You only need to keep reference to Inferno::RegMgr::Monitor object if you will need
to interrupt this monitoring using detach().


=head1 INTERFACE 

=over

=item new()

Create and return Inferno::RegMgr::Monitor object.

Accept HASHREF with options:

 attr       OPTIONAL hash with wanted service attrs
 cb_add     OPTIONAL user callback (CODEREF or CLASS name or OBJECT)
 method_add OPTIONAL user callback method (if {cb} is CLASS/OBJECT)
 cb_mod     OPTIONAL user callback (CODEREF or CLASS name or OBJECT)
 method_mod OPTIONAL user callback method (if {cb} is CLASS/OBJECT)
 cb_del     OPTIONAL user callback (CODEREF or CLASS name or OBJECT)
 method_del OPTIONAL user callback method (if {cb} is CLASS/OBJECT)

On each registry change new search for services will be done (using
Inferno::RegMgr::Lookup), and if you provided callbacks they will be called
when new service registered (add), existing service will change it attributes
(mod), service unregistered (del).

In all cases user callback will be called with parameters:

 ($service_name, \%service_attr)


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
