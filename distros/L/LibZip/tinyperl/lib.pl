
  use LibZip::Scan ;

BEGIN {  
  @lib = qw(
  strict
  vars
  warnings
  warnings::register
  utf8
  
  UNIVERSAL
  attributes
  constant
  integer

  lib
  base
  overload

  re
  open
  ops
  
  Carp
  Config
  
  AutoLoader
  FindBin
  
  Safe
  
  IO::Socket

  #POSIX

  PerlIO
  
  
#Archive::Zip
#Compress::Zlib
Cwd
DB
Env
Errno
Exporter
Fcntl
File::Basename
File::CheckTree
File::Compare
File::Copy
File::DosGlob
File::Find
File::Glob
#File::Listing
File::Path
File::Spec
File::Spec::Cygwin
File::Spec::Epoc
File::Spec::Functions
File::Spec::Mac
File::Spec::OS2
File::Spec::Unix
File::Spec::VMS
File::Spec::Win32
File::Temp
File::stat
IO
#IO::AtomicFile
IO::Dir
IO::File
IO::Handle
#IO::InnerFile
#IO::Lines
IO::Pipe
IO::Poll
#IO::Scalar
#IO::ScalarArray
IO::Seekable
IO::Select
IO::Socket
IO::Socket::INET
IO::Socket::UNIX
#IO::String
#IO::Stringy
#IO::Wrap
#IO::WrapTie
#List::Util
PerlIO
PerlIO::encoding
PerlIO::scalar
PerlIO::via
PerlIO::via::QuotedPrint
Safe
#Scalar::Util
Symbol
Tie::Handle
#Time::Local
  
  );
  
  my %use ;
  foreach my $lib_i ( @lib ) {
    next if $use{$lib_i} || $lib_i !~ /^[\w:]+$/ ;
    eval("use $lib_i ();\n");
    print "$@\n" if $@ ;
    $use{$lib_i} = 1 ;
  }

}  

  

