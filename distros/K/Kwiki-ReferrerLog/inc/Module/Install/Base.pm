#line 1 "inc/Module/Install/Base.pm - /kunden/homepages/6/d100394168/htdocs/.perlprefix/lib//Module/Install/Base.pm"
# $File: //depot/cpan/Module-Install/lib/Module/Install/Base.pm $ $Author: autrijus $
# $Revision: #10 $ $Change: 1847 $ $DateTime: 2003/12/31 23:14:54 $ vim: expandtab shiftwidth=4

package Module::Install::Base;

#line 31

sub new {
    my ($class, %args) = @_;

    foreach my $method (qw(call load)) {
        *{"$class\::$method"} = sub {
            +shift->_top->$method(@_);
        } unless defined &{"$class\::$method"};
    }

    bless(\%args, $class);
}

=item AUTOLOAD

The main dispatcher - copy extensions if missing

=cut

sub AUTOLOAD {
    my $self = shift;
    goto &{$self->_top->autoload};
}

=item _top()

Returns the top-level B<Module::Install> object.

=cut

sub _top { $_[0]->{_top} }

=item admin()

Returns the C<_top> object's associated B<Module::Install::Admin> object
on the first run (i.e. when there was no F<inc/> when the program
started); on subsequent (user-side) runs, returns a fake admin object
with an empty C<AUTOLOAD> method that does nothing at all.

=cut

sub admin {
    my $self = shift;
    $self->_top->{admin} or Module::Install::Base::FakeAdmin->new;
}

sub is_admin {
    my $self = shift;
    $self->admin->VERSION;
}

sub DESTROY {}

package Module::Install::Base::FakeAdmin;

my $Fake;
sub new { $Fake ||= bless(\@_, $_[0]) }
sub AUTOLOAD {}
sub DESTROY {}

1;

__END__

=back

=head1 SEE ALSO

L<Module::Install>

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2003, 2004 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
