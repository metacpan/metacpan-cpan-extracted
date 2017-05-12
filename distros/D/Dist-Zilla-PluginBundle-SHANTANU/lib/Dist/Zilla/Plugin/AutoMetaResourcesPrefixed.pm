use strict;
use warnings;

package Dist::Zilla::Plugin::AutoMetaResourcesPrefixed;

our $VERSION = '0.43'; #VERSION

use Moose;
extends 'Dist::Zilla::Plugin::AutoMetaResources';

sub _build__repository_map {

    # based on Dist::Zilla::PluginBundle::FLORA
    return {
        github => {
            url  => 'git://github.com/%{user}/perl-%{lcdist}.git',
            web  => 'https://github.com/%{user}/perl-%{lcdist}',
            type => 'git',
        },
        gitmo => {
            url => 'git://git.moose.perl.org/%{dist}.git',
            web =>
'http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=gitmo/%{dist}.git;a=summary',
            type => 'git',
        },
        catsvn => {
            url => 'http://dev.catalyst.perl.org/repos/Catalyst/%{dist}/',
            web =>
              'http://dev.catalystframework.org/svnweb/Catalyst/browse/%{dist}',
            type => 'svn',
        },
        (
            map {
                (
                    $_ => {
                        url => "git://git.shadowcat.co.uk/$_/%{dist}.git",
                        web =>
"http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=$_/%{dist}.git;a=summary",
                        type => 'git',
                    }
                  )
            } qw(catagits p5sagit dbsrgits)
        ),
    };
}

sub _build__bugtracker_map {
    return {
        rt => {
            web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=%{dist}',
            mailto => 'bug-%{dist}@rt.cpan.org',
        },
        github => {
            web => 'https://github.com/%{user}/perl-%{lcdist}/issues',
        }
    };
}

1;

__END__

=pod

=head1 NAME

Dist::Zilla::Plugin::AutoMetaResourcesPrefixed

=head1 VERSION

version 0.43

=head1 AUTHOR

Shantanu Bhadoria <shantanu@cpan.org> L<https://www.shantanubhadoria.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Shantanu Bhadoria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
