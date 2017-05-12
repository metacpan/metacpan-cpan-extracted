use Module::Build;

Module::Build -> new
(
 module_name    => 'Log::Handler::Plugin::DBI',
 license        => 'artistic',
 dist_abstract  => 'A plugin for Log::Handler using Log::Hander::Output::DBI',
 dist_author    => 'Ron Savage <ron@savage.net.au>',
 build_requires =>
 {
	 Test::More => 0.94,
	 Test::Pod  => 1.44,
 },
 configure_requires =>
 {
	 Module::Build => 0.3800,
 },
 requires =>
 {
	 Carp                      => 1.20,
	 Config::Plugin::Tiny      => 1.01,
	 DBD::SQLite               => 1.35,
	 DBIx::Admin::CreateTable  => 2.07,
	 DBIx::Connector           => 0.47,
	 Hash::FieldHash           => 0.12,
	 Log::Handler::Output::DBI => 0.11,
	 strict                    => 1.03,
	 vars                      => 1.01,
	 warnings                  => 1.03,
 },
) -> create_build_script();
