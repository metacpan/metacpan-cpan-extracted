package Kephra::Help;
our $VERSION = '0.04';

use strict;
use warnings;

my $dir;
sub _dir { if (defined $_[0]) {$dir = $_[0]} else {$dir} }
sub _hf { Kephra::Document::add ( File::Spec->catfile( $dir, shift ) ) }
sub _config { Kephra::API::settings()->{texts} }

sub welcome              { _hf _config()->{welcome}}
sub version_text         { _hf _config()->{version}}
sub licence_gpl          { _hf _config()->{license}}
sub feature_tour         { _hf _config()->{feature}}
sub advanced_tour        { _hf _config()->{special}}
sub navigation_guide     { _hf _config()->{navigation}}
sub credits              { _hf _config()->{credits}}
sub keyboard_map         { _hf _config()->{keymap}}

sub _web_page { Wx::LaunchDefaultBrowser( $_[0] ) }
sub _lang     { lc Kephra::Config::Localisation::language() }

sub online_documentation {
	my $url = _lang() eq 'deutsch'
		? 'http://kephra.sourceforge.net/site/de/documentation.shtml' 
		: 'http://kephra.sourceforge.net/site/en/documentation.shtml'; 
	_web_page($url);
}

sub forum_site {
	my $url = _lang() eq 'deutsch'
		? 'http://www.perl-community.de/bat/poard/start' 
		: 'http://www.perlmonks.org'; 
	_web_page($url);
}

sub bug_tracker { _web_page('http://sourceforge.net/tracker/?func=add&group_id=169747&atid=851590') }
sub feature_wish { _web_page('http://sourceforge.net/tracker/?func=add&group_id=169747&atid=851593') }
1;