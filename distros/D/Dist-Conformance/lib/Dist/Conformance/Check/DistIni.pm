package Dist::Conformance::Check::DistIni 0.011;

# ABSTRACT: dist.ini is its template, with the overrides of the repository, authordeps included

use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
no autovivification;
use Mojo::Base 'Dist::Conformance::Check::IniTemplate', -signatures;

use Dist::Conformance::Check::AuthorDeps();


sub config_schema ($class) {
    my $schema = $class->SUPER::config_schema;
    $schema->{properties}{authordeps} = Dist::Conformance::Check::AuthorDeps->config_schema->{properties}{overrides};
    return $schema;
}

sub expected ( $self, $snapshot = undef ) {
    my $text = $self->SUPER::expected($snapshot);
    return Dist::Conformance::Check::AuthorDeps::with_overrides( $text, $self->config->{authordeps}, $snapshot );
}

sub compare ( $self, $text, $want ) {
    return ( $self->SUPER::compare( $text, $want ), Dist::Conformance::Check::AuthorDeps::authordep_differences( $text, $want ) );
}

sub adopt ( $self, $snapshot ) {
    my ( $file, $template ) = @{ $self->config }{qw{file template}};
    my $text    = $snapshot->content($file) // return;
    my %adopted = %{ $self->SUPER::adopt($snapshot) // {} };

    my ($filled) = $self->template($template);
    my %want = map { $_->{module} => $_->{version} } grep { local ($_) = $_; !Dist::Conformance::Check::AuthorDeps::own_module( $snapshot, $_->{module} ) } Dist::Conformance::Check::AuthorDeps::authordeps_of($filled);
    my %authordeps;
    for my $dep ( Dist::Conformance::Check::AuthorDeps::authordeps_of($text) ) {
        my ( $module, $version ) = @{$dep}{qw{module version}};
        next                            if Dist::Conformance::Check::AuthorDeps::own_module( $snapshot, $module );
        $authordeps{$module} = $version if !exists $want{$module} || $want{$module} ne $version;
    }
    $adopted{authordeps} = \%authordeps if %authordeps;
    return %adopted ? \%adopted : undef;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Conformance::Check::DistIni - dist.ini is its template, with the overrides of the repository, authordeps included

=head1 VERSION

version 0.011

=head1 DESCRIPTION

F<dist.ini> is the template with the overrides of the repository, as
L<Dist::Conformance::Check::IniTemplate> says, read as Dist::Zilla reads it.
The values that differ from one distribution to the next, such as its name and
its author, are the variables of the template, which F<.conformance.yml> sets.

The authordeps of F<dist.ini> are comments, which the reader of the file never
sees, so this check holds them to the template as well.  The authordep lines of
the file are those of the template with C<authordeps> applied, as
L<Dist::Conformance::Check::AuthorDeps> reads them: C<off> leaves the
authordep of a module out, a version replaces the template's, and a module
that the template does not name gets a line after its last authordep.  An
authordep of a module that the repository has under F<lib/> is left out,
because a distribution builds with its own modules.

The check fails for each section, key and authordep that differs, and the
update writes the text.  C<conformance adopt> prints the overrides, positions,
settings and authordeps that keep F<dist.ini> as it is.  It adopts no section
and no authordep that the template has and the file lacks, so the update adds
those, and no authordep of a module of the repository, which the update
removes.  Nor can it keep the sections of the template in another order: the
update puts them in the order of the template, which is the order that
Dist::Zilla runs them in.

=head1 IN A FLAVOR

    checks:
      DistIni:
        file: dist.ini
        template: templates/dist.ini

=head1 IN .conformance.yml

    checks:
      DistIni:
        overrides:
          '@TestingMania':
            disable: [ Test::Portability, Test::Synopsis ]
          PodCoverageTests: off
          Run::BeforeBuild:
            run: cp extra/files .
        positions:
          Run::BeforeBuild: GatherDir
        settings:
          main_module: lib/Foo/Bar.pm
        authordeps:
          Perl::Tests::Covering: off
          Local::Plugin: '1.2'
    variables:
      DIST: Foo-Bar
      AUTHOR_NAME: A. Tester
      AUTHOR_EMAIL: tester@test.test

=head1 CONFIGURATION

=over

=item file

Required.  The path of F<dist.ini>.

=item template

Required.  The template of F<dist.ini>.

=item overrides

=item positions

=item settings

What the repository sets otherwise than the template, as
L<Dist::Conformance::Check::IniTemplate/CONFIGURATION> says.  Default none.

=item authordeps

What the repository asks for otherwise than the authordeps of the template, by
module: C<off>, or a version.  Default none.

=back

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Conformance|Dist::Conformance>

=item *

L<Dist::Conformance::Check::IniTemplate>

=item *

L<Dist::Conformance::Check::AuthorDeps>

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
