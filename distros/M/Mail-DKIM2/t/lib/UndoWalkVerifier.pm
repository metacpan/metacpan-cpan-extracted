package UndoWalkVerifier;
use strict;
use warnings;

# The Verifier with its Message-Instance chain walked the slow, obvious way:
# keep the body, check the top instance against the message, undo it
# (MessageInstance->undo, rebuilding the previous message in full) and check
# the next one down. Mail::DKIM2::Verifier itself never rebuilds anything:
# it reads every hash from Mail::DKIM2::HeaderPlan and BodyPlan. This is the
# reference the tests hold those plans to -- same verdicts, same words.

use parent 'Mail::DKIM2::Verifier';
use Mail::DKIM2::Common qw(parse_mime extract_mi_version);
use Mail::DKIM2::MessageInstance;

# Keep the body as well as planning it.
sub finish_header {
    my $self = shift;
    $self->SUPER::finish_header;
    return if $self->stopped;
    my $planned = $self->{_body_sink};
    $self->{_kept_body} = '';
    $self->{_body_sink} = sub {
        $self->{_kept_body} .= $_[0];
        $planned->($_[0]) if $planned;
    };
}

sub _verify_mi_chain {
    my ($self) = @_;
    return $self->SUPER::_verify_mi_chain if $self->{HeadersOnly};

    my $msg = parse_mime(join('', @{$self->{headers}}) . "\r\n" . $self->{_kept_body});
    my $headers_only = 0;
    while (1) {
        my %by_v = map { (extract_mi_version($_) // 0) => $_ } $msg->header_raw('Message-Instance');
        my $num = %by_v ? (sort { $b <=> $a } keys %by_v)[0] : 0;
        last unless $num;

        my ($ok, $err) = Mail::DKIM2::MessageInstance->verify($msg,
            IgnorePrefixes => $self->{IgnorePrefixes}, HeadersOnly => $headers_only);
        return $self->_mi_mismatch($num, $err) unless $ok;
        last if $num <= 1;

        $headers_only = 1 if Mail::DKIM2::MessageInstance->parse($by_v{$num})->unrecoverable;
        my $prev = eval { Mail::DKIM2::MessageInstance->undo($msg, HeadersOnly => $headers_only) };
        die $@ if ref $@;
        return $self->_mi_undo_failed($num, $@) if $@ || !$prev;
        $msg = $prev;
    }
    return 1;
}

1;
