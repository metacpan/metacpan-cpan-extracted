use Test::More tests => 1;
use Email::MIME;
use Email::MIME::Attachment::Stripper;
use Data::Dumper;
use Email::Simple;
{ local $/;
$mess = <DATA>;
}
my $msg = Email::MIME->new($mess);
$mm = Email::MIME::Attachment::Stripper->new( $msg );
do{ok(0); require Data::Dumper;warn Data::Dumper::Dumper($_);} for $mm->attachments;
like($mm->message->body, qr/\S/, "We have a body");
__DATA__
Return-Path: <jtobey@john-edwin-tobey.org>
Mailing-List: contact perl6-internals-help@perl.org; run by ezmlm
Delivered-To: mailing list perl6-internals@perl.org
Received: (qmail 15206 invoked from network); 2 Aug 2000 21:04:45 -0000
Received: from jtobey.ne.mediaone.net (HELO feynman.localnet) (24.147.19.222)
  by tmtowtdi.perl.org with SMTP; 2 Aug 2000 21:04:45 -0000
Received: by ne.mediaone.net
	via sendmail from stdin
	id <m13K5lI-000FOJC@feynman.localnet> (Debian Smail3.2.0.102)
	for perl6-internals@perl.org; Wed, 2 Aug 2000 17:09:12 -0400 (EDT) 
Message-Id: <m13K5lI-000FOJC@feynman.localnet>
Date: Wed, 2 Aug 2000 17:09:12 -0400 (EDT)
From: John Tobey <jtobey@john-edwin-tobey.org>
To: dan@sidhe.org
CC: perl6-internals@perl.org, brent.fulgham@xpsystems.com
In-reply-to: <4.3.2.7.0.20000802165315.00d4fdd0@24.8.96.48> (message from Dan
	Sugalski on Wed, 02 Aug 2000 16:55:16 -0400)
Subject: Pickle now Helmi (was Re: GC)
References:  <4.3.2.7.0.20000802165315.00d4fdd0@24.8.96.48>

Dan Sugalski <dan@sidhe.org> wrote:
> At 04:38 PM 8/2/00 -0400, John Tobey wrote:
> >Can I safely assume that we will be counting references for garbage
> >collection?
> 
> No.
> 
> In fact, you can safely assume that GC will be handled by some non-refcount 
> method, and that GC and end-of-scope action will be decoupled. (Whether 
> that *happens* is a separate issue, but it was the plan)

No problem.  I'll have both an addref()/delref() pair and a
protect()/unprotect() pair and use all four functions where
appropriate.  One of the pairs will be no-ops, depending on which GC
we use.  Pickle may end up bringing mark+sweep to Perl 5 as a viable
option...

By the way, an announcement:  Pickle is now called HELMI, at the
suggestion of Brent Fulgham, who has volunteered to get in on
SourceForge.  Brent explains:

    HELMI

    (Helmi is Finnish for 'pearl').

    We can then create some stupid acronym:

    _H_euristic
    _E_xtension
    _L_anguage
    and
    _M_odular
    _I_nterpreter

    coupled with the more whimsical version:

    _H_orrifyingly
    _E_clectic
    _L_anguage
    of
    _M_ass
    _I_nsanity

Thanks, Brent!

-- 
John Tobey, late nite hacker <jtobey@john-edwin-tobey.org>
\\\                                                               ///
]]]             With enough bugs, all eyes are shallow.           [[[
///                                                               \\\
