use Test2::V0 -no_srand => 1;
use FFI::C::File;
use Path::Tiny qw( path tempfile );

subtest 'basic read' => sub {

  my $expected = path(__FILE__)->slurp_raw;
  my $bytes    = length($expected);

  subtest 'explicit close' => sub {

    my $file = FFI::C::File->fopen(__FILE__, "r");
    isa_ok $file, 'FFI::C::File';

    is( $file->feof, F() );

    my $content = "\0" x $bytes;
    is( $file->fread(\$content, $bytes), $bytes );
    is( $content, $expected );

    is( $file->feof, F() );

    is( $file->fread(\$content, $bytes), 0 );
    is( $file->feof, T() );

    $file->fclose;

  };

  subtest 'implicit close' => sub {

    my $file = FFI::C::File->fopen(__FILE__, "r");
    isa_ok $file, 'FFI::C::File';

    my $content = "\0" x $bytes;
    is( $file->fread(\$content, $bytes), $bytes );
    is( $content, $expected );

  };

  subtest 'take / new' => sub {

    my $file = FFI::C::File->fopen(__FILE__, "r");
    isa_ok $file, 'FFI::C::File';

    my $ptr = $file->take;
    undef $file;
    $file = FFI::C::File->new($ptr);
    isa_ok $file, 'FFI::C::File';

    my $content = "\0" x $bytes;
    is( $file->fread(\$content, $bytes), $bytes );
    is( $content, $expected );

  };

};

subtest 'tmpfile' => sub {
  skip_all 'tricky permissions on windows' if $^O eq 'MSWin32';

  my $file = FFI::C::File->tmpfile;
  isa_ok $file, 'FFI::C::File';
};

subtest 'basic write' => sub {

  my $path = tempfile;

  my $content = "hello world\0there";
  my $bytes = length $content;

  my $file = FFI::C::File->fopen("$path", "w");
  is($file->fwrite(\$content, $bytes), $bytes);
  $file->fflush;

  is($path->slurp_raw, $content);

};

subtest 'freopen' => sub {

  my $path1 = tempfile;
  my $path2 = tempfile;

  my $file = FFI::C::File->fopen("$path1", "a");
  $file->fwrite(\"foo", 3);

  $file->freopen("$path2", "a");
  $file->fwrite(\"bar", 3);

  if($^O eq 'MSWin32')
  {
    $file->fflush;
    is($path1->slurp_raw, "foo");
    is($path2->slurp_raw, "bar");
  }
  else
  {
    $file->freopen(undef, "a");
    $file->fwrite(\"baz", 3);
    $file->fflush;
    is($path1->slurp_raw, "foo");
    is($path2->slurp_raw, "barbaz");
  }

  is dies { $file->freopen("bogus.txt", "r") }, match qr/^Error opening bogus\.txt with mode r:/;

};

subtest 'fseek / ftell / rewind' => sub {

  my $file = FFI::C::File->fopen(__FILE__, "r");
  is $file->ftell, 0;
  $file->fseek(0, 'end');
  cmp_ok $file->ftell, '>', 0;

  note "ftell = ", $file->ftell;

  $file->fseek(0, 'set');
  is $file->ftell, 0;
  $file->fseek(10, 'cur');
  is $file->ftell, 10;
  $file->fseek(-5, 'cur');
  is $file->ftell, 5;
  $file->rewind;
  is $file->ftell, 0;
};

subtest 'exceptions' => sub {

  is dies { FFI::C::File->fopen("bogus.txt", "r") }, match qr/^Error opening bogus\.txt with mode r:/;

};

done_testing;
