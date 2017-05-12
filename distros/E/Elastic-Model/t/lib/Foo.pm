package Foo;

use Elastic::Model;

#===================================
has_namespace 'foo' => {
#===================================
    user => 'Foo::User'
};

#===================================
has_namespace 'bar' => {
#===================================
    user => 'Foo::User',
    post => 'Foo::Post'
    },
    fixed_domains => [ 'aaa', 'bbb' ];

no Elastic::Model;

1;
