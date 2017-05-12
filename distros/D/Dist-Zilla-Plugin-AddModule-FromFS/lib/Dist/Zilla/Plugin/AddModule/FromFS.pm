package Dist::Zilla::Plugin::AddModule::FromFS;

our $DATE = '2015-07-01'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

use Moose;
with (
        'Dist::Zilla::Role::FileGatherer',
);

has name => (is => 'rw', required => 1);
has dest => (is => 'rw', required => 1);

use namespace::autoclean;

sub gather_files {
    require Dist::Zilla::File::OnDisk;
    require Module::Path::More;

    my ($self, $arg) = @_;

    $self->log_fatal("Please specify name") unless $self->name;
    $self->log_fatal("Please specify dest") unless $self->dest;

    my $modpath = Module::Path::More::module_path(module => $self->name)
        or $self->log_fatal(["Module %s not found on filesystem", $self->name]);

    my $fileobj = Dist::Zilla::File::OnDisk->new({
        name => $modpath,
        mode => 0644,
    });
    $fileobj->name($self->dest);

    $self->log(["Adding module %s (from %s) to %s",
                $self->name, $modpath, $self->dest]);
    $self->add_file($fileobj);
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Add module from filesystem

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::AddModule::FromFS - Add module from filesystem

=head1 VERSION

This document describes version 0.02 of Dist::Zilla::Plugin::AddModule::FromFS (from Perl distribution Dist-Zilla-Plugin-AddModule-FromFS), released on 2015-07-01.

=head1 SYNOPSIS

In F<dist.ini>:

 [AddModule::FromFS]
 name=Module::List
 dest=t/lib/Module/List.pm

To add more files:

 [AddModule::FromFS / AddModulePathMore]
 name=Module::Path::More
 dest=t/lib/Module/Path/More.pm

=head1 DESCRIPTION

This plugin adds a module source file from local filesystem to your build.

=for Pod::Coverage .+

=head1 SEE ALSO

L<Dist::Zilla::Plugin::AddFile::FromFS>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-AddModule-FromFS>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-AddModule-FromFS>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-AddModule-FromFS>

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
