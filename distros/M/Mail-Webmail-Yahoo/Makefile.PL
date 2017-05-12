use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Mail::Webmail::Yahoo',
    'VERSION_FROM'	=> 'Yahoo.pm', # finds $VERSION
		'PM'  => {
			'MessageParser.pm' => '$(INST_LIB)/Mail/Webmail/MessageParser.pm',
			'Yahoo.pm' => '$(INST_LIB)/Mail/Webmail/Yahoo.pm',
			'snagmail.pl' => '$(INST_LIB)/Mail/Webmail/snagmail.pl',
			'sendhoo.pl' => '$(INST_LIB)/Mail/Webmail/sendhoo.pl',
			'yahootils.pl' => '$(INST_LIB)/Mail/Webmail/yahootils.pl',
			},
    'PREREQ_PM'		=> {
			LWP::UserAgent => 0.1,
			HTTP::Request => 0.1,
			HTTP::Headers => 0.1,
			HTTP::Cookies => 0.1,
			HTML::LinkExtor => 0.1,
			HTML::Entities => 0.1,
			Mail::Internet => 0.1,
			MIME::Base64 => 0.1,
			HTML::FormParser => 0.1,
			HTML::TableExtractor => 0.1,
			HTML::TableContentParser => 0.1,
			HTML::Tree => 3.14,
			Class::MethodMaker  => 0.1,
		}, # e.g., Module::Name => 1.1

    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Yahoo.pm', # retrieve abstract from module
       AUTHOR     => 'Simon Drabble <sdrabble@cpan.org>') : ()),
);
