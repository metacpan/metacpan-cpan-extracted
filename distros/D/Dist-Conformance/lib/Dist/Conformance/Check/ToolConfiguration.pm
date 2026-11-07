package Dist::Conformance::Check::ToolConfiguration 0.003;

# ABSTRACT: The configuration files of the tools exist

use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Mojo::Base 'Dist::Conformance::Check', -signatures;

use Dist::Conformance::Schema();


sub config_schema ($) {
    return {
        required   => ['files'],
        properties => { files => { type => 'object', additionalProperties => { %$Dist::Conformance::Schema::PATH, nullable => 1 } } },
    };
}


sub check ( $self, $snapshot ) {
    my @missing = $self->missing( $snapshot, sort keys %{ $self->config->{files} } );
    return ( 'fail', 'missing: ' . join ', ', @missing ) if @missing;
    return ( 'pass', 'all present' );
}


sub update ( $self, $update ) {
    my $files = $self->config->{files};
    for my $path ( $self->missing( $update->snapshot, sort keys %$files ) ) {
        if ( defined $files->{$path} ) {
            $self->write_template( $update, $path, $files->{$path} );
        }
        else {
            $update->by_hand("Write $path by hand: the flavor names no template for it");
        }
    }
    return;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Conformance::Check::ToolConfiguration - The configuration files of the tools exist

=head1 VERSION

version 0.003

=head1 DESCRIPTION

Files that the tools of the harness read, such as perltidy, perlcritic and
tests-covering.  The check passes when every file exists, and fails with the
list of those that do not.  Their content is the repository's own: a stopword
list grows with the repository, so the check does not compare it with the
template.

The update writes each missing file from its template, and leaves a file that
exists alone.

=head1 METHODS

=head2 check

=head2 update

Writes each missing file from its template.

=head1 IN A FLAVOR

    checks:
      ToolConfiguration:
        files:
          .perltidyrc: templates/perltidyrc
          .preferred_modules.ini: templates/preferred_modules.ini
          .pod_stopwords: templates/pod_stopwords
          .tests-covering-map.pl: templates/tests-covering-map.pl

=head1 CONFIGURATION

=over

=item files

Required.  A mapping from each path to its template.  A path whose template is
C<~> must exist, and the update says to write it by hand.

=back

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Conformance|Dist::Conformance>

=item *

L<Dist::Conformance::Check>

=item *

L<Dist::Conformance::Check::DistFiles>

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
