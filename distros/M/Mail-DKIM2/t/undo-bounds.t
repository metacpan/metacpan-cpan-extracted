#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Email::MIME;
use Mail::DKIM2::MessageInstance;

# undo rebuilds the previous version from this one, so a Recipe may only copy
# lines that are here, never the same line twice, and only in ascending
# order. Anything else describes nothing a real hop did, and without the
# check a few bytes of header could make undo build a list of billions of
# lines.

my $orig = join("\r\n",
    'From: a@example.com',
    'Subject: hi',
    '',
    'line one',
    'line two',
    '',
);
my $mi1   = Mail::DKIM2::MessageInstance->calculate(Email::MIME->new($orig));
my $with1 = "Message-Instance: " . $mi1->as_string . "\r\n" . $orig;

# A real m=2 over a body with a footer added, then its body Recipe swapped for
# $recipe. The body is "line one", "line two", "footer": three lines.
sub with_body_recipe {
    my ($recipe) = @_;
    my $cur = Email::MIME->new($with1);
    $cur->body_set($cur->body_raw . "footer\r\n");
    my $mi2 = Mail::DKIM2::MessageInstance->calculate($cur, Email::MIME->new($with1));
    $mi2->set_tag('rb', $recipe);
    $cur->header_raw_prepend('Message-Instance', $mi2->as_string);
    return $cur->as_string;
}

sub undo_error {
    my ($text) = @_;
    return eval { Mail::DKIM2::MessageInstance->undo($text); 1 } ? undef : $@;
}

{
    my ($ok, $why) = Mail::DKIM2::MessageInstance->chain_verifies(
        with_body_recipe([[1, 2]]));
    ok($ok, 'a Recipe within the body undoes cleanly') or diag($why);
}

my @bogus = (
    [ [[1, 1000000000]],     qr/^body Recipe copies lines 1-1000000000 of 3$/,
      'a range past the end' ],
    [ [[0, 1]],              qr/^body Recipe copies lines 0-1 of 3$/,
      'a range from line 0' ],
    [ [[3, 2]],              qr/^body Recipe copies lines 3-2 of 3$/,
      'a range that runs backwards' ],
    [ [[1, 3], [1, 3]],      qr/^body Recipe copies lines 1-3 twice$/,
      'the same range twice' ],
    [ [[2, 3], [1, 2]],      qr/^body Recipe copies lines 2-2 twice$/,
      'ranges that overlap by one line, out of order' ],
    [ [[-1, 2]],             qr/^body Recipe has a malformed copy range$/,
      'a negative line number' ],
    [ [[1.5, 2]],            qr/^body Recipe has a malformed copy range$/,
      'a fractional line number' ],
    [ [[1, 2, 3]],           qr/^body Recipe has a malformed copy range$/,
      'a range of three numbers' ],
    [ [[1]],                 qr/^body Recipe has a malformed copy range$/,
      'a range of one number' ],
);

for my $case (@bogus) {
    my ($recipe, $error, $name) = @$case;
    my $text = with_body_recipe($recipe);
    like(undo_error($text), $error, "undo refuses $name");
    my ($ok, $why) = Mail::DKIM2::MessageInstance->chain_verifies($text);
    ok(!$ok, "... and so does chain_verifies");
}

# Ranges must ascend (spec-06 §5.1): a Recipe that copies a later line before
# an earlier one describes a reordering, which a hop records literally.
{
    my $text = with_body_recipe([[3, 3], [1, 2]]);
    like(undo_error($text), qr/^body Recipe copies lines 1-2 out of order$/,
        'undo refuses ranges out of order even when apart');
    my ($ok, $why) = Mail::DKIM2::MessageInstance->chain_verifies($text);
    ok(!$ok, '... and so does chain_verifies');
}

# The same rules for a header Recipe, counted per field name.
{
    my $cur = Email::MIME->new($with1);
    $cur->header_str_set('Subject', 'changed');
    my $mi2 = Mail::DKIM2::MessageInstance->calculate($cur, Email::MIME->new($with1));
    $mi2->set_tag('rh', { subject => [[1, 1000000000]] });
    $cur->header_raw_prepend('Message-Instance', $mi2->as_string);
    like(undo_error($cur->as_string),
        qr/^subject header Recipe copies lines 1-1000000000 of 1$/,
        'undo refuses a header range past the end');
}

# A hop that drops one of two identical fields: both previous copies match the
# one that is left, which a Recipe may copy only once, so calculate records
# the second copy literally.
{
    my $two = join("\r\n",
        'From: a@example.com',
        'Comments: same',
        'Comments: same',
        '',
        'body',
        '',
    );
    my $mi = Mail::DKIM2::MessageInstance->calculate(Email::MIME->new($two));
    my $prev = "Message-Instance: " . $mi->as_string . "\r\n" . $two;
    (my $one = $prev) =~ s/Comments: same\r\n//;
    my $cur = Email::MIME->new($one);
    my $mi2 = Mail::DKIM2::MessageInstance->calculate($cur, Email::MIME->new($prev));
    $cur->header_raw_prepend('Message-Instance', $mi2->as_string);
    my ($ok, $why) = Mail::DKIM2::MessageInstance->chain_verifies($cur->as_string);
    ok($ok, 'dropping one of two identical fields undoes cleanly') or diag($why);
}

done_testing;
