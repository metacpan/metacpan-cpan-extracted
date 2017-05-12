package Dist::Zilla::Plugin::InsertExecsList;

our $DATE = '2015-08-31'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

use Moose;
with (
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [':InstallModules', ':ExecFiles'],
    },
);

use namespace::autoclean;

sub munge_files {
    my $self = shift;

    $self->munge_file($_) for @{ $self->found_files };
}

sub munge_file {
    my ($self, $file) = @_;
    my $content = $file->content;
    if ($content =~ s{^#\s*INSERT_EXECS_LIST\s*$}{$self->_insert_execs_list($1, $2)."\n"}egm) {
        $self->log(["inserting execs list into '%s'", $file->name]);
        $file->content($content);
    }
}

sub _insert_execs_list {
    my($self, $file, $name) = @_;

    # XXX use DZR:FileFinderUser's multiple finder feature instead of excluding
    # it manually again using regex

    my @list;
    for my $file (@{ $self->found_files }) {
        my $fullname = $file->name;
        next if $fullname =~ m!^lib[/\\]!;
        my $shortname = $fullname; $shortname =~ s!.+[/\\]!!;
        next if $shortname =~ /^_/;
        push @list, $shortname;
    }
    @list = sort @list;

    join(
        "",
        "=over\n\n",
        (map {"=item * L<$_>\n\n"} @list),
        "=back\n\n",
    );
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Insert a POD containing a list of scripts/executables in the distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::InsertExecsList - Insert a POD containing a list of scripts/executables in the distribution

=head1 VERSION

This document describes version 0.02 of Dist::Zilla::Plugin::InsertExecsList (from Perl distribution Dist-Zilla-Plugin-InsertExecsList), released on 2015-08-31.

=head1 SYNOPSIS

In dist.ini:

 [InsertExecsList]

In lib/Foo.pm:

 ...

 =head1 DESCRIPTION

 This distribution contains the following utilities:

 #INSERT_EXECS_LIST

 ...

After build, lib/Foo.pm will contain:

 ...

 =head1 DESCRIPTION

 This distribution contains the following utilities:

 =over

 =item * L<script1>

 =item * L<script2>

 =item * L<script3>

 =back

 ...

=head1 DESCRIPTION

This plugin finds C<< # INSERT_EXECS_LIST >> directive in your POD/code and
replace it with a POD containing list of scripts/executables in the
distribution.

=for Pod::Coverage .+

=head1 SEE ALSO

L<Dist::Zilla::Plugin::InsertModulesList>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-InsertExecsList>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-InsertExecsList>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-InsertExecsList>

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
