use strict;
use warnings;
use Test::More;
use HTTP::Entity::Parser::MultiPart;
use Hash::MultiValue;
use HTTP::Headers;
require "./t/Util.pm";
use File::Basename;


my @tests = (
    [ q<form-data; name="foo">,
        [ q<foo>, undef ]
    ],
    [ q<form-data; name="">,
        [ q<>, undef ]
    ],
    [ q<form-data; name=""; filename="">,
        [ q<>, q<> ]
    ],
    [ q<form-data; name="foo"; filename="">,
        [ q<foo>, q<> ]
    ],
    [ q<form-data; name=""; filename="foo.ext">,
        [ q<>, q<foo.ext> ]
    ],
    [ q<form-data; name="Foo"; filename="doc.ext">,
        [ q<Foo>, q<doc.ext> ]
    ],
    [ q<form-data; name="foO"; filename="bar baz.ext">,
        [ q<foO>, q<bar baz.ext> ]
    ],
    [ q<form-data; name="FoO"; filename="b\az.ext">,
        [ q<FoO>, q<b\az.ext> ]
    ],
    [ q<form-data; name="FOO"; filename="\"quoted\" bar.ext">,
        [ q<FOO>, q<\"quoted\" bar.ext> ]
    ],
    [ q<form-data; name="foo"; filename="foo;bar;baz.ext">,
        [ q<foo>, q<foo;bar;baz.ext> ]
    ],
    [ q<form-data; name="foo"; filename="foo\\bar||baz\\ext">,
        [ q<foo>, q<foo\\bar||baz\\ext> ]
    ],
    [ q<form-data; name="foo"; filename="'bar.ext'">,
        [ q<foo>, q<'bar.ext'> ]
    ],
    [ q<form-data; filename="foo"; name="bar">,
        [ q<bar>, q<foo> ]
    ],
    [ q<form-data; name="=name"; filename="=filename.ext">,
        [ q<=name>, q<=filename.ext> ]
    ],
    [ q<form-data; name="foo"; filename="/path/filename.ext">,
        [ q<foo>, q</path/filename.ext> ]
    ],

    # disposition type and parameter names are case insensitive
    [ q<FORM-DATA; name="foo"; FiLeNaMe="bar">,
        [ q<foo>, q<bar> ]
    ],
    [ q<form-data; NamE="foo">,
        [ q<foo>, undef ]
    ],

    # unquoted parameter values
    [ q<form-data; name=foo>,
        [ q<foo>, undef ]
    ],
    [ q<form-data; name=foo; filename=>,
        [ q<foo>, q<> ]
    ],
    [ q<form-data; name=foo; filename=baz.ext>,
        [ q<foo>, q<baz.ext> ]
    ],
    [ q<form-data; name=foo; filename=foo-bar+baz.ext>,
        [ q<foo>, q<foo-bar+baz.ext> ]
    ],
    
    # excessive LWS
    [ q<  form-data  ;  name = "foo" >,
        [ q<foo>, undef ]
    ],
    [ q<  form-data  ;  name = foo >,
        [ q<foo>, undef ]
    ],
    [ q<  form-data  ;  name = "foo"  ;  filename = "baz"  >,
        [ q<foo>, q<baz> ]
    ],
    [ q<  form-data  ;  name = "foo"  ;  filename =  >,
        [ q<foo>, q<> ]
    ],
    
    # lack of LWS
    [ q<form-data;name="foo">,
        [ q<foo>, undef ]
    ],
    [ q<form-data;name=foo>,
        [ q<foo>, undef ]
    ],
    [ q<form-data;name="foo";filename="baz">,
        [ q<foo>, q<baz> ]
    ],
    [ q<form-data;name="foo";filename=>,
        [ q<foo>, q<> ]
    ],

    # extension parameters are ignored
    [ q<form-data; name="foo"; baz="foo">,
        [ q<foo>, undef ]
    ],
    [ q<form-data; name="foo"; baz="foo"; baz="bar">,
        [ q<foo>, undef ]
    ],
    [ q<form-data; name="foo"; filename="bar"; baz="foo"; baz="bar">,
        [ q<foo>, q<bar> ]
    ],
    
    # ignore empty parameters and unknown tokens
    [ q<form-data; name=foo; ;; baz=foo ; >,
        [ q<foo>, undef ]
    ],
    [ q<form-data; name=foo; baz ; baz=foo ; >,
        [ q<foo>, undef ]
    ],

    # Webkit based browsers percent-encode double-quote marks but does not
    # percent-encode any percent characters or backslash characters.
    # " Foo %22 " => %22 Foo %22 %22
    # " \" "      => %22 \%22 %22
    [ q<form-data; name="foo"; filename="%22 Foo %22 %22">,
        [ q<foo>, q<%22 Foo %22 %22> ]
    ],
    [ q<form-data; name="foo"; filename="%22 \%22 %22">,
        [ q<foo>, q<%22 \%22 %22> ]
    ],
    
    # Firefox quotes double-quote marks but does not quoute any backslash 
    # characters.
    # " Foo " => \" Foo \"
    # " \" "  => \" \\" \"
    [ q<form-data; name="foo"; filename="\" Foo \"">,
        [ q<foo>, q<\" Foo \"> ]
    ],
    [ q<form-data; name="foo"; filename="\" \\" \"">,
        [ q<foo>, q<\" \\" \"> ]
    ],
    
    # IE may provide a path containing backslash characters but does not 
    # encode or quote the backslash character.
    [ q<form-data; name="foo"; filename="C:\Documents and Settings\user\Documents\file.ext">,
        [ q<foo>, q<C:\Documents and Settings\user\Documents\file.ext> ]
    ],

    # some old browsers does not escape double-quote marks
    # <https://bugzilla.mozilla.org/show_bug.cgi?id=136676>
    [ q<form-data; name=" foo " ">,
        [ ],
    ],

    # disposition type must be form-data
    [ q<attachment; name="foo">,
        [ ]
    ],
    [ q<attachment; name="foo"; filename="baz">,
        [ ]
    ],

    # name parameter is required
    [ q<form-data;">,
        [ ]
    ],
    [ q<form-data; filename="bar">,
        [ ]
    ],

    # name parameter redundantly specified
    [ q<form-data; name="foo"; name="bar"; filename="baz">,
        [ ]
    ],

    # filename parameter redundantly specified
    [ q<form-data; name="foo"; filename="bar"; filename="baz">,
        [ ]
    ],
    
    [ q<form-data; name>,
        [ ]
    ]
);


foreach my $test (@tests) {
    my ($disposition, $exp) = @$test;
    my $content = qq{------BOUNDARY
Content-Disposition: $disposition
Content-Type: text/plain

fuga
------BOUNDARY--
};
    $content =~ s/\r\n/\n/g;
    $content =~ s/\n/\r\n/g;
    my $env = {
        CONTENT_LENGTH => length($content),
        CONTENT_TYPE   => 'multipart/form-data; boundary=----BOUNDARY',
    };

    my ($params, $uploads) = ([],[]);
    eval {
        my $parser = HTTP::Entity::Parser::MultiPart->new($env);
        $parser->add($_) for split //, $content;
        ($params, $uploads) = $parser->finalize();
    };
    if ( $exp->[1] ) {
        is_deeply($params,[], "no-params-<$disposition>");
        is($uploads->[0], $exp->[0], "uploads-name-<$disposition>");
        is($uploads->[1]->{filename}, $exp->[1], "uploads-filename-<$disposition>");
    }
    else {
        is_deeply($uploads,[], "no-uploads-<$disposition>");
        if (defined $exp->[0] && $disposition !~ m!filename!i ){
            is($params->[0], $exp->[0], "params-name-<$disposition>");
            is($params->[1], "fuga", "params-val-<$disposition>");
        }
        else {
            is_deeply($params,[], "no-params2-<$disposition>");
        }
    }
}

done_testing();
