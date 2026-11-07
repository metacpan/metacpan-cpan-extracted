package Dist::Conformance::Config 0.003;

# ABSTRACT: .conformance.yml, which picks the flavor of a repository and its source

use 5.040;
use warnings FATAL => 'all';
use re '/aasx';

use Dist::Conformance::Schema();


our $FILE = '.conformance.yml';

my $NOT_AN_OPTION = { type => 'string', minLength => 1, pattern => '\A[^-]' };

our %SCHEMA = (
    type                 => 'object',
    required             => [qw{flavor source}],
    additionalProperties => 0,
    properties           => {
        flavor => $Dist::Conformance::Schema::NAME,
        source => {
            oneOf => [
                {
                    type                 => 'object',
                    required             => ['git'],
                    additionalProperties => 0,
                    properties           => { git => $NOT_AN_OPTION, ref => $NOT_AN_OPTION, path => $Dist::Conformance::Schema::PATH },
                },
                {
                    type                 => 'object',
                    required             => ['directory'],
                    additionalProperties => 0,
                    properties           => { directory => { type => 'string', minLength => 1 }, path => $Dist::Conformance::Schema::PATH },
                },
            ],
        },
        skip      => { type => 'array',  items                => $Dist::Conformance::Schema::NAME, default => [] },
        checks    => { type => 'object', additionalProperties => { type => 'object' }, default => {} },
        variables => { type => 'object', additionalProperties => { type => 'string' }, default => {} },
    },
);


sub load ($snapshot) {
    my $text = $snapshot->content($FILE) // die("The repository has no $FILE, so it names no flavor\n");
    return validate( Dist::Conformance::Schema::parse_yaml( $text, $FILE ) );
}


sub validate ($data) {
    return Dist::Conformance::Schema::validate( $data, \%SCHEMA, $FILE );
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Conformance::Config - .conformance.yml, which picks the flavor of a repository and its source

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use 5.040;
    use Dist::Conformance::Config;
    use Dist::Conformance::Snapshot::Directory;

    my $config = Dist::Conformance::Config::load( Dist::Conformance::Snapshot::Directory->new( root => '/bogus/checkout' ) );
    say $config->{flavor};

=head1 DESCRIPTION

A repository says which standards it is held to in F<.conformance.yml> at its
root: which flavor, from which source, which checks it skips, and what it sets
differently from the flavor.

    # .conformance.yml
    flavor: troglodyne-5.040
    source:
      git: https://forge.test.test/standards.git
      ref: main
      path: skills/packaging-perl
    skip:
      - Workflows
    checks:
      ClaudeSettings:
        missing: fail
      GitHooks:
        replace: true
    variables:
      DIST: Foo-Bar
      AUTHOR_NAME: A. Tester
      AUTHOR_EMAIL: tester@test.test

=head1 FUNCTIONS

=head2 load

C<($snapshot)>.  The validated F<.conformance.yml> of the snapshot, with the
defaults filled in.  Dies when the file is missing, does not parse or is not
valid.

=head2 validate

C<($data)>.  C<$data> checked against C<%SCHEMA>, with the defaults filled in,
for a caller that has the configuration without the file.

=head1 KEYS

=over

=item flavor

Required.  The name of the flavor, which is the file
F<conformance/NAME.yml> of the source.

=item source

Required.  Where the standards are, as one of:

=over

=item C<< { git => URL, ref => REF, path => PATH } >>

A git repository.  C<ref> is a branch, a tag or a commit, default C<HEAD>, the
default branch.  See L<Dist::Conformance::Source::Git>.

=item C<< { directory => DIR, path => PATH } >>

A directory on this machine.  A relative C<DIR> is relative to the root of the
repository.  See L<Dist::Conformance::Source::Directory>.

=back

In both, C<path> is the directory inside the tree that holds F<conformance/>,
default the top.

=item skip

The names of the checks of the flavor not to run.  A skipped check is reported
as C<skip>, and an update does not touch what it would have changed.  Naming a
check that the flavor does not run is an error, so that a misspelling does not
quietly skip nothing.

=item checks

A mapping from the name of a check of the flavor to the settings that this
repository has differently, laid over the configuration of the flavor by
L<Dist::Conformance::Flavor/THE MERGE RULE>: each key replaces the same key of
the flavor, and a key set to C<~> is removed.  It cannot add a check that the
flavor does not run; write a flavor that extends it for that.

=item variables

Values for the placeholders of the templates, such as C<DIST>, laid over the
variables of the flavor.

=back

Every key is validated, and an error names the file and the key, such as
C<.conformance.yml is not valid: /skip/0: ...>.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Conformance|Dist::Conformance>

=item *

L<Dist::Conformance>

=item *

L<Dist::Conformance::Flavor>

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
