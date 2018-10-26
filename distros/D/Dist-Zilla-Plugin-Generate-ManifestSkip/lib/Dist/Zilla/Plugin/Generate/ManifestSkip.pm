package Dist::Zilla::Plugin::Generate::ManifestSkip;

# ABSTRACT: generate a MANIFEST.SKIP file for your distribution

use v5.10;

use Moose;
extends 'Dist::Zilla::Plugin::ManifestSkip';
with qw/
    Dist::Zilla::Role::FileGatherer
    Dist::Zilla::Role::FilePruner
  /;

use List::Util  1.33 qw/ any /;
use File::ShareDir (); # needed by Module::Manifest::Skip v0.23
use Module::Manifest::Skip ();
use MooseX::MungeHas;
use Types::Standard -types;

use namespace::autoclean;

our $VERSION = 'v0.1.3';


sub mvp_multivalue_args { qw/ add remove / }

has mms => (
    is => 'lazy',
    isa => InstanceOf['Module::Manifest::Skip'],
    builder => sub { Module::Manifest::Skip->new },
    init_arg => undef,
);


has add => (
    is      => 'ro',
    isa     => ArrayRef[Str],
    default => sub { [] },
);


has remove => (
    is      => 'ro',
    isa     => ArrayRef[Str],
    default => sub { [] },
);

sub gather_files {
    my ($self) = @_;

    my $zilla = $self->zilla;

    my @files = @{ $zilla->files };
    my $mms = $self->mms;

    $mms->text;

    $mms->add( "# Added by " . __PACKAGE__ );
    $mms->add( '\.build/' );
    $mms->add( $zilla->name . '-.*/' );
    $mms->add( $zilla->name . '-.*\.tar\.gz' );
    $mms->add( '\.mailmap$' );

    $mms->remove('^MANIFEST\.SKIP$');
    $mms->remove('^dist.ini$');
    $mms->remove('^weaver.ini$');
    $mms->remove('^xt/');

    $mms->add('cpanfile\.snapshot$') if any { $_->name eq 'cpanfile' } @files;
    $mms->add('_alien/') if any { $_->name eq 'alienfile' } @files;

    foreach my $file (@{ $self->add }) {
        $mms->add($file);
    }

    foreach my $file (@{ $self->remove }) {
        $mms->remove($file);
    }

    $self->log([ 'writing %s', $self->skipfile ]);

    require Dist::Zilla::File::InMemory;
    $self->add_file(
        Dist::Zilla::File::InMemory->new(
            {
                name    => $self->skipfile,
                content => $mms->text,
            }
        )
    );

    return;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Generate::ManifestSkip - generate a MANIFEST.SKIP file for your distribution

=head1 VERSION

version v0.1.3

=head1 SYNOPSIS

In your F<dist.ini> file:

  [Generate::ManifestSkip]
  :version = v0.1.2

=head1 DESCRIPTION

This plugin will generate a F<MANIFEST.SKIP> file for your
distribution, and then prune any files that match.

=head1 ATTRIBUTES

=head2 skipfile

This is the name of the file to generate. It defaults to F<MANIFEST.SKIP>.

=head2 add

This adds a regular expression to the L</skipfile>.

By defaut, the following files are added to the skipfile:

=over

=item C<\.build/>

=item C<\.mailmap$>

=item C<{$dist_name}-.*/>

=item C<{$dist_name}-.*\.tar\.gz>

=back

where C<$dist_name> is the name of the distribution.

If the distribution has an F<alienfile>, then C<_alien/> will be added,

If the distribution has a F<cpanfile>, then C<cpanfile\.snapshot$>
will be added.

=head2 remove

This removes a regular expression from the L</skipfile>. Note that it
must the expression from L<Module::Manifest::Skip>.

By default, the following files are already removed from the skipfile:

=over

=item C<^MANIFEST\.SKIP$>

=item C<^dist\.ini$>

=item C<^weaver\.ini$>

=item C<^xt/>

=back

If you want them to be excluded from your distribution, then specify
them with L</add>.

=head1 SEE ALSO

L<Module::Manifest::Skip>

L<Dist::Zilla::Plugin::ManifestSkip>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Dist-Zilla-Plugin-Generate-ManifestSkip>
and may be cloned from L<git://github.com/robrwo/Dist-Zilla-Plugin-Generate-ManifestSkip.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/Dist-Zilla-Plugin-Generate-ManifestSkip/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

Some of the code and tests have been borrowed from L<Dist::Zilla::Plugin::InstallGuide>.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
