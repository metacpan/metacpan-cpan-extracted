use 5.008001;
use utf8;
use strict;
use warnings;

use ExtUtils::MakeMaker;

# Make setting optional MakeMaker parameters more readable.
sub OPTIONAL {
   return () unless $ExtUtils::MakeMaker::VERSION ge shift;
   return @_;
}

WriteMakefile(
   NAME => 'Locale::KeyedText',
   VERSION => '2.1.0',
   ABSTRACT => 'Refer to user messages in programs by keys',
   AUTHOR => 'Darren Duncan <darren@DarrenDuncan.net>',
   PREREQ_PM => {
      # This list is a copy of "META_ADD:[configure_|build_|]requires"
      # where the other is canonical; this list is for use by MakeMaker
      # itself, which in general wouldn't see the info in the other lists,
      # as the other lists are primarily used when generating the META.yml/json.
      'ExtUtils::MakeMaker' => '6.17',
      'overload' => '1.01',
      'Scalar::Util' => '1.13',
      'Test::More' => '0.92',
   },
   OPTIONAL( '6.48',
      MIN_PERL_VERSION => '5.008001',
   ),
   OPTIONAL( '6.31',
      LICENSE => 'lgpl_3_0',
   ),
   OPTIONAL( '6.46',
      # Use META_ADD instead of META_MERGE so that we can remove
      # any build-time dependencies that MakeMaker will put into
      # the requires field.  (Comment From DBD::SQLite; do *we* need that?)
      META_ADD => {
         configure_requires => {
            'ExtUtils::MakeMaker' => '6.17', # bundled with Perl 5.8.1
         },
         build_requires => {
            'ExtUtils::MakeMaker' => '6.17', # bundled with Perl 5.8.1
            # These are bundled with newer versions of Perl only.
            'Test::More' => '0.92', # bundled with Perl 5.10.1, min 0.88 needed
         },
         requires => {
            'perl' => '5.008001', # as MIN_PERL_VERSION no affect META.yml
            'overload' => '1.01', # bundled with Perl 5.8.1
            'Scalar::Util' => '1.13', # bundled with Perl 5.8.1
         },
      },
      META_MERGE => {
         no_index => {
            directory => ['examples','t'],
         },
         resources => {
            homepage => 'http://www.muldis.com/',
            license => 'http://www.fsf.org/licensing/licenses/lgpl.html',
            MailingList => 'http://mm.darrenduncan.net/mailman/listinfo',
            repository => 'http://github.com/muldis/Locale-KeyedText-Perl5',
         },
      },
   ),
);

1;
