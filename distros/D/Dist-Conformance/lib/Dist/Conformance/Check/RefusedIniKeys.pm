package Dist::Conformance::Check::RefusedIniKeys 0.004;

# ABSTRACT: An INI file, such as dist.ini, sets no key that the flavor refuses, and the update removes each one

use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Mojo::Base 'Dist::Conformance::Check', -signatures;

use Config::INI::Reader();

use Dist::Conformance::Schema();


sub config_schema ($) {
    return {
        required   => [qw{file refuse}],
        properties => {
            file   => $Dist::Conformance::Schema::PATH,
            refuse => {
                type                 => 'object',
                minProperties        => 1,
                additionalProperties => {
                    type                 => 'object',
                    minProperties        => 1,
                    additionalProperties => { type => 'string', minLength => 1 },
                },
            },
            missing => { %$Dist::Conformance::Schema::STATUS, default => 'info' },
        },
    };
}


sub refused ( $self, $text ) {
    my $config = $self->config;
    Dist::Conformance::Schema::parse_ini( $text, $config->{file} );
    my $reader = Config::INI::Reader->new;
    my ( $keys, $section ) = ( $config->{refuse}{_}, '_' );
    my @refused;
    my @lines = split /^/, $text;
    for my $index ( 0 .. $#lines ) {
        my $line = $lines[$index];
        $reader->preprocess_line( \$line );
        next if $reader->can_ignore($line);
        if ( defined( my $header = $reader->parse_section_header($line) ) ) {
            my ($plugin) = $header =~ m{\A(.+?)(?:\s*/.*)?\z};
            ( $keys, $section ) = ( $config->{refuse}{$plugin}, $header );
            next;
        }
        next if !$keys;
        my ($key) = $reader->parse_value_assignment($line);
        push @refused, { line => $index, section => $section, key => $key, reason => $keys->{$key} } if defined $key && exists $keys->{$key};
    }
    return @refused;
}


sub check ( $self, $snapshot ) {
    my $file    = $self->config->{file};
    my $text    = $snapshot->content($file) // return ( $self->config->{missing}, "there is no $file" );
    my @refused = eval { $self->refused($text) };
    return ( 'fail', Dist::Conformance::Schema::first_line($@) ) if $@;
    return ( 'pass', 'sets no key that the flavor refuses' )     if !@refused;
    return ( 'fail', "$file sets " . join '; ', map { "$_->{key} in [$_->{section}], which $_->{reason}" } @refused );
}


sub update ( $self, $update ) {
    my $file    = $self->config->{file};
    my $text    = $update->snapshot->content($file) // return;
    my @refused = eval { $self->refused($text) };
    if ($@) {
        $update->by_hand( Dist::Conformance::Schema::first_line($@) . ': fix it by hand' );
        return;
    }
    return if !@refused;
    my %remove = map { $_->{line} => 1 } @refused;
    my @lines  = split /^/, $text;
    $update->write( $file, join q{}, @lines[ grep { !$remove{$_} } 0 .. $#lines ] );
    return;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Conformance::Check::RefusedIniKeys - An INI file, such as dist.ini, sets no key that the flavor refuses, and the update removes each one

=head1 VERSION

version 0.004

=head1 DESCRIPTION

Some keys of an INI file do harm wherever they are set, and the fix is always
to remove them.  C<user> under C<[GithubMeta]> in F<dist.ini> is one: it
overrides the account in the URL of the origin remote, so the metadata of the
distribution can name the wrong repository.  L<Dist::Conformance::Check::DataSchema>
can refuse such a key, but it cannot remove it, because a schema says what is
wrong and not how to fix it.

This check fails when a section of C<file> sets a key that C<refuse> names for
it, and the detail names each such key, its section and the reason.  It passes
when there is none.  The file is read as
L<Dist::Conformance::Schema/parse_ini> reads it, and a file that does not parse
fails.

A section of C<refuse> is the name of a plugin.  It matches the section with
that header, and each section with that header followed by C</> and a name of
its own, as Dist::Zilla writes a plugin that it loads twice: C<GithubMeta>
matches C<[GithubMeta]> and C<[GithubMeta / Meta]>.  The keys before the first
header are in the section C<_>.

The update removes each line that sets a refused key, and nothing else.  It
edits the file as text, so every other line, every comment and the order stay
as they were.  The lines are found by the methods of L<Config::INI::Reader>
that read the file, so the update removes what the check reads.  A file that
does not parse is left for a person.

=head1 METHODS

=head2 refused

C<($text)>.  The lines of the INI file C<$text> that set a refused key, in
their order, as hash references with the C<line>, counted from 0, the
C<section>, the C<key> and the C<reason>.  Dies when the text does not parse.

=head2 check

C<($snapshot)>.  The status and the detail that L</DESCRIPTION> says, for the
file in C<$snapshot>.

=head2 update

Removes each line that sets a refused key, or says what is wrong when the file
does not parse.

=head1 IN A FLAVOR

    checks:
      GithubMetaFromRemote:
        module: RefusedIniKeys
        file: dist.ini
        refuse:
          GithubMeta:
            user: overrides the account in the URL of the origin remote

=head1 CONFIGURATION

=over

=item file

Required.  The path of the INI file.

=item refuse

Required.  A mapping from the name of a plugin to a mapping from each key that
it must not set to the reason, which the detail gives.

=item missing

The status when the file is absent.  Default C<info>, because a repository without the file sets no key of it.

=back

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Conformance|Dist::Conformance>

=item *

L<Dist::Conformance::Check>

=item *

L<Dist::Conformance::Check::DataSchema>

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
