use strict;
use warnings;
no warnings "void";

=head1 NAME

LWP::UserAgent::Paranoid::Compat - LWP::UserAgent::Paranoid drop-in replacement
for LWPx::ParanoidAgent

=cut

package LWP::UserAgent::Paranoid::Compat;
use base 'LWP::UserAgent::Paranoid';

=head1 SYNOPSIS

    use LWP::UserAgent::Paranoid::Compat;
    my $ua = LWP::UserAgent::Paranoid::Compat->new;

    # use $ua the same as LWPx::ParanoidAgent...

=head1 DESCRIPTION

This class is a subclass of L<LWP::UserAgent::Paranoid> and changes the default
behaviour and interface to match L<LWPx::ParanoidAgent> as closely as possible.

=head2 Differences from L<LWP::UserAgent::Paranoid>

=over

=item * Only HTTP and HTTPS are allowed

=item * Timeout is 15s by default

=item * A C<timeout> constructor param and L</timeout> method are available

=item * The L</resolver> method gets/sets the underlying resolver used by an
L<Net::DNS::Paranoid> instance instead of acting as the getter of the
L<Net::DNS::Paranoid> instance itself.  The C<resolver> constructor param
follows suite.

=back

=cut

sub new {
    my ($class, %opts) = @_;

    # LWPx::ParanoidAgent uses 'timeout' instead of a separate
    # 'request_timeout' and a default of 15s instead of 5s.
    $opts{timeout}         ||= 15;
    $opts{request_timeout} ||= $opts{timeout};

    # Resolver is used to set the Net::DNS::Paranoid resolver
    my $resolver = delete $opts{resolver};

    my $self = $class->SUPER::new(%opts);

    # LWPx::ParanoidAgent limits to http/https by default.
    $self->protocols_allowed(["http", "https"]);
    $self->_resolver->resolver($resolver)
        if $resolver;

    return $self;
}

sub timeout {
    my $self = shift;
    $self->_elem("timeout", @_);
    $self->request_timeout(@_);
}

sub resolver {
    shift->_resolver->resolver(@_);
}

"The truth is out there.";

=head1 BUGS

All bugs should be reported via
L<rt.cpan.org|https://rt.cpan.org/Public/Dist/Display.html?Name=LWP-UserAgent-Paranoid>
or L<bug-LWP-UserAgent-Paranoid@rt.cpan.org>.

=head1 AUTHOR

Thomas Sibley <tsibley@cpan.org>

=head1 LICENSE AND COPYRIGHT
 
This software is primarily Copyright (c) 2013 by Best Practical Solutions,
with parts of it Copyright (c) 2014-2015 by Thomas Sibley.
 
This is free software, licensed under:
 
  The GNU General Public License, Version 2, June 1991

=cut
