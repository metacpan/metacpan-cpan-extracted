package Eve::RegistryStub;

use strict;
use warnings;

no warnings qw(redefine);

use Test::MockObject::Extends;

use Eve::Registry;

=head1 NAME

B<Eve::RegistryStub> - a helper class that replaces the registry with
a mock object.

=head1 SYNOPSIS

    package SomeTestCase;

    use Eve::RegistryStub;
    use Eve::Registry;

    my $already_mocked_registry = Eve::Registry->new(
        # some literals declarations);

    my $service = $registry->get_service();

=head1 DESCRIPTION

B<Eve::RegistryStub> is the mock version of a B<Eve::Registry> class
that contains all services and automatically replaces some input
parameter with bogus default values..

=head1 METHODS

=head2 B<main()>

=cut

sub main {
    my $init = \&Eve::Registry::init;

    *Eve::Registry::new = sub {
        my $self = &Eve::Class::new(@_);

        return Test::MockObject::Extends->new($self);
    };

    *Eve::Registry::init = sub {
        my $self = shift;

        $init->(
            $self,
            base_uri_string => 'http://example.com',
            email_from_string => 'Someone <someone@example.com>',
            session_storage_path => File::Spec->catdir(
                File::Spec->tmpdir(), 'test_session_storage'),
            session_expiration_interval => 3600,
            @_);
    };
}

main();

=head1 SEE ALSO

=over 4

=item L<Eve::Test>

=item L<Test::Class>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2013 Sergey Konoplev, Igor Zinovyev.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 AUTHOR

=over 4

=item L<Sergey Konoplev|mailto:gray.ru@gmail.com>

=item L<Igor Zinovyev|mailto:zinigor@gmail.com>

=back

=cut

1;
