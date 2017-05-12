package Dist::Zilla::Plugin::InsertModulesList;

our $DATE = '2016-03-25'; # DATE
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
    if ($content =~ s{^#\s*INSERT_MODULES_LIST(?:\s+(\S.*?))?\s*$}{$self->_insert_modules_list($1)."\n"}egm) {
        $self->log(["inserting modules list into '%s'", $file->name]);
        $file->content($content);
    }
}

sub _insert_modules_list {
    my($self, $opts) = @_;

    $opts = [split /\s+/, $opts];

    # XXX use DZR:FileFinderUser's multiple finder feature instead of excluding
    # it manually again using regex

    my @list0;
    for my $file (@{ $self->found_files }) {
        my $name = $file->name;
        next unless $name =~ s!^lib[/\\]!!;
        $name =~ s![/\\]!::!g;
        $name =~ s/\.(pm|pod)$//;
        push @list0, $name;
    }

    my $opts_has_includes = grep { !/^-/ } @$opts;

    # filter with options
    my @list;
  MODULE:
    for my $mod (sort @list0) {
        my $found = 0;
      OPT:
        for my $opt (@$opts) {
            if ($opt =~ m!^-/(.*)/$!) {
                # exclude modules matching a regex
                next MODULE if $mod =~ /$1/;
            } elsif ($opt =~ /^-(.*)/) {
                # exclude a module
                next MODULE if $mod eq $1;
            } elsif ($opt =~ m!^/(.*)/!) {
                # only include modules matching a regex
                if ($mod =~ /$1/) {
                    $found++;
                } else {
                    next MODULE;
                }
            } else {
                # only include this module
                if ($mod eq $1) {
                    $found++;
                } else {
                    next MODULE;
                }
            }
        }
        push @list, $mod if !$opts_has_includes || $found;
    }

    join(
        "",
        "=over\n\n",
        (map {"=item * L<$_>\n\n"} @list),
        "=back\n\n",
    );
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Insert a POD containing a list of modules in the distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::InsertModulesList - Insert a POD containing a list of modules in the distribution

=head1 VERSION

This document describes version 0.02 of Dist::Zilla::Plugin::InsertModulesList (from Perl distribution Dist-Zilla-Plugin-InsertModulesList), released on 2016-03-25.

=head1 SYNOPSIS

In dist.ini:

 [InsertModulesList]

In lib/Foo.pm:

 ...

 =head1 DESCRIPTION

 This distribution contains the following modules:

 #INSERT_MODULES_LIST

 ...

After build, lib/Foo.pm will contain:

 ...

 =head1 DESCRIPTION

 This distribution contains the following modules:

 =over

 =item * L<Foo>

 =item * L<Foo::Bar>

 =item * L<Foo::Baz>

 =back

 ...

=head1 DESCRIPTION

This plugin finds C<< # INSERT_MODULES_LIST >> directive in your POD/code and
replace it with a POD containing list of modules in the distribution.

To exclude a module from the generated list, use:

 # INSERT_MODULES_LIST -Foo::Bar -Baz ...

To exclude modules matching a regex, use:

 # INSERT_MODULES_LIST -/^Foo::Bar::(Helper|Util)/

To only include modules matching a regex, use:

 Below are the included plugins in this distribution"

 # INSERT_MODULES_LIST /^Foo::Plugin::/

Excludes and includes can be combined.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-InsertModulesList>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-InsertModulesList>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-InsertModulesList>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Dist::Zilla::Plugin::InsertExecsList>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
