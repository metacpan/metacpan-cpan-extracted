#!perl

use strict;
use warnings;

use HTTP::Tiny;
use HTTP::Tiny::Multipart;

use Test::More;

{
    my $error;
    eval { HTTP::Tiny::Multipart::_build_content(); 1; } or $error = $@;
    like $error, qr/Can't use an undefined value/, 'undefined value passed';
}

{
    my $error;
    eval { HTTP::Tiny::Multipart::_build_content('string'); 1; } or $error = $@;
    like $error, qr/Can't use string \("string"\)/, 'string passed';
}

{
    my $error;
    eval { HTTP::Tiny::Multipart::_build_content(['test']); 1; } or $error = $@;
    like $error, qr/form data reference must have an even number of terms/, 'odd number of elements in arrayref passed';
}

{
    my $content = HTTP::Tiny::Multipart::_build_content([ 'field1' => 'test']);
    is_deeply $content, [ "Content-Disposition: form-data; name=\"field1\"\x0d\x0a\x0d\x0atest\x0d\x0a" ], "simple field";
}

{
    my $content = HTTP::Tiny::Multipart::_build_content([ 'field1' => 'test', field2 => 'noch ein test']);
    is_deeply $content, [
        "Content-Disposition: form-data; name=\"field1\"\x0d\x0a\x0d\x0atest\x0d\x0a",
        "Content-Disposition: form-data; name=\"field2\"\x0d\x0a\x0d\x0anoch ein test\x0d\x0a",
    ], "two simple fields";
}

{
    my $content = HTTP::Tiny::Multipart::_build_content({ 'field1' => 'test' });
    is_deeply $content, [ "Content-Disposition: form-data; name=\"field1\"\x0d\x0a\x0d\x0atest\x0d\x0a" ], "simple field (hashref)";
}

{
    my $content = HTTP::Tiny::Multipart::_build_content([ 'field1' => [ 'test', 'noch ein test'] ]);
    is_deeply $content, [
        "Content-Disposition: form-data; name=\"field1\"\x0d\x0a\x0d\x0atest\x0d\x0a",
        "Content-Disposition: form-data; name=\"field1\"\x0d\x0a\x0d\x0anoch ein test\x0d\x0a",
    ], "one field, two values";
}

{
    my $content = HTTP::Tiny::Multipart::_build_content({ 'field1' => { content => 'test' }  });
    is_deeply $content,
       [ "Content-Disposition: form-data; name=\"field1\"; filename=\"field1\"\x0d\x0a\x0d\x0atest\x0d\x0a" ],
       "simple file field";
}

{
    my $content = HTTP::Tiny::Multipart::_build_content({ 'field1' => { content => 'test', content_type => 'text/plain' }  });
    is_deeply $content,
       [ "Content-Disposition: form-data; name=\"field1\"; filename=\"field1\"\x0d\x0aContent-Type: text/plain\x0d\x0a\x0d\x0atest\x0d\x0a" ],
       "simple file field with content type";
}

{
    my $content = HTTP::Tiny::Multipart::_build_content({ 'field1' => { content => 'test', content_type => 'text/plain', filename => 'test.txt' }  });
    is_deeply $content,
       [ "Content-Disposition: form-data; name=\"field1\"; filename=\"test.txt\"\x0d\x0aContent-Type: text/plain\x0d\x0a\x0d\x0atest\x0d\x0a" ],
       "simple file field with content type and filename (basename)";
}

{
    my $content = HTTP::Tiny::Multipart::_build_content({ 'field1' => { content => 'test', content_type => 'text/plain', filename => '/tmp/test.txt' }  });
    is_deeply $content,
       [ "Content-Disposition: form-data; name=\"field1\"; filename=\"test.txt\"\x0d\x0aContent-Type: text/plain\x0d\x0a\x0d\x0atest\x0d\x0a" ],
       "simple file field with content type and filename (basename)";
}

done_testing();
