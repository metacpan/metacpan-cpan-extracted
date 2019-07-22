use Test2::V0 -no_srand => 1;
use File::Listing::Ftpcopy qw( :all );
use POSIX qw( strftime );

subtest 'unixy file' => sub {
  my $line = '-rw-r--r-- 1 ollisg ollisg 788 Jan 24 17:37 Ftpcopy.xs';
  note $line;
  my $h = ftpparse($line);
  is $h->{name}, 'Ftpcopy.xs', 'name = Ftpcopy.xs';
  is $h->{size}, '788',        'size = 788';
  is $h->{sizetype}, SIZE_BINARY, 'sizetype = SIZE_BINARY';
  note 'mtimetype: ' . $h->{mtimetype};
  note 'mtime:     ' . $h->{mtime};
  note 'as string: ' . strftime( "%T %A, %B %d, %Y", gmtime($h->{mtime}));
};

subtest 'VMS' => sub {
  my $line = 'SYSUAF.DAT;1            36/36         12-JUL-2012 09:17:04  [OLLISG]               (RWED,RWED,,)';
  note $line;
  my $h = ftpparse($line);
  is $h->{name}, 'SYSUAF.DAT', 'name = SYSUAF.DAT';
  is $h->{size}, 0,            'size = 0';
  is $h->{sizetype}, SIZE_UNKNOWN, 'sizetype = SIZE_UNKNOWN';
  note 'mtimetype: ' . $h->{mtimetype};
  note 'mtime:     ' . $h->{mtime};
  note 'as string: ' . strftime( "%T %A, %B %d, %Y", gmtime($h->{mtime}));
};

subtest 'unixy dir' => sub {
  my $line = 'drwxr-xr-x 5 ollisg ollisg 4096 Jan 24 23:58 Ftpparse';
  note $line;
  my $h = ftpparse($line);
  is $h->{name}, 'Ftpparse', 'name = Ftpparse';
  is $h->{flagtrycwd},  1, 'flagtrycwd = 1';
  is $h->{flagtryretr}, 0, 'flagtryretr = 0';
  is $h->{symlink}, undef, 'symlink = undef';
  note 'mtimetype: ' . $h->{mtimetype};
  note 'mtime:     ' . $h->{mtime};
  note 'as string: ' . strftime( "%T %A, %B %d, %Y", gmtime($h->{mtime}));
};

subtest 'unixy file 2' => sub {
  my $line = '-rw-r--r-- 1 ollisg ollisg 2713 Jan 24 23:58 ftpparse.h';
  note $line;
  my $h = ftpparse($line);
  is $h->{name}, 'ftpparse.h', 'name = ftpparse.h';
  is $h->{flagtrycwd},  0, 'flagtrycwd = 0';
  is $h->{flagtryretr}, 1, 'flagtryretr = 1';
  is $h->{symlink}, undef, 'symlink = undef';
  note 'mtimetype: ' . $h->{mtimetype};
  note 'mtime:     ' . $h->{mtime};
  note 'as string: ' . strftime( "%T %A, %B %d, %Y", gmtime($h->{mtime}));
};

subtest 'unixy sym link' => sub {
  my $line = 'lrwxrwxrwx 1 ollisg ollisg   11 Jan 25 10:31 passwd -> /etc/passwd';
  note $line;
  my $h = ftpparse($line);
  is $h->{name}, 'passwd', 'name = passwd';
  is $h->{flagtrycwd},  1, 'flagtrycwd = 1';
  is $h->{flagtryretr}, 1, 'flagtryretr = 1';
  is $h->{symlink}, '/etc/passwd', 'symlink = /etc/passwd';
  note 'mtimetype: ' . $h->{mtimetype};
  note 'mtime:     ' . $h->{mtime};
  note 'as string: ' . strftime( "%T %A, %B %d, %Y", gmtime($h->{mtime}));
};

done_testing;
