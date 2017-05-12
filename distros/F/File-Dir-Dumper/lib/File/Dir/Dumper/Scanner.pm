package File::Dir::Dumper::Scanner;
$File::Dir::Dumper::Scanner::VERSION = 'v0.4.0';
use warnings;
use strict;
use autodie;

use 5.012;

use parent 'File::Dir::Dumper::Base';

use Carp;

use File::Find::Object;
use Devel::CheckOS qw(:booleans);

use POSIX qw(strftime);
use List::Util qw(min);

use Class::XSAccessor
    accessors => {
        _digest_cache => '_digest_cache',
        _digests => '_digests',
        _file_find => '_file_find',
        _group_cache => '_group_cache',
        _last_result => '_last_result',
        _queue => '_queue',
        _reached_end => '_reached_end',
        _result => '_result',
        _user_cache => '_user_cache',
    };

use Digest ();

sub _init
{
    my $self = shift;
    my $args = shift;

    my $dir_to_dump = $args->{dir};

    $self->_file_find(
        File::Find::Object->new(
            {
                followlink => 0,
            },
            $dir_to_dump,
        )
    );

    $self->_queue([]);

    $self->_add({ type => "header", dir_to_dump => $dir_to_dump, stream_type => "Directory Dump"});

    $self->_digests(undef());
    if (exists($args->{digests}))
    {
        my $digests = {};
        foreach my $d (@{ $args->{digests} })
        {
            if (exists $digests->{$d})
            {
                Carp::confess( "Duplicate digest '$d'!" );
            }
            $digests->{$d} = 1;
        }
        if (! %$digests)
        {
            Carp::confess( "The list of digests is empty." );
        }
        $self->_digests([sort {$a cmp $b} keys%$digests]);
    }
    my $base = ($args->{digest_cache} || 'Dummy');
    if ($base !~ /\A[A-Za-z_][A-Za-z_0-9]*\z/)
    {
        Carp::confess( "Invalid digest_cache format." );
    }
    my $cl = "File::Dir::Dumper::DigestCache::$base";
    eval "require $cl";
    if ($@)
    {
        die $@;
    }
    $self->_digest_cache(
        scalar $cl->new(
            {
                params => ($args->{digest_cache_params} || +{}),

            }
        )
    );

    $self->_user_cache({});
    $self->_group_cache({});

    return;
}

sub _add
{
    my $self = shift;
    my $token = shift;

    push @{$self->_queue()}, $token;

    return;
}

sub fetch
{
    my $self = shift;

    if (! @{$self->_queue()})
    {
        $self->_populate_queue();
    }

    return shift(@{$self->_queue()});
}

sub _up_to_level
{
    my $self = shift;
    my $target_level = shift;

    my $last_result = $self->_last_result();

    for my $level (
        reverse($target_level .. $#{$last_result->dir_components()})
    )
    {
        $self->_add(
            {
                type => "updir",
                depth => $level+1,
            }
        )
    }

    return;
}

sub _find_new_common_depth
{
    my $self = shift;

    my $result = $self->_result();
    my $last_result = $self->_last_result();

    my $depth = 0;

    my $upper_limit =
        min(
            scalar(@{$last_result->dir_components()}),
            scalar(@{$result->dir_components()}),
        );

    FIND_I:
    while ($depth < $upper_limit)
    {
        if ($last_result->dir_components()->[$depth] ne
            $result->dir_components()->[$depth]
        )
        {
            last FIND_I;
        }
    }
    continue
    {
        $depth++;
    }

    return $depth;
}

BEGIN
{
    if (os_is('Unix'))
    {
        *_my_getpwuid =
            sub {
                my $uid = shift; return scalar(getpwuid($uid));
            };
        *_my_getgrgid =
            sub {
                my $gid = shift; return scalar(getgrgid($gid));
            };
    }
    else
    {
        *_my_getpwuid = sub { return "unknown"; };
        *_my_getgrgid = sub { return "unknown"; };
    }
}

sub _get_user_name
{
    my $self = shift;
    my $uid = shift;

    if (!exists($self->_user_cache()->{$uid}))
    {
        $self->_user_cache()->{$uid} = _my_getpwuid($uid);
    }

    return $self->_user_cache()->{$uid};
}

sub _get_group_name
{
    my $self = shift;
    my $gid = shift;

    if (!exists($self->_group_cache()->{$gid}))
    {
        $self->_group_cache()->{$gid} = _my_getgrgid($gid);
    }

    return $self->_group_cache()->{$gid};
}

sub _calc_file_digests_key
{
    my ($self, $stat) = @_;

    my $digests = $self->_digests;

    if (!defined$digests)
    {
        return [];
    }
    my $result = $self->_result();
    my $path = $result->path;
    my $ret = $self->_digest_cache->get_digests(
        {
            path => $result->full_components,
            mtime => $stat->[9],
            digests => $digests,
            calc_cb => sub {
                my %ret;
                foreach my $d (@$digests)
                {
                    my $o = Digest->new($d);
                    open my $fh, '<', $path;
                    binmode $fh;
                    $o->addfile($fh);
                    $ret{$d} = $o->hexdigest;
                    close ($fh);
                }
                return \%ret;
            },
        }
    );
    return [digests => $ret,];
}

sub _calc_file_or_dir_token
{
    my $self = shift;

    my $result = $self->_result();

    my @stat = stat($result->path());

    return
    {
        filename => $result->full_components()->[-1],
        depth => scalar(@{$result->full_components()}),
        perms => sprintf("%04o", ($stat[2]&07777)),
        mtime => strftime("%Y-%m-%dT%H:%M:%S", localtime($stat[9])),
        user => $self->_get_user_name($stat[4]),
        group => $self->_get_group_name($stat[5]),
        ($result->is_dir()
            ? (type => "dir",)
            : (
                type => "file",
                size => $stat[7],
                @{$self->_calc_file_digests_key(\@stat)},
            )
        ),
    };
}

sub _populate_queue
{
    my $self = shift;

    if ($self->_reached_end())
    {
        return;
    }

    $self->_result($self->_file_find->next_obj());

    if (! $self->_last_result())
    {
        $self->_add({ type => "dir", depth => 0 });
    }
    elsif (! $self->_result())
    {
        $self->_up_to_level(-1);

        $self->_add({type => "footer"});

        $self->_reached_end(1);
    }
    else
    {
        $self->_up_to_level($self->_find_new_common_depth());

        $self->_add(
            $self->_calc_file_or_dir_token()
        );
    }

    $self->_last_result($self->_result());
}


1; # End of File::Dir::Dumper

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Dir::Dumper::Scanner - scans a directory and returns a stream of Perl
hash-refs

=head1 VERSION

version v0.4.0

=head1 SYNOPSIS

    use File::Dir::Dumper::Scanner;

    my $scanner = File::Dir::Dumper::Scanner->new(
        {
            dir => $dir_pathname
        }
    );

    while (defined(my $token = $scanner->fetch()))
    {
    }

=head1 VERSION

version v0.4.0

=head1 METHODS

=head2 $self->new({ dir => $dir_path, digests => [LIST]})

Scans the directory $dir_path with the L<Digest>'s digests as contained
in the list of strings pointed by the digests array reference. C<digests>
is optional.

=head2 my $hash_ref = $self->fetch()

Outputs the next token as a hash ref.

=head1 AUTHOR

Shlomi Fish, C<< <shlomif@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-dir-dumper at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Dir-Dumper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Dir::Dumper

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Dir-Dumper>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Dir-Dumper>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-Dir-Dumper>

=item * Search CPAN

L<http://search.cpan.org/dist/File-Dir-Dumper>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT/X11 Licence.

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/file-dir-dumper/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc File::Dir::Dumper

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/File-Dir-Dumper>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/File-Dir-Dumper>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=File-Dir-Dumper>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/File-Dir-Dumper>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/File-Dir-Dumper>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/File-Dir-Dumper>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/File-Dir-Dumper>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/F/File-Dir-Dumper>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=File-Dir-Dumper>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=File::Dir::Dumper>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-file-dir-dumper at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=File-Dir-Dumper>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-File-Dir-Dumper>

  git clone https://github.com/shlomif/perl-File-Dir-Dumper

=cut
