package Dist::Zilla::Plugin::InsertDistImage;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-09'; # DATE
our $DIST = 'Dist-Zilla-Plugin-InsertDistImage'; # DIST
our $VERSION = '0.007'; # VERSION

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

use File::Slurper qw(read_binary);
use URI;

sub munge_files {
    my $self = shift;

    # check hosting configuration
    my $hosting = $self->hosting;

    my $code_insert = sub {
        my ($paths) = @_;
        $paths =~ s!\\!/!g; # windows
        my @paths = split /\s*\|\s*/, $paths;

        unless ($paths[0] =~ /\.(jpe?g|png|gif)\z/) {
            $self->log_fatal(["File %s not supported, only jpg/png/gif supported", $paths[0]]);
        }
        my $url;
        if ($hosting eq 'data') {
            my $ct;
            if ($paths[0] =~ /\.jpe?g\z/) {
                $ct = "image/jpeg";
            } else {
                $paths[0] =~ /\.(\w+)\z/ or die;
                $ct = "image/$1";
            }
            $url = URI->new("data:");
            $url->media_type($ct);
            my $found;
            for my $path (@paths) {
                if (-f $path) {
                    $url->data(read_binary($path));
                    $found++;
                    last;
                } elsif (my ($file) = grep { $_->name eq $path } @{ $self->zilla->files }) {
                    $url->data($file->encoded_content);
                    $found++;
                    last;
                }
            }
            $self->log_fatal(["Can't find files %s in filesystem or build", \@paths])
                unless $found;
            $url = "$url";
        } else {
            $url = $self->get_shared_file_url($hosting, $paths[0]);
        }

        "=begin html\n\n<img src=\"$url\" />\n\n=end html\n\n";
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
        if ($content =~ s{^#\s*IMAGE(?:\s*:\s*|\s+)(\S.+?)\s*$}{$code_insert->($1)}egm) {
            $self->log(["inserting images into '%s'", $file->name]);
            $file->content($content);
        }
    }
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Insert images contained in distribution into POD as HTML snippets

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::InsertDistImage - Insert images contained in distribution into POD as HTML snippets

=head1 VERSION

This document describes version 0.007 of Dist::Zilla::Plugin::InsertDistImage (from Perl distribution Dist-Zilla-Plugin-InsertDistImage), released on 2023-11-09.

=head1 SYNOPSIS

In F<share/images>, put some images e.g. F<img1.jpg> and F<img2.png>.

In F<dist.ini>:

 [InsertDistImage]
 ;hosting=metacpan
 ;include_files=...
 ;exclude_files=...
 ;include_file_pattern=...
 ;exclude_file_pattern=...

In F<lib/Foo.pm> or F<bin/bar>:

 ...

 # IMAGE: share/images/img1.jpg
 # IMAGE: share/images/img2.png

 ...

After build, F<lib/Foo.pm> will contain:

 ...

 =begin html

 <img src="https://st.aticpan.org/source/CPANID/Your-Dist-Name-0.123/share/images/img1.jpg" />

 =end html

 =begin html

 <img src="https://st.aticpan.org/source/CPANID/Your-Dist-Name-0.123/share/images/img2.png" />

 =end html

=head1 DESCRIPTION

This plugin finds C<# IMAGE> directive in your POD/code and replace it with
a POD containing HTML snippet to load the images, using the selected hosting
provider's URL scheme.

Rationale: sometimes documentation needs some images. Sometimes the proper (not
to mention convenient) place to put the images is within the distribution
itself. And you want to be able to view the images when you browse the POD in
HTML form.

The C<#IMAGE> directive must occur at the beginning of line and must be followed
by path to the image (relative to the distribution's root). It is recommended to
put the images in F<share/images>.

You can put alternate locations by using C<|>, e.g.:

 # IMAGE: location1.jpg|location2.jpg

This can be useful if you are using hosting=data (where this plugin needs to
read the content of the file) and C<location1.jpg> is produced by another plugin
and might not be ready or added to the build at the time this plugin runs (but
C<location2.jpg> is the temporary version of the file that already exists).

Shared image files deployed inside a tarball (such as one created using
L<Dist::Zilla::Plugin::ShareDir::Tarball>) are not yet supported.

=for Pod::Coverage .+

=head1 CONFIGURATION

=head2 hosting => str (default: metacpan)

Choose hosting provider. Available choices:

=over

=item * metacpan

This is the default because all distributions uploaded to PAUSE/CPAN will
normally show up on L<metacpan.org>. Note that some people advise not to abuse
metacpan.org to host images because metacpan.org is not an image hosting
service. However, at the time of this writing, I couldn't find any mention of
this in the metacpan.org FAQ or About pages.

=item * github

This can only be used if the distribution specifies its repository in its
metadata, and the repository URL's host is github.com.

=item * gitlab

This can only be used if the distribution specifies its repository in its
metadata, and the repository URL's host is gitlab.com.

=item * bitbucket

This can only be used if the distribution specifies its repository in its
metadata, and the repository URL's host is bitbucket.org.

=item * data

Instead of using a remote http/https hosting provider, this will instead use
C<data:> URIs where the image data is directly embedded in the URL.

=back

=head2 include_files => str+

=head2 exclude_files => str+

=head2 include_file_pattern => re

=head2 exclude_file_pattern => re

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-InsertDistImage>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-InsertDistImage>.

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

This software is copyright (c) 2023, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-InsertDistImage>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
