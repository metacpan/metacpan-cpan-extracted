package Module::Install::Base;

$VERSION = '0.67';

# Suspend handler for "redefined" warnings
BEGIN {
	my $w = $SIG{__WARN__};
	$SIG{__WARN__} = sub { $w };
}

### This is the ONLY module that shouldn't have strict on
# use strict;

=pod

=head1 NAME

Module::Install::Base - Base class for Module::Install extensions

=head1 SYNOPSIS

In a B<Module::Install> extension:

    use Module::Install::Base;
    @ISA = qw(Module::Install::Base);

=head1 DESCRIPTION

This module provide essential methods for all B<Module::Install>
extensions, in particular the common constructor C<new> and method
dispatcher C<AUTOLOAD>.

=head1 METHODS

=over 4

=item new(%args)

Constructor -- need to preserve at least _top

=cut

sub new {
    my ($class, %args) = @_;

    foreach my $method ( qw(call load) ) {
        *{"$class\::$method"} = sub {
            shift()->_top->$method(@_);
        } unless defined &{"$class\::$method"};
    }

    bless( \%args, $class );
}

=pod

=item AUTOLOAD

The main dispatcher - copy extensions if missing

=cut

sub AUTOLOAD {
    my $self = shift;
    local $@;
    my $autoload = eval { $self->_top->autoload } or return;
    goto &$autoload;
}

=pod

=item _top()

Returns the top-level B<Module::Install> object.

=cut

sub _top { $_[0]->{_top} }

=pod

=item admin()

Returns the C<_top> object's associated B<Module::Install::Admin> object
on the first run (i.e. when there was no F<inc/> when the program
started); on subsequent (user-side) runs, returns a fake admin object
with an empty C<AUTOLOAD> method that does nothing at all.

=cut

sub admin {
    $_[0]->_top->{admin} or Module::Install::Base::FakeAdmin->new;
}

sub is_admin {
    $_[0]->admin->VERSION;
}

sub DESTROY {}

package Module::Install::Base::FakeAdmin;

my $Fake;
sub new { $Fake ||= bless(\@_, $_[0]) }

sub AUTOLOAD {}

sub DESTROY {}

# Restore warning handler
BEGIN {
	$SIG{__WARN__} = $SIG{__WARN__}->();
}

1;

=pod

=back

=head1 SEE ALSO

L<Module::Install>

=head1 AUTHORS

Audrey Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2003, 2004 by Audrey Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
