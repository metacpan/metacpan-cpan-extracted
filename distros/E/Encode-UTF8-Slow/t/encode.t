#!perl
use Test::More;
use Encode::UTF8::Slow qw/codepoint_to_bytes bytes_to_codepoint/;
use utf8;

pass 'import Encode::UTF8::Slow';

subtest codepoint_to_bytes => sub {
  is sprintf('%X',       unpack('C', codepoint_to_bytes(0x0024))),   '24',       'to_bytes dollar sign';
  is sprintf('%X%X',     unpack('CC',codepoint_to_bytes(0x00A2))),   'C2A2',     'to_bytes cent sign';
  is sprintf('%X%X',     unpack('CC',codepoint_to_bytes(0x0080))),   'C280',     'to_bytes control';
  is sprintf('%X%X%X',   unpack('CCC',codepoint_to_bytes(0x2764))),  'E29DA4',   'to_bytes heavy black heart';
  is sprintf('%X%X%X%X', unpack('CCCC',codepoint_to_bytes(0x10348))),'F0908D88', 'to_bytes gothic letter hwair';
  is sprintf('%X%X%X%X', unpack('CCCC',codepoint_to_bytes(0x1F5FC))),'F09F97BC', 'to_bytes tokyo tower';
};

subtest bytes_to_codepoint => sub {
  cmp_ok bytes_to_codepoint('$'), '==', 0x0024, 'to_codepoint dollar sign';
  cmp_ok bytes_to_codepoint('¢'), '==', 0x00A2, 'to_codepoint cent sign';
  cmp_ok bytes_to_codepoint('❤'), '==', 0x2764, 'to_codepoint heavy black heart';
  cmp_ok bytes_to_codepoint('𐍈'), '==', 0x10348,'to_codepoint gothic letter hwair';
  cmp_ok bytes_to_codepoint('🗼'),'==', 0x1F5FC,'to_codepoint tokyo tower';
  cmp_ok bytes_to_codepoint("\x{0080}"),'==', 0x0080, 'to_codepoint control';
};

done_testing;
