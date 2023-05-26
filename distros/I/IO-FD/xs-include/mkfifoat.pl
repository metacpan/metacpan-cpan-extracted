use Config;

my $output;
my @vers=split /\./, $Config{osvers};
if($Config{osname}=~/darwin/ and $vers[0]<21){
  print STDERR "mkfifoat is not implemented on your version of  $Config{osname}";
  
$output=qq|
void
mkfifoat(...)

  CODE:
    Perl_croak(aTHX_ "%s", "IO::FD::mkfifoat is not implemented on your system");
  
|;
}
else {
  $output=qq|
SV*
mkfifoat(fd, path, ...)
    SV *fd
    char *path

		PREINIT:
			int f;
      int mode=0666;	//Default if not provided

		PPCODE:
      if(SvOK(fd) &&SvIOK(fd)){
        if(items >=3){
          mode=SvIV(ST(2));
        }
        f=mkfifoat(SvIV(fd), path, mode);
        if(f<0){
          XSRETURN_UNDEF;
        }
        else{
          if(!(mode & O_CLOEXEC) && (f>PL_maxsysfd)){
            fcntl(f, F_SETFD, FD_CLOEXEC);
          }
          XSRETURN_IV(f);
        }
      }
      else{
        errno=EBADF;
        Perl_warn(aTHX_ "%s", "IO::FD::mkfifoat called with something other than a file descriptor");
        XSRETURN_UNDEF;
      }
|;
}

print $output;
