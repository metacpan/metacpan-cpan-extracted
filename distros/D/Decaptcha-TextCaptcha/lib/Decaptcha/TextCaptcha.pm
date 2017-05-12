package Decaptcha::TextCaptcha;

use 5.010;
use strict;
use warnings;
use Exporter qw(import);

use Lingua::EN::Words2Nums;
use List::Util qw(first max min);

our $VERSION = '0.02';
$VERSION = eval $VERSION;

our @EXPORT = qw(decaptcha);

my %body_part = map { $_ => 1 } qw(
    ankle arm brain chest chin ear elbow eye face finger foot hair hand head
    heart knee leg nose stomach thumb toe tongue tooth waist
);
my %head_part = map { $_ => 1 } qw(
    brain chin ear eye face hair head mouth nose tooth
);
my %multiple_part = map { $_ => 1 } qw(
    ankle arm ear elbow eye finger foot hand knee leg thumb toe tooth
);
my %part_above_waist = map { $_ => 1 } qw(
    arm brain chest chin ear elbow eye face finger foot hair hand head heart
    mouth nose stomach thumb tongue tooth
);
my %part_below_waist = map {$_ => 1} qw( ankle foot knee leg toe );

my %colors = map { $_ => 1 } qw(
    black blue brown green pink purple red white yellow
);

my @days = qw(sunday monday tuesday wednesday thursday friday saturday);
my %days; @days{@days} = (0 .. @days);
my %weekend = map { $_ => 1 } @days[0,6];


sub decaptcha {
    my $q = shift or return;
    my $lq = lc $q;

    # Words and letters
    if ($lq eq 'which word in this sentence is all in capitals?') {
        my $word = first { ! tr/a-z// } split /\W+/, $q;
        return $word ? lc $word : undef;
    }
    if ($lq =~ /^(?:the word )?"(.*?)" has how many letters\?$/
        or $lq =~ /^how many letters in (?:the word )?"(.*?)"\?$/
    ) {
        return length $1;
    }
    if ($q =~ /^The word in capitals from (.*?) is\?$/
        or $q =~ /^Which word is all in capitals: (.*?)\?$/
        or $q =~ /^Which of (.*?) is in capitals\?$/
    ) {
        my $word = first { ! tr/a-z// } split /(?:,\s*| or )/, $1;
        return $word ? lc $word : undef;
    }
    if ($lq =~ /^which word starts with "(?<c>.)" from the list: (?<l>.*?)\?$/
        or $lq =~ /which word from list "(?<l>.*?)" has "(?<c>.)" as a first letter\?$/
        or $lq =~ /^what word from "(?<l>.*?)" begins with "(?<c>.)"\?$/
        or $lq =~ /^(?<l>.*?): the word starting with "(?<c>.)" is\?$/
    ) {
        return first { $+{c} eq substr $_, 0, 1 } split /,\s*/, $+{l};
    }
    if ($lq =~ /^which word contains "(?<c>[a-z])" from the list: (?<l>.*?)\?$/
        or $lq =~ /^(?<l>.*?): the word containing the letter "(?<c>[a-z])" is\?$/
        or $lq =~ /^what word from "(?<l>.*?)" contains the letter "(?<c>[a-z])"\?$/
        or $lq =~ /^which word from list "(?<l>.*?)" contains the letter "(?<c>[a-z])"\?$/
    ) {
        return first { 0 <= index $_, $+{c} } split /,\s*/, $+{l};
    }
    return $1 if $lq =~ /^the word "(.).*?" starts with which letter\?$/
        or $lq =~ /^the letter at the beginning of the word "(.).*?" is\?$/
        or $lq =~ /^the word "(.).*?" has which letter at the start\?$/
        or $lq =~ /^the (?:last|final) letter of word ".*?(.)" is\?$/
        or $lq =~ /^the word ".*?(.)" has which letter at the end\?$/;
    if ($lq =~ /^the (?<p>\d+)\S+ letter in (?:the word )?"(?<w>.*?)" is\?$/
        or $lq =~ /^the word "(?<w>.*?)" has which letter in (?<p>\d+)\S+ position\?$/
    ) {

        return $+{p} > length $+{w} ? undef : substr $+{w}, $+{p} - 1, 1;
    }

    # Days of week
    if ($lq =~ /^tomorrow is (\w+)\. if this is true, what day is today\?$/
        or $lq =~ /^if tomorrow is (\w+), what day is today\?$/
        or $lq =~ /^what day is today, if tomorrow is (\w+)\?$/
    ) {
        return exists $days{$1} ? $days[ ($days{$1} - 1) % 7 ] : undef;
    }
    if ($lq =~ /^yesterday was (\w+)\. if this is true, what day is today\?$/
        or $lq =~ /^if yesterday was (\w+), what day is today\?$/
        or $lq =~ /^what day is today, if yesterday was (\w+)\?$/
    ) {
        return exists $days{$1} ? $days[ ($days{$1} + 1) % 7 ] : undef;
    }
    if ($lq =~ /^which of these is a day of the week: (.*?)\?$/
        or $lq =~ /^which of (.*?) is a day of the week\?$/
        or $lq =~ /^which of (.*?) is the name of a day\?$/
        or $lq =~ /^the day of the week in (.*?) is\?$/
        or $lq =~ /^(.*?): the day of the week is\?$/
    ) {
        return first { exists $days{$_} } split /\W+/, $1;
    }
    if ($lq =~ /^(.*?) is part of the weekend\?$/) {
        return first { $weekend{$_} } split /\W+/, $1;
    }

    # Names
    return $1 if $lq =~ /^(\w+)'s? name is\?$/
        or $lq =~ /^what is (\w+)'s? name\?$/
        or $lq =~ /^the name of (\w+) is\?$/
        or $lq =~ /^if a person is called (\w+), what is their name\?$/;
    if ($q =~ /^The person's firstname in (.*?) is\?$/
        or $q =~ /^Which in this list is the name of a person: (.*?)\?$/
        or $q =~ /^(.*?): the person's name is\?$/
        or $q =~ /^Which of (.*?) is the name of a person\?$/
        or $q =~ /^Which of (.*?) is a person's name\?$/
    ) {
        my $name = first { /^[A-Z][a-z]+$/ } reverse split /\W+/, $1;
        return $name ? lc $name : undef;
    }

    # Colors
    return $1 if $lq =~ /^the colour of a (\w+) \S+ is\?$/
        or $lq =~ /^the (\w+) \S+ is what colour\?$/
        or $lq =~ /^if the \S+ is (\w+), what colour is it\?$/;
    if ($lq =~ /^how many colours in the list (.*?)\?$/
        or $lq =~ /^the list (.*?) contains how many colours\?$/
        or $lq =~ /^(.*?): how many colours in the list\?$/
    ) {
        return 0 + grep { $colors{$_} } split /\W+/, $1;
    }
    if ($lq =~ /^which of these is a colour: (.*?)\?$/
        or $lq =~ /^which of (.*?) is a colour\?$/
        or $lq =~ /^(.*?): the colour is\?$/
        or $lq =~ /^the colour in the list (.*?) is\?$/
    ) {
        return first { $colors{$_} } split /\W+/, $1;
    }
    if ($lq =~ /^what is the (?<p>\d+)\S+ colour in the list (?<l>.*?)\?$/
        or $lq =~ /^the (?<p>\d+)\S+ colour in (?<l>.*?) is\?$/
        or $lq =~ /^(?<l>.*?): the (?<p>\d+)\S+ colour is\?$/
    ) {
        return (grep { $colors{$_} } split /\W+/, $+{l})[ $+{p} - 1 ];
    }

    # Body parts
    if ($lq =~ /^the number of body parts in the list (.*?) is\?$/
        or $lq =~ /^the list (.*?) contains how many body parts\?$/
        or $lq =~ /^(.*?): how many body parts in the list\?$/
    ) {
        return 0 + grep { $body_part{$_} } split /\W+/, $1;
    }
    if ($lq =~ /^the body part in (.*?) is\?$/
        or $lq =~ /^which of these is a body part: (.*?)\?$/
        or $lq =~ /^which of (.*?) is a body part\?$/
        or $lq =~ /^which of (.*?) is part of a person\?$/
        or $lq =~ /^(.*?): the body part is\?$/
    ) {
        return first { $body_part{$_} } split /(?:,\s*| or )/, $1;
    }
    if ($lq =~ /^(.*?) is part of the head\?$/) {
        return first { $head_part{$_} } split /\W+/, $1;
    }
    if ($lq =~ /^(.*?) is something each person has more than one of\?$/) {
        return first { $multiple_part{$_} } split /\W+/, $1;
    }
    if ($lq =~ /^(.*?) is above the waist\?$/) {
        return first { $part_above_waist{$_} } split /\W+/, $1;
    }
    if ($lq =~ /^(.*?) is below the waist\?$/) {
        return first { $part_below_waist{$_} } split /\W+/, $1;
    }

    # Numbers and digits
    if ($lq =~ /^enter the number (.*?) in digits:$/
        or $lq =~ /^what is (.*?) as (?:digits|a number)\?$/
    ) {
        return words2nums $1;
    }
    if ($lq =~ /^which digit is (?<p>\d+)\S+ in the number (?<n>\d+)\?$/
        or $lq =~ /^what is the (?<p>\d+)\S+ digit in (?<n>\d+)\?$/
        or $lq =~ /^in the number (?<n>\d+), what is the (?<p>\d+)\S+ digit\?$/
    ) {
        return $+{p} > length $+{n} ? undef : substr $+{n}, $+{p} - 1, 1;
    }
    if ($lq =~ /^the (?<p>\d+)\S+ number from (?<l>.*?) is\?$/
        or $lq =~ /^what is the (?<p>\d+)\S+ number in the list (?<l>.*?)\?$/
        or $lq =~ /^what number is (?<p>\d+)\S+ in the series (?<l>.*?)\?$/
        or $lq =~ /^(?<l>.*?): the (?<p>\d+)\S+ number is\?$/
    ) {
        my @nums = map { words2nums $_ } split /(?:,\s*| and )/, $+{l};
        return $nums[ $+{p} - 1 ];
    }
    state $biggest_re = qr/(?:biggest | largest | highest)/x;
    if ($lq =~ /^enter the $biggest_re number of (.*?):$/
        or $lq =~ /^of the numbers (.*?), which is the $biggest_re\?$/
        or $lq =~ /^which of (.*?) is the $biggest_re\?$/
        or $lq =~ /^(.*?): which of these is the $biggest_re\?$/
        or $lq =~ /^(.*?): the $biggest_re is\?$/
    ) {
        return max map { words2nums $_ } split /(?:,\s*| or )/, $1;
    }
    state $smallest_re = qr/(?:smallest | lowest)/x;
    if ($lq =~ /^enter the $smallest_re number of (.*?):$/
        or $lq =~ /^of the numbers (.*?), which is the $smallest_re\?$/
        or $lq =~ /^which of (.*?) is the $smallest_re\?$/
        or $lq =~ /^(.*?): which of these is the $smallest_re\?$/
        or $lq =~ /^(.*?): the $smallest_re is\?$/
    ) {
        return min map { words2nums $_ } split /(?:,\s*| or )/, $1;
    }
    if ($lq =~ /^(.*?) (?:= |equals |is what)\?$/
        or $lq =~ /^what(?:'s| is) (.*?)\?$/
    ) {
        my $expr = $1;
        s/\b(?:add|plus)\b/+/ or s/\bminus\b/-/ for $expr;
        $expr =~ s{\b(\w+)\b}{ words2nums($1) // $1 }eg;
        return eval $expr if $expr =~ /^[ \d+-]+$/;
    }

    return;
}


1;

__END__

=head1 NAME

Decaptcha::TextCaptcha - solve captchas from textcaptcha.com

=head1 SYNOPSIS

    use Decaptcha::TextCaptcha;

    my $answer = decaptcha $question;

=head1 DESCRIPTION

Solves captchas from textcaptcha.com. The solve rate is currently 100%.

=head1 FUNCTIONS

=head2 decaptcha

Given a question provided by textcaptcha.com, returns the answer or undef.

=head1 SEE ALSO

L<http://textcaptcha.com/>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Decaptcha-TextCaptcha>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Decaptcha::TextCaptcha

You can also look for information at:

=over

=item * GitHub Source Repository

L<http://github.com/gray/decaptcha-textcaptcha>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Decaptcha-TextCaptcha>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Decaptcha-TextCaptcha>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Decaptcha-TextCaptcha>

=item * Search CPAN

L<http://search.cpan.org/dist/Decaptcha-TextCaptcha/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2015 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
