use 5.010;   # too addicted to the  //  operator
use strict;
use warnings;
#use ExtUtils::MakeMaker;
use inc::Module::Install;

name 'I22r-Translate';
all_from 'lib/I22r/Translate.pm';
license 'perl';

requires 'Class::Accessor';
requires 'Class::Data::Inheritable';
requires 'HTTP::Request';
requires 'JSON::MaybeXS';
requires 'LWP::UserAgent';
requires 'LWP::Protocol::https';
requires 'Moose';
requires 'Moose::Role';
requires 'MooseX::ClassAttribute';
requires 'URI';
test_requires 'Test::More';

no_index package => 'I22r::Translate::Request';
no_index package => 'I22r::Translate::Result';
no_index package => 'I22r::REST::Google';
no_index package => 'I22r::REST::Google::Translate';
no_index package => 'I22r::REST::Google::Data';

auto_install;
WriteAll;

=pod

Thar be old config passed to WriteMakefile function:

    NAME                => 'I22r::Translate',
    AUTHOR              => q{Marty O'Brien <mob@cpan.org>},
    VERSION_FROM        => 'lib/I22r/Translate.pm',
    ABSTRACT_FROM       => 'lib/I22r/Translate.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    META_MERGE => {
	no_index => {
	    package => [
		'I22r::Translate::Request',
		'I22r::Translate::Result',
		'I22r::REST::Google',
		'I22r::REST::Google::Translate',
		'I22r::REST::Google::Data'
		],
	}
    },
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Class::Accessor' => 0,
	'Class::Data::Inheritable' => 0,
	'HTTP::Request' => 0,
	'JSON::Any' => 0,
	'LWP::UserAgent' => 0,
	'Moose' => 0,
	'Moose::Role' => 0,
	'MooseX::ClassAttribute' => 0,
	'URI' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'I22r-Translate-*' },

=cut

print STDERR qq[
*******************************************************************
Using the Google translation backend requires an API key.
If you wish to test the Google backend, you will need to
edit the file

       t/Constants.pm

and specify your API key. You can get a Google API key from

       https://code.google.com/apis/console/

*******************************************************************
];
