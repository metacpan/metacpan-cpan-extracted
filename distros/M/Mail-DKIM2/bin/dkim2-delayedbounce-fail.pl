#!/usr/bin/perl
use 5.020; use strict; use warnings;

# DKIM2 delayed-bounce demo delivery agent.
#
# Postfix pipe(8) transport for reflector-delayedbounce@dkim2.com. The address
# is a valid recipient (listed in local_recipient_maps), so Postfix ACCEPTS it
# at RCPT TO with a 250 — then this "delivery agent" always fails permanently,
# so Postfix's own bounce(8) originates a real Delivery Status Notification.
# That DSN is DKIM2-signed on the way out by the outbound milter (main.cf:
# internal_mail_filter_classes = bounce), demonstrating a genuinely
# MTA-generated, DKIM2-signed delayed bounce (RFC 6522 DSN structure; DKIM2
# draft §11/§12).
#
# This is deliberately NOT the "error:" transport: error: rejects the
# recipient at RCPT time for SMTP clients (a synchronous 550), which is not a
# *delayed* bounce. Accepting at RCPT and failing at delivery is what produces
# the asynchronous, Postfix-originated DSN.
#
# pipe(8) exit-status convention (sysexits.h): EX_OK (0) = delivered,
# EX_TEMPFAIL (75) = defer/retry, anything else = permanent failure -> bounce.
# We exit EX_NOUSER (67) so Postfix generates a permanent (5.x.x) bounce; the
# text printed here becomes the diagnostic in that bounce.

# Consume the message on stdin so Postfix never sees a broken pipe.
do { local $/; my $discard = <STDIN>; };

print "DKIM2 delayed-bounce demo: this address intentionally fails delivery, ",
      "so the MTA originates a bounce that the outbound DKIM2 milter signs.\n";

exit 67;   # EX_NOUSER -> permanent failure -> Postfix bounce(8) generates a DSN
