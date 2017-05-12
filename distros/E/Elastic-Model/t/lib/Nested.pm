package Nested;

use Elastic::Model;

#===================================
has_namespace 'myapp' => {
#===================================
    multiuser => 'MyApp::MultiUser'
};

no Elastic::Model;

1;
