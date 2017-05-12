# vim: filetype=perl :
use Test::More tests => 29;
use lib 't/lib';
use Test::MMS::Parser;

BEGIN {
   use_ok('MMS::Parser');
}

my $parser = MMS::Parser->create();

my %tests_for = (
   multipart_header => [
      ["\x00"                 => 0],
      ["\x01"                 => 1],
      ["\x10"                 => 16],
      ["\x7F"                 => 127],
      ["\xFF\x0F"             => 0x3F8F],
      ["\x82\x8F\x25"         => 0x87A5],
      ["\x8F\xFF\xFF\xFF\x7F" => 0xFF_FF_FF_FF],
   ],
   multipart_headers => [
      ["\x02\x01\x00" => {content_type => { text => '*/*', media_type => '*/*', parameters => {}},    other_headers => ''}],
      ["\x02\x01\x01" => {content_type => { text => 'text/*', media_type => 'text/*', parameters => {}}, other_headers => ''}],
      [
         "\x02\x01\x01blahblahblah" =>
           {content_type => { text => 'text/*', media_type => 'text/*', parameters => {}}, other_headers => 'blahblahblah'}
      ],
      [
         "\x02\x01\x3e" => {
            content_type  => {
               text => 'application/vnd.wap.mms-message',
               media_type => 'application/vnd.wap.mms-message',
               parameters => {},
            },
            other_headers => ''
         }
      ],
   ],
   multipart_entry => [
      [
         "\x07\x07\x02\x01\x00ciao1234567" => {
            headers => {
               content_type => {
                  text => '*/*',
                  media_type => '*/*',
                  parameters => {},
               },
               other_headers => 'ciao'
            },
            data    => '1234567'
         }
      ]
   ],
);
$tests_for{multipart_headers_len} = $tests_for{multipart_header};
$tests_for{multipart_data_len}    = $tests_for{multipart_header};

my ($in, @out);
for my $test (@{$tests_for{multipart_entry}}) {
   my ($input, $output) = @$test;
   next unless defined $output;
   $in .= $input;
   push @out, $output;
} ## end for my $test (@{$tests_for...
push @{$tests_for{multipart}}, [("\x00" . $in) => [@out]];
push @{$tests_for{multipart}}, [(pack("C*", scalar @out) . $in) => [@out]];

check_cases($parser, \%tests_for);
