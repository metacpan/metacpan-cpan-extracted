package Lingua::ZH::Summary;

use warnings;
use strict;
use utf8;

use Net::YASA;

=head1 NAME

Lingua::ZH::Summary - Extract summary from Chinese text

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

Given a Chinese text, it will return the summary. Unlike Lingua-ZH-Summarize, 
this module depends on term frequency instead of knowledge. If knowledge 
analysis is required, use L<Lingua::ZH::Summarize> instead.

Perhaps a little code snippet.

    use Lingua::ZH::Summary;

    my $foo = Lingua::ZH::Summary->new();
    my $summary = $foo->summary(<FH> or $text);
    ...

=cut

my %punct = map { $_ => $_ } qw(。 ？ ！ ； …);
$punct{$_} = '。' for qw(， －);

my %key  = map { $_ => 1 } qw(是 會 曾 將 能 有);
my %stop = (
    %key, map { $_ => 1 } qw(
	的 裡 和 與 及 年 月 日 時 分 秒 可 對 於 但 也 且 或 中 而 為 叫
    )
);

=head1 METHODS

=head2 new

=cut

sub new {
    my $class = shift;
    my $self = {
	yasa => undef
    };
    if(@_) {
	my %arg = @_;

	foreach (keys %arg) {
	    $self->{lc($_)} = $arg{$_};
	}
    }
    $self->{yasa} = Net::YASA->new (minlength => 2);
    bless($self, $class);
    return($self);
}

=head1 FUNCTIONS

=head2 summary

=cut

sub summary {
    my $self = shift;
    my ($text, %options) = @_;

    return unless $text;

    # Strip whitespace and formatting out of the text.
    $text =~ s/^\s+//;
    $text =~ s/\s+/ /sg;
    $text =~ s/\s+$//;

    unless (exists $options{maxlength} and $options{maxlength} > 0) {
	$options{maxlength} = log(length($text)) * 15;
    }

    my $re = "(".join ("|",keys %punct).")";
    my @textlines = split /$re/,$text;

    # First we get the meaningful terms with respect to their term frequency

    my $summary = '';
    my $flag = 1;

    my $termset = $self->{yasa}->extract($text);

    # Get top 5
    my @terms = map {s/\t.*//; $_;} (@{$termset}[0..4]);
    $re = "(?:".join ("|",@terms).")";

    my $i=0;
    my $chunk;
    while (($chunk, my $punct) = (shift @textlines, shift @textlines) and defined($chunk)) {
	($flag = $punct{$punct}, next) unless $flag;
	$flag = $punct{$punct} or next;

	next unless length($chunk) > 5;
	next unless $chunk =~ /.+(?:\Q是\E|\Q會\E|\Q曾\E|\Q將\E|\Q能\E|\Q有\E|\Q為\E)/;
	next unless $chunk =~ /$re/;
	next if $stop{substr($chunk, 0, 1)} or $stop{substr($chunk, -1)};

	$summary .= $chunk . $punct{$punct};

	last if length($summary) >= $options{maxlength};
    }

    ### Done! Do any necessary postprocessing before returning.

    return $summary;
}

=head1 SEE ALSO

L<Lingua::ZH::Toke>, L<Lingua::ZH::Wrap>, L<Lingua::EN::Summary>

=head1 AUTHOR

Cheng-Lung Sung, C<< <clsung at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-lingua-zh-summary at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lingua-ZH-Summary>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lingua::ZH::Summary

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Lingua-ZH-Summary>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Lingua-ZH-Summary>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-ZH-Summary>

=item * Search CPAN

L<http://search.cpan.org/dist/Lingua-ZH-Summary>

=back

=head1 ACKNOWLEDGEMENTS

Reference to the L<Lingua::ZH::Summarize> module from
Audrey Tang E<lt>cpan@audreyt.orgE<gt>.

=head1 COPYRIGHT & LICENSE

Copyright 2007-2009 Cheng-Lung Sung, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Lingua::ZH::Summary
