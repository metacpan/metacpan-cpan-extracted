use Test::Most;

use HTML::DeferableCSS;

subtest "css_files" => sub {

    my $css = HTML::DeferableCSS->new(
        css_root => 't/etc/css',
        aliases  => {
            reset => 'reset',
        },
    );

    isa_ok $css, 'HTML::DeferableCSS';

    my $files = $css->css_files;

    cmp_deeply $files, {
        reset => [ obj_isa('Path::Tiny'), ignore(), 773 ],
    }, "css_files";

    is $files->{reset}->[0]->stringify => "t/etc/css/reset.min.css", "path";
    is $files->{reset}->[1]            => "reset.min.css", "filename";

};

subtest "css_files (alias => 1)" => sub {

    my $css = HTML::DeferableCSS->new(
        css_root => 't/etc/css',
        aliases  => {
            reset => 1,
            gone1 => 0,
            gone2 => '',
            gone3 => undef,
        },
    );

    isa_ok $css, 'HTML::DeferableCSS';

    my $files = $css->css_files;

    cmp_deeply $files, {
        reset => [ obj_isa('Path::Tiny'), ignore(), 773 ],
    }, "css_files";

    is $files->{reset}->[0]->stringify => "t/etc/css/reset.min.css", "path";
    is $files->{reset}->[1]            => "reset.min.css", "filename";

};

subtest "css_files (1.css fails)" => sub {

    my $css = HTML::DeferableCSS->new(
        css_root => 't/etc/css',
        aliases  => {
            one => 1,
        },
    );

    isa_ok $css, 'HTML::DeferableCSS';

    throws_ok {
        $css->css_files;
    } qr/alias 'one' refers to a non-existent file/;

};

subtest "css_files (1.css workaround)" => sub {

    my $css = HTML::DeferableCSS->new(
        css_root => 't/etc/css',
        aliases  => {
            one => "1.css",
        },
    );

    isa_ok $css, 'HTML::DeferableCSS';

    my $files = $css->css_files;

    cmp_deeply $files, {
        one => [ obj_isa('Path::Tiny'), '1.css', 17 ],
    }, "css_files";

    is $files->{one}->[0]->stringify => "t/etc/css/1.css", "path";

};

subtest "css_files (prefer_min=0)" => sub {

    my $css = HTML::DeferableCSS->new(
        css_root => 't/etc/css',
        aliases  => {
            reset => 'reset',
        },
        prefer_min => 0,
    );

    isa_ok $css, 'HTML::DeferableCSS';

    my $files = $css->css_files;

    cmp_deeply $files, {
        reset => [ obj_isa('Path::Tiny'), ignore(), 1089 ],
    }, "css_files";

    is $files->{reset}->[0]->stringify => "t/etc/css/reset.css", "path";
    is $files->{reset}->[1]            => "reset.css", "filename";

};

subtest "css_files (prefer_min=0 works when there is only min)" => sub {

    my $css = HTML::DeferableCSS->new(
        css_root => 't/etc/css',
        aliases  => {
            bar => 1
        },
        prefer_min => 0,
    );

    isa_ok $css, 'HTML::DeferableCSS';

    my $files = $css->css_files;

    cmp_deeply $files, { bar => ignore() }, "css_files";

    is $files->{bar}->[0]->stringify => "t/etc/css/bar.min.css", "path";
    is $files->{bar}->[1]            => "bar.min.css", "filename";

};

subtest "css_files (full name)" => sub {

    my $css = HTML::DeferableCSS->new(
        css_root => 't/etc/css',
        prefer_min => 0,
        aliases  => {
            reset => 'reset.css',
        },
    );

    isa_ok $css, 'HTML::DeferableCSS';

    my $files = $css->css_files;

    cmp_deeply $files, {
        reset => [ obj_isa('Path::Tiny'), ignore(), 1089 ],
    }, "css_files";

    is $files->{reset}->[0]->stringify => "t/etc/css/reset.css", "path";
    is $files->{reset}->[1]            => "reset.css", "filename";

};

subtest "css_files (full name)" => sub {

    my $css = HTML::DeferableCSS->new(
        css_root => 't/etc/css',
        aliases  => {
            reset => 'reset.min.css',
        },
    );

    isa_ok $css, 'HTML::DeferableCSS';

    my $files = $css->css_files;

    cmp_deeply $files, {
        reset => [ obj_isa('Path::Tiny'), ignore(), 773 ],
    }, "css_files";

    is $files->{reset}->[0]->stringify => "t/etc/css/reset.min.css", "path";
    is $files->{reset}->[1]            => "reset.min.css", "filename";

};

subtest "css_files (bad css_root)" => sub {

    # We don't test for the actual error, since that is dependent upon
    # Types::Path::Tiny

    dies_ok {
        my $css = HTML::DeferableCSS->new(
            css_root => 't/etc/cssx',
            aliases  => {
                reset => 'resetx',
            },
        );
    } 'constructor died';

};

subtest "css_files (bad filename)" => sub {

    my $css = HTML::DeferableCSS->new(
        css_root => 't/etc/css',
        aliases  => {
            reset => 'resetx',
        },
    );

    isa_ok $css, 'HTML::DeferableCSS';

    throws_ok {
        $css->css_files
    } qr/alias 'reset' refers to a non-existent file/;

};

subtest "css_files (URI)" => sub {

    my $css = HTML::DeferableCSS->new(
        css_root => 't/etc/css',
        aliases  => {
            reset => 'http://cdn.example.com/reset.css',
        },
    );

    isa_ok $css, 'HTML::DeferableCSS';

    my $files = $css->css_files;

    cmp_deeply $files, {
        reset => [ undef, ignore(), ignore() ],
    }, "css_files";

    is $files->{reset}->[1] => "http://cdn.example.com/reset.css", "uri";

};

subtest "css_files (URI)" => sub {

    my $css = HTML::DeferableCSS->new(
        css_root => 't/etc/css',
        aliases  => {
            reset => '//cdn.example.com/reset.css',
        },
    );

    isa_ok $css, 'HTML::DeferableCSS';

    my $files = $css->css_files;

    cmp_deeply $files, {
        reset => [ undef, ignore(), ignore() ],
    }, "css_files";

    is $files->{reset}->[1] => "//cdn.example.com/reset.css", "uri";

};

subtest "css_files (array ref)" => sub {

    my $css = HTML::DeferableCSS->new(
        css_root => 't/etc/css',
        aliases  => [ qw[ reset ] ],
    );

    isa_ok $css, 'HTML::DeferableCSS';

    my $files = $css->css_files;

    cmp_deeply $files, {
        reset => [ obj_isa('Path::Tiny'), ignore(), 773 ],
    }, "css_files";

    is $files->{reset}->[0]->stringify => "t/etc/css/reset.min.css", "path";
    is $files->{reset}->[1]            => "reset.min.css", "filename";

};

done_testing;
