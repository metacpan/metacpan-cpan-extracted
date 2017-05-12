use inc::Module::Install;
  
name           'Flickr-Embed';
all_from       'lib/Flickr/Embed.pm';

requires       'Flickr::API';
requires       'HTML::Entities';

WriteAll;
