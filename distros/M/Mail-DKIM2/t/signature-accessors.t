use strict;
use warnings;
use Test::More;
use lib 'lib';
use Mail::DKIM2::Signature;

# Every tag accessor on a Signature is a getter with an optional setter
# argument -- sequence(), domain(), mail_from(), rcpt_to(), flags() alike.

my $sig = Mail::DKIM2::Signature->new(
    Sequence => 1, Domain => 'example.com', Timestamp => 1,
    MailFrom => '<a@example.com>', RcptTo => ['<b@example.net>'],
    Signatures => [['sel1', 'rsa-sha256', '']],
);

is($sig->mail_from, '<a@example.com>', 'mail_from reads mf=');
is($sig->mail_from('c@example.org'), '<c@example.org>', 'mail_from sets, bracketing the path, and returns the new value');
is($sig->mail_from, '<c@example.org>', '  ... and the tag changed');
is($sig->mail_from('<>'), '<>', 'the null sender round-trips');

is_deeply($sig->rcpt_to, ['<b@example.net>'], 'rcpt_to reads rt=');
is_deeply($sig->rcpt_to(['d@example.net', '<e@example.net>']), ['<d@example.net>', '<e@example.net>'],
    'rcpt_to sets from a list, bracketing each');
is_deeply($sig->rcpt_to('f@example.net'), ['<f@example.net>'], 'a single address is accepted');
ok(!eval { $sig->rcpt_to([]); 1 }, 'an empty list croaks');

is($sig->flags, undef, 'no f= means undef');
is_deeply($sig->flags(['donotmodify', 'feedback']), ['donotmodify', 'feedback'], 'flags sets from a list');
is($sig->get_tag('f'), 'donotmodify,feedback', '  ... as a comma list on the wire');

my $nd = Mail::DKIM2::Signature->new(Sequence => 2, Domain => 'fwd.example', NextDomain => 'next.example',
    Signatures => [['sel1', 'rsa-sha256', '']]);
ok(!eval { $nd->rcpt_to(['<x@y>']); 1 }, 'rcpt_to on an nd= signature croaks');
like($@, qr/nd=/, '  ... citing the exclusion');
ok(!eval { $nd->mail_from('<x@y>'); 1 }, 'mail_from on an nd= signature croaks');
ok(!$sig->can('set_rcpt_to'), 'there is one way to set rt=');

done_testing;
