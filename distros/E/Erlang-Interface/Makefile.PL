use 5.008008;
use ExtUtils::MakeMaker;

my @dirs = qw(
/usr/
/usr/local
/usr/local/otp
);

my $otp_dir;
my $otp_cflags;
my $otp_ldflags;
foreach (@dirs) {
    if (-f $_ . "/include/erl_interface.h") {
        $otp_dir = $_;
        last;
    }
}

if (!defined($otp_dir)) {
    die "Cannot find Erlang/OTP directory - see Makefile.PL";
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Erlang::Interface',
    VERSION_FROM      => 'lib/Erlang/Interface.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Erlang/Interface.pm', # retrieve abstract from module
       AUTHOR         => 'Tsukasa Hamano <hamano@cpan.org>') : ()),
       LIBS              => ["-lpthread -L$otp_dir/lib -lerl_interface -lei"],
       DEFINE            => '',
       INC               => '-I. -I$otp_dir/include',
       LICENSE           => 'perl',
);

if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(ERL_ATOM ERL_BIG ERL_BINARY ERL_COMPOUND ERL_CONS
         ERL_EMPTY_LIST ERL_FLOAT ERL_FUNCTION ERL_INTEGER ERL_LIST
         ERL_LONGLONG ERL_NIL ERL_PID ERL_PORT ERL_REF ERL_SMALL_BIG
         ERL_TUPLE ERL_UNDEF ERL_U_INTEGER ERL_U_LONGLONG
         ERL_U_SMALL_BIG ERL_VARIABLE MAXREGLEN));
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Erlang::Interface',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}

