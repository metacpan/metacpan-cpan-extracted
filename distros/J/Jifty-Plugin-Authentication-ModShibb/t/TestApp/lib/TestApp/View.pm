use warnings;
use strict;

package TestApp::View;
use Jifty::View::Declare -base;

template '/' => page {
    title is 'testApp';
    hyperlink( label => 'protected', url => '/protected');
};

template 'protected' => page {
    title is 'testApp protected';
      ul {
         foreach  my $keys (sort keys %ENV) {
           li { strong {$keys}; outs ' : '.$ENV{$keys}; };
         };
     };
};

1;
