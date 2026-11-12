package Dist::Conformance::Check::CriticProfile 0.005;

# ABSTRACT: The perlcritic profile enables or turns off every policy of its template, and no retired one

use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Mojo::Base 'Dist::Conformance::Check', -signatures;

use Config::Tiny();

use Dist::Conformance::Schema();


sub config_schema ($) {
    return {
        required   => [qw{file template}],
        properties => {
            file     => $Dist::Conformance::Schema::PATH,
            template => $Dist::Conformance::Schema::PATH,
            replace  => { type => 'boolean', default   => 0 },
            retired  => { type => 'array',   items     => $Dist::Conformance::Check::MODULE, uniqueItems => 1, default => [] },
            header   => { type => 'string',  minLength => 1 },
            outdated => { type => 'array',   items     => { type => 'string', minLength => 1 } },
        },
    };
}


sub policies ( $text, $where ) {
    my $profile = Config::Tiny->read_string($text) // die( "$where does not parse as a perlcritic profile: " . Config::Tiny->errstr . "\n" );
    my %policies;
    for my $section ( grep { $_ ne q{_} } keys %$profile ) {
        my ( $off, $name ) = policy_of($section);
        $policies{$name} = $off ? 'disabled' : 'enabled';
    }
    return \%policies;
}


sub policy_of ($section) {
    my ( $off, $name ) = $section =~ m/\A(-?)(?:Perl::Critic::Policy::)?(.+)\z/;
    return ( !!$off, $name );
}


sub missing_policies ( $self, $text ) {
    my ( $file, $template ) = @{ $self->config }{qw{file template}};
    my $want    = policies( ( $self->template($template) )[0], $template );
    my $have    = policies( $text,                             $file );
    my @missing = sort grep { $want->{$_} eq 'enabled' && !exists $have->{$_} } keys %$want;
    return @missing;
}


sub retired ($self) {
    my @retired = map { ( policy_of($_) )[1] } @{ $self->config->{retired} };
    return if !@retired;
    my $template = $self->config->{template};
    my $want     = policies( ( $self->template($template) )[0], $template );
    my @both     = grep { ( $want->{$_} // q{} ) eq 'enabled' } @retired;
    die( "$template enables " . join( ', ', @both ) . ", which retired names too: a policy is either in the template or retired\n" ) if @both;
    return @retired;
}


sub enabled_retired ( $self, $text, @retired ) {
    my $have    = policies( $text, $self->config->{file} );
    my @enabled = sort grep { ( $have->{$_} // q{} ) eq 'enabled' } @retired;
    return @enabled;
}


sub lacks (@missing) {
    return 'lacks the ' . ( @missing == 1 ? 'policy ' : 'policies ' ) . join ', ', @missing;
}


sub verdict ( $self, $text ) {
    my $template = $self->config->{template};
    my @retired  = $self->retired;
    my ( $missing, $enabled ) = eval { ( [ $self->missing_policies($text) ], [ $self->enabled_retired( $text, @retired ) ] ) };
    if ($@) {
        my $detail = Dist::Conformance::Schema::first_line($@);
        return ( 'fail', $detail, "$detail: fix it by hand, or set replace: true to overwrite it" );
    }
    return ( 'pass', "has every policy of $template" ) if !@$missing && !@$enabled;
    my @details;
    push @details, lacks(@$missing) . " of $template"                                                                                                     if @$missing;
    push @details, 'enables the retired ' . ( @$enabled == 1 ? 'policy ' : 'policies ' ) . join( ', ', @$enabled ) . ', which conformance update removes' if @$enabled;
    return ( 'fail', join( '; ', @details ), undef, $missing, $enabled );
}


sub header_of ($line) {
    my ($section) = $line =~ s/\s;\s.+$//r =~ m/\A\s*\[\s*(.+?)\s*\]\s*$/;
    return $section;
}


sub ignored ($line) {
    return $line =~ m/\A\s*(?:[\#;]|$)/;
}


sub sections ($text) {
    my ( %sections, $name );
    for my $line ( split /^/, $text ) {
        if ( defined( my $section = header_of($line) ) ) {
            my ( $off, $policy ) = policy_of($section);
            $name = $off ? undef : $policy;
            $sections{$name} = q{} if defined $name;
            next;
        }
        next if !defined $name || ignored($line);
        $sections{$name} .= $line =~ s/\n?\z/\n/r;
    }
    return { map { $_ => "[$_]\n$sections{$_}" } keys %sections };
}


sub without_sections ( $text, @names ) {
    my %gone  = map { $_ => 1 } @names;
    my @lines = split /^/, $text;
    my %remove;
    for my $start ( grep { defined header_of( $lines[$_] ) } 0 .. $#lines ) {
        my ( $off, $policy ) = policy_of( header_of( $lines[$start] ) );
        next if $off || !$gone{$policy};
        my $end = $start + 1;
        $end++ while $end <= $#lines   && !defined header_of( $lines[$end] );
        $end-- while $end > $start + 1 && ignored( $lines[ $end - 1 ] );
        my $above = $start;
        $above-- while $above > 0 && $lines[ $above - 1 ] =~ m/\A\s*[\#;]/;
        $above = $start if $above == 0;
        $remove{$_} = 1 for $above .. $end - 1;
    }
    return join q{}, @lines[ grep { !$remove{$_} } 0 .. $#lines ];
}


sub check ( $self, $snapshot ) {
    my $file = $self->config->{file};
    my $text = $snapshot->content($file) // return ( 'fail', "$file is missing" );
    my ( $status, $detail ) = $self->verdict($text);
    return ( $status, $detail );
}


sub update ( $self, $update ) {
    my ( $file, $template ) = @{ $self->config }{qw{file template}};
    my $text = $update->snapshot->content($file);
    if ( defined $text ) {
        my ( $status, undef, $by_hand, $missing, $enabled ) = $self->verdict($text);
        return if $status eq 'pass';
        if ( !$self->config->{replace} ) {
            return $update->by_hand($by_hand) if defined $by_hand;
            my $edited = without_sections( $text, @$enabled );
            $edited = $self->append_policies( $update, $edited, @$missing ) // $edited if @$missing;
            $update->write( $file, $edited ) if $edited ne $text;
            return;
        }
    }
    $self->write_template( $update, $file, $template );
    return;
}


sub append_policies ( $self, $update, $text, @missing ) {
    my ( $file,     $template ) = @{ $self->config }{qw{file template}};
    my ( $policies, @unfilled ) = $self->template($template);
    if (@unfilled) {
        $update->by_hand( 'Add the policies ' . join( ', ', @missing ) . " of $template to $file by hand, or set the variables " . join( ', ', @unfilled ) . ' in .conformance.yml: nothing sets them' );
        return;
    }
    my $sections = sections($policies);
    $text .= "\n" if $text =~ m/[^\n]\z/;
    return $text . join q{}, @{$sections}{@missing};
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Conformance::Check::CriticProfile - The perlcritic profile enables or turns off every policy of its template, and no retired one

=head1 VERSION

version 0.005

=head1 DESCRIPTION

A profile is compared with its template by the policies that each names.  Both
are read as Perl::Critic reads a profile, with L<Config::Tiny>: each section
C<[Name]> enables the policy C<Name>, a section C<[-Name]> turns it off, and the
keys before the first section are global settings.  A name with the prefix
C<Perl::Critic::Policy::> is the same policy as the name without it.

The check passes when the file names each policy that the template enables,
either as C<[Name]>, which enables it, or as C<[-Name]>, which turns it off on
purpose.  It fails when the file is missing, when it does not parse, and when
it does not name a policy that the template enables.  The detail names each
such policy.  So when the template gains a policy, every profile that does not
have it yet fails, by the name of that policy.

It also fails when the file enables a policy that C<retired> names, and the
detail names each such policy and says that C<conformance update> removes it.
Dropping a policy from the template is not enough to take it away, because a
profile may enable policies of its own, and the check cannot tell one of them
from a policy that the standards used to have.  So the standards say which
policies they take back, by name.  A section C<[-Name]>, which turns a retired
policy off, is not an error, and stays.

What else the file says is the distribution's own business, and does not
change the result:

=over

=item the parameters of a policy

A policy that the template configures, and the file configures differently or
not at all, is there.  An exemption or a threshold of its own is a choice of
the distribution, not a policy that it lacks.

=item a policy that the template does not enable

A policy of the distribution's own, or one that the template has dropped or
turns off, can stay, unless C<retired> names it.

=item the global settings and the comments

The first line among them, so a header says nothing about whether a profile
is current.

=back

The update writes the template when the file is missing.  A profile that is
there usually has changes of its own, such as exemptions, so it is replaced
only when C<replace> is true.  Otherwise the update appends to the end of the
file each policy that it lacks, as the template writes its section: the
C<[Name]> line and the parameters below it, without the comments.  Every line
that the file had stays as it was.  A profile that does not parse is left for a
person, and so is one whose template still has a placeholder that nothing
fills.

Without C<replace>, the update also removes the section of each retired policy
that the file enables: the C<[Name]> line, the parameters below it, and the
comment lines directly above the C<[Name]> line, up to a line that is blank or
is not a comment.  A comment block at the very top of the file is its header,
and stays.  The comment lines and blank lines at the end of the section stay
as well, because they are usually about the section after it.  Every other
line stays as it was.

A template that enables a policy that C<retired> names contradicts itself, so
the check dies, and so does the update, and each says which policy.

=head1 METHODS

=head2 missing_policies

C<($text)>.  The sorted names of the policies that the template enables and
the profile C<$text> does not name.  Dies when either does not parse.

=head2 retired

The short names of the policies that C<retired> names, in its order.  Dies
when the template enables one of them, or does not parse.

=head2 enabled_retired

C<($text, @retired)>.  The sorted names of the policies of C<@retired> that
the profile C<$text> enables.  Dies when it does not parse.

=head2 verdict

C<($text)>.  The status and the detail of the profile C<$text>, as C<check>
returns them.  For a profile that does not parse, then what a person must do
to fix it by hand; for one that lacks policies or enables retired ones, then
C<undef> and two array references: the names of the policies that it lacks,
and of the retired policies that it enables.  Dies when the template enables a
retired policy, as L</retired> does.

=head2 check

C<($snapshot)>.  The status and the detail that L</DESCRIPTION> says, for the
profile in C<$snapshot>.

=head2 update

Writes the template when the profile is missing, or when it is not current and
C<replace> is true.  Otherwise removes the sections of the retired policies
that the profile enables, and appends the sections of the template that it
lacks, as L</DESCRIPTION> says.

=head2 append_policies

C<($update, $text, @missing)>.  The profile C<$text> with the section of the
template of each policy of C<@missing> appended.  When the template still has
a placeholder, returns C<undef> and records through C<$update> what is needed.

=head1 FUNCTIONS

=head2 policies

C<($text, $where)>.  The policies of the profile C<$text>, as a hash reference
from the short name of each to C<enabled> or C<disabled>.  Dies, naming
C<$where>, when Perl::Critic could not parse the text either.

=head2 policy_of

C<($section)>.  Whether the header C<$section> of a profile turns its policy
off, and the short name of the policy.

=head2 lacks

C<(@missing)>.  The detail for a profile that lacks the policies C<@missing>,
without the template.

=head2 header_of

C<($line)>.  The section that the line C<$line> of a profile starts, as
L<Config::Tiny> reads it, with its inline C< ; > comment: C<undef> when it
starts none.

=head2 ignored

C<($line)>.  Whether L<Config::Tiny> ignores the line C<$line> of a profile,
as a comment or a blank line.

=head2 sections

C<($text)>.  The text of each section of the profile C<$text> that enables a
policy, as a hash reference from the short name of the policy: the line of the
section and the lines of its parameters, each with its newline, without the
comments and the blank lines.  The lines are found as L<Config::Tiny> finds
them, so the names are the names of L</policies>.

=head2 without_sections

C<($text, @names)>.  The profile C<$text> without each section that enables a
policy of C<@names>, as L</DESCRIPTION> says: the line of the section, its
parameters, and the comment lines directly above it unless they start the
file, but not the comment lines and blank lines that end it.  A section that
turns a policy off stays.

=head1 IN A FLAVOR

    checks:
      CriticProfile:
        file: .perlcriticrc
        template: templates/perlcriticrc
        replace: false
        retired:
          - Subroutines::ProhibitUnderscorePrivateSubs

=head1 CONFIGURATION

=over

=item file

Required.  The path of the profile.

=item template

Required.  The template of the current profile.

=item replace

Whether an update overwrites a profile that is not current.  Default false.

=item retired

The policies that the standards have taken back, by name, with or without the
prefix C<Perl::Critic::Policy::>.  A profile must not enable one, and the
update removes it.  Default none.  Name a policy here when the template drops
it, and keep it here for as long as a profile made from an older template can
still enable it.

=item header

=item outdated

Deprecated, and ignored.  Each named a first line to compare, which the check
no longer does.  They are accepted so that a flavor that names them still
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
