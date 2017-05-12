use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Mail::Webmail::Gmail',
    VERSION_FROM      => 'lib/Mail/Webmail/Gmail.pm',
    PREREQ_PM         => {
        LWP::UserAgent        => 0,
        HTTP::Headers         => 0,
        HTTP::Cookies         => 0,
        HTTP::Request::Common => 0,
        Crypt::SSLeay         => .51,
        Exporter              => 0,
        lib                   => 0,
        strict                => 0,
},
    ($] >= 5.005 ?
      ( AUTHOR         => 'Allen Holman (mincus) mincus@cpan.org') : ()),
);
