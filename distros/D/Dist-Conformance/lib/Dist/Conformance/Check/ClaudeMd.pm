package Dist::Conformance::Check::ClaudeMd 0.003;

# ABSTRACT: CLAUDE.md exists and names the skills that it must

use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Mojo::Base 'Dist::Conformance::Check', -signatures;

use Dist::Conformance::Schema();


sub config_schema ($) {
    return {
        required   => [qw{file mentions}],
        properties => {
            file     => $Dist::Conformance::Schema::PATH,
            mentions => { type => 'array', items => { type => 'string', minLength => 1 } },
            template => $Dist::Conformance::Schema::PATH,
        },
    };
}


sub check ( $self, $snapshot ) {
    my ( $file, $mentions ) = @{ $self->config }{qw{file mentions}};
    my $text   = $snapshot->content($file) // return ( 'fail', "$file is missing" );
    my @absent = grep { index( $text, $_ ) < 0 } @$mentions;
    return ( 'fail', "$file does not name " . join ', ', @absent ) if @absent;
    return ( 'pass', @$mentions ? 'names ' . join ', ',  @$mentions : "$file exists" );
}


sub update ( $self, $update ) {
    my ( $status, $detail ) = $self->check( $update->snapshot );
    return if $status ne 'fail';
    my $start = defined $self->config->{template} ? ', starting from ' . $self->config->{template} : q{};
    $update->by_hand("$detail: write it by hand$start, because its prose cannot be generated");
    return;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Conformance::Check::ClaudeMd - CLAUDE.md exists and names the skills that it must

=head1 VERSION

version 0.003

=head1 DESCRIPTION

The instructions that an agent reads first.  The check passes when the file
exists and contains each string of C<mentions>.  It fails when the file is
missing, or when a string is not in it.

Its update writes nothing.  What the file says about a repository is prose that
a person writes, so the update names the file, the template to start from, and
what the file lacks.

=head1 METHODS

=head2 check

=head2 update

Records what the file needs, for a person.

=head1 IN A FLAVOR

    checks:
      ClaudeMd:
        file: CLAUDE.md
        template: templates/CLAUDE.md
        mentions:
          - perl-slop:reading-perl

=head1 CONFIGURATION

=over

=item file

Required.  The path of the file.

=item mentions

Required.  The strings that the file must contain, such as the names of the
skills that it tells an agent to load.  An empty list asks only that the file
exist.

=item template

The template that a person starts from, named in the update.

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
