package Dist::Zilla::Role::PERLANCAR::WriteModules;

our $DATE = '2015-07-27'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use Moose::Role;

use File::Path qw(make_path);
use File::Slurper qw(write_binary);

has written_modules_dir => (is => 'rw');
has has_written_modules_to_dir => (is => 'rw');

sub write_modules_to_dir {
    my ($self, $dir, $force) = @_;

    return if !$force && $self->has_written_modules_to_dir;

    $dir //= $self->written_modules_dir;
    unless (defined $dir) {
        require File::Temp;
        $dir = File::Temp::tempdir(CLEANUP => ($ENV{DEBUG_KEEP_TEMPDIR} ? 0:1));
    }

    $self->log_debug(["writing built modules to dir %s ...", $dir]);
    my @modules  = grep { $_->name =~ m!^lib/! } @{ $self->zilla->files };
    for my $modobj (@modules) {
        my ($d, $n) = $modobj->{name} =~ m!lib/(?:(.*)/)?(.+)!;
        make_path("$dir/$d") if length($d);
        my $target = "$dir/$d/$n";
        $self->log_debug(["  writing %s ...", $target]);
        write_binary($target, $modobj->content);
    }
    $self->has_written_modules_to_dir(1);
    $self->written_modules_dir($dir);
}

no Moose::Role;
1;
# ABSTRACT: Role to write modules to disk to a specified directory

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::PERLANCAR::WriteModules - Role to write modules to disk to a specified directory

=head1 VERSION

This document describes version 0.02 of Dist::Zilla::Role::PERLANCAR::WriteModules (from Perl distribution Dist-Zilla-Role-PERLANCAR-WriteModules), released on 2015-07-27.

=head1 DESCRIPTION

Rationale: in the middle of a build process, sometimes we want to write the
built version of modules to disk (as actual files). The problem is, Dist::Zilla
writes the dist to disk at the end of build.

An example of this is with L<Dist::Zilla::Plugin::GenPericmdScript> which
generates scripts in the file gathering step. Or, L<Dist::Zilla::Plugin::Depak>
which replaces scripts with packed version in the file munging step. These
generated scripts might embed modules inside them, including from the current
dist we're building, and we need the built version of these modules instead of
the raw version.

So this role can be used to write the built modules (so far, at that point) to a
temporary directory.

=head1 ATTRIBUTES

=head2 written_modules_dir => str

If already written modules to dir, will contain the directory name. Otherwise,
undef.

=head2 has_written_modules_to_dir => bool

=head1 METHODS

=head2 $obj->write_modules_to_dir([ $dir[, $force ] ])

Write built modules to disk at the specified directory (or, to a temporary
directory if C<$dir> is not specified).

To find out the directory being used, use the C<written_modules_dir> attribute.

If a temporary directory is automatically selected, it will automatically be
cleaned up at the end of build (created using L<File::Temp>'s C<tempdir> with
C<CLEANUP> set to 1) unless the environment C<DEBUG> is set to true, in which
case the temporary directory will not be automatically cleaned up.

By default will only do this once during build, and subsequent call to
C<write_modules_to_dir()> will be a no-op. But if you set C<$force> to 1, will
write modules to disk even if it has been done previously during the same build.

=head1 ENVIRONMENT

=head2 DEBUG_KEEP_TEMPDIR => bool

=head1 SEE ALSO

L<Dist::Zilla::Dist::Builder> the module which dzil uses to write the dist and
archive to disk, usually at the end of build.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Role-PERLANCAR-WriteModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Role-PERLANCAR-WriteModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Role-PERLANCAR-WriteModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
