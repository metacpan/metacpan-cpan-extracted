package ChainPlanReference;
use strict;
use warnings;

# Every Message-Instance's header and body hashes for a raw message, two
# ways: by the undo walk, rebuilding each previous message in full
# (MessageInstance->undo, h_digest and b_digest), and by one pass with
# Mail::DKIM2::HeaderPlan and Mail::DKIM2::BodyPlan. Both return
#
#   { heads  => { m => { alg => base64 } },
#     hashes => { m => { alg => base64 } },
#     errors => { m => text } }
#
# heads are header hashes, hashes body hashes. An error is why instance m's
# Recipes do not undo; the walk stops there. Body hashes also stop below a
# null body Recipe.

use Exporter 'import';
our @EXPORT_OK = qw(reference_walk plan_walk);

use Mail::DKIM2::Common qw(parse_mime extract_mi_version);
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::BodyPlan;
use Mail::DKIM2::HeaderPlan;

my @ALGS = qw(sha256 sha512);

sub _top_mi {
    my ($msg) = @_;
    my %by_v = map { (extract_mi_version($_) // 0) => $_ } $msg->header_raw('Message-Instance');
    my ($num) = sort { $b <=> $a } keys %by_v;
    return ($num, $num && $by_v{$num});
}

sub reference_walk {
    my ($raw, %opts) = @_;
    my $msg = parse_mime($raw);
    my %out = (heads => {}, hashes => {}, errors => {});
    my $has_body = 1;
    while (1) {
        my ($num, $field) = _top_mi($msg);
        last unless $num;
        my $mi = Mail::DKIM2::MessageInstance->parse($field);
        my $hashes = $mi->get_tag('hashes') || {};
        for my $alg (grep { $hashes->{$_} } @ALGS) {
            $out{heads}{$num}{$alg} =
                Mail::DKIM2::MessageInstance::h_digest($msg, $alg, $opts{IgnorePrefixes});
            $out{hashes}{$num}{$alg} = Mail::DKIM2::MessageInstance::b_digest($msg, $alg)
                if $has_body;
        }
        $has_body = 0 if $mi->unrecoverable;
        my $prev = eval {
            Mail::DKIM2::MessageInstance->undo($msg, HeadersOnly => !$has_body)
        };
        unless ($prev) {
            $out{errors}{$num} = $@;
            last;
        }
        $msg = $prev;
    }
    return \%out;
}

# $chunks: the raw message cut into pieces, to feed the plan the body in the
# same pieces (the cut that falls in the headers is dropped).
sub plan_walk {
    my ($raw, $chunks, %opts) = @_;
    $chunks //= [$raw];
    my $hdr_end = index($raw, "\r\n\r\n");
    $hdr_end = $hdr_end < 0 ? length $raw : $hdr_end + 4;
    my $header = substr($raw, 0, $hdr_end - 2);

    my $hplan = Mail::DKIM2::HeaderPlan->new($header,
        IgnorePrefixes => $opts{IgnorePrefixes});
    my %by_v = map { (extract_mi_version($_) // 0) => $_ } $hplan->values('Message-Instance');
    my @mi;
    for my $v (sort { $b <=> $a } grep { $_ } keys %by_v) {
        my $mi = eval { Mail::DKIM2::MessageInstance->parse($by_v{$v}) } or last;
        push @mi, $mi;
    }
    $hplan->plan(@mi);
    my $plan = Mail::DKIM2::BodyPlan->new(@mi);

    my $pos = 0;
    for my $c (@$chunks) {
        my $end = $pos + length $c;
        if ($end > $hdr_end) {
            my $from = $pos > $hdr_end ? $pos : $hdr_end;
            $plan->add(substr($raw, $from, $end - $from));
        }
        $pos = $end;
    }
    $plan->finish;

    my %out = (heads => {}, hashes => {}, errors => {});
    for my $mi (@mi) {
        my $m = 0 + $mi->get_tag('m');    # m=01 is 1, as the Verifier asks
        for my $alg (@ALGS) {
            my $hh = $hplan->header_hash($m, $alg);
            $out{heads}{$m}{$alg} = $hh if defined $hh;
            my $bh = $plan->body_hash($m, $alg);
            $out{hashes}{$m}{$alg} = $bh if defined $bh;
        }
        if (defined(my $e = $plan->recipe_error($m) // $hplan->recipe_error($m))) {
            $out{errors}{$m} = $e;
            last;
        }
    }
    return \%out;
}

1;
