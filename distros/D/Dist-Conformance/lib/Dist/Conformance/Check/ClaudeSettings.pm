package Dist::Conformance::Check::ClaudeSettings 0.004;

# ABSTRACT: .claude/settings.json enables the plugins of the harness

use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Mojo::Base 'Dist::Conformance::Check', -signatures;

use Cpanel::JSON::XS();

use Dist::Conformance::Schema();


sub config_schema ($) {
    return {
        required   => [qw{file plugins}],
        properties => {
            file    => $Dist::Conformance::Schema::PATH,
            plugins => { type => 'array', items => { type => 'string', pattern => '\A[^@\s]+@[^@\s]+\z' } },
            missing => { %$Dist::Conformance::Schema::STATUS, default => 'fail' },
        },
    };
}


sub settings ( $self, $snapshot ) {
    my $file = $self->config->{file};
    my $text = $snapshot->content($file) // return undef;
    return Dist::Conformance::Schema::parse_json( $text, $file );
}


sub disabled ( $self, $settings ) {
    my $enabled  = ref $settings->{enabledPlugins} eq 'HASH' ? $settings->{enabledPlugins} : {};
    my @disabled = grep { !$enabled->{$_} } @{ $self->config->{plugins} };
    return @disabled;
}


sub check ( $self, $snapshot ) {
    my ( $file, $missing ) = @{ $self->config }{qw{file missing}};
    my $settings = eval { $self->settings($snapshot) };
    return ( 'fail',   Dist::Conformance::Schema::first_line($@) ) if $@;
    return ( $missing, "$file is missing" )                        if !$settings;
    my @disabled = $self->disabled($settings);
    return ( $missing, 'does not enable ' . join ', ', @disabled ) if @disabled;
    return ( 'pass',   'enables ' . join ', ',         @{ $self->config->{plugins} } );
}


sub update ( $self, $update ) {
    my $settings = eval { $self->settings( $update->snapshot ) };
    if ($@) {
        $update->by_hand( Dist::Conformance::Schema::first_line($@) . ': fix it by hand' );
        return;
    }
    $settings //= {};
    my @disabled = $self->disabled($settings);
    return if !@disabled;
    $settings->{enabledPlugins}     = {} if ref $settings->{enabledPlugins} ne 'HASH';
    $settings->{enabledPlugins}{$_} = Cpanel::JSON::XS::true() for @disabled;
    $update->write( $self->config->{file}, Dist::Conformance::Schema::encode_json($settings) );
    return;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Conformance::Check::ClaudeSettings - .claude/settings.json enables the plugins of the harness

=head1 VERSION

version 0.004

=head1 DESCRIPTION

Claude Code loads a plugin for a repository when the project settings enable
it, under C<enabledPlugins>, as C<plugin@marketplace>.  The check passes when
the file enables each plugin of C<plugins>.  It reports C<missing> when the
file is absent or does not enable one, and fails when the file does not parse
as a JSON object, which Claude Code would not read either.

The update writes the file when it is absent, and sets each plugin to C<true>
in C<enabledPlugins> when it is there.  It keeps every other key of the file,
and writes it with sorted keys and an indent of two.  A file that does not
parse is left for a person.

=head1 METHODS

=head2 settings

C<($snapshot)>.  The parsed settings, C<undef> when the file is absent.  Dies
when it does not parse.

=head2 disabled

C<($settings)>.  The plugins that C<$settings> does not enable.

=head2 check

=head2 update

Writes the settings, or enables the plugins in them.

=head1 IN A FLAVOR

    checks:
      ClaudeSettings:
        file: .claude/settings.json
        missing: info
        plugins:
          - perl-slop@troglodyne-marketplace

=head1 CONFIGURATION

=over

=item file

Required.  The path of the settings.

=item plugins

Required.  The plugins to enable, each as C<plugin@marketplace>.

=item missing

The status when the file is absent or does not enable a plugin.  Default
C<fail>.

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
