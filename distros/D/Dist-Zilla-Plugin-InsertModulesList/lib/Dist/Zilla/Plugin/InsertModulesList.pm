package Dist::Zilla::Plugin::InsertModulesList;

use 5.010001;
use strict;
use warnings;

use Moose;
with (
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [':AllFiles'], # XXX dzil doesn't provide InstallPODs only InstallModules
    },
);

has ordered => (is => 'rw');

use namespace::autoclean;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-03-02'; # DATE
our $DIST = 'Dist-Zilla-Plugin-InsertModulesList'; # DIST
our $VERSION = '0.031'; # VERSION

sub munge_files {
    my $self = shift;

    for my $file (@{ $self->found_files }) {
        my $name = $file->name;
        next unless $name =~ m!^(lib|script|bin)[/\\]!;
        $self->munge_file($file);
    }
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
    @list = sort @list;

    my $ordered = $self->ordered // (@list > 6);

    join(
        "",
        "=over\n\n",
        (map {"=item ".($ordered ? ($_+1).".":"*")." L<$list[$_]>\n\n"} 0..$#list),
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

This document describes version 0.031 of Dist::Zilla::Plugin::InsertModulesList (from Perl distribution Dist-Zilla-Plugin-InsertModulesList), released on 2023-03-02.

=head1 SYNOPSIS

In F<dist.ini>:

 [InsertModulesList]

In F<lib/Foo.pm>:

 ...

 =head1 DESCRIPTION

 This distribution contains the following modules:

 #INSERT_MODULES_LIST

 ...

After build, F<lib/Foo.pm> will contain:

 ...

 =head1 DESCRIPTION

 This distribution contains the following modules:

 =over

 =item 1. L<Foo>

 =item 2. L<Foo::Bar>

 =item 3. L<Foo::Baz>

 ...

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

 Below are the included plugins in this distribution:

 # INSERT_MODULES_LIST /^Foo::Plugin::/

Excludes and includes can be combined.

=for Pod::Coverage .+

=head1 CONFIGURATION

=head2 ordered

Bool. Can be set to true to always generate an ordered list, or false to always
generate an unordered list. If unset, will use unordered list for 6 or less
items and ordered list otherwise.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-InsertModulesList>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-InsertModulesList>.

=head1 SEE ALSO

L<Dist::Zilla::Plugin::InsertExecsList>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2019, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-InsertModulesList>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
