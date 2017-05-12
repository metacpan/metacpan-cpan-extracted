use strict;
use warnings;
package Dist::Zilla::Plugin::Test::NewVersion;
BEGIN {
  $Dist::Zilla::Plugin::Test::NewVersion::AUTHORITY = 'cpan:ETHER';
}
{
  $Dist::Zilla::Plugin::Test::NewVersion::VERSION = '0.009';
}
# git description: v0.008-16-g1594bb3

# ABSTRACT: Generate a test that checks a new version has been assigned

use Moose;
with
    'Dist::Zilla::Role::FileGatherer',
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::TextTemplate',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [ ':InstallModules' ],
    },
    'Dist::Zilla::Role::PrereqSource',
;
use Sub::Exporter::ForMethods 'method_installer';
use Data::Section 0.004 # fixed header_re
    { installer => method_installer }, '-setup';
use namespace::autoclean;

sub register_prereqs
{
    my $self = shift;
    $self->zilla->register_prereqs(
        {
            type  => 'requires',
            phase => 'develop',
        },
        'Test::More' => '0.88',
        'Encode' => '0',
        'HTTP::Tiny' => '0',
        'JSON' => '0',
        'version' => '0',
        'Module::Metadata' => '0',
        'List::Util' => '0',
        'CPAN::Meta' => '2.120920',
    );
}

has _test_file => (
    is => 'ro', isa => 'Dist::Zilla::File::InMemory',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $filename = 'xt/release/new-version.t';
        use Dist::Zilla::File::InMemory;
        Dist::Zilla::File::InMemory->new({
            name => $filename,
            content => ${$self->section_data($filename)},
        });
    },
);

sub gather_files
{
    my $self = shift;

    $self->add_file($self->_test_file);
    return;
}

sub munge_file
{
    my ($self, $file) = @_;

    # cannot check $file by name, as the file may have been moved by [ExtraTests].
    return unless $file eq $self->_test_file;

    $file->content(
        $self->fill_in_string(
            $file->content,
            {
                dist => \($self->zilla),
                plugin => \$self,
                files => [ map { $_->name } @{ $self->found_files } ],
            },
        )
    );
    return;
}
__PACKAGE__->meta->make_immutable;

=pod

=encoding UTF-8

=for :stopwords Karen Etheridge FileFinder irc

=head1 NAME

Dist::Zilla::Plugin::Test::NewVersion - Generate a test that checks a new version has been assigned

=head1 VERSION

version 0.009

=head1 SYNOPSIS

    # in dist.ini:
    [Test::NewVersion]

=head1 DESCRIPTION

This L<Dist::Zilla> plugin generates a release test C<new-version.t>, which
checks the PAUSE index for latest version of each module, to confirm that
the version number(s) has been/have been incremented.

This is mostly useful only for distributions that do not automatically
increment their version from an external source, e.g.
L<Dist::Zilla::Plugin::Git::NextVersion>.

It is permitted for a module to have no version number at all, but if it is
set, it must have been incremented from the previous value, as otherwise this case
would be indistinguishable from developer error (forgetting to increment the
version), which is what we're testing for.  You can, however, explicitly
exclude some files from being checked, by passing your own
L<FileFinder|Dist::Zilla::Role::FileFinderUser/default_finders>.

=for Pod::Coverage register_prereqs gather_files munge_file

=head1 CONFIGURATION

This plugin takes as an optional setting:

=over 4

=item *

C<finders> - list the finder(s), one per line, that are to be used for

finding the modules to test.  Defaults to C<:InstallModules>; other
pre-defined options are listed in L<FileFinder|Dist::Zilla::Role::FileFinderUser/default_finders>.
You can define your own with the
L<Dist::Zilla::Plugin::FileFinder::ByName|[FileFinder::ByName]> plugin.

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Test-NewVersion>
(or L<bug-Dist-Zilla-Plugin-Test-NewVersion@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-Test-NewVersion@rt.cpan.org>).
I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla::Plugin::CheckVersionIncrement>

=back

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
___[ xt/release/new-version.t ]___
# this test was generated with {{ ref($plugin) . ' ' . ($plugin->VERSION || '<self>') }}

use strict;
use warnings FATAL => 'all';

use Test::More 0.88;
use Encode;
use HTTP::Tiny;
use JSON;
use version;
use Module::Metadata;
use List::Util 'first';
use CPAN::Meta 2.120920;

# 'provides' field from dist metadata, if needed
my $dist_provides;

# returns bool, detailed message
sub version_is_bumped
{
    my ($module_metadata, $pkg) = @_;

    my $res = HTTP::Tiny->new->get("http://cpanidx.org/cpanidx/json/mod/$pkg");
    return (0, 'index could not be queried?') if not $res->{success};

    # JSON wants UTF-8 bytestreams, so we need to re-encode no matter what
    # encoding we got. -- rjbs, 2011-08-18 (in
    # Dist::Zilla::Plugin::CheckPrereqsIndexed)
    my $json_octets = Encode::encode_utf8($res->{content});
    my $payload = JSON::->new->decode($json_octets);

    return (0, 'no valid JSON returned') unless $payload;

    return (1, 'not indexed') if not defined $payload->[0]{mod_vers};
    return (1, 'VERSION is not set in index') if $payload->[0]{mod_vers} eq 'undef';

    my $indexed_version = version->parse($payload->[0]{mod_vers});
    my $current_version = $module_metadata->version($pkg);

    if (not defined $current_version)
    {
        $dist_provides ||= do {
            my $metafile = first { -e $_ } qw(MYMETA.json MYMETA.yml META.json META.yml);
            my $dist_metadata = $metafile ? CPAN::Meta->load_file($metafile) : undef;
            $dist_metadata->provides if $dist_metadata;
        };

        $current_version = $dist_provides->{$pkg}{version};
        return (0, 'VERSION is not set; indexed version is ' . $indexed_version)
            if not $dist_provides or not $current_version;
    }

    return (
        $indexed_version < $current_version,
        'indexed at ' . $indexed_version . '; local version is ' . $current_version,
    );
}

foreach my $filename (
{{ join(",\n", map { '    "' . quotemeta($_) . '"' } sort @files) }}
)
{
    my $module_metadata = Module::Metadata->new_from_file($filename);
    foreach my $pkg ($module_metadata->packages_inside)
    {
        my ($bumped, $message) = version_is_bumped($module_metadata, $pkg);
        ok($bumped, $pkg . ' (' . $filename . ') VERSION is ok'
            . ( $message ? (' (' . $message . ')') : '' )
        );
    }
}

done_testing;
__END__
