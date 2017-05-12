use ExtUtils::MakeMaker;

WriteMakefile
  NAME          => 'Mail::CheckUser',
  VERSION_FROM  => 'CheckUser.pm', # finds $VERSION
  PREREQ_PM     => {
    'Net::SMTP'  => 2.13,
    'Net::Ping'  => 2.24,
    'Net::DNS'   => 0.31,
    'IO::Handle' => 1.21,
  },
  EXE_FILES => ['procmail/cufilter'],
  ;
