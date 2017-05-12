########################################################
# Copyright © 2009 Six Apart, Ltd.

package HTML::Laundry::Rules;
use strict;
use warnings;

=head1 NAME

HTML::Laundry::Rules - base class for HTML::Laundry rulesets

=head1 VERSION

Version 0.0002

=cut

=head1 FUNCTIONS

=head2 new

Create an HTML::Tidy::Rules object.

    my $rules = HTML::Laundry::Rules::MyRules->new();

=cut

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;
    return $self;
}

=head2 tidy_ruleset

Return a hashref representing a ruleset for an HTML::Tidy object.

=cut

sub tidy_ruleset {
    my $self         = shift;
    my $tidy_ruleset = {
        show_body_only   => 1,
        output_xhtml     => 1,
        fix_backslash    => 1,
        fix_uri          => 1,
        numeric_entities => 1,
        drop_empty_paras => 0,
        vertical_space   => 0,
        wrap             => 0,
        quote_marks      => 1,
    };
    return $tidy_ruleset;
}

=head2 acceptable_a

Return a hashref representing a list of acceptable attributes

=cut

sub acceptable_a {
    my $self = shift;
    my @acceptable
        = qw(abbr accept accept-charset accesskey action align alt axis border
        cellpadding cellspacing char charoff charset checked cite class clear
        cols colspan color compact coords datetime dir disabled enctype for
        frame headers height href hreflang hspace id ismap label lang longdesc
        maxlength media method multiple name nohref noshade nowrap prompt
        readonly rel rev rows rowspan rules scope selected shape size span src
        start summary tabindex target title type usemap valign value vspace
        width xml:lang );
    my %acceptable = map { ( $_, 1 ) } @acceptable;
    return \%acceptable;
}

=head2 acceptable_e

Return a hashref representing a list of acceptable elements

=cut

sub acceptable_e {
    my $self       = shift;
    my @acceptable = qw(
        a abbr acronym address area b bdo big blockquote
        br button caption center cite code col colgroup dd
        del dfn dir div dl dt em fieldset font form
        h1 h2 h3 h4 h5 h6 hr i img input ins kbd
        label legend li map menu ol optgroup option p
        pre q s samp select small span strike strong
        sub sup table tbody td textarea tfoot th thead
        tr tt u ul var wbr
    );
    my %acceptable = map { ( $_, 1 ) } @acceptable;
    return \%acceptable;
}

=head2 empty_e

Return a hashref representing a list of empty elements

=cut

sub empty_e {
    my $self = shift;
    my @empty
        = qw( area base basefront br col frame hr img input isindex link meta param );
    my %empty = map { ( $_, 1 ) } @empty;
    return \%empty;
}

=head2 unacceptable_e

Return a hashref representing a list of unacceptable elements

=cut

sub unacceptable_e {
    my $self         = shift;
    my @unacceptable = qw( applet script );
    my %unacceptable = map { ( $_, 1 ) } @unacceptable;
    return \%unacceptable;
}

=head2 uri_list

Return a hashref representing a list of elements/attribute pairs known to contain
hrefs (for rebasing and URI scheme checking)

=cut

sub uri_list {
    my $self = shift;
    return {
        a          => ['href'],
        applet     => ['codebase'],
        area       => ['href'],
        blockquote => ['cite'],
        body       => ['background'],
        del        => ['cite'],
        form       => ['action'],
        frame      => [ 'longdesc', 'src' ],
        iframe     => [ 'longdesc', 'src' ],
        img        => [ 'longdesc', 'src', 'usemap' ],
        input => [ 'src', 'usemap' ],
        ins   => ['cite'],
        link  => ['href'],
        object => [ 'classid', 'codebase', 'data', 'usemap' ],
        q      => ['cite'],
        script => ['src']
    };
}

=head2 allowed_schemes

Return an arrayref representing a list of allowed schemas

=cut

sub allowed_schemes {
    my $self = shift;
    return {
        http  => 1,
        https => 1,
        afs => 1,
        aim => 1,
        callto => 1,
        #data => 1,
        ed2k => 1,
        feed => 1,
        ftp => 1,
        gopher => 1,
        irc => 1,
        mailto => 1,
        news => 1,
        nntp => 1,
        rsync => 1,
        rtsp => 1,
        sftp => 1,
        ssh => 1,
        tag => 1,
        tel => 1,
        telnet => 1,
        urn => 1,
        webcal => 1,
        wtai => 1,
        xmpp => 1,
    };
}

=head2 finalize_initialization

Function allowing transformation of the HTML::Laundry object.

=cut

sub finalize_initialization {
    my $self    = shift;
    my $laundry = shift;
    return 1;
}

1;
