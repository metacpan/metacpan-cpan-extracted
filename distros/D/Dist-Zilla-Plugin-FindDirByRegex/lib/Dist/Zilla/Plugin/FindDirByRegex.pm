use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::FindDirByRegex;
BEGIN {
  $Dist::Zilla::Plugin::FindDirByRegex::VERSION = '1.102640';
}

# ABSTRACT: A regex-based FileFinder plugin
use Moose;
with 'Dist::Zilla::Role::FileFinder';

use Moose::Autobox;
use namespace::autoclean;

has dir => (
    is => 'ro',
    isa => 'Str',
    default => 'bin',
);

has skip => (
    is => 'ro',
);

sub find_files {
    my $self = shift;
    my $skip = $self->skip;
    my $re = qr/$skip/;
    my $dir = $self->dir;
    $self->zilla->files->grep(sub {
        index($_->name, "$dir/") == 0 && $_->name !~ $re
    });
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;


__END__
=pod

=for stopwords FileFinder dir

=for test_synopsis 1;
__END__

=head1 NAME

Dist::Zilla::Plugin::FindDirByRegex - A regex-based FileFinder plugin

=head1 VERSION

version 1.102640

=head1 SYNOPSIS

In C<dist.ini>:

    [FindDirByRegex / MyExecFiles]
    skip = \.sh$

    [PodWeaver]
    finder = :InstallModules
    finder = MyExecFiles

=head1 DESCRIPTION

This plugin finds files in a directory and skips them if they match a regular
expression.

=head1 METHODS

=head2 dir

The directory in which to find files. Defaults to C<bin>.

=head2 skip

The regular expression that determines whether or not a file will be skipped.

=head2 find_files

Finds files by matching them against the C<skip> regular expression.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Dist-Zilla-Plugin-FindDirByRegex/>.

The development version lives at L<http://github.com/hanekomu/Dist-Zilla-Plugin-FindDirByRegex>
and may be cloned from L<git://github.com/hanekomu/Dist-Zilla-Plugin-FindDirByRegex>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 AUTHOR

Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

