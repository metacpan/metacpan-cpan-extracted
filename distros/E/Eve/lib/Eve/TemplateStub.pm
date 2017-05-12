package Eve::TemplateStub;

use strict;
use warnings;

use Test::MockObject;
use Test::MockObject::Extends;

use Digest::MD5 ();
use Data::Dumper;

my $stash_stub = {};

=head1 NAME

B<Eve::TemplateStub> - a stub class that replaces the template class
with a mock.

=head1 SYNOPSIS

    use Eve::TemplateStub;
    use Eve::Template;

    my $mocked_template = Eve::Template->new(
        path => $path_string,
        compile_path => $compile_path_string,
        expiration_interval => $interval_value);

    my $output = $template->process(
        file => $file_name, var_hash => $var_hash);

=head1 DESCRIPTION

B<Eve::TemplateStub> is a class that provides a mocked template object
with limited stubbed templating functionality..

=head1 METHODS

=head2 B<mock_template()>

Returns a mocked B<Eve::Template> object.

=cut

sub mock_template {
    my @args = @_;

    my $template_mock = Test::MockObject::Extends->new('Template');

    $template_mock->mock(
        'new',
        sub {
            my ($self, undef, $arg_hash) = @_;

            my $result = $self;
            if ($arg_hash->{'INCLUDE_PATH'} eq '/some/buggy/path') {
                $result = undef
            }

            return $result;
        });

    $template_mock->mock(
        'error', sub { return 'Oops'; });

    $template_mock->mock(
        'process',
        sub {
            my (undef, $file, $var_hash, $output_ref) = @_;

            my $result = 1;
            if ($file eq 'buggy.html') {
                $result = undef;
            }

            if ($file eq 'empty.html') {
                ${$output_ref} = '';
            } elsif ($file eq 'dump.html') {
                local $Data::Dumper::Maxdepth = 2;
                ${$output_ref} = Dumper($var_hash);
            } else {
                delete $var_hash->{'matches_hash'};
                ${$output_ref} = Digest::MD5::md5_hex(Dumper($file, $var_hash));
            }

            return $result;
        });

    return $template_mock->new(@args);
}

=head2 B<main()>

=cut

sub main {
    Test::MockObject::Extends->new('Template')->fake_module(
        'Template', 'new' => sub { return mock_template(@_); });
    Test::MockObject::Extends->new('Template')->fake_module(
        'Template::Stash::XS', 'new' => sub { return $stash_stub; });
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
