# vim: filetype=perl :
use Test::More tests => 9217;
use lib 't/lib';
use Test::MMS::Parser;

BEGIN {
   use_ok('MMS::Parser');
}

my $parser = MMS::Parser->create();

my @immediates = (
   [ YES => 0x80 ],
   [ NO => 0x81 ],
   [ absolute_token => 0x80 => 'absolute' ],
   [ relative_token => 0x81 => 'relative' ],
   [ address_present_token => 0x80 => 'address-present' ],
   [ insert_address_token => 0x81 => 'insert-address' ],
   [ PERSONAL => 0x80 ],
   [ ADVERTISEMENT => 0x81 ],
   [ INFORMATIONAL => 0x82 ],
   [ AUTO => 0x83 ],
   [ m_send_req => 0x80 ],
   [ m_send_conf => 0x81 ],
   [ m_notification_ind => 0x82 ],
   [ m_notifyresp_ind => 0x83 ],
   [ m_retrieve_conf => 0x84 ],
   [ m_acknowledge_ind => 0x85 ],
   [ m_delivery_ind => 0x86 ],
   [ LOW => 0x80 ],
   [ NORMAL => 0x81 ],
   [ HIGH => 0x82 ],
   [ OK => 0x80 ],
   [ ERROR_UNSPECIFIED => 0x81 ],
   [ ERROR_SERVICE_DENIED => 0x82 ],
   [ ERROR_MESSAGE_FORMAT_CORRUPT => 0x83 ],
   [ ERROR_SENDING_ADDRESS_UNRESOLVED => 0x84 ],
   [ ERROR_MESSAGE_NOT_FOUND => 0x85 ],
   [ ERROR_NETWORK_PROBLEM => 0x86 ],
   [ ERROR_CONTENT_NOT_ACCEPTED => 0x87 ],
   [ ERROR_UNSUPPORTED_MESSAGE => 0x88 ],
   [ HIDE => 0x80 ],
   [ SHOW => 0x81 ],
   [ EXPIRED => 0x80 ],
   [ RETRIEVED => 0x81 ],
   [ REJECTED => 0x82 ],
   [ DEFERRED => 0x83 ],
   [ UNRECOGNISED => 0x84 ],
);

immediate($parser, @$_) for @immediates;
