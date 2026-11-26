package Dist::Conformance::Check::CriticProfile 0.011;

# ABSTRACT: The perlcritic profile is its template, with the overrides of the repository

use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
no autovivification;
use Mojo::Base 'Dist::Conformance::Check::IniTemplate', -signatures;

use Config::Tiny();

use Dist::Conformance::Schema();


our $VALUE = { anyOf => [ { type => 'string', nullable => 1 }, { type => 'number' } ] };

sub config_schema ($) {
    return {
        required   => [qw{file template}],
        properties => {
            file      => $Dist::Conformance::Schema::PATH,
            template  => $Dist::Conformance::Schema::PATH,
            overrides => {
                type                 => 'object',
                additionalProperties => { anyOf => [ { type => 'string', enum => ['off'] }, { type => 'object', additionalProperties => $VALUE } ] },
                default              => {},
            },
            settings => { type => 'object', additionalProperties => $VALUE, default => {} },
            replace  => { type => 'boolean' },
            retired  => { type => 'array', items => { type => 'string' } },
            header   => { type => 'string' },
            outdated => { type => 'array', items => { type => 'string' } },
        },
    };
}


sub policy_of ($section) {
    my ( $off, $name ) = $section =~ m/\A(-?)(?:Perl::Critic::Policy::)?(.+)\z/;
    return ( !!$off, $name );
}


sub profile_of ( $text, $where ) {
    my $tiny    = Config::Tiny->read_string($text) // die( "$where does not parse as a perlcritic profile: " . Config::Tiny->errstr . "\n" );
    my %profile = ( settings => $tiny->{_} // {}, policies => {} );
    for my $section ( grep { $_ ne q{_} } keys %$tiny ) {
        my ( $off, $name ) = policy_of($section);
        $profile{policies}{$name} = { off => $off, parameters => $off ? {} : $tiny->{$section} };
    }
    return \%profile;
}


sub header_of ($line) {
    my ($section) = $line =~ s/\s;\s.+$//r =~ m/\A\s*\[\s*(.+?)\s*\]\s*$/;
    return $section;
}


sub parameter_of ($line) {
    return if $line =~ m/\A\s*(?:[\#;]|$)/;
    my ( $key, $value ) = $line =~ m/\A\s*([^=]+?)\s*=\s*(.*?)\s*$/;
    return if !defined $key;
    return ( $key, $value );
}


sub rewrite ( $lines, $overlay ) {
    return __PACKAGE__->rewrite_lines( $lines, $overlay );
}

# How Perl::Critic reads a line, a section and a profile, for
# L<Dist::Conformance::Check::IniTemplate>.
sub line_header    ( $, $line )    { return header_of($line) }
sub line_parameter ( $, $line )    { return parameter_of($line) }
sub section_of     ( $, $header )  { return policy_of($header) }
sub on_header      ( $, $name, $ ) { return "[$name]\n" }
sub comment ($)                { return q{#} }
sub parse ( $, $text, $where ) { return profile_of( $text, $where ) }

# A policy that an override turns off keeps its section, as C<[-Name]>, with
# its parameters removed.
sub off_lines ( $, $name, $body ) {
    my %gone;
    for my $line (@$body) {
        my ($key) = parameter_of($line);
        $gone{$key} = undef if defined $key;
    }
    return ( "[-$name]\n", rewrite( $body, \%gone ) );
}

sub compare ( $self, $text, $want ) {
    my ( $file, $template ) = @{ $self->config }{qw{file template}};
    return differences( profile_of( $text, $file ), profile_of( $want, $template ) );
}

# The entries of C<overrides>, by the short name of each policy.
# @returns HashRef  from the name of each policy to C<off> or its parameters
# @throws  on a name that is not that of a policy, and on two entries for one policy
# @example my $overrides = $check->overrides;
sub overrides ($self) {
    my %overrides;
    for my $given ( sort keys %{ $self->config->{overrides} } ) {
        my ( $off, $name ) = policy_of($given);
        die "overrides names $given, which is not the name of a policy\n" if $off || !Dist::Conformance::Schema::matches( $Dist::Conformance::Check::MODULE, $name );
        die "overrides names the policy $name twice\n"                    if exists $overrides{$name};
        $overrides{$name} = $self->config->{overrides}{$given};
    }
    return \%overrides;
}

# The entries of C<overrides>, by the full name of each policy, as the
# template C<$standard> names it.
# @param   standard  HashRef  the template, as L<profile_of|/"profile_of($text, $where)"> returns it
# @returns HashRef  from the name of each policy to C<off> or its parameters
# @throws  on a name that is not that of a policy, and on two entries for one policy
# @example my $overrides = $check->resolved_overrides($standard);
sub resolved_overrides ( $self, $standard ) {
    my $given = $self->overrides;
    my %overrides;
    for my $as ( sort keys %$given ) {
        my $name = full_name( $as, $standard->{policies} );
        die "overrides names the policy $name twice\n" if exists $overrides{$name};
        $overrides{$name} = $given->{$as};
    }
    return \%overrides;
}


sub differences ( $have, $want ) {
    my ( $hp, $wp ) = ( $have->{policies}, $want->{policies} );
    my $same = sub ( $x, $y ) {
        return join( "\n", map { "$_=$x->{$_}" } sort keys %$x ) eq join( "\n", map { "$_=$y->{$_}" } sort keys %$y );
    };
    my @kinds = (
        [ 'lacks the policy',     grep { !$hp->{$_} } sort keys %$wp ],
        [ 'names the policy',     grep { !$wp->{$_} } sort keys %$hp ],
        [ 'enables the policy',   grep { $hp->{$_} && $wp->{$_}{off}  && !$hp->{$_}{off} } sort keys %$wp ],
        [ 'turns off the policy', grep { $hp->{$_} && !$wp->{$_}{off} && $hp->{$_}{off} } sort keys %$wp ],
        [ 'sets other parameters for the policy', grep { local ($_) = $_; $hp->{$_} && !$wp->{$_}{off} && !$hp->{$_}{off} && !$same->( $hp->{$_}{parameters}, $wp->{$_}{parameters} ) } sort keys %$wp ],
    );
    my @differences;
    for my $kind (@kinds) {
        my ( $phrase, @names ) = @$kind;
        next if !@names;
        my $text = ( @names > 1 ? $phrase =~ s/policy\z/policies/r : $phrase ) . ' ' . join ', ', @names;
        $text .= ', which neither the template nor the overrides name' if $phrase eq 'names the policy';
        push @differences, $text;
    }
    push @differences, 'sets other global settings' if !$same->( $have->{settings}, $want->{settings} );
    return @differences;
}


sub adopt ( $self, $snapshot ) {
    my ( $file, $template ) = @{ $self->config }{qw{file template}};
    my $text = $snapshot->content($file) // return;
    my ( $filled, @unfilled ) = $self->template($template);
    die( "$template needs the variables " . join( ', ', @unfilled ) . " in .conformance.yml: nothing sets them\n" ) if @unfilled;
    my $have = profile_of( $text,   $file );
    my $want = profile_of( $filled, $template );

    my %overrides;
    for my $given ( sort keys %{ $have->{policies} } ) {
        my $mine     = $have->{policies}{$given};
        my $name     = full_name( $given, $want->{policies} );
        my $standard = $want->{policies}{$name};
        if ( $mine->{off} ) {
            $overrides{$name} = 'off' if !$standard || !$standard->{off};
            next;
        }
        if ( !$standard || $standard->{off} ) {
            $overrides{$name} = { %{ $mine->{parameters} } };
            next;
        }
        my $changed = overlay( $standard->{parameters}, $mine->{parameters} );
        $overrides{$name} = $changed if %$changed;
    }
    my $settings = overlay( $want->{settings}, $have->{settings} );
    my %adopted  = ( %overrides ? ( overrides => \%overrides ) : (), %$settings ? ( settings => $settings ) : () );
    return %adopted ? \%adopted : undef;
}


sub full_name ( $name, $policies ) {
    return $name if exists $policies->{$name};
    my @longer = grep { local ($_) = $_; substr( $_, -length("::$name") ) eq "::$name" } keys %$policies;
    return @longer == 1 ? $longer[0] : $name;
}


sub overlay ( $from, $to ) {
    my %overlay = map { $_ => $to->{$_} } grep { !exists $from->{$_} || $from->{$_} ne $to->{$_} } keys %$to;
    $overlay{$_} = undef for grep { !exists $to->{$_} } keys %$from;
    return \%overlay;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Conformance::Check::CriticProfile - The perlcritic profile is its template, with the overrides of the repository

=head1 VERSION

version 0.011

=head1 DESCRIPTION

The profile is not edited by hand.  It is the template, with the variables
filled in, and with the overrides of the repository applied.  So the standards
decide every policy and every parameter, and a repository says where it
departs from them in F<.conformance.yml>, where a reviewer sees it.  The
comments of the profile are those of the template.  A note about an override
goes in F<.conformance.yml>, beside it.

Each entry of C<overrides> names a policy, with or without the prefix
C<Perl::Critic::Policy::>, and says one of these.  A name that is the last
parts of a name in the template, such as C<ProhibitLeadingZeros> for
C<Plicease::ProhibitLeadingZeros>, is that policy, as Perl::Critic reads it.

=over

=item C<off>

The profile turns the policy off with C<[-Name]>, whether the template enables
it or does not name it.  A profile that sets C<severity> low runs every
installed policy that it does not turn off.

=item a mapping of parameters

The profile enables the policy, with the parameters of the template and these
over them.  A parameter whose value is C<~> is removed.  An empty mapping
enables the policy with the parameters of the template, so it adds a policy
that the template does not name, or turns on one that the template turns off.

=back

C<settings> does the same for the global settings, the keys before the first
section, such as C<severity>: each key replaces the setting of the template,
and C<~> removes it.

The overrides change the text of the template in place.  A parameter that an
override changes stays on its line, a new parameter goes after the last
parameter of its section, and a policy that the template does not name goes at
the end of the file.

The check passes when the profile is the text that the template and the
overrides make.  It reports C<info> when the profile differs from that text
only in comments and layout, so that Perl::Critic reads both the same.  It
fails when the profile is missing, does not parse, or makes Perl::Critic read
other policies, parameters or settings, and the detail names each difference.

The update writes that text to the profile when the file differs from it.

The check passes when the profile is that text.  It fails when the file is
missing, and when it differs in what Perl::Critic reads: a policy that it
lacks, a policy that neither the template nor the overrides name, a policy
that it turns on or off otherwise, a parameter, or a global setting.  The
detail names each.  A profile that differs only in comments or layout is
C<info>.  A profile that does not parse fails.

So when the standards add a policy, drop one, turn one off or change a
parameter, every profile that does not follow fails, and the update brings it
along.  A policy that the template drops leaves every profile, unless an
override names it.

L<Dist::Conformance::Check::IniTemplate> writes the text, and this check tells
it how Perl::Critic reads a profile: a section is a policy, C<[-Name]> turns it
off, and a comment starts with C<#> or C<;>.

The update writes the text whenever the file differs from it, also in the
comments.  It replaces whatever the file had, so run C<conformance adopt>
before the first update of a profile that has changes of its own.  See
L<adopt|/"adopt($snapshot)">.  A template with a placeholder that nothing fills is not written:
the update says which variables it needs.

=head1 METHODS

=head2 adopt($snapshot)

The C<overrides> and C<settings> that make L<expected|Dist::Conformance::Check::IniTemplate/"expected($snapshot)"> read as the profile in
C<$snapshot> reads now.  A policy that the template names and the profile
lacks is not adopted: the profile lacked it because the template gained it
later.  A policy that the profile names by the last parts of a name that the
template gives in full, such as C<ProhibitLeadingZeros> for
C<Plicease::ProhibitLeadingZeros>, is the policy of the template, as
Perl::Critic reads it, and is adopted by the full name.

=over 4

=item snapshot - InstanceOf["Dist::Conformance::Snapshot"] - the repository

=back

Returns HashRef or undef: the keys that hold something, C<undef> when the
profile needs neither key, and nothing when the profile is missing.

Dies when either the profile or the template does not parse, and when a
placeholder has no variable.

    my $keys = $check->adopt($snapshot);

=head2 overrides

The entries of C<overrides>, by the short name of each policy.

Returns HashRef, from the name of each policy to C<off> or its parameters.

Dies on a name that is not that of a policy, and on two entries for one policy.

    my $overrides = $check->overrides;

=head2 resolved_overrides(standard)

The entries of C<overrides>, by the full name of each policy, as the template C<$standard> names it.

=over 4

=item standard - HashRef - the template, as L<profile_of|/"profile_of($text, $where)"> returns it

=back

Returns HashRef, from the name of each policy to C<off> or its parameters.

Dies on a name that is not that of a policy, and on two entries for one policy.

    my $overrides = $check->resolved_overrides($standard);

=head1 FUNCTIONS

=head2 policy_of($section)

Whether the header C<$section> of a profile turns its policy off, and the
short name of the policy, without C<Perl::Critic::Policy::>.

=over 4

=item section - Str - the header, without its brackets

=back

Returns a boolean and the name, as a list.

    my ( $off, $name ) = policy_of('-Perl::Critic::Policy::Variables::ProhibitPunctuationVars');

=head2 profile_of($text, $where)

What Perl::Critic reads from the profile C<$text>.

=over 4

=item text - Str - the profile

=item where - Str - names the profile in an error

=back

Returns HashRef, with C<settings>, the global settings, and C<policies>, from
the short name of each policy that a section names to a hash reference with
C<off>, whether it turns the policy off, and C<parameters>.

Dies, naming C<$where>, when the text does not parse.

    my $profile = profile_of( "severity = 3\n[-Variables::ProhibitPunctuationVars]\n", '.perlcriticrc' );

=head2 header_of($line)

The section that the line C<$line> of a profile starts, as L<Config::Tiny>
reads it, with its inline C< ; > comment.

=over 4

=item line - Str - one line of a profile

=back

Returns Str, the header without its brackets, or C<undef> when the line starts
no section.

    my $header = header_of("[Variables::ProhibitPunctuationVars] ; a comment\n");

=head2 parameter_of($line)

The key and the value that the line C<$line> of a profile sets, as
L<Config::Tiny> reads them.

=over 4

=item line - Str - one line of a profile

=back

Returns the key and the value, as a list, or an empty list for a line that
sets none, such as a comment.

    my ( $key, $value ) = parameter_of("severity = 3\n");

=head2 rewrite(\@lines, \%overlay)

The lines C<@lines> of a section, without its header, with the parameters of
C<%overlay> over theirs: a key that it sets to a value has that value on its
line, a key that it sets to C<undef> loses its line, and a key that the lines
lack gets a line after their last parameter, or first when they have none.
The other lines stay as they were.

=over 4

=item lines - ArrayRef[Str] - the lines of the section, each with its newline

=item overlay - HashRef - from each key to its new value, or to C<undef>

=back

Returns the new lines, as a list.

    my @lines = rewrite( [ "# a comment\n", "max = 3\n" ], { max => 5 } );

=head2 differences($have, $want)

How the profile C<$have> differs from C<$want>, as phrases for a person.

=over 4

=item have - HashRef - the profile that the repository has, as L<profile_of|/"profile_of($text, $where)"> returns it

=item want - HashRef - the profile that it must have, as L<profile_of|/"profile_of($text, $where)"> returns it

=back

Returns the phrases, as a list, which is empty when Perl::Critic reads both
the same.

    my @differences = differences( profile_of( $text, $file ), profile_of( $expected, $template ) );

=head2 full_name($name, \%policies)

The name in C<%policies> that ends with C<::$name>, when C<$name> is not a key
there and exactly one name ends so.

=over 4

=item name - Str - the name of a policy, maybe its last parts only

=item policies - HashRef - keyed by the names of the policies of a profile

=back

Returns Str, that name, or else C<$name>.

    my $name = full_name( 'ProhibitLeadingZeros', $profile->{policies} );

=head2 overlay(\%from, \%to)

The overlay that turns the parameters C<%from> into C<%to>: each key of
C<%to> whose value differs, and C<undef> for each key that only C<%from> has.

=over 4

=item from - HashRef - the parameters to start from

=item to - HashRef - the parameters to end with

=back

Returns HashRef, the overlay, as L<rewrite|/"rewrite(\@lines, \%overlay)"> takes it.

    my $overlay = overlay( { max => 3, min => 1 }, { max => 5 } );

=head1 IN A FLAVOR

    checks:
      CriticProfile:
        file: .perlcriticrc
        template: templates/perlcriticrc

=head1 IN .conformance.yml

    checks:
      CriticProfile:
        overrides:
          logicLAB::RequireSheBang:
            formats: '#!/usr/bin/env perl'
          Subroutines::ProhibitExcessComplexity:
            max_mccabe: 30
          ValuesAndExpressions::ProhibitMagicNumbers: off
          Some::Policy::OfItsOwn: {}
        settings:
          severity: 3

=head1 CONFIGURATION

=over

=item file

Required.  The path of the profile.

=item template

Required.  The template of the profile.

=item overrides

What the repository sets otherwise than the template, by policy, as
L</DESCRIPTION> says.  Default none.

=item settings

The global settings that the repository sets otherwise.  Default none.

=item replace

=item retired

=item header

=item outdated

Deprecated, and ignored.  The profile is always the template with the
overrides, so it is always replaced, and a policy that the template drops goes
without a list.  They are accepted so that a flavor that names them still
loads.

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
