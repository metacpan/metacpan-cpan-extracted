package HTML::ExtractText::Extra;

use strict;
use warnings;

our $VERSION = '1.001003'; # VERSION

use parent 'HTML::ExtractText';

use Devel::TakeHashArgs;
use Carp qw/croak/;

sub new {
    my $class = shift;

    get_args_as_hash( \@_, \ my %args,
        {   # these are optional with defaults
            whitespace       => 1,
            nbsp             => 1,
        },
    ) or croak $@;

    my $self = $class->SUPER::new;

    $self->$_( $args{$_} ) for keys %args;

    return $self;
}

sub _extract {
    my ( $self, $dom, $selector, $what ) = @_;

    my $want = $what->{ $selector };
    my $find = $want;

    if ( ref $want eq 'ARRAY' ) {
        $find = $want->[0];
    }

    my @results = $dom->find( $find )->map(sub{ $self->_process })->each;

    for ( @results ) {
        $self->nbsp       and tr/\x{00A0}/ /;
        $self->whitespace and s/^\s+|\s+$//g;
        if ( ref $want eq 'ARRAY' ) {
            if ( ref $want->[1] eq 'Regexp' ) {
                s/$want->[1]//g;
            }
            elsif ( ref $want->[1] eq 'CODE' ) {
                $_ = $want->[1]->( $_ );
            }
        }
    }

    return @results;
}

sub whitespace {
    my $self = shift;
    if ( @_ ) { $self->[0]->{WHITESPACE} = shift; }
    return $self->[0]->{WHITESPACE};
}

sub nbsp {
    my $self = shift;
    if ( @_ ) { $self->[0]->{nbsp} = shift; }
    return $self->[0]->{nbsp};
}

q|
I called the janitor the other day to see what he could do about my
dingy linoleum floor. He said he would have been happy to loan me a
polisher, but that he hadn't the slightest idea what he had done with
it. I told him not to worry about it--that as a programmer
it wasn't the first time I had experienced a buffer
allocation failure due to a memory error.
|;

__END__

=encoding utf8

=for stopwords Znet Zoffix errored  html

=head1 NAME

HTML::ExtractText::Extra - extra useful HTML::ExtractText

=head1 SYNOPSIS

=for test_synopsis no strict qw/vars/; no warnings;

At its simplest; use CSS selectors:

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

    # Same usage as HTML::ExtractText, but now we have extra
    # optional options (default values are shown):
    use HTML::ExtractText::Extra;
    my $ext = HTML::ExtractText::Extra->new(
        whitespace => 1, # strip leading/trailing whitespace
        nbsp       => 1, # replace non-breaking spaces with regular ones
    );

    $ext->extract(
        {
            page_title => 'title', # same extraction as HTML::ExtractText
            links => ['a', qr{http://|www\.} ], # strip what matches
            bold  => ['b', sub { "<$_[0]>"; } ], # wrap what's found in <>
        },
        $html,
    ) or die "Error: $ext";
    print "Page title is $ext->{page_title}\nLinks are: $ext->{links}";

=for html  </div></div>

=head1 DESCRIPTION

The module offers extra options and post-processing that the vanilla
L<HTML::ExtractText> does not provide.

=head1 METHODS FROM C<HTML::ExtractText>

This module offers all the standard methods and behaviour
L<HTML::ExtractText> provides. See its documentation for details.

=head1 EXTRA OPTIONS IN C<< ->new >>

    my $ext = HTML::ExtractText::Extra->new(
        whitespace => 1, # strip leading/trailing whitespace
        nbsp       => 1, # replace non-breaking spaces with regular ones
    );

=head2 C<whitespace>

    my $ext = HTML::ExtractText::Extra->new(
        whitespace => 1,
    );

B<Optional>. B<Defaults to:> C<1>. When set to a true value,
leading and trailing whitespace will be trimmed from the results.

=head2 C<nbsp>

    my $ext = HTML::ExtractText::Extra->new(
        nbsp => 1,
    );

B<Optional>. B<Defaults to:> C<1>. When set to a true value,
non-breaking spaces in the results will be converted into regular spaces.
Note that this does not affect how the normal white-space folding
operates, so C<foo &nbsp; bar> will end up having 3 spaces between
C<foo> and C<bar>.

=head1 EXTRA PROCESSING OPERATIONS IN C<< ->extract >>

    $ext->extract(
        {
            page_title => 'title', # same extraction as HTML::ExtractText
            links => ['a', qr{http://|www\.} ],  # strip what matches
            bold  => ['b', sub { "<$_[0]>"; } ], # wrap what's found in <>
        },
        $html,
    ) or die "Error: $ext";

This module extends possible values in the hashref given as the first
argument to C<< ->extract >> method. They are given by changing
the string containing the selector to an arrayref, where the first element
is the selector you want to match and the rest of the elements are as
follows:

=head2 Regex reference

    $ext->extract({ links => ['a', qr{http://|www\.} ] }, $html )

When second element of the arrayref is a regex reference,
any text that matches the regex will be stripped from the text
that is being extracted.

=head2 Code reference

     $ext->extract({ links => ['a', sub { "<$_[0]>"; } ] }, $html )

When second element of the arrayref is a code reference, it will be
called for each found bit of text we're extracting and its C<@_> will
contain that text as the first element. Whatever the sub returns will
be used as the result of extraction.

=head1 ACCESSORS

=head2 C<whitespace>

    $ext->whitespace(0);

Accessor method for the C<whitespace> argument to C<< ->new >>.

=head2 C<nbsp>

    $ext->nbsp(0);

Accessor method for the C<nbsp> argument to C<< ->new >>.

=head1 SEE ALSO

L<HTML::ExtractText> - a basic version of this extractor

L<Mojo::DOM>, L<Text::Balanced>, L<HTML::Extract>

=for html <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>

=head1 REPOSITORY

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

Fork this module on GitHub:
L<https://github.com/zoffixznet/HTML-ExtractText-Extra>

=for html  </div></div>

=head1 BUGS

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

To report bugs or request features, please use
L<https://github.com/zoffixznet/HTML-ExtractText-Extra/issues>

If you can't access GitHub, you can email your request
to C<bug-html-extracttext-extra at rt.cpan.org>

=for html  </div></div>

=head1 AUTHOR

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-author.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

=for html   <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/ZOFFIX"> <img src="http://www.gravatar.com/avatar/328e658ab6b08dfb5c106266a4a5d065?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F627d83ef9879f31bdabf448e666a32d5" alt="ZOFFIX" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">ZOFFIX</span> </a> </span>

=for text Zoffix Znet <zoffix at cpan.org>

=for html  </div></div>

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut
