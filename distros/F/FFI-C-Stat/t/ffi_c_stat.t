use Test2::V0 -no_srand => 1;
use FFI::C::Stat;
use File::stat;
use Config;

my @props = qw(
  dev
  ino
  mode
  nlink
  uid
  gid
  size
  mtime
  ctime
  blksize
  blocks
);

my $first = 1;

sub expect
{
  my($pstat) = @_;

  my %expect;

  foreach my $prop (@props)
  {
    $expect{$prop} = $pstat->$prop;
  }

  # work around possible Perl stat bug
  if($^O eq 'freebsd')
  {
    my($dev, $rdev) = (split /\s+/, `stat -r corpus/xx.txt`)[0,6];
    if($first)
    {
      note "On FreeBSD we will use the stat command instead of Perl's stat to find dev / rdev values";
      note "see https://github.com/uperl/FFI-C-Stat/issues/5";
      note "dev  = $dev / @{[ $pstat->dev ]}";
      note "rdev = $rdev / @{[ $pstat->rdev ]}";
    }
    $first = 0;
    $expect{dev}  = $dev;
  }

  $expect{rdev} = match qr/^-?[0-9]+$/;
  $expect{atime} = match qr/^[0-9]+$/;

  %expect;
}

my %expect = expect(stat 'corpus/xx.txt');

is(
  FFI::C::Stat->new('corpus/xx.txt'),
  object {
    call [ isa => 'FFI::C::Stat' ] => T();
    call $_ => $expect{$_} for @props;
  },
  'do a stat on a regular file',
);

is(
  FFI::C::Stat->clone(FFI::C::Stat->new('corpus/xx.txt')),
  object {
    call [ isa => 'FFI::C::Stat' ] => T();
    call $_ => $expect{$_} for @props;
  },
  'clone a stat',
);

is(
  FFI::C::Stat->clone(undef),
  object {
    call [ isa => 'FFI::C::Stat' ] => T();
    call $_ => D() for @props;
  },
  'clone undef',
);

{
  my $other = FFI::C::Stat->new('corpus/xx.txt');
  is(
    FFI::C::Stat->clone($$other),
    object {
      call [ isa => 'FFI::C::Stat' ] => T();
      call $_ => $expect{$_} for @props;
    },
    'clone a from an opaque',
  );
}

{
  my $fh;
  open $fh, '<', 'corpus/xx.txt';
  %expect = expect(stat $fh);
  is(
    FFI::C::Stat->new($fh),
    object {
      call [ isa => 'FFI::C::Stat' ] => T();
      call $_ => $expect{$_} for @props;
    },
    'do a stat on a filehandle',
  );

  close $fh;
}

unlink 'testlink';

if($Config{d_symlink} eq 'define')
{
  my $ret = eval { symlink 'corpus/xx.txt', 'testlink' };
  if($ret == 1)
  {
    %expect = expect(lstat 'testlink');

    is(
      FFI::C::Stat->new('testlink', symlink => 1),
      object {
        call [ isa => 'FFI::C::Stat' ] => T();
        call $_ => $expect{$_} for @props;
      },
      'do a stat on a symlink',
    );

  }
}

unlink 'testlink';

is(
  FFI::C::Stat->new,
  object {
    call [ isa => 'FFI::C::Stat' ] => T();
    call $_ => D() for @props;
  },
  'create uninitalized stat',
);

done_testing;
