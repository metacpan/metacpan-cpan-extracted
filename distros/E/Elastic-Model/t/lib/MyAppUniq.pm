package MyAppUniq;

use Elastic::Model;

#===================================
has_namespace 'myapp' => {
#===================================
    user => 'MyApp::UniqUser',
};

#===================================
has_unique_index 'myapp1';
#===================================

no Elastic::Model;

1;
