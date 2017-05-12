use ExtUtils::MakeMaker;

# $Id: Makefile.PL 38 2008-09-05 09:11:15Z rjray $

WriteMakefile(
              (MM->can('signature_target') ? (SIGN => 1) : ()),
              ABSTRACT     => 'Collect a list of modules loaded at compile-time',
              AUTHOR       => 'Randy J. Ray (rjray@blackperl.com)',
              NAME         => 'Devel::Modlist',
              VERSION_FROM => 'lib/Devel/Modlist.pm', # finds $VERSION
              license      => 'perl',
              clean        => { FILES =>
                                'pod2html-* *.html blibdirs META.yml' },
             );
