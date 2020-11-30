use strict;
use warnings;
use File::Listing;
use Test::More;
use Data::Dumper qw( Dumper );

subtest 'unix' => sub {

  my $dir = do {
    open my $fh, '<', 'corpus/unix.txt';
    local $/;
    <$fh>;
  };

  {
    check_output( parse_dir($dir, undef, 'unix') );
  }

  {
    open LISTING, '<', 'corpus/unix.txt';  ## no critic
    check_output( parse_dir(\*LISTING, undef, 'unix') );
  }

  {
    open my $fh, '<', 'corpus/unix.txt';
    check_output( parse_dir($fh, undef, 'unix') );
  }

  sub check_output {
    my @dir = @_;

    ok(@dir, 'ok 25');

    for (@dir) {
       my ($name, $type, $size, $mtime, $mode) = @$_;
       $size ||= 0;  # ensure that it is defined
       printf "# %-25s $type %6d  ", $name, $size;
       print scalar(localtime($mtime));
       printf "  %06o", $mode;
       print "\n";
    }

    # Pick out the Socket.pm line as the sample we check carefully
    my ($name, $type, $size, $mtime, $mode) = @{$dir[9]};

    ok($name, "Socket.pm");
    ok($type, "f");
    ok($size, 'ok 8817');

    # Must be careful when checking the time stamps because we don't know
    # which year if this script lives for a long time.
    my $timestring = scalar(localtime($mtime));
    ok($timestring =~ /Mar\s+15\s+18:05/);

    ok($mode, 'mode 0100644');
  }

  {
    my @dir = parse_dir(<<'EOT');
drwxr-xr-x 21 root root 704 2007-03-22 21:48 dir
EOT

    ok(@dir, 'ok 1');
    ok($dir[0][0], "dir");
    ok($dir[0][1], "d");

    my $timestring = scalar(localtime($dir[0][3]));
    print "# $timestring\n";
    ok($timestring =~ /^Thu Mar 22 21:48/);
  }
};

subtest 'apache' => sub {


  {
    my %expected;
    foreach my $test_name (qw( fancy-indexing html-table html-table-with-icons old-date xhtml with-icons ))
    {
      subtest $test_name => sub {
        my $html = do {
          open my $fh, '<', "corpus/apache-$test_name.html";
          local $/;
          <$fh>;
        };

        my %actual = map { $_->[0] => $_ } parse_dir($html, undef, "apache");

        subtest 'dir' => sub {
          note join(':', map { defined $_ ? $_ : 'undef' } @{ $actual{'lib'} });
          is $actual{'lib'}->[0], 'lib';
          is $actual{'lib'}->[1], 'd';
          is $actual{'lib'}->[2], 0;
          cmp_ok $actual{'lib'}->[3], '>', 0;
          is $actual{'lib'}->[4], undef;
        };

        subtest 'file' => sub {
          note join(':', map { defined $_ ? $_ : 'undef' } @{ $actual{'dist.ini'} });
          is $actual{'dist.ini'}->[0], 'dist.ini';
          is $actual{'dist.ini'}->[1], 'f';
          cmp_ok $actual{'dist.ini'}->[2], '>', 0;
          cmp_ok $actual{'dist.ini'}->[3], '>', 0;
          is $actual{'dist.ini'}->[4], undef;
        };

        if(%expected)
        {
          is_deeply \%actual, \%expected;
        }
        else
        {
          %expected = %actual;
        }

      };
    }

    foreach my $file (values %expected)
    {
      $file->[2] = undef;
      $file->[3] = undef;
    }

    subtest 'default' => sub {
      my $html = do {
        open my $fh, '<', "corpus/apache-default.html";
        local $/;
        <$fh>;
      };

      my %actual = map { $_->[0] => $_ } parse_dir($html, undef, "apache");

      subtest 'dir' => sub {
        is_deeply $actual{lib}, ['lib','d',undef,undef,undef];
      };
      subtest 'file' => sub {
        is_deeply $actual{'dist.ini'}, ['dist.ini','f',undef,undef,undef];
      };

      is_deeply \%actual, \%expected;
    };
  }

  foreach my $num (1..3)
  {
    subtest "legacy $num" => sub {
      my @dir = do {
        open my $fh, '<', "corpus/apache-legacy$num.html";
        local $/;
        <$fh>;
      };

      my @listing = parse_dir(shift @dir, undef, "apache");
      ok(@listing);
      note Dumper(\@listing);
   };
  }

  subtest 'year' => sub {

    my $parse = sub {
      my $date = shift;
      my $time = [
        parse_dir(
          qq{<img src="/icons/unknown.gif" alt="[   ]"> <a href="apache-modperl-1.3.6_1.19-0.i386.rpm">apache-modperl-1.3.6_1.19-0.i386.rpm</a>  $date  696K},
          undef,
          "apache",
        )
      ]->[0]->[3];

      [localtime($time)]->[5] + 1900;
    };

    # Note: explicitly not tested are two digit years,
    # because the current behavior is probably wrong.
    # Right now we assume 9x is 199x and 0-89 is 20xx,
    # which is definitely wrong in the long term, but
    # I don't even have any examples where apache provides
    # a two digit date.
    foreach my $year (1970..2500) {
      is( $parse->("$year-06-29 16:30"), $year, "year = $year" );
    }

  };

};

subtest 'dosftp' => sub {

  my $list = parse_dir(<<EOT, undef, 'dosftp');
02-05-96  10:48AM                 1415 src.slf
09-10-96  09:18AM       <DIR>          sl_util
EOT

  ok @$list, "is 2";
  ok $list->[0][0], "src.slf";
  ok $list->[0][1], "f";
  ok $list->[1][1], "d";
};

subtest 'perms' => sub {

  my $generator = sub {
    my($filename) = @_;
    open my $fh, '<', $filename or die "unable to open $filename $!";
    my $line = 0;
    return sub {
      while(my $text = <$fh>)
      {
        next if $text =~ /^#/;
        chomp $text;
        return ($line++, $text);
      }
      return;
    };
  };

  foreach my $type (qw( solaris ucb xpg4 gnu ))
  {
    subtest $type => sub {

      my $iter = $generator->("corpus/perms-$type.txt");

      while(my($expected, $line) = $iter->())
      {
        # This version of `ls' does not show whether the sticky bit (file mode bit
        # 01000 ) is set, so remove it from the expected output.
        $expected &= 06777 unless $type eq 'gnu';

        # Information text.
        my $text = sprintf('"%s" -> "%05o"', $line, $expected);

        # Get output and keep only permission (no file type info).
        my $got = File::Listing::file_mode($line);
        $got &= 07777;
        cmp_ok($got, '==', $expected, $text);
      }
    };
  };

};

subtest 'win32-openssh' => sub {
  my $txt = do {
    open my $fh, '<', "corpus/win32-openssh.txt";
    local $/;
    <$fh>;
  };

  my %actual = map { $_->[0] => $_ } parse_dir($txt, undef);

  subtest 'dir' => sub {
    is $actual{'.ssh'}->[0], '.ssh';
    is $actual{'.ssh'}->[1], 'd';
    like $actual{'.ssh'}->[3], qr/^[0-9]+$/;
    is $actual{'.ssh'}->[4], '16832';
  };
  subtest 'file' => sub {
    is $actual{'.bash_history'}->[0], '.bash_history';
    is $actual{'.bash_history'}->[1], 'f';
    is $actual{'.bash_history'}->[2], '2090';
    like $actual{'.bash_history'}->[3], qr/^[0-9]+$/;
    is $actual{'.bash_history'}->[4], '33152';
  };
};

done_testing;
