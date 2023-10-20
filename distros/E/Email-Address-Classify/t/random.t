use strict;
use warnings FATAL => 'all';
use Test::More;
use lib 'lib';
use Email::Address::Classify;


# every other one is random
my @addresses = qw(
    vhenderson@example.com
    jnqrcpdd@example.com
    rlesnik@example.com
    diewtntp@example.com
    watch@example.com
    ebyxxhnbj@example.com
    recommendations@example.com
    twqyhmsy@example.com
    gwhite@example.com
    ylukvfog@example.com
    cherri@example.com
    yiyagqqh@example.com
    notifications-noreply@example.com
    zfziyxta@example.com
    newsletter@example.com
    bjjnkctu@example.com
    no-reply@example.com
    clsjevwz@example.com
    sales@example.com
    tdycdutu@example.com
    april@example.com
    kkjzxasz@example.com
    ftadviser@example.com
    vrnlwono@example.com
    ejohnson@example.com
    sfzdprhg@example.com
    membersuccess@example.com
    ypblfzlo@example.com
    hello@example.com
    nktvupxv@example.com
    adam.nanson@example.com
    dlcfukdk@example.com
    info@example.com
    deyqkgmz@example.com
    notification@example.com
    tztfcfqo@example.com
    klund@example.com
    uekkmrks@example.com
    a.berros@example.com
    jpbdyrfy@example.com
    birthdays@facebookmail.com
    lczuxneg@example.com
    kohls@s.kohls.com
    vvaeepeq@example.com
    oldnavy@email.oldnavy.com
    gtqwvpzl@example.com
);

plan tests => 2 * scalar @addresses;

my $is_random = 0;
foreach my $address (@addresses) {
    my $email = Email::Address::Classify->new($address);
    is $email->is_valid, 1, "$address is valid";
    is $email->is_random, $is_random, "$address is ".($is_random ? "random" : "not random");
    $is_random = 1-$is_random;
}
