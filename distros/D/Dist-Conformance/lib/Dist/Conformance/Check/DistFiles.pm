package Dist::Conformance::Check::DistFiles 0.001;

# ABSTRACT: A distribution has the files that its build needs

use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Mojo::Base 'Dist::Conformance::Check::ToolConfiguration', -signatures;

use Dist::Conformance::Schema();


sub config_schema ($class) {
    my $schema = $class->SUPER::config_schema;
    return {
        required   => [ 'marker', @{ $schema->{required} } ],
        properties => {
            %{ $schema->{properties} },
            marker => $Dist::Conformance::Schema::PATH,
            absent => { %$Dist::Conformance::Schema::STATUS, default => 'info' },
        },
    };
}


sub check ( $self, $snapshot ) {
    my $marker = $self->config->{marker};
    return ( $self->config->{absent}, "no $marker" ) if !$snapshot->contains($marker);
    return $self->SUPER::check($snapshot);
}


sub update ( $self, $update ) {
    return if !$update->snapshot->contains( $self->config->{marker} );
    return $self->SUPER::update($update);
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Conformance::Check::DistFiles - A distribution has the files that its build needs

=head1 VERSION

version 0.001

=head1 DESCRIPTION

L<Dist::Conformance::Check::ToolConfiguration>, for a repository that has a
marker file.  A repository without F<dist.ini> is not a Dist::Zilla
distribution, so it needs no F<weaver.ini>.  Without the marker the check
reports C<absent> and the update does nothing.  With it, it is the same as
L<Dist::Conformance::Check::ToolConfiguration>.

A flavor for a repository that is never a distribution can remove this check
with C<DistFiles: ~>.

=head1 METHODS

=head2 check

=head2 update

Does nothing without the marker.

=head1 IN A FLAVOR

    checks:
      DistFiles:
        marker: dist.ini
        absent: info
        files:
          weaver.ini: templates/weaver.ini
          Changes: templates/Changes
          prereqs.yml: templates/prereqs.yml

=head1 CONFIGURATION

=over

=item marker

Required.  The path whose presence makes the repository one that needs the
files.

=item absent

The status without the marker.  Default C<info>.

=item files

Required.  As in L<Dist::Conformance::Check::ToolConfiguration>.

=back

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
