use 5.10.0;
use strict;
use warnings;

package Dist::Iller::Config::Author::CSSON;

# ABSTRACT: Dist::Iller config
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0316';

use Moose;
use namespace::autoclean;
use Path::Tiny;
use Types::Path::Tiny qw/Path/;
use Types::Standard qw/Bool Str Int/;
use MooseX::AttributeDocumented;

has filepath => (
    is => 'ro',
    isa => Path,
    default => 'author-csson.yaml',
    coerce => 1,
    documentation => q{Path to the plugin configuration file, relative to the installed share dir location.},
);
has is_task => (
    is => 'ro',
    isa => Bool,
    default => 0,
    documentation => q{If set to a true value it will include [TaskWeaver] instead of [PodWeaver].},
);
has installer => (
    is => 'rw',
    isa => Str,
    lazy => 1,
    default => 'MakeMaker',
    documentation => q{The installer plugin to be used.},
);
has is_private => (
    is => 'rw',
    isa => Int,
    lazy => 1,
    default => 0,
    documentation_alts => {
        0 => q{Include [UploadToCPAN] and [GithubMeta].},
        1 => q{Include [UploadToStratopan].},
    }
);
has homepage => (
    is => 'rw',
    isa => Str,
    lazy => 1,
    default => sub {
        my $self = shift;
        $self->has_distribution_name ? sprintf 'https://metacpan.org/release/%s', $self->distribution_name : undef;
    },
    documentation_default => q{https://metacpan.org/release/[distribution_name]},
    documentation => q{URL to the distribution's homepage.},
);
has splint => (
    is => 'rw',
    isa => Int,
    default => 0,
    documentation_alts => {
        0 => q{Exclude Pod::Elemental::Transformer::Splint from weaver.ini},
        1 => q{Include Pod::Elemental::Transformer::Splint in weaver.ini},
    }
);
has badges => (
    is => 'ro',
    isa => Bool,
    default => 1,
    documentation => 'Include Badge::Depot badges or not.',
);

has travis => (
    is => 'rw',
    isa => Int,
    default => 1,
    documentation_order => 100,
    documentation_alts => {
        0 => q{Exclude [TravisYML].},
        1 => q{Include [TravisYML].},
    },
);
has travis_perl_min => (
    is => 'ro',
    isa => Int,
    lazy => 1,
    default => '14',
    documentation_order => 101,
    documentation => q{Minimum Perl version to test on Travis. All production releases up to (and including) 'travis_perl_max' are automatically included. Only give the minor version number (eg '14' for Perl 5.14).},
);
has travis_perl_max => (
    is => 'ro',
    isa => Int,
    lazy => 1,
    default => '22',
    documentation_order => 102,
    documentation => q{Maximum Perl version to test on Travis. See 'travis_perl_min'.}
);


with 'Dist::Iller::Config';

sub build_file {
    my $self = shift;
    return $self->installer =~ m/MakeMaker/ ? 'Makefile.PL' : 'Build.PL';
}

sub is_private_release {
    my $self = shift;
    return !$ENV{'FAKE_RELEASE'} && $self->is_private ? 1 : 0;
}
sub is_cpan_release {
    my $self = shift;
    return $ENV{'FAKE_RELEASE'} || $self->is_private ? 0 : 1;
}

sub add_default_github {
    my $self = shift;
    # check git config
    my $add_default_github = 0;
    my $git_config = path('.git/config');
    if($git_config->exists) {
        my $git_config_contents = $git_config->slurp_utf8;
        if($git_config_contents =~ m{github\.com:([^/]+)/(.+)\.git}) {
            $add_default_github = 1;
        }
        else {
            say ('[DI/@Author::CSSON] No github url found');
        }
    }
    return $add_default_github;
}
sub travis_perl {
    my $self = shift;
    return join ' ' => map { "5.$_" } grep { $_ >= $self->travis_perl_min && $_ <= $self->travis_perl_max } qw/6 8 10 12 14 16 18 20 22/;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Iller::Config::Author::CSSON - Dist::Iller config



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.10+-blue.svg" alt="Requires Perl 5.10+" />
<a href="https://travis-ci.org/Csson/p5-Dist-Iller-Config-Author-CSSON"><img src="https://api.travis-ci.org/Csson/p5-Dist-Iller-Config-Author-CSSON.svg?branch=master" alt="Travis status" /></a>
<a href="http://cpants.cpanauthors.org/release/CSSON/Dist-Iller-Config-Author-CSSON-0.0316"><img src="http://badgedepot.code301.com/badge/kwalitee/CSSON/Dist-Iller-Config-Author-CSSON/0.0316" alt="Distribution kwalitee" /></a>
<a href="http://matrix.cpantesters.org/?dist=Dist-Iller-Config-Author-CSSON%200.0316"><img src="http://badgedepot.code301.com/badge/cpantesters/Dist-Iller-Config-Author-CSSON/0.0316" alt="CPAN Testers result" /></a>
<img src="https://img.shields.io/badge/coverage-42.7%-red.svg" alt="coverage 42.7%" />
</p>

=end html

=head1 VERSION

Version 0.0316, released 2017-06-27.



=head1 SYNOPSIS

    # in iller.yaml
    +config: Author::CSSON
    splint: 1

=head1 DESCRIPTION

Dist::Iller::Config::Author::Csson is a L<Dist::Iller> configuration. The plugin list is in C<share/author-csson.yaml>.

=head1 ATTRIBUTES


=head2 travis

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Int">Int</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>1</code></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">read/write</td>
    <td style="text-align: right; padding-right: 6px; padding-left: 6px;"><code>0</code>:</td>
    <td style="padding-left: 12px;">Exclude [TravisYML].</td>
</tr>
<tr>
    <td>&#160;</td>
    <td>&#160;</td>
    <td>&#160;</td>
    <td style="text-align: right; padding-right: 6px; padding-left: 6px;"><code>1</code>:</td>
    <td style="padding-left: 12px;">Include [TravisYML].</td>
</tr>
</table>

<p></p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Int">Int</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>1</code></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">read/write</td>
    <td style="text-align: right; padding-right: 6px; padding-left: 6px;"><code>1</code>:</td>
    <td style="padding-left: 12px;">Include [TravisYML].</td>
</tr>
</table>

<p></p>

=end markdown

=head2 travis_perl_min

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Int">Int</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>14</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Minimum Perl version to test on Travis. All production releases up to (and including) 'travis_perl_max' are automatically included. Only give the minor version number (eg '14' for Perl 5.14).</p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Int">Int</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>14</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Minimum Perl version to test on Travis. All production releases up to (and including) 'travis_perl_max' are automatically included. Only give the minor version number (eg '14' for Perl 5.14).</p>

=end markdown

=head2 travis_perl_max

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Int">Int</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>22</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Maximum Perl version to test on Travis. See 'travis_perl_min'.</p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Int">Int</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>22</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Maximum Perl version to test on Travis. See 'travis_perl_min'.</p>

=end markdown

=head2 badges

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Bool">Bool</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>1</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Include Badge::Depot badges or not.</p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Bool">Bool</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>1</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Include Badge::Depot badges or not.</p>

=end markdown

=head2 filepath

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Path::Tiny#Path">Path</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>author-csson.yaml</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Path to the plugin configuration file, relative to the installed share dir location.</p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Path::Tiny#Path">Path</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>author-csson.yaml</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Path to the plugin configuration file, relative to the installed share dir location.</p>

=end markdown

=head2 homepage

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Str">Str</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>https://metacpan.org/release/[distribution_name]</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read/write</td>
</tr>
</table>

<p>URL to the distribution's homepage.</p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Str">Str</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>https://metacpan.org/release/[distribution_name]</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read/write</td>
</tr>
</table>

<p>URL to the distribution's homepage.</p>

=end markdown

=head2 installer

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Str">Str</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>MakeMaker</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read/write</td>
</tr>
</table>

<p>The installer plugin to be used.</p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Str">Str</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>MakeMaker</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read/write</td>
</tr>
</table>

<p>The installer plugin to be used.</p>

=end markdown

=head2 is_private

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Int">Int</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>0</code></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">read/write</td>
    <td style="text-align: right; padding-right: 6px; padding-left: 6px;"><code>0</code>:</td>
    <td style="padding-left: 12px;">Include [UploadToCPAN] and [GithubMeta].</td>
</tr>
<tr>
    <td>&#160;</td>
    <td>&#160;</td>
    <td>&#160;</td>
    <td style="text-align: right; padding-right: 6px; padding-left: 6px;"><code>1</code>:</td>
    <td style="padding-left: 12px;">Include [UploadToStratopan].</td>
</tr>
</table>

<p></p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Int">Int</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>0</code></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">read/write</td>
    <td style="text-align: right; padding-right: 6px; padding-left: 6px;"><code>1</code>:</td>
    <td style="padding-left: 12px;">Include [UploadToStratopan].</td>
</tr>
</table>

<p></p>

=end markdown

=head2 is_task

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Bool">Bool</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>0</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>If set to a true value it will include [TaskWeaver] instead of [PodWeaver].</p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Bool">Bool</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>0</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>If set to a true value it will include [TaskWeaver] instead of [PodWeaver].</p>

=end markdown

=head2 main_module

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Str">Str</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>The package name</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Override this attribute when there's more than one config in a distribution. It uses the main_module's sharedir location for the config files.</p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Str">Str</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>The package name</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Override this attribute when there's more than one config in a distribution. It uses the main_module's sharedir location for the config files.</p>

=end markdown

=head2 splint

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Int">Int</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>0</code></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">read/write</td>
    <td style="text-align: right; padding-right: 6px; padding-left: 6px;"><code>0</code>:</td>
    <td style="padding-left: 12px;">Exclude Pod::Elemental::Transformer::Splint from weaver.ini</td>
</tr>
<tr>
    <td>&#160;</td>
    <td>&#160;</td>
    <td>&#160;</td>
    <td style="text-align: right; padding-right: 6px; padding-left: 6px;"><code>1</code>:</td>
    <td style="padding-left: 12px;">Include Pod::Elemental::Transformer::Splint in weaver.ini</td>
</tr>
</table>

<p></p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Int">Int</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>0</code></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">read/write</td>
    <td style="text-align: right; padding-right: 6px; padding-left: 6px;"><code>1</code>:</td>
    <td style="padding-left: 12px;">Include Pod::Elemental::Transformer::Splint in weaver.ini</td>
</tr>
</table>

<p></p>

=end markdown

=head1 ENVIRONMENT VARIABLES

=head2 FAKE_RELEASE

If set to a true value this will include [FakeRelease] and remove either [UploadToCPAN] or [UploadToStratopan].

=head1 SOURCE

L<https://github.com/Csson/p5-Dist-Iller-Config-Author-CSSON>

=head1 HOMEPAGE

L<https://metacpan.org/release/Dist-Iller-Config-Author-CSSON>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
