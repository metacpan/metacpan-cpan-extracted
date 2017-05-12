use Test::More tests => 5;
use Mac::Spotlight::MDItem ':constants';

{
    my $item = Mac::Spotlight::MDItem->new("MDItem.c");
    ok defined $item;
    like $item->get(kMDItemPath), qr/MDItem.c/;
#    like $item->get(kMDItemKind), qr/C Source File/;
    is $item->get(kMDItemIdentifier), undef;
    ok 1;
}

{
    my $item = Mac::Spotlight::MDItem->new("not existent");
    is $item, undef;
}



