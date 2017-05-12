use Module::Build;

Module::Build -> new
(
 module_name    => 'HTML::Revelation',
 license        => 'artistic',
 dist_abstract  => 'Reveal HTML document structure in a myriad of colors',
 dist_author    => 'Ron Savage <ron@savage.net.au>',
 build_requires =>
 {
	 Test::More => 0,
	 Test::Pod  => 0,
 },
 requires =>
 {
	 accessors::classic          => 0,
	 File::Spec                  => 0,
	 HTML::Entities::Interpolate => 0,
	 HTML::Tagset                => 0,
	 HTML::TreeBuilder           => 0,
	 List::Cycle                 => 0,
 },
) -> create_build_script();

