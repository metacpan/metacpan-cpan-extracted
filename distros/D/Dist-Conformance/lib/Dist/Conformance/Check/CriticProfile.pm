package Dist::Conformance::Check::CriticProfile 0.002;

# ABSTRACT: The perlcritic profile enables or turns off every policy of its template

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
            header   => { type => 'string',  minLength => 1 },
            outdated => { type => 'array',   items     => { type => 'string', minLength => 1 } },
        },
    };
}


sub policies ( $text, $where ) {
    my $profile = Config::Tiny->read_string($text) // die( "$where does not parse as a perlcritic profile: " . Config::Tiny->errstr . "\n" );
    my %policies;
    for my $section ( grep { $_ ne q{_} } keys %$profile ) {
        my ( $off, $name ) = $section =~ m/\A(-?)(?:Perl::Critic::Policy::)?(.+)\z/;
        $policies{$name} = $off ? 'disabled' : 'enabled';
    }
    return \%policies;
}


sub missing_policies ( $self, $text ) {
    my ( $file, $template ) = @{ $self->config }{qw{file template}};
    my $want    = policies( ( $self->template($template) )[0], $template );
    my $have    = policies( $text,                             $file );
    my @missing = sort grep { $want->{$_} eq 'enabled' && !exists $have->{$_} } keys %$want;
    return @missing;
}


sub lacks (@missing) {
    return 'lacks the ' . ( @missing == 1 ? 'policy ' : 'policies ' ) . join ', ', @missing;
}


sub verdict ( $self, $text ) {
    my ( $file, $template ) = @{ $self->config }{qw{file template}};
    my @missing = eval { $self->missing_policies($text) };
    if ($@) {
        my $detail = Dist::Conformance::Schema::first_line($@);
        return ( 'fail', $detail, "$detail: fix it by hand, or set replace: true to overwrite it" );
    }
    return ( 'pass', "has every policy of $template" ) if !@missing;
    my $detail = lacks(@missing) . " of $template";
    return ( 'fail', $detail, "$file $detail: add each one to it by hand, or add it as [-Name] to turn it off on purpose, or set replace: true to overwrite it" );
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
        my ( $status, undef, $by_hand ) = $self->verdict($text);
        return                            if $status eq 'pass';
        return $update->by_hand($by_hand) if !$self->config->{replace};
    }
    $self->write_template( $update, $file, $template );
    return;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Conformance::Check::CriticProfile - The perlcritic profile enables or turns off every policy of its template

=head1 VERSION

version 0.002

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

What else the file says is the distribution's own business, and does not
change the result:

=over

=item the parameters of a policy

A policy that the template configures, and the file configures differently or
not at all, is there.  An exemption or a threshold of its own is a choice of
the distribution, not a policy that it lacks.

=item a policy that the template does not enable

A policy of the distribution's own, or one that the template has dropped or
turns off, can stay.

=item the global settings and the comments

The first line among them, so a header says nothing about whether a profile
is current.

=back

The update writes the template when the file is missing.  A profile that is
there usually has changes of its own, such as exemptions, so it is replaced
only when C<replace> is true; otherwise the update names the policies to add
by hand.

=head1 METHODS

=head2 missing_policies

C<($text)>.  The sorted names of the policies that the template enables and
the profile C<$text> does not name.  Dies when either does not parse.

=head2 verdict

C<($text)>.  The status and the detail of the profile C<$text>, as C<check>
returns them, and for a failure, what a person must do to fix it by hand.

=head2 check

=head2 update

Writes the template when the profile is missing, or when it is not current and
C<replace> is true.  Otherwise names what to add by hand.

=head1 FUNCTIONS

=head2 policies

C<($text, $where)>.  The policies of the profile C<$text>, as a hash reference
from the short name of each to C<enabled> or C<disabled>.  Dies, naming
C<$where>, when Perl::Critic could not parse the text either.

=head2 lacks

C<(@missing)>.  The detail for a profile that lacks the policies C<@missing>,
without the template.

=head1 IN A FLAVOR

    checks:
      CriticProfile:
        file: .perlcriticrc
        template: templates/perlcriticrc
        replace: false

=head1 CONFIGURATION

=over

=item file

Required.  The path of the profile.

=item template

Required.  The template of the current profile.

=item replace

Whether an update overwrites a profile that is not current.  Default false.

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
