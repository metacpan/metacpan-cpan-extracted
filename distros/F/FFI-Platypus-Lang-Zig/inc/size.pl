use strict;
use warnings;
use File::chdir;
use Capture::Tiny qw( capture_stdout );
use Path::Tiny qw( path );
use Data::Dumper qw( Dumper );

{
  local $CWD = path(__FILE__)->parent->stringify;

  system 'zig', 'build-exe', 'size.zig' and die 'error building zig exe';

  my($out, $ret) = capture_stdout {
    system './size';
  };

  die 'error computing size' if $ret;

  my %types;

  foreach my $line (split /\n/, $out)
  {
    if($line =~ /^([\S]+)\s*=\s*([\S]+)$/)
    {
      $types{$1} = $2;
    }
  }

  unlink 'size';
  path('zig-cache')->remove_tree;

  path('../share/types.pl')->spew_utf8('my ' . Dumper(\%types));

  if(caller)
  {
    return \%types;
  }
  else
  {
    print Dumper(\%types);
  }
}
