package Eve::Template;

use parent qw(Eve::Class);

use utf8;
use strict;
use autodie;
use warnings;
use open qw(:std :utf8);
use charnames qw(:full);

use Template;
use Template::Stash::XS;

=head1 NAME

B<Eve::Template> - a template engine class.

=head1 SYNOPSIS

    my $template = Eve::Template->new(
        path => '/some/include/path',
        compile_path => '/some/compile/path',
        expiration_interval => 60);

    my $output = $template->process(
        file => 'helloworld.html',
        var_hash => $var_hash);

=head1 DESCRIPTION

B<Eve::Template> is a template engine adapter class. It adapts well
known B<Template> package.

=head3 Constructor arguments

=over 4

=item C<path>

a path to template files

=item C<compile_path>

a path where compiled template files will be stored

=item C<expiration_interval>

determines how long (in seconds) a template is keeping cached in
memory before checking if it is changed

=item C<var_hash>

an optional hash of variables that will be additionally made available
to all processed templates.

=back

=head3 Throws

=over 4

=item C<Eve::Error::Template>

when the template creation was unsuccessful.

=back

=head1 METHODS

=head2 B<init()>

=cut

sub init {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(
        \%arg_hash,
        my ($path, $compile_path, $expiration_interval),
        my $var_hash = {});

    $self->{'template'} = Template->new({
        INCLUDE_PATH => $path,
        COMPILE_DIR => $compile_path,
        STAT_TTL => $expiration_interval,
        ENCODING => 'utf8',
        STASH => Template::Stash::XS->new($var_hash)});

    if (not defined $self->{'template'}) {
        Eve::Error::Template->throw(message => $Template::ERROR);
    }

    return;
}

=head2 B<process()>

Process the template.

=head3 Arguments

=over 4

=item C<file>

a template file to process

=item C<var_hash>

a variables hash to be used in the template.

=back

=head3 Returns

A text assembled after processing.

=head3 Throws

=over 4

=item C<Eve::Error::Template>

when the processing was unsuccessful.

=back

=cut

sub process {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(
        \%arg_hash, my ($file, $var_hash) = (\undef, {}));

    my $output;

    if (not defined $self->template->process(
            $file, $var_hash, \$output, {'binmode' => ":utf8"})) {
        Eve::Error::Template->throw(message => $self->template->error());
    }

    return $output;
}

=head1 SEE ALSO

=over 4

=item L<Eve::Class>

=item L<Eve::Exception>

=item L<Template>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Igor Zinovyev.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=head1 AUTHOR

=over 4

=item L<Sergey Konoplev|mailto:gray.ru@gmail.com>

=back

=cut

1;
