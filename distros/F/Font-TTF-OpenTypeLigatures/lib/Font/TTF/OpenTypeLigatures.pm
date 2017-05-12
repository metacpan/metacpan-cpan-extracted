package Font::TTF::OpenTypeLigatures;
use Carp qw/croak/;
use Font::TTF::Font;
use warnings;
use strict;

=head1 NAME

Font::TTF::OpenTypeLigatures - Transforms OpenType glyphs based on GSUB tables

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    use Font::TTF::OpenTypeLigatures;

    my $foo = Font::TTF::OpenTypeLigatures->new($fontfile, %options);
    @glyph_ids = $foo->substitute(@glyph_ids);
    ...

=head1 DESCRIPTION

This module is a building block for fine typography systems implemented
in Perl. It reads the GSUB table of OpenType fonts to transform glyphs
based on selected OpenType features. The most common use of this is to
implement ligatures, but OpenType supports a variety of features such as
alternates, old-style numbers, non-Roman contextual substitutions and so
on. 

=head1 METHODS

=head2 new

The constructor takes a font file path and a set of options. The options
will determine which substitutions are performed. The default options
will substitute ligatures in Latin-script texts. You may supply:

=over 3

=item script

Four-letter code for the script in which your text is written. (See
http://www.microsoft.com/typography/developers/opentype/scripttags.aspx
for a list of these.)

=item lang

Three-letter language tag. If this is not given, or there are no special
features for this language, the default language for the script is used.

=item features

This is a I<regular expression> matching the features you want to
support. The default is C<liga>.

=back

If there are any problems, the constructor will die with an error
message.

=cut

use Memoize;
sub new {
    my ($class, $ff, %options) = @_;
    my $self = bless { }, $class;
    my $script = (lc $options{script}) || "latn";
    my $wanted = $options{features} || "liga";
    my $lang = sprintf "%3s ", uc $options{lang};
    my $f = $self->{ff} = Font::TTF::Font->open($ff) or croak "Couldn't open font file";
    $f->read;
    $f->{GSUB}->read;
    my $languages = $f->{GSUB}{SCRIPTS}{$script};
    if (!$languages) { croak "Font doesn't support script '$script'" }
    my $features = ($languages->{uc $options{lang}} || $languages->{DEFAULT})->{FEATURES};
    return $self unless $features;
    my @ligs = 
        grep { $_->{TYPE} == 4 } # XXX Contextual substitutions only for now
        map { $f->{GSUB}{LOOKUP}[$_] }
        map { @{ $f->{GSUB}{FEATURES}{$_}{LOOKUPS} } }
        grep /$wanted/, @$features;
    my %ligtable;
    for my $lig (@ligs) {
        for (@{$lig->{SUB}}) {
            while (my ($k, $v) = each %{$_->{COVERAGE}{val}}) {
                for (@{$_->{RULES}[$v]}) {
                    my $target = \%ligtable;
                    my $final = pop @{$_->{MATCH}};
                    for ($k, @{$_->{MATCH}}) {
                        $target->{$_} ||= {};
                        $target = $target->{$_};
                    }
                    $target->{$final}{FINAL} = join(",",@{$_->{ACTION}});
                }
            }
        }
    }
    $self->{ligtable} = \%ligtable;
    return $self;
}
memoize("new");

=head2 substitute 

This performs contextual substitution on a list of numeric glyph IDs,
returning a substituted list.

=cut

sub substitute {
    my ($self, @list) = @_;
    my @output;
    push @list, -1;
    my $s = $self->stream(sub { push @output, @_ });
    $s->($_) for @list;
    return @output;
}

=head2 stream 

    my $substitutor = $self->stream( \&output );
    for (@glyphids) { $substitutor->($_) }

This creates a stateful closure subroutine which acts as a
glyph-by-glyph substitution stream. Once a substitution is processed, or
no substitution is needed for the glyph ID stream, the closure calls the
provided output subroutine.

This allows you to interpose the stream in between an input and output
mechanism, and not worry about maintaining ligature substitution state
yourself.

Passing -1 to the substitutor drains the stream.

=cut

sub stream {
    my ($self, $outputsub) = @_;
    my $state = {};
    my $closure;
    $closure = sub {
        my $input = shift;
        # Despatch simple case
        $outputsub->($input),return if !%$state and !$self->{ligtable}{$input}
            and $input != -1;

        $state->{target} ||= $self->{ligtable};
        push @{$state->{list}}, $input unless $input == -1;
        if (defined $state->{target}{$input}) {
            $state->{target} = $state->{target}{$input};
            # And wait for next thing
        } elsif ( $state->{target}{FINAL} ) {
            # This swallows everything apart from current input
            $outputsub->($state->{target}{FINAL});
            $state = {};
            $closure->($input);
        } else {
            # Output one and unwind the stack
            my @list = @{$state->{list} || []};
            $state = {};
            $outputsub->(shift @list) if @list;
            $closure->($_) for @list;
        }
    }
}

=head1 AUTHOR

Simon Cozens, C<< <simon at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-font-ttf-opentypeligatures at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Font-TTF-OpenTypeLigatures>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Font::TTF::OpenTypeLigatures


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Font-TTF-OpenTypeLigatures>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Font-TTF-OpenTypeLigatures>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Font-TTF-OpenTypeLigatures>

=item * Search CPAN

L<http://search.cpan.org/dist/Font-TTF-OpenTypeLigatures/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2011 Simon Cozens.

This program is released under the following license: Perl


=cut

1; # End of Font::TTF::OpenTypeLigatures
