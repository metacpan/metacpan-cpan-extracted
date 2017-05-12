use 5.006001;

use strict;

use lib qw(inc);
use Config;
use Devel::CheckLib;
use ExtUtils::MakeMaker;

if ( $^O =~ /^(MS)?Win32$/ ) {
  warn "IPC::ShareLite doesn't work on Windows.\nStopping.\n";
  exit 0;    # == NA test result
}

if ( $^O =~ /^VMS$/ ) {
  warn "IPC::ShareLite doesn't work on VMS.\nStopping.\n";
  exit 0;    # == NA test result
}

# Check that we have a C compiler
check_lib_or_exit();

my %mm_args = (
  ( MM->can( 'signature_target' ) ? ( SIGN => 1 ) : () ),
  NAME          => 'IPC::ShareLite',
  AUTHOR        => 'Maurice Aubrey <maurice@cpan.org>',
  VERSION_FROM  => 'lib/IPC/ShareLite.pm',
  ABSTRACT_FROM => 'lib/IPC/ShareLite.pm',
  PL_FILES      => {},
  PREREQ_PM     => {
    'Test::More' => 0,
    'File::Spec' => 0,
  },
  LIBS   => [''],
  DEFINE => '',
  INC    => '',
  OBJECT => 'sharestuff.o ShareLite.o',
  dist   => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES => 'IPC-ShareLite-*' },
);

{
  local $^W = 0;    # Silence warning about non-numeric version
  if ( $ExtUtils::MakeMaker::VERSION >= '6.31' ) {
    $mm_args{LICENSE} = 'perl';
  }
}

WriteMakefile( %mm_args );

package MY;

sub metafile {
  my @lines = split /\n/, shift->SUPER::metafile_target( @_ );

  my @exclude = qw( Devel::CheckLib IO::CaptureOutput );
  my $pad     = ' ' x 4;
  die "Can't parse Makefile fragment"
   unless $lines[-2] =~ /^([^"']*(["'])).*?(\2[^"']*)$/;
  splice @lines, -1, 0, map { "$1$_$3" } (
    'no_index:', "${pad}package:", map { "${pad}${pad}- $_" } @exclude
  );

  return join "\n", @lines;
}
