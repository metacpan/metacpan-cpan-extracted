package Dist::Conformance::Update 0.001;

# ABSTRACT: What an update changed, or would change, in a checkout, and what it left to a person

use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Mojo::Base -base, -signatures;


has 'snapshot';
has dry_run => 0;
has changes => sub { [] };
has manual  => sub { [] };


sub new ( $class, @args ) {
    my $self     = $class->SUPER::new(@args);
    my $snapshot = $self->snapshot;
    die "An update needs a snapshot that it can write, such as a Dist::Conformance::Snapshot::Directory\n" if !$snapshot || !$snapshot->writable;
    return $self;
}


sub write ( $self, $path, $bytes, $mode = oct 644 ) {    ## no critic (Subroutines::ProhibitBuiltinHomonyms) -- a method, never called as the builtin
    my $snapshot = $self->snapshot;
    my $old      = $snapshot->content($path);
    return 0                                 if defined $old && $old eq $bytes;
    $snapshot->write( $path, $bytes, $mode ) if !$self->dry_run;
    push @{ $self->changes }, { action => defined $old ? 'replace' : 'create', path => $path };
    return 1;
}


sub install_hook ( $self, $name, $bytes ) {
    my $snapshot = $self->snapshot;
    my $dir      = $snapshot->hooks_dir;
    if ( !defined $dir ) {
        $self->by_hand( 'Install the hook ' . $name . ': ' . $snapshot->root . ' is not a git checkout' );
        return 0;
    }
    my $installed = $snapshot->installed_hook($name);
    return 0                                 if defined $installed && $installed eq $bytes;
    $snapshot->install_hook( $name, $bytes ) if !$self->dry_run;
    my $hook = $dir->child($name);
    push @{ $self->changes }, { action => 'install', path => $hook->to_rel( $snapshot->root )->to_string };
    return 1;
}


sub by_hand ( $self, @sentences ) {
    push @{ $self->manual }, @sentences;
    return;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Conformance::Update - What an update changed, or would change, in a checkout, and what it left to a person

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use 5.040;
    use Dist::Conformance::Snapshot::Directory;
    use Dist::Conformance::Update;

    my $update = Dist::Conformance::Update->new(
        snapshot => Dist::Conformance::Snapshot::Directory->new( root => '/bogus/checkout' ),
        dry_run  => 1,
    );
    $update->write( '.perltidyrc', "-l=400\n" );
    $update->by_hand('Write the prose of CLAUDE.md');
    say "$_->{action} $_->{path}" for @{ $update->changes };

=head1 DESCRIPTION

A check's C<update> does not write to the checkout itself.  It calls the
methods of this object, which write unless this is a dry run, and keep a record
either way.  So a dry run takes the same path through every check as a real
one, and says what the real one would change.

A check runs with an object of its own, so the record of an update is the
record of one check.

=head1 ATTRIBUTES

=head2 snapshot

Required.  The writable L<Dist::Conformance::Snapshot> to change.

=head2 dry_run

When true, nothing is written, and the changes are what would be written.

=head2 changes

The changes, in the order they were made: hash references with an C<action>,
which is C<create>, C<replace> or C<install>, and a C<path>.

=head2 manual

The things that no check could do, as sentences for a person.

=head1 METHODS

=head2 new

Dies unless L</snapshot> is writable.

=head2 write

C<($path, $bytes, $mode)>.  Writes C<$bytes> to C<$path> in the snapshot, with
C<$mode>, default 0644, and records a C<create> or a C<replace>.  A file that
already has these bytes is left alone, and nothing is recorded, so a second
update after the first has nothing to do.

=head2 install_hook

C<($name, $bytes)>.  Installs C<$bytes> as the git hook C<$name> of the
checkout, and records an C<install> of the hook's path, unless the hook that is
installed has these bytes already.  When the snapshot is not a git checkout, it
records a line for L</manual> instead.

=head2 by_hand

C<(@sentences)>.  Records what a person has to do, because no check can do it
safely.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Conformance|Dist::Conformance>

=item *

L<Dist::Conformance::Check>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/Troglodyne-Internet-Widgets/Dist-Conformance/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
