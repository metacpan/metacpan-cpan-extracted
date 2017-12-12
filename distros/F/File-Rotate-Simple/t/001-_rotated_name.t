#!/usr/bin/env perl

use Test::Most;

use Time::Piece;
use Path::Tiny;

use_ok 'File::Rotate::Simple';

subtest 'default_format' => sub {

  my $r = File::Rotate::Simple->new(
      file => 'test.dat',
  );

  foreach (1,2, 10, 100) {
      is $r->_rotated_name($_) =>
          path("test.dat.$_"), "_rotated_name($_)";
  }

};

subtest 'custom number format' => sub {

    my $r = File::Rotate::Simple->new(
        file             => 'test.dat',
        extension_format => '.backup-%4#',
    );

  foreach (1,2, 10, 100, 1000) {
      is $r->_rotated_name($_) => path(sprintf('test.dat.backup-%04d', $_)),
      "_rotated_name($_)";
  }
};

subtest 'replace_extension' => sub {
    my $r = File::Rotate::Simple->new(
        file              => 'test.log',
        extension_format  => '.%3#.log',
        replace_extension => '.log',
        );

    foreach (1,2, 10, 100) {
        is $r->_rotated_name($_) =>
            path(sprintf('test.%03d.log', $_)), "_rotated_name($_)";
    }
};


    {
        my $time = localtime( time - 60 );

        my $r = File::Rotate::Simple->new(
            file             => 'test.dat',
            extension_format => '.%Y%m%d',
            time             => $time,
        );

        is $r->_rotated_name(1) =>
            path('test.dat' . $time->strftime($r->extension_format)),
            '_rotated_name(1) with date format';
    }

subtest 'Time::Piece date format' => sub {
    my $time = localtime();

    my $r = File::Rotate::Simple->new(
        file             => 'test.dat',
        extension_format => '.%Y%m%d',
        time             => $time,
        );

    isa_ok $r->time => 'Time::Piece';

  SKIP: {
      skip "not daylight savings time" => 1 unless $time->isdst;

      isnt $r->time->tzoffset => 0, 'localtime';
    }

    is $r->_rotated_name(1) =>
        path('test.dat' . $time->strftime($r->extension_format)),
        '_rotated_name(1) with date format';
};

subtest 'Time::Piece date format with gmtime' => sub {
    my $time = gmtime();

    my $r = File::Rotate::Simple->new(
        file             => 'test.dat',
        extension_format => '.%Y%m%d',
        time             => $time,
        );

    is $r->time->tzoffset => 0, 'gmtime';

    is $r->_rotated_name(1) =>
        path('test.dat' . $time->strftime($r->extension_format)),
        '_rotated_name(1) with date format';
};

subtest 'Time::Piece date format with %# extension' => sub {
        my $time = localtime;

        my $r = File::Rotate::Simple->new(
            file             => 'test.dat',
            extension_format => '.%y-%m-%d.%2#',
            time             => $time,
        );

        is $r->_epoch => $time->epoch, '_epoch';

        is $r->_rotated_name(9) =>
            path('test.dat' . $time->strftime('.%y-%m-%d.09')),
            '_rotated_name(9)';
};

subtest 'Time::Moment with date format' => sub {

  SKIP: {

      eval 'use Time::Moment; 1;'
          or skip 'Time::Moment not installed' => 3;

      my $time = Time::Moment->now;

      my $r = File::Rotate::Simple->new(
            file             => 'test.dat',
            extension_format => '.%Y%m%d',
            time             => $time,
      );

      isa_ok $r->time, 'Time::Moment';

      is $r->_epoch => $time->epoch, '_epoch';

      is $r->_rotated_name(1) =>
          path('test.dat' . $time->strftime($r->extension_format)),
          '_rotated_name(1) with Time::Moment date';
    }

};

subtest 'DateTime with date format' => sub {

  SKIP: {

      eval 'use DateTime; 1;'
          or skip 'DateTime not installed' => 3;

      my $time = DateTime->now;

      my $r = File::Rotate::Simple->new(
          file             => 'test.dat',
          extension_format => '.%Y%m%d',
          time             => $time,
      );

      isa_ok $r->time => 'DateTime';

      is $r->_epoch => $time->epoch, '_epoch';

      is $r->_rotated_name(1) =>
          path('test.dat' . $time->strftime($r->extension_format)),
          '_rotated_name(1) with DateTime date';
    }
};

done_testing;
