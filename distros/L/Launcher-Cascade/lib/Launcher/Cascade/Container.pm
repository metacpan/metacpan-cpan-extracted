package Launcher::Cascade::Container;

=head1 NAME

Launcher::Cascade::Container - a class to run L::C::Base launchers in cascade

=head1 SYNOPSIS

    use Launcher::Cascade::Base::...;
    use Launcher::Cascade::Container;

    my $launcher1 = new Launcher::Cascade::Base:... ...;
    my $launcher2 = new Launcher::Cascade::Base:... ...;
    my $launcher3 = new Launcher::Cascade::Base:... ...;

    my $container = new Launcher::Cascade::Container
	-launchers => [ $launcher1, $launcher2, $launcher3 ];

    $container->run_session();

=head1 DESCRIPTION

A C<L::C::Container> object maintains a list of launchers, which are instances
of C<L::C::Base> or of its subclasses. The run_session() method let all the
launchers run in turn and checks their status until all of them succeed or one
of them fails.

=cut

use strict;
use warnings;

use base qw( Launcher::Cascade );

=head2 Methods

=over 4

=item B<launchers>

=item B<launchers> I<LIST>

=item B<launchers> I<ARRAYREF>

Returns the list of C<Launcher::Cascade::Base> objects that are to be run in this section.

When called with a I<LIST> of arguments, this methods also sets the list of
launchers to I<LIST>. The argument can also be an I<ARRAYREF>, in which case
it will automatically be dereferenced.

All elements in I<LIST> or I<ARRAYREF> should be instances of
C<Launcher::Cascade::Base> or one of its subclasses.

=cut

sub launchers {

    my $self = shift;

    $self->{_launchers} ||= [];
    if ( @_ ) {
	if ( UNIVERSAL::isa($_[0], 'ARRAY') ) {
	    # Dereference the first arg if it is an arrayref (so that the
	    # method can be called with an arrayref from the constructor).
	    $self->{_launchers} = $_[0];
	}
	else {
	    $self->{_launchers} = [ @_ ];
	}
    }
    return @{$self->{_launchers}};
}

=item B<add_launcher> I<LIST>

Pushes a launcher to list of launchers. All elements in I<LIST> should be
instances of C<Launcher::Cascade::Base> or one of its subclasses.

=cut

sub add_launcher {

    my $self = shift;
    push @{$self->{_launchers} ||= []}, @_;
}

=item B<is_success>

Returns a true status if all the contained launchers are successfull (their
is_success() yields true).

=cut

sub is_success {

    my $self = shift;
    
    foreach ( $self->launchers() ) {
	return unless $_->is_success();
    }
    return 1;
}

=item B<is_failure>

Returns a true status if at least one contained launcher has failed (its
is_failure() yields true).

=cut

sub is_failure {

    my $self = shift;

    foreach ( $self->launchers() ) {
	return 1 if $_->is_failure();
    }
    return 0;
}

=item B<status>

Returns 1 if is_success(), 0 if is_failure() and C<undef> if the status is yet
undetermined, i.e. some launchers are still running or haven't run yet.

=cut

sub status {

    my $self = shift;

    return $self->is_success()  ? 1
	 : $self->is_failure()  ? 0
	 :                        undef;
}

=item B<run>

=item B<check_status>

Invokes run(), respectively check_status() on all the contained launchers.

=cut

sub run {

    my $self = shift;

    foreach ( $self->launchers() ) {
	$_->run()
    }
}

sub check_status {

    my $self = shift;

    foreach ( $self->launchers() ) {
	$_->check_status();
    }
}

=item B<run_session>

Launches run() and check_status() in loop, until either all the contained
launchers are successfull or one of them fails.

=cut

sub run_session {

    my $self = shift;
    
    while ( !defined($self->status()) ) {
	$self->run();
	$self->check_status();
    }
}

=back

=head1 SEE ALSO

L<Launcher::Cascade>, L<Launcher::Cascade::Base>

=head1 AUTHOR

Cédric Bouvier C<< <cbouvi@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2006 Cédric Bouvier, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1; # end of Launcher::Cascade::Container
