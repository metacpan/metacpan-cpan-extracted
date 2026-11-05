package Dist::Conformance::Check::Workflows 0.002;

# ABSTRACT: The CI workflows exist

use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Mojo::Base 'Dist::Conformance::Check', -signatures;

use Dist::Conformance::Schema();


sub config_schema ($) {
    return {
        required   => ['directory'],
        properties => {
            directory => $Dist::Conformance::Schema::PATH,
            required  => { type => 'object', additionalProperties => { %$Dist::Conformance::Schema::PATH, nullable => 1 }, default => {} },
        },
    };
}


sub missing_workflows ( $self, $snapshot ) {
    my ( $directory, $required ) = @{ $self->config }{qw{directory required}};
    my @missing = grep { !$snapshot->contains("$directory/$_") } sort keys %$required;
    return @missing;
}


sub check ( $self, $snapshot ) {
    my ( $directory, $required ) = @{ $self->config }{qw{directory required}};
    if ( !%$required ) {
        my @have = grep { index( $_, q{/} ) < 0 } $snapshot->under($directory);
        return ( 'info', @have ? 'present: ' . join ', ', @have : 'none' );
    }
    my @missing = $self->missing_workflows($snapshot);
    return ( 'fail', 'missing: ' . join ', ', map { "$directory/$_" } @missing ) if @missing;
    return ( 'pass', 'all present' );
}


sub update ( $self, $update ) {
    my ( $directory, $required ) = @{ $self->config }{qw{directory required}};
    for my $name ( $self->missing_workflows( $update->snapshot ) ) {
        if ( defined $required->{$name} ) {
            $self->write_template( $update, "$directory/$name", $required->{$name} );
        }
        else {
            $update->by_hand("Write $directory/$name by hand: the flavor names no template for it");
        }
    }
    return;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Conformance::Check::Workflows - The CI workflows exist

=head1 VERSION

version 0.002

=head1 DESCRIPTION

The workflow files in C<directory>.  With none in C<required>, the check only
lists the ones present, as C<info>.  Otherwise it fails when a required
workflow is missing, and passes when none is.

The update writes each missing workflow from its template.

=head1 METHODS

=head2 missing_workflows

C<($snapshot)>.  The required workflows that the snapshot does not have.

=head2 check

=head2 update

Writes each missing workflow from its template.

=head1 IN A FLAVOR

    checks:
      Workflows:
        directory: .github/workflows
        required:
          ci.yml: templates/workflows/ci.yml

=head1 CONFIGURATION

=over

=item directory

Required.  The directory of the workflows.

=item required

A mapping from the file name of each workflow that must exist to its template.
A workflow whose template is C<~> must exist, and the update says to write it by
hand.  Default none.

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
