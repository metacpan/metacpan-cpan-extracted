#
# MARCXML implementation for MARC records
#
# Copyright (c) 2011-2014, 2016 University Of Helsinki (The National Library Of Finland)
#
# This file is part of marc-file-marcxml
#
# This project's source code is licensed under the terms of GNU General Public License Version 3.
#

use Fennec class => 'MARC::File::MARCXML';
use MARC::Record;

sub readFileToString {

  my $file;
  my $str = '';
  my $filename = shift;

  open($file, $filename);

  while (<$file>) {
    $str .= $_;
  }

  close($file);

  return $str;

}

my $class = 'MARC::File::MARCXML';

ok($INC{'MARC/File/MARCXML.pm'}, "Loaded {$class}");
is($CLASS, $class, "We have {$class}");
is(class(), $class, "We have class()");

describe(decode => sub {

  tests(invalid_input => sub {
    throws_ok(sub { MARC::File::MARCXML->decode('foo') }, '/^could not parse xml:/', 'Should fail to decode invalid input');
  });

  tests(success => sub {

    my $str = '<?xml';
    my $record = MARC::File::MARCXML->decode(readFileToString('t/files/marcxml.xml'));

    isa_ok($record, 'MARC::Record', 'Should decode xml to MARC::Record');
  
  });

});

describe(encode => sub {

  tests(invalid_input => sub {
    throws_ok(sub { MARC::File::MARCXML->encode('foo') }, '/^/', 'Should fail to encode invalid input');
});

  tests(success => sub {

    my $record = MARC::Record->new();

    $record->leader('02209cam a2200541zi 4500');
    $record->append_fields((
      MARC::Field->new('001', '000000000'),
      MARC::Field->new('245',
                       ' ',
                       ' ',
                       'a' => 'foobar'
      )
    ));

    is(MARC::File::MARCXML->encode($record), readFileToString('t/files/marcxml.xml'));

  })

});

done_testing();
