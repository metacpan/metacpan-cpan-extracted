use Test::More;
use Test::Exception;
use IO::Slice;
use File::Basename qw< dirname >;
my $dirname = dirname(__FILE__);
my @specs = map { $_->{filename} = "$dirname/$_->{filename}"; $_ }
   @{ do "$dirname/testfile.specs" };

lives_ok {
   my $s = IO::Slice->new($specs[0])
      or die 'new failed';
} 'new on filename lives, with hashref';

lives_ok {
   my $s = IO::Slice->new(%{$specs[0]})
      or die 'new failed';
} 'new on filename lives, with hash';

lives_ok {
   my %spec = %{$specs[0]};
   my $filename = delete $spec{filename};
   open my $fh, '<:raw', $filename
      or die "open('$filename'): $!";
   $spec{fh} = $fh;
   my $s = IO::Slice->new(%spec)
      or die 'new failed';
} 'new on filehandle lives';

lives_ok {
   my %spec = %{$specs[0]};
   my $filename = delete $spec{filename};
   open my $fh, '<:raw', $filename
      or die "open('$filename'): $!";
   $spec{fh} = $fh;
   $spec{filename} = '/path/to/nowhere';
   my $s = IO::Slice->new(%spec)
      or die 'new failed';
} 'new on filehandle lives, filename overridden and inexistent';

throws_ok {
   my %spec = %{$specs[0]};
   delete $spec{offset};
   my $s = IO::Slice->new(%spec)
      or die 'new failed';
} qr{offset}mxs, 'no offset is forbidden in new()';

throws_ok {
   my %spec = %{$specs[0]};
   delete $spec{length};
   my $s = IO::Slice->new(%spec)
      or die 'new failed';
} qr{length}mxs, 'no length is forbidden in new()';

throws_ok {
   my %spec = %{$specs[0]};
   delete $spec{filename};
   my $s = IO::Slice->new(%spec)
      or die 'new failed';
} qr{fh\ or\ filename}mxs, 'neither fh or filename is forbidden in new()';

done_testing();
