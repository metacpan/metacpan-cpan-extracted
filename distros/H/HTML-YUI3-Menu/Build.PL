use Module::Build;

my $class = Module::Build->subclass(code => <<'EOF');

sub ACTION_build
{
	my $self = shift;
	$self->SUPER::ACTION_build(@_);
	$self->run_perl_script('scripts/copy.config.pl');
}
EOF

$class -> new
(
 module_name    => 'HTML::YUI3::Menu',
 license        => 'artistic',
 dist_abstract  => 'Convert a Tree::DAG_Node object into the HTML and JS for a YUI3 menu',
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
	 Config::Tiny    => 2.13,
	 File::Copy      => 2.18,
	 File::HomeDir   => 0.97,
	 Hash::FieldHash => 0.10,
	 Path::Class     => 0.23,
	 Text::Xslate    => 1.0007,
 },
) -> create_build_script();
