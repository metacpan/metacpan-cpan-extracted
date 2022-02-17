#!/usr/bin/env perl

use strict;
use warnings;

use Carp 'croak';
use Test::More tests => 13;

BEGIN {use_ok('Finance::AMEX::Transaction')}

use lib '.';
use t::lib::CompareFile;

my $file_v1 = 't/data/AMEX/SAMPLE.GRRCN Delimited (US) v1.2.txt';
my $file_v2 = 't/data/AMEX/SAMPLE.GRRCN Delimited (US) v2.01.txt';

{
  # autodetect
  my $grrcn = Finance::AMEX::Transaction->new(file_type => 'GRRCN');
  open my $fh, '<', $file_v1 or croak "cannot open GRRCN file: $!";

  is($grrcn->file_format, 'UNKNOWN', 'file_format is UNKNOWN before we have parsed any lines');

  my $record = $grrcn->getline($fh);

  is($grrcn->file_format, 'CSV', 'file_format is CSV after we have parsed a line');

  close $fh or croak "unable to close: $!";
}
{
  # set to CSV
  my $grrcn = Finance::AMEX::Transaction->new(
    file_type   => 'GRRCN',
    file_format => 'CSV',
  );
  open my $fh, '<', $file_v1 or croak "cannot open GRRCN file: $!";

  is($grrcn->file_format, 'CSV', 'file_format is CSV before we have parsed any lines when it has been set manually');

  my $record = $grrcn->getline($fh);

  is($grrcn->file_format, 'CSV', 'file_format is still CSV after we have parsed a line');

  close $fh or croak "unable to close: $!";
}
{
  # autodetect 1.01
  my $grrcn = Finance::AMEX::Transaction->new(file_type => 'GRRCN');
  open my $fh, '<', $file_v1 or croak "cannot open GRRCN file: $!";

  is($grrcn->file_version, 'UNKNOWN', 'file_version is UNKNOWN before we have parsed any lines');

  my $record = $grrcn->getline($fh);

  is($grrcn->file_version, '1.01', 'file_version is 1.01 after we have parsed a line');

  close $fh or croak "unable to close: $!";
}
{
  # set 1.01
  my $grrcn = Finance::AMEX::Transaction->new(
    file_type    => 'GRRCN',
    file_version => 1.01,
  );
  open my $fh, '<', $file_v1 or croak "cannot open GRRCN file: $!";

  is($grrcn->file_version, '1.01', 'file_version is 1.01 before we have parsed any lines when it has been set manually');

  my $record = $grrcn->getline($fh);

  is($grrcn->file_version, '1.01', 'file_version is still 1.01 after we have parsed a line');

  close $fh or croak "unable to close: $!";
}
{
  # autodetect 2.01
  my $grrcn = Finance::AMEX::Transaction->new(file_type => 'GRRCN');
  open my $fh, '<', $file_v2 or croak "cannot open GRRCN file: $!";

  is($grrcn->file_version, 'UNKNOWN', 'file_version is UNKNOWN before we have parsed any lines');

  my $record = $grrcn->getline($fh);

  is($grrcn->file_version, '2.01', 'file_version is still 2.01 after we have parsed a line');

  close $fh or croak "unable to close: $!";
}
{
  # set 2.01
  my $grrcn = Finance::AMEX::Transaction->new(
    file_type    => 'GRRCN',
    file_version => 2.01,
  );
  open my $fh, '<', $file_v2 or croak "cannot open GRRCN file: $!";

  is($grrcn->file_version, '2.01', 'file_version is 2.01 before we have parsed any lines when it has been set manually');

  my $record = $grrcn->getline($fh);

  is($grrcn->file_version, '2.01', 'file_version is still 2.01 after we have parsed a line');

  close $fh or croak "unable to close: $!";
}

done_testing();
