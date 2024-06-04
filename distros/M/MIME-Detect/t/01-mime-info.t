#!perl -w
use strict;
use Test::More tests => 20;
use MIME::Detect;
my $mime = MIME::Detect->new();

my $mbox = $mime->known_types->{'application/mbox'};

ok $mbox, "We find a type for 'application/mbox'";
my $superclass = $mbox->superclass;
if( !ok $superclass, "We have a superclass") {
    use Data::Dumper;
    diag Dumper $mbox;
    SKIP: { skip "We didn't even find a superclass", 1 };
} else {
    is $mbox->superclass->mime_type, 'text/plain', "It's a text file";

    ok $mbox->matches(<<'MBOX'), "We match some fake mbox file";
From me@example.com

Hello Friend!

MBOX
};

my $perl = $mime->known_types->{'application/x-perl'};

ok $perl, "We find a type for 'application/x-perl'";
   $superclass = $perl->superclass;
if( !ok $superclass, "We have a superclass") {
    SKIP: { skip "We didn't even find a superclass", 1 };
} else {
    is $perl->superclass->mime_type, 'application/x-executable', "It's an executable file";

    ok $perl->matches(<<'PERL'), "We match some fake Perl file";
#!/usr/bin/perl -w
use strict;
some random gibberish
qweoibvsjewrij
PERL
};

{
    open(my $fh, '<', \<<'PERL');
#!perl -w
use strict;
some random gibberish
qweoibvsjewrij
PERL
    ok $mime->mime_types($fh), "We match the second rule for some fake Perl file";
}

is $perl->valid_extension($0), 't', ".t is a valid extension for Perl scripts";
is $perl->valid_extension('test.pl'), 'pl', ".pl is a valid extension for Perl scripts";
is $perl->valid_extension('test.exe'), undef, ".exe is not valid extension for Perl scripts";

my $pl = $mime->mime_type_from_name($0);
is $pl, $perl, ".t files identify as Perl (test) files";

my $foo = $mime->mime_type_from_name('/uploads/foo.pl');
is $foo, $perl, "Nonexistent files identify as Perl files as well";

my $hpp = $mime->mime_type_from_name('/uploads/foo.h++');

if( !ok $hpp, "We identify h++ files") {
    SKIP: { skip "We didn't even find a type for 'h++' files", 1 };
} else {
    is $hpp->mime_type, 'text/x-c++hdr', "We identify h++ files correctly";
}

my $sevenZip = $mime->known_types->{'application/x-7z-compressed'};

if( !ok $sevenZip, "We find a type for 'application/x-7z-compressed'") {
    SKIP: { skip "We didn't even find a type for 'application/x-7z-compressed'", 1 };
} else {
    ok $sevenZip->matches("7z\274\257'\34\0"), "We identify 7zip files correctly";
}

my $payload = join '',
              "\x89",
              'PNG',
              "\x0d\x0a",
              "\x1a",
              "\x0a"
              ;

my $png = $mime->known_types->{'image/png'};

if( !ok $png, "We find a type for 'image/png'") {
    SKIP: { skip "We didn't even find a type for 'image/png'", 1 };
} else {
    ok $png->matches($payload), "We identify PNG files correctly";
}

