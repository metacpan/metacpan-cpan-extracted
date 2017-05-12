use strict;
use warnings;
package Dist::Zilla::Plugin::CheckSelfDependency; # git description: v0.010-10-g077e534
# ABSTRACT: Check if your distribution declares a dependency on itself
# KEYWORDS: plugin validate distribution prerequisites dependencies modules
# vim: set ts=8 sts=4 sw=4 tw=78 et :
our $VERSION = '0.011';
use Moose;
with 'Dist::Zilla::Role::AfterBuild',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [ ':InstallModules' ],
    },
    'Dist::Zilla::Role::ModuleMetadata',
;
use CPAN::Meta::Prereqs 2.132830;   # for merged_requirements
use CPAN::Meta::Requirements;
use namespace::autoclean;

around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        finder => $self->finder,
    };

    return $config;
};

sub after_build
{
    my $self = shift;

    my %prereqs = map { $_ => 1 }
        map { keys %$_ }
        map { values %$_ }
        grep { defined }
        @{ $self->zilla->prereqs->as_string_hash }{qw(configure build runtime test)};

    my $develop_prereqs = $self->zilla->prereqs->cpan_meta_prereqs
        ->merged_requirements(['develop'], [qw(requires recommends suggests)]);
    my $develop_prereqs_hash = $develop_prereqs->as_string_hash;

    my $provides = $self->zilla->distmeta->{provides};  # copy, to avoid autovivifying

    my @errors;
    # when 'provides' data is mandatory, we will rely on what it says -
    # but for now, we will check our modules explicitly for provided packages.
    foreach my $file (@{$self->found_files})
    {
        $self->log_fatal([ 'Could not decode %s: %s', $file->name, $file->added_by ])
            if $file->can('encoding') and $file->encoding eq 'bytes';

        my @packages = $self->module_metadata_for_file($file)->packages_inside;
        foreach my $package (@packages)
        {
            if (exists $prereqs{$package}
                or (exists $develop_prereqs_hash->{$package}
                    # you can only have a develop prereq on yourself if you
                    # use 'provides' metadata - so we're darned sure we
                    # matched up the right module names
                    and not exists $provides->{$package}))
            {
                push @errors, $package . ' is listed as a prereq, but is also provided by this dist ('
                    . $file->name . ')!';
                next;
            }

            next if not exists $develop_prereqs_hash->{$package};

            my $version = $provides ? $provides->{$package}{version} : $self->zilla->version;
            if (not $develop_prereqs->accepts_module($package => $version))
            {
                push @errors, "$package $develop_prereqs_hash->{$package} is listed as a develop prereq, "
                    . 'but this dist doesn\'t provide that version ('
                    . $file->name . ' only has ' . $version . ')!';
            }
        }
    }

    $self->log_fatal(@errors) if @errors;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::CheckSelfDependency - Check if your distribution declares a dependency on itself

=head1 VERSION

version 0.011

=head1 SYNOPSIS

In your F<dist.ini>:

    [CheckSelfDependency]

=head1 DESCRIPTION

=for Pod::Coverage after_build

=for stopwords indexable

This is a L<Dist::Zilla> plugin that runs in the I<after build> phase, which
checks all of your module prerequisites (all phases, all types except develop) to confirm
that none of them refer to modules that are B<provided> by this distribution
(that is, the metadata declares the module is indexable).

In addition, all modules B<in> the distribution are checked against all module
prerequisites (all phases, all types B<including> develop). Thus, it is
possible to ship a L<Dist::Zilla> plugin and use (depend on) yourself, but
errors such as declaring a dependency on C<inc::HelperPlugin> are still caught.

While some prereq providers (e.g. L<C<[AutoPrereqs]>|Dist::Zilla::Plugin::AutoPrereqs>)
do not inject dependencies found internally, there are many plugins that
generate code and also inject the prerequisites needed by that code, without
regard to whether some of those modules might be provided by your dist.
This problem is particularly acute when packaging low-level toolchain distributions.

If such modules are found, the build fails.  To remedy the situation, remove
the plugin that adds the prerequisite, or remove the prerequisite itself with
L<C<[RemovePrereqs]>|Dist::Zilla::Plugin::RemovePrereqs>. (Remember that
plugin order is significant -- you need to remove the prereq after it has been
added.)

=head1 CONFIGURATION OPTIONS

=head2 C<finder>

=for stopwords FileFinder

This is the name of a L<FileFinder|Dist::Zilla::Role::FileFinder> for finding
modules to check.  The default value is C<:InstallModules>; this option can be
used more than once.

Other predefined finders are listed in
L<Dist::Zilla::Role::FileFinderUser/default_finders>.
You can define your own with the
L<[FileFinder::ByName]|Dist::Zilla::Plugin::FileFinder::ByName> and
L<[FileFinder::Filter]|Dist::Zilla::Plugin::FileFinder::Filter> plugins.

=head1 SUPPORT

=for stopwords irc

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-CheckSelfDependency>
(or L<bug-Dist-Zilla-Plugin-CheckSelfDependency@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-CheckSelfDependency@rt.cpan.org>).
I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
