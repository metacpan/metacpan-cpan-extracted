# $File: //member/autrijus/Lingua-ZH-Summarize/Summarize.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3687 $ $DateTime: 2003/01/20 07:22:40 $

package Lingua::ZH::Summarize;
$Lingua::ZH::Summarize::VERSION = '0.01';

use strict;
use vars qw($VERSION @ISA @EXPORT);

use Exporter;
use Lingua::ZH::Toke;

=head1 NAME

Lingua::ZH::Summarize - Summarizing bodies of Chinese text

=head1 SYNOPSIS

    use Lingua::ZH::Summarize;

    print summarize( $text );                    # Easy, no? :-)
    print summarize( $text, maxlength => 500 );  # 500-byte summary
    print summarize( $text, wrap => 75 );        # Wrap output to 75 col.

=head1 DESCRIPTION

This is a simple module which makes an unscientific effort at
summarizing Chinese text. It recognizes simple patterns which look like
statements, abridges them, and concatenates them into something vaguely
resembling a summary. It needs more work on large bodies of text, but
it seems to have a decent effect on small inputs at the moment.

Lingua::ZH::Summarize exports one function, C<summarize()>, which takes
the text to summarize as its first argument, and any number of optional
directives in C<name =E<gt> value> form. The options it'll take are:

=over

=item maxlength

Specifies the maximum length, in bytes, of the generated summary.

=item wrap

Prettyprints the summary output by wrapping it to the number of columns
which you specify.  This requires the L<Lingua::ZH::Wrap> module.

=back

Needless to say, this is a very simple and not terribly universally
effective scheme, but it's good enough for a first draft, and I'll bang
on it more later. Like I said, it's not a scientific approach to the
problem, but it's better than nothing.

=cut

@ISA     = qw(Exporter);
@EXPORT  = qw(summarize);

my %punct = map { $_ => $_ } qw(。 ？ ！ ； ...);
$punct{$_} = '。' for qw(， －);

my %key  = map { $_ => 1 } qw(是 會 曾 將 能 有);
my %stop = (
    %key, map { $_ => 1 } qw(
	的 裡 和 與 及 年 月 日 時 分 秒 可 對 於 但 也 且 或 中 而 為 叫
    )
);

my $is_utf8;
sub import {
    my $class = shift;

    if ($_[0] eq 'utf8' and !$is_utf8++) {
	Lingua::ZH::Toke->import(@_);

	require Encode;
	%key   = map { Encode::decode( big5 => $_ ) => 1 } keys %key;
	%stop  = map { Encode::decode( big5 => $_ ) => 1 } keys %stop;
	%punct = map {
	    Encode::decode( big5 => $_ ) =>
	    Encode::decode( big5 => $punct{$_} )
	} keys %punct;
    }
}

sub summarize {
    my ($text, %options) = @_;

    # Run each filter over the text.
    return unless $text;

    # Strip whitespace and formatting out of the text.
    $text =~ s/^\s+//;
    $text =~ s/\s+/ /sg;
    $text =~ s/\s+$//;

    unless (exists $options{maxlength} and $options{maxlength} > 0) {
	$options{maxlength} = log(length($text)) * 30;
    }

    ### Here's where the interesting logic happens.

    my $sentence = Lingua::ZH::Toke->new($text);

    # First we break it into sentence pieces. Kind of. Sort of.

    my $summary = '';
    my $flag = 1;

    <$sentence> unless $sentence->[0][0];

    while (my ($chunk, $punct) = (scalar <$sentence>, scalar <$sentence>)) {
	($flag = $punct{$punct}, next) unless $flag;
	$flag = $punct{$punct} or next;

	next unless length($chunk) > 10;
	next unless $chunk =~ /.+(?:\Q是\E|\Q會\E|\Q曾\E|\Q將\E|\Q能\E|\Q有\E)/;
	next if $stop{substr($chunk, 0, 2)} or $stop{substr($chunk, -2)};

	$summary .= $chunk . $punct{$punct};

	last if length($summary) >= $options{maxlength};
    }

    ### Done! Do any necessary postprocessing before returning.

    return $summary unless $options{wrap};

    # Prettyprint the summary to make it look nice on a terminal, if requested.

    require Lingua::ZH::Wrap;

    $summary = Encode::encode(big5 => $summary) if $is_utf8;
    $summary = Lingua::ZH::Wrap::wrap(
	$summary, $options{wrap} || 72, 1
    );
    $summary = Encode::decode(big5 => $summary) if $is_utf8;

    return $summary;
}

1;

=head1 SEE ALSO

L<Lingua::ZH::Toke>, L<Lingua::ZH::Wrap>, L<Lingua::EN::Summarize>

=head1 ACKNOWLEDGEMENTS

Algorithm adapted from the L<Lingua::EN::Summarize> module by
Dennis Taylor, E<lt>dennis@funkplanet.comE<gt>.

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2003 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
