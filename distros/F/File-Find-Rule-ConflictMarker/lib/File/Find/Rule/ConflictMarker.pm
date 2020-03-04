package File::Find::Rule::ConflictMarker;
use strict;
use warnings;
use parent qw/File::Find::Rule/;

our $VERSION = '0.02';

my $CONFLICT_MARKER_BASE    = '<' x 7;
my $CONFLICT_MARKER_DEVIDER = '=' x 7;
my $CONFLICT_MARKER_TARGET  = '>' x 7;
my $CONFLICT_MARKER_SOURCE  = '|' x 7;

my $CONFLICT_MARKER_COND = join '|', map { "\Q$_\E" } (
    $CONFLICT_MARKER_BASE,
    $CONFLICT_MARKER_DEVIDER,
    $CONFLICT_MARKER_TARGET,
    $CONFLICT_MARKER_SOURCE,
);

our $CONFLICT_MARKER_REGEX = qr/($CONFLICT_MARKER_COND)/;

sub File::Find::Rule::conflict_marker {
    my ($file_find_rule) = @_;

    my $self = $file_find_rule->_force_object;

    return $self->file->exec(sub{
        my ($file) = @_;

        open my $fh, '<', $file or die "Could not open $file, $!";
        my $content = do { local $/; <$fh>; };
        close $fh;

        return $content =~ m!$CONFLICT_MARKER_REGEX!;
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

File::Find::Rule::ConflictMarker - Conflict markers finder


=head1 SYNOPSIS

    use File::Find::Rule::ConflictMarker;

    my @files = File::Find::Rule->conflict_marker->relative->in($dir);

=head2 FOR TEST EXAMPLE

It might be helpful as xt/no_conflict.t

    use Test::More;

    eval "use File::Find::Rule::ConflictMarker;";

    plan skip_all => "skip the no conflict test because $@" if $@;

    my @files = File::Find::Rule->name('*.pm', '*.t')->conflict_marker->in('lib', 't', 'xt');

    ok( scalar(@files) == 0 )
        or die join("\t", map { "'$_' has conflict markers." } @files);

    done_testing;


=head1 DESCRIPTION

File::Find::Rule::ConflictMarker searches for the conflict markers C<E<lt>E<lt>E<lt>E<lt>E<lt>E<lt>E<lt>>, C<E<gt>E<gt>E<gt>E<gt>E<gt>E<gt>E<gt>>, C<E<verbar>E<verbar>E<verbar>E<verbar>E<verbar>E<verbar>E<verbar>> in files.


=head1 REPOSITORY

=begin html

<a href="https://github.com/bayashi/File-Find-Rule-ConflictMarker/blob/master/README.pod"><img src="https://img.shields.io/badge/Version-0.02-green?style=flat"></a> <a href="https://github.com/bayashi/File-Find-Rule-ConflictMarker/blob/master/LICENSE"><img src="https://img.shields.io/badge/LICENSE-Artistic%202.0-GREEN.png"></a> <a href="https://github.com/bayashi/File-Find-Rule-ConflictMarker/actions"><img src="https://github.com/bayashi/File-Find-Rule-ConflictMarker/workflows/master/badge.svg?_t=1583101213"/></a> <a href="https://coveralls.io/r/bayashi/File-Find-Rule-ConflictMarker"><img src="https://coveralls.io/repos/bayashi/File-Find-Rule-ConflictMarker/badge.png?_t=1583101213&branch=master"/></a>

=end html

File::Find::Rule::ConflictMarker is hosted on github: L<http://github.com/bayashi/File-Find-Rule-ConflictMarker>

I appreciate any feedback :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<File::Find::Rule>


=head1 LICENSE

C<File::Find::Rule::ConflictMarker> is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0. (Note that, unlike the Artistic License 1.0, version 2.0 is GPL compatible by itself, hence there is no benefit to having an Artistic 2.0 / GPL disjunction.) See the file LICENSE for details.

=cut
