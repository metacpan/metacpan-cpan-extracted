use inc::Module::Install;


WriteMakefile(
    'NAME'		=> 'Image::Signature',
    'VERSION_FROM'	=> 'Signature.pm', 
    'PREREQ_PM'		=> {
	'Image::Magick' => '5.5.7',
	'List::Util' => '0',
    }, 
    ($] >= 5.005 ?    
      (ABSTRACT_FROM => 'Signature.pm', 
       AUTHOR     => 'xern <xern@cpan.org>') : ()),
);
