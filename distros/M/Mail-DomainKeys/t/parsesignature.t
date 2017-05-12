use Test::More tests => 6;
use Mail::DomainKeys::Header;
use Mail::DomainKeys::Signature;

use strict;

my $line = <<EOB;
DomainKey-Signature: q=dns; a=rsa-sha1; c=nofws;
        s=brisbane; d=football.example.com;
        h=Received:From:To:Subject:Date;
        b=SNgONWQ+ACNdqUV+QjDIgn1tNbiPOtxoIzqRKZobc5geq2Qllf++3bxi2mdU08ju
          7X0fGsmhp/f/Zdve+aao3klB7xUpIjpJhhSSPaIK8qjGErTG+mWPAD8CPdGsUUpX
EOB

my $hedr = new Mail::DomainKeys::Header(Line => $line);

my $sign = parse Mail::DomainKeys::Signature(String => $hedr->vunfolded);

ok(defined $sign, "parsed the signature...");
isa_ok($sign, "Mail::DomainKeys::Signature");
is($sign->protocol, "dns", "found the protocol...");
is($sign->selector, "brisbane", "found the selector...");
is($sign->domain, "football.example.com", "found the domain...");

my @list = $sign->headerlist;

is(@list, 5, "and the headerlist!");
