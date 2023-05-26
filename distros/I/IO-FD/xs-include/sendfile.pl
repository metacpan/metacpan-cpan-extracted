use Config;

my $output;
my @vers=split /\./, $Config{osvers};
if($Config{osname}=~/netbsd|openbsd/i){
  print STDERR "sendfile is not implemented on your version of $Config{osname}";
  $output=qq|
void
sendfile(...)

  CODE:
    Perl_croak(aTHX_ "%s", "IO::FD::sendfile is not implemented on your system");
  
|;
}
else {
  $output=qq|
SV *
sendfile(socket, source, len, offset)
  SV * socket
  SV * source
  SV * len 
  SV * offset

  INIT:

    off_t l;
	  off_t o;
    int ret;

  PPCODE:
    if(SvOK(socket) && SvIOK(socket) && SvOK(source) && SvIOK(source)){
        l=SvIV(len);
	o=SvIV(offset);
#if defined(IO_FD_OS_DARWIN)
        ret=sendfile(SvIV(source),SvIV(socket),SvIV(offset),&l, NULL, 0);
#endif
#if defined(IO_FD_OS_BSD)
        ret=sendfile(SvIV(source),SvIV(socket),SvIV(offset),l, NULL, 0,0);
#endif
#if defined(IO_FD_OS_LINUX)
        ret=sendfile(SvIV(socket), SvIV(source), &o,l);
#endif
        if(ret<0){
          //Return undef on error
          XSRETURN_UNDEF;
        }
        //Otherwise return the number of bytes transfered
        ret=l;
        XSRETURN_IV(ret);

      }
      else {
        errno=EBADF;
        Perl_warn(aTHX_ "%s", "IO::FD::sendfile called with something other than a file descriptor");
        XSRETURN_UNDEF;
      }
|;
}
print $output;
