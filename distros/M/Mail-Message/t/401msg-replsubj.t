#!/usr/bin/env perl
#
# Test the creation of reply subjects
#

use strict;
use warnings;

use Mail::Message::Test;
use Mail::Message::Construct::Reply;

use Test::More tests => 21;


is(Mail::Message->replySubject('subject'), 'Re: subject');
is(Mail::Message->replySubject('Re: subject'), 'Re[2]: subject');
is(Mail::Message->replySubject('Re[1]: subject'), 'Re[2]: subject');
is(Mail::Message->replySubject('Re[2]: subject'), 'Re[3]: subject');
is(Mail::Message->replySubject('Re: Re: subject'), 'Re[3]: subject');
is(Mail::Message->replySubject('Re: Re[2]: subject'), 'Re[4]: subject');
is(Mail::Message->replySubject('Re Re: subject'), 'Re[3]: subject');
is(Mail::Message->replySubject('Re,Re: subject'), 'Re[3]: subject');
is(Mail::Message->replySubject('Re Re[2]: subject'), 'Re[4]: subject');
is(Mail::Message->replySubject('subject (Re)'), 'Re[2]: subject');
is(Mail::Message->replySubject('subject (Re) (Re)'), 'Re[3]: subject');
is(Mail::Message->replySubject('Re: subject (Re)'), 'Re[3]: subject');
is(Mail::Message->replySubject('subject (Forw)'), 'Re[2]: subject');
is(Mail::Message->replySubject('subject (Re) (Forw)'), 'Re[3]: subject');
is(Mail::Message->replySubject('Re: subject (Forw)'), 'Re[3]: subject');

is(Mail::Message->replySubject('subject: sub2'), 'Re: subject: sub2');
is(Mail::Message->replySubject('Re: subject: sub2'), 'Re[2]: subject: sub2');
is(Mail::Message->replySubject('subject : sub2'), 'Re: subject : sub2');
ok(Mail::Message->replySubject('Re: subject : sub2 (Forw)')
   eq 'Re[3]: subject : sub2');
is(Mail::Message->replySubject(''), 'Re: your mail');
is(Mail::Message->replySubject(undef), 'Re: your mail');
