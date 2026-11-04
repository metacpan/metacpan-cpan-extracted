package Dist::Conformance::Check::CriticProfile 0.001;

# ABSTRACT: The perlcritic profile starts with the header of its template

use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Mojo::Base 'Dist::Conformance::Check', -signatures;

use List::Util();

use Dist::Conformance::Schema();


sub config_schema ($) {
    return {
        required   => [qw{file template}],
        properties => {
            file     => $Dist::Conformance::Schema::PATH,
            template => $Dist::Conformance::Schema::PATH,
            header   => { type => 'string',  minLength => 1 },
            outdated => { type => 'array',   items     => { type => 'string', minLength => 1 }, default => [] },
            replace  => { type => 'boolean', default   => 0 },
        },
    };
}


sub header ($self) {
    return $self->config->{header} // first_line( ( $self->template( $self->config->{template} ) )[0] );
}


sub check ( $self, $snapshot ) {
    my $file  = $self->config->{file};
    my $text  = $snapshot->content($file) // return ( 'fail', "$file is missing" );
    my $first = first_line($text);
    return ( 'pass', 'the current profile' )         if index( $first, $self->header ) == 0;
    return ( 'fail', "an outdated profile: $first" ) if List::Util::any { index( $first, $_ ) == 0 } @{ $self->config->{outdated} };
    return ( 'fail', "not a profile of this standard: $first" );
}


sub update ( $self, $update ) {
    my ( $file,   $template ) = @{ $self->config }{qw{file template}};
    my ( $status, $detail )   = $self->check( $update->snapshot );
    return if $status eq 'pass';
    if ( $update->snapshot->contains($file) && !$self->config->{replace} ) {
        $update->by_hand("$file is $detail: bring it up to $template by hand, keeping its own changes, or set replace: true to overwrite it");
        return;
    }
    $self->write_template( $update, $file, $template );
    return;
}


sub first_line ($text) {
    my ($first) = split /\n/, $text // q{};
    return $first // q{};
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Conformance::Check::CriticProfile - The perlcritic profile starts with the header of its template

=head1 VERSION

version 0.001

=head1 DESCRIPTION

A profile is told apart by its first line.  The two profiles of the
packaging-perl skill each start with a header that says which perl it is for,
so the strict flavor and the compat flavor name different templates, and each
expects the header of its own.

The check passes when the first line of the file starts with C<header>.  It
fails when the file is missing, when the first line starts with one of
C<outdated>, which is an older profile of the same standard, or a profile for
another perl, and when it starts with neither.  The detail quotes the first
line.

The update writes the template when the file is missing.  A profile that is
there but differs usually has changes of its own, such as exemptions, so it is
replaced only when C<replace> is true; otherwise the update says to merge the
template by hand.

=head1 METHODS

=head2 header

The C<header>, or the first line of the template.

=head2 check

=head2 update

Writes the template when the profile is missing, or when it is not current and
C<replace> is true.

=head1 FUNCTIONS

=head2 first_line

C<($text)>.  The first line of C<$text>, without its newline.

=head1 IN A FLAVOR

    checks:
      CriticProfile:
        file: .perlcriticrc
        template: templates/perlcriticrc
        outdated:
          - '# Troglodyne perlcritic policy'
        replace: false

=head1 CONFIGURATION

=over

=item file

Required.  The path of the profile.

=item template

Required.  The template of the current profile.

=item header

The text that the first line of a current profile starts with.  Default the
first line of the template, with its variables filled in.

=item outdated

Texts that the first line of an older profile starts with.  Default none.

=item replace

Whether an update overwrites a profile that is not current.  Default false.

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
