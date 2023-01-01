#!/usr/bin/env perl

use Test::Most;

use lib 't/lib';
use Renard::Incunabula::Devel::TestHelper;
use Renard::Incunabula::Common::Setup;

# need to import later --- after we initialise the data dirs
use Intertangle::API::Gtk3::Helper ();

my $temp = Path::Tiny->tempdir;
# Add to XDG_DATA_DIRS early so that it is available for system data dir lookup.
$ENV{XDG_DATA_DIRS} .= join(":", "/usr/local/share", "/usr/share", $temp);

plan Gtk3::init_check()
	? ( tests    => 2 )
	: ( skip_all => 'Could not init GTK' );

# we can now import
Intertangle::API::Gtk3::Helper->import;

subtest "Use helper functions" => sub {
	my $val = Intertangle::API::Gtk3::Helper->gval(int => 512);
	isa_ok( $val, 'Glib::Object::Introspection::GValueWrapper' );

	my $enum = Intertangle::API::Gtk3::Helper->genum(
		'Gtk3::PackType' => 'GTK_PACK_START' );
	is( $enum, 0 );
};

subtest "Theming" => sub {
	plan skip_all => "Do not need to test theming on Windows"
		unless Intertangle::API::Gtk3::Helper::_can_set_theme();

	my $settings = Gtk3::Settings::get_default;
	my $default_theme = 'Adwaita';

	subtest "Check that system data dirs are set properly" => sub {
		my @data_dirs = Glib::get_system_data_dirs();
		cmp_deeply( \@data_dirs, supersetof("$temp"), 'Has the temprary data directory');
	};

	subtest "Set theme" => sub {
		my $theme_property = 'gtk-theme-name';

		subtest "Try non-existent theme" => sub {
			$settings->set_property($theme_property, $default_theme);

			diag 'Warning about missing theme can be ignored';
			my $try_theme = 'Does-Not-Exist';
			Intertangle::API::Gtk3::Helper::_set_theme($try_theme);
			isnt( $settings->get_property($theme_property),
				$try_theme, 'Theme has not changed' );
		};

		subtest "Try existing theme" => sub {
			$settings->set_property($theme_property, $default_theme);

			my $try_theme = 'My-Custom-Theme';
			my $theme_dir = $temp->child('themes', $try_theme);
			$theme_dir->mkpath;
			$theme_dir->child('index.theme')->spew_utf8(<<"EOF" );
[Desktop Entry]
Type=X-GNOME-Metatheme
Name=${try_theme}
Comment=A Test theme
Encoding=UTF-8

[X-GNOME-Metatheme]
GtkTheme=${try_theme}
MetacityTheme=${try_theme}
EOF

			$theme_dir->child(qw(gtk-3.0 gtk.css))->touchpath;

			Intertangle::API::Gtk3::Helper::_set_theme($try_theme);
			is( $settings->get_property($theme_property),
				$try_theme, 'Theme has changed' );

		}
	};

	subtest "Set icon-theme" => sub {
		my $icon_theme_property = 'gtk-icon-theme-name';

		subtest "Try non-existent icon theme" => sub {
			$settings->set_property($icon_theme_property, $default_theme);

			diag 'Warning about missing icon theme can be ignored';
			my $try_icon_theme = 'Does-Not-Exist';
			Intertangle::API::Gtk3::Helper::_set_icon_theme($try_icon_theme);
			isnt( $settings->get_property($icon_theme_property),
				$try_icon_theme, 'Icon theme has not changed' );
		};

		subtest "Try existing icon theme" => sub {
			$settings->set_property($icon_theme_property, $default_theme);

			my $try_theme = 'My-Custom-Icon-Theme';

			my $icon_theme_dir = $temp->child('icons', $try_theme);
			$icon_theme_dir->mkpath;
			$icon_theme_dir->child('index.theme')->spew_utf8(<<"EOF" );
[Icon Theme]
Name=${try_theme}

#Directory list
Directories=actions/16

[actions/16]
Size=16
Context=Actions
Type=Fixed
EOF
			$icon_theme_dir->child(qw(actions 16 gtk-open.png))->touchpath;

			Intertangle::API::Gtk3::Helper::_set_icon_theme($try_theme);
			is( $settings->get_property($icon_theme_property),
				$try_theme, 'Icon theme has changed' );

		}
	};
};
