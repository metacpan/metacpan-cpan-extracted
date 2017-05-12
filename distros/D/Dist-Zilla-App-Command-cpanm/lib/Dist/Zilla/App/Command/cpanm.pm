use strict;
use warnings;


package Dist::Zilla::App::Command::cpanm;
our $VERSION = '1.0.2'; # VERSION
# ABSTRACT: install your dist using cpanminus
use Dist::Zilla::App '-command';


sub opt_spec
{
    [ 'keep-build-dir|keep' => 'keep the build directory even after a success' ];
}


sub execute
{
    my ( $self, $opt, $arg ) = @_;

    my @params = ( install_command => ["cpanm ."] );
    push @params, ( keep_build_dir => 1 ) if $opt->keep_build_dir;

    my $cpanm_options;
    my $stash = $self->zilla->stash_named('%CPANMinus');
    if ( defined($stash) && defined( $stash->options ) ) {
        $cpanm_options = $stash->options;
    }

    if ( defined $ENV{DZ_CPANM_OPTIONS} ) {
        if ( $ENV{DZ_CPANM_OPTIONS} =~ m{^\s*\+\s*(.+)$} ) {
            $cpanm_options .= " $1";
        }
        else {
            $cpanm_options = $ENV{DZ_CPANM_OPTIONS};
        }
    }

    $params[1][0] = "cpanm $cpanm_options ." if $cpanm_options;
    $self->zilla->install( {@params} );
}


package Dist::Zilla::Stash::CPANMinus;
our $VERSION = '1.0.2'; # VERSION
use Moose;
use namespace::autoclean;

with 'Dist::Zilla::Role::Stash';

has 'options',
  is       => 'ro',
  isa      => 'Str',
  required => '1';

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Dist::Zilla::App::Command::cpanm - installs your dist using cpanminus

=head1 VERSION

version 1.0.2

=head1 SYNOPSIS

    $ dzil cpanm

=head1 DESCRIPTION

Installs your distribution as if you had typed:

    dzil install --install-command="cpanm ."    # Really no fun at all!

Options that will be passed to the cpanm script can come in via environment
(DZ_CPANM_OPTIONS), or your Dist::Zilla configuration (~/.dzil/config.ini):

    [%CPANMinus]
    options = --interactive --verbose --sudo

The environment variable supersedes any setting in the config; that is unless
it is prefixed with a C<+>, in which case it will be appended to the value
pulled from the configuration file.

B<Examples>

=over

=item As simple as it gets:

    $ dzil cpanm

=item You may want cpanm to use these options:

    $ export DZ_CPANM_OPTIONS='--verbose --interactive'
    $ dzil cpanm

These options will override any you have in the configuration file.

=item You may just want to add C<--sudo> to your C<config.ini> options:

    $ DZ_CPANM_OPTIONS='+--sudo' dzil cpanm

The C<--sudo> option is appended to those in the configuration file.

=back

=head1 SEE ALSO

=over 2

=item * L<Dist::Zilla::Dist::Builder/install>

=back

=head1 REPOSITORY

=over 2

=item * L<https://github.com/cpanic/Dist-Zilla-App-Command-cpanm>

=item * L<http://search.cpan.org/dist/Dist-Zilla-App-Command-cpanm/lib/Dist/Zilla/App/Command/cpan.pm>

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dist::Zilla::App::Command::cpanm

=head1 ACKNOWLEDGEMENTS

Shamelessly butchered Richard Signes Dist::Zilla::App::Command::install code.

The need was great.

=head1 AUTHOR

Iain Campbell <cpanic@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
