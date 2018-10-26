package JSON::Patch;

use 5.006;
use strict;
use warnings FATAL => 'all';
use parent 'Exporter';

use Carp qw(croak);
use Struct::Diff 0.96;
use Struct::Path 0.82 qw(path);
use Struct::Path::JsonPointer 0.04 qw(path2str str2path);

our @EXPORT_OK = qw(
    diff
    patch
);

=head1 NAME

JSON::Patch - JSON Patch (rfc6902) for perl structures

=begin html

<a href="https://travis-ci.org/mr-mixas/JSON-Patch.pm"><img src="https://travis-ci.org/mr-mixas/JSON-Patch.pm.svg?branch=master" alt="Travis CI"></a>
<a href='https://coveralls.io/github/mr-mixas/JSON-Patch.pm?branch=master'><img src='https://coveralls.io/repos/github/mr-mixas/JSON-Patch.pm/badge.svg?branch=master' alt='Coverage Status'/></a>
<a href="https://badge.fury.io/pl/JSON-Patch"><img src="https://badge.fury.io/pl/JSON-Patch.svg" alt="CPAN version"></a>

=end html

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

    use Test::More tests => 2;
    use JSON::Patch qw(diff patch);

    my $old = {foo => ['bar']};
    my $new = {foo => ['bar', 'baz']};

    my $patch = diff($old, $new);
    is_deeply(
        $patch,
        [
            {op => 'add', path => '/foo/1', value => 'baz'}
        ]
    );

    patch($old, $patch);
    is_deeply($old, $new);

=head1 EXPORT

Nothing is exported by default.

=head1 SUBROUTINES

=head2 diff

Calculate patch for two arguments:

    $patch = diff($old, $new);

Convert L<Struct::Diff> diff to JSON Patch when single arg passed:

    require Struct::Diff;
    $patch = diff(Struct::Diff::diff($old, $new));

=cut

sub diff($;$) {
    my $diff = @_ == 2
        ? Struct::Diff::diff($_[0], $_[1], noO => 1, noU => 1, trimR => 1)
        : $_[0];
    my @stask = Struct::Diff::list_diff($diff, sort => 1);

    my ($hunk, @patch, $path);

    while (@stask) {
        ($path, $hunk) = splice @stask, -2, 2;

        if (exists ${$hunk}->{A}) {
            push @patch, {op => 'add', value => ${$hunk}->{A}};
        } elsif (exists ${$hunk}->{N}) {
            push @patch, {op => 'replace', value => ${$hunk}->{N}};
        } elsif (exists ${$hunk}->{R}) {
            push @patch, {op => 'remove'};
        } else {
            next;
        }

        $patch[-1]->{path} = path2str($path);
    }

    return \@patch;
}

=head2 patch

Apply patch.

    patch($target, $patch);

=cut

sub patch($$) {
    croak "Arrayref expected for patch" unless (ref $_[1] eq 'ARRAY');

    for my $hunk (@{$_[1]}) {
        croak "Hashref expected for patch item" unless (ref $hunk eq 'HASH');
        croak "Undefined op value" unless (defined $hunk->{op});
        croak "Path parameter missing" unless (exists $hunk->{path});

        my $path = eval { str2path($hunk->{path}) }
            or croak "Failed to parse 'path' pointer";

        if ($hunk->{op} eq 'add' or $hunk->{op} eq 'replace') {
            croak "Value parameter missing" unless (exists $hunk->{value});
            path(
                $_[0],
                $path,
                assign => $hunk->{value},
                expand => 1,
                insert => $hunk->{op} eq 'add',
                strict => 1,
            );

        } elsif ($hunk->{op} eq 'remove') {
            eval { path($_[0], $path, delete => 1) } or
                croak "Path does not exist";

        } elsif ($hunk->{op} eq 'move' or $hunk->{op} eq 'copy') {
            my $from = eval { str2path($hunk->{from}) } or
                croak "Failed to parse 'from' pointer";
            my @found = path(
                $_[0],
                $from,
                delete => $hunk->{op} eq 'move',
                deref => 1
            );
            croak "Source path does not exist" unless (@found);

            path($_[0], $path, assign => $found[0], expand => 1);

        } elsif ($hunk->{op} eq 'test') {
            croak "Value parameter missing" unless (exists $hunk->{value});
            my @found = path($_[0], $path, deref => 1) or
                croak "Path does not exist";
            my $diff = Struct::Diff::diff($found[0], $hunk->{value}, noU => 1);
            croak "Test failed" if (keys %{$diff});

        } else {
            croak "Unsupported op '$hunk->{op}'";
        }
    }
}

=head1 AUTHOR

Michael Samoglyadov, C<< <mixas at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-json-patch at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=JSON-Patch>. I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc JSON::Patch

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=JSON-Patch>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/JSON-Patch>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/JSON-Patch>

=item * Search CPAN

L<http://search.cpan.org/dist/JSON-Patch/>

=back

=head1 SEE ALSO

L<rfc6902|https://tools.ietf.org/html/rfc6902>,
L<Struct::Diff>, L<Struct::Diff::MergePatch>

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Michael Samoglyadov.

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1; # End of JSON::Patch
