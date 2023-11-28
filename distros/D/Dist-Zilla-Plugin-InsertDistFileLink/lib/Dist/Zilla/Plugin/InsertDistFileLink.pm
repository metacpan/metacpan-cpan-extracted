package Dist::Zilla::Plugin::InsertDistFileLink;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-09'; # DATE
our $DIST = 'Dist-Zilla-Plugin-InsertDistFileLink'; # DIST
our $VERSION = '0.001'; # VERSION

use Moose;
with (
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::GetSharedFileURL',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [':InstallModules', ':ExecFiles'],
    },
);

has hosting => (is => 'rw', default => sub {'metacpan'});
has include_files => (is => 'rw');
has exclude_files => (is => 'rw');
has include_file_pattern => (is => 'rw');
has exclude_file_pattern => (is => 'rw');

sub mvp_multivalue_args { qw(include_files exclude_files) }

use namespace::autoclean;

sub munge_files {
    require HTML::Entities;

    my $self = shift;

    my $code_insert = sub {
        my ($path) = @_;
        $path =~ s!\\!/!g; # windows

        my $url = $self->get_shared_file_url($self->hosting, $path);

        "=begin html\n\n<a href=\"$url\">" . HTML::Entities::encode_entities($path) . "</a><br />\n\n=end html\n\n";
    };

  FILE:
    for my $file (@{ $self->found_files }) {
        if ($self->include_files && @{ $self->include_files }) {
            unless (grep {$_ eq $file->name} @{$self->include_files}) {
                $self->log_debug(["Skipped file %s (not in include_files)", $file->name]);
                next FILE;
            }
        }
        if ($self->exclude_files && @{ $self->exclude_files }) {
            if (grep {$_ eq $file->name} @{$self->exclude_files}) {
                $self->log_debug(["Skipped file %s (in include_files)", $file->name]);
                next FILE;
            }
        }
        if (my $pat = $self->include_file_pattern) {
            unless ($file->name =~ /$pat/) {
                $self->log_debug(["Skipped file %s (doesn't match include_file_pattern)", $file->name]);
                next FILE;
            }
        }
        if (my $pat = $self->exclude_file_pattern) {
            if ($file->name =~ /$pat/) {
                $self->log_debug(["Skipped file %s (matches exclude_file_pattern)", $file->name]);
                next FILE;
            }
        }

        my $content = $file->content;
        if ($content =~ s{^#\s*FILE(?:\s*:\s*|\s+)(\S.+?)\s*$}{$code_insert->($1)}egm) {
            $self->log(["inserting file link into '%s'", $file->name]);
            $file->content($content);
        }
    }
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Insert links to distribution shared files into POD as HTML snippets

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::InsertDistFileLink - Insert links to distribution shared files into POD as HTML snippets

=head1 VERSION

This document describes version 0.001 of Dist::Zilla::Plugin::InsertDistFileLink (from Perl distribution Dist-Zilla-Plugin-InsertDistFileLink), released on 2023-11-09.

=head1 SYNOPSIS

In F<share>, put some files e.g. F<foo.xlsx> and F<share/img1.png>.

In F<dist.ini>:

 [InsertDistFileLink]
 ;hosting=metacpan
 ;include_files=...
 ;exclude_files=...
 ;include_file_pattern=...
 ;exclude_file_pattern=...

In F<lib/Qux.pm> or F<script/quux>:

 ...

 # FILE: share/foo.xlsx
 # FILE: share/

 ...

After build, F<lib/Foo.pm> will contain:

 ...

 =begin html

 <a href="https://st.aticpan.org/source/CPANID/Your-Dist-Name-0.123/share/foo.xlsx" />foo.xlsx</a><br />

 =end html

 =begin html

 <a href="https://st.aticpan.org/source/CPANID/Your-Dist-Name-0.123/share/images/img1.png">image/img1.png</a><br />

 =end html

=head1 DESCRIPTION

This plugin finds C<# FILE> directive in your POD/code and replace it with a POD
containing HTML snippet to link to the file, using the selected hosting
provider's URL scheme.

Rationale: sometimes it's convenient to link to the distribution shared files in
HTML documentation. In POD there's currently no mechanism to do this.

The C<#FILE> directive must occur at the beginning of line and must be followed
by path to the image (relative to the distribution's root).

Shared files deployed inside a tarball (such as one created using
L<Dist::Zilla::Plugin::ShareDir::Tarball>) are not yet supported.

=for Pod::Coverage .+

=head1 CONFIGURATION

=head2 hosting => str (default: metacpan)

Choose hosting provider. For available choicese, see
L<Dist::Zilla::Role::GetDistFileURL>.

=head2 include_files => str+

=head2 exclude_files => str+

=head2 include_file_pattern => re

=head2 exclude_file_pattern => re

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-InsertDistFileLink>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-InsertDistFileLink>.

=head1 SEE ALSO

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-InsertDistFileLink>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
