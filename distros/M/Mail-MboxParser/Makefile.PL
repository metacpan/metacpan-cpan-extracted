use ExtUtils::MakeMaker;

use constant MMMPARSER => eval { require Mail::Mbox::MessageParser; 1 } || 0;

if (!MMMPARSER) {
    warn <<EOWARN;
*******************
You don't have Mail::Mbox::MessageParser installed. If you want to get
significantly faster parsing, you should install this module from the CPAN.

If you do so, you are advised to do it before issuing 'make test' on this
module because otherwise the new parsing routines can't be tested on your
platform.
*******************
EOWARN
}

eval { require FileHandle::Unget };

if (MMMPARSER && !$@ && FileHandle::Unget->VERSION < 0.13) {
    die <<EOCROAK;
*******************
Since you have Mail::Mbox::MessageParser installed, you also need
version 0.13 of FileHandle::Unget. 

Please install it before running me again.
*******************
EOCROAK
}

WriteMakefile(
    AUTHOR       => 'Tassilo v. Parseval <tassilo.parseval@post.rwth-aachen.de',
    NAME         => 'Mail::MboxParser',
    PMLIBDIRS    => ['MboxParser'],
    VERSION_FROM => 'MboxParser.pm', 
    PREREQ_PM    => { MIME::Tools               => 5.0,
                      MIME::QuotedPrint         => 0, 
		      MIME::Base64		=> 0,
		      File::Temp		=> 0,
                    },
    DISTNAME     => 'Mail-MboxParser',
    clean	 => { FILES => "t/cache" },
);
