use 5.012000;
use warnings;
use inc::Module::Install 1.00;

# Configure-time dependencies MUST be done first.
# This version ensures that we have a new MakeMaker that
# WON'T load modules to determine the version.
# This _SHOULD_ theoretically make the "require Test::NoWarnings".
# stuff above here no longer needed.
configure_requires 'ExtUtils::MakeMaker'   => '6.52';
configure_requires 'File::Copy::Recursive' => 0;
configure_requires 'File::Find::Rule'      => 0;
configure_requires 'File::Spec'            => 0;

name 'Dwimmer';
license 'perl';
author 'Gabor Szabo <szabgab@dwimmer.org>';
all_from 'lib/Dwimmer.pm';

requires 'perl' => '5.012000';

my %prereq = (
	'autodie'             => 0,
	'Dancer'              => 1.3060,
	'Data::Dumper'        => 0,
	'DateTime'            => 0,
	'DBIx::Class'         => 0,
	'DBIx::Class::Schema' => 0,
	'DBIx::Class::Schema::Loader' => 0, # only needed for developers using script/dbic.pl
	'DBIx::RunSQL'        => 0,
	'Email::Valid'        => 0,
	'Encode'              => 0,
	'Fcntl'               => 0,
	'File::ShareDir'      => '1.00',
	'File::Slurp'         => 0,
	'Getopt::Long'        => 0,
	'List::Util'          => 0,
	'LWP::Protocol::https' => 0,  # for https support for the feed reader
	'JSON'                => 0,
	'MIME::Lite'          => 0,
	'Moose'               => 0,
	'Pod::Usage'          => 0,
	'String::Random'      => 0,
	'Template'            => 0,
	'XML::Feed'           => 0,
	'XML::RSS'            => 0,
	'XML::Simple'         => 0,
	'YAML'                => 0,
);

if ( $^O =~ /win32/i ) {
	$prereq{'Win32::Process'} = 0;
}

foreach my $module ( keys %prereq ) {
	requires $module => $prereq{$module};
}

test_requires 'Test::More'           => 0;
test_requires 'Test::Deep'           => 0;
test_requires 'Test::WWW::Mechanize' => 0;
test_requires 'Test::Differences'    => 0;


homepage 'http://dwimmer.org/';
bugtracker 'http://github.com/szabgab/dwimmer';
repository 'http://github.com/szabgab/dwimmer';

install_script 'script/dwimmer_admin.pl';
install_script 'script/dwimmer_backup.pl';
install_script 'script/dwimmer';

install_script 'script/dwimmer_feed_admin.pl';
install_script 'script/dwimmer_feed_collector.pl';

# Copy files to share before installing (but it is not included in the distribution)
foreach my $module (qw(File::Copy::Recursive File::Spec)) {
	eval "use $module";
	die "Need to install $module before running Makefile.PL again\n" if $@;
}
foreach my $dir (qw(bin views schema public environments)) {
	File::Copy::Recursive::dircopy( $dir, File::Spec->catdir( 'share', $dir ) );
}
File::Copy::Recursive::fcopy( 'config.yml', 'share' );

install_share;


WriteAll;
