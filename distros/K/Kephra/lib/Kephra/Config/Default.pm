package Kephra::Config::Default;
our $VERSION = '0.19';

use strict;
use warnings;

#   complete set of config to be able to start app under all circumstances


sub global_settings {
	require Kephra::Config::Default::GlobalSettings;
	my $config = Kephra::Config::Default::GlobalSettings::get();
	if ($^O =~ /linux/i) {
		$config->{editpanel}{font}{family} = 'DejaVu Sans Mono';
		$config->{editpanel}{font}{size} = 10;
		$config->{app}{panel}{output}{font_family} = 'DejaVu Sans Mono';
		$config->{app}{panel}{output}{font_size} = 9;
		$config->{app}{panel}{notepad}{font_family} = 'Nimbus Sans L';
		$config->{app}{panel}{notepad}{font_size} = 10;
		$config->{app}{window}{position_x} = 10;
		$config->{app}{window}{position_y} = 10;
		$config->{app}{window}{size_x} = 770;
		$config->{app}{window}{size_y} = 525;
	}
	elsif ($^O =~ /darwin/i) {
		$config->{editpanel}{font}{family} = 'Monaco';
		$config->{editpanel}{font}{size} = 12;
		$config->{app}{panel}{output}{font_family} = 'Monaco';
		$config->{app}{panel}{output}{font_size} = 11;
		$config->{app}{panel}{notepad}{font_family} = 'Arial';
		$config->{app}{panel}{notepad}{font_size} = 12;
		$config->{app}{window}{position_x} = 10;
		$config->{app}{window}{position_y} = 25;
		$config->{app}{window}{size_x} = 780;
		$config->{app}{window}{size_y} = 565;
	}
	return $config;
}

sub commandlist {
	require Kephra::Config::Default::CommandList;
	Kephra::Config::Default::CommandList::get();
}

sub localisation {
	require Kephra::Config::Default::Localisation;
	Kephra::Config::Default::Localisation::get();
}

sub mainmenu {
	require Kephra::Config::Default::MainMenu;
	Kephra::Config::Default::MainMenu::get();
}

sub contextmenus {
	require Kephra::Config::Default::ContextMenus;
	Kephra::Config::Default::ContextMenus::get();
}

sub toolbars {
	require Kephra::Config::Default::ToolBars;
	Kephra::Config::Default::ToolBars::get();
}

sub drop_xp_style_file{
	my $file    = shift;
	my $content = <<EOD;
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
 <assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">
	 <assemblyIdentity
		 processorArchitecture="x86"
		 version="5.1.0.0"
		 type="win32"
		 name="Controls"
	 />
	 <description>MOM Client Application</description>
	 <dependency>
		 <dependentAssembly>
			 <assemblyIdentity
				 type="win32"
				 name="Microsoft.Windows.Common-Controls"
				 version="6.0.0.0"
				 publicKeyToken="6595b64144ccf1df"
				 language="*"
				 processorArchitecture="x86"
		 />
	 </dependentAssembly>
	 </dependency>
 </assembly>
EOD
	my $l18n = Kephra::Config::Localisation::strings()->{dialogs}{error};
	open my $FILE, '>', $file or Kephra::Dialog::warning_box
			($l18n->{file_write}." $file", $l18n->{file});
	print $FILE $content;
}

1;
