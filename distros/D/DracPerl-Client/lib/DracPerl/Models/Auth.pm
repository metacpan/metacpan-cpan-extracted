package DracPerl::Models::Auth;

use XML::Rabbit::Root;

has_xpath_value 'request_status' => '/root/status';
has_xpath_value 'auth_result'    => '/root/authResult';
has_xpath_value 'forward_url'    => '/root/forwardUrl';

finalize_class();

1;
