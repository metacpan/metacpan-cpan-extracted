#!/usr/bin/perl
use Test::More qw/no_plan/;
use HTML::Template::Compiled;

# Tests for the "new_" shortcuts

new_filehandle: { 
    open(TEMPLATE, "t/templates/simple.tmpl") || croak $!;
    $t = HTML::Template::Compiled->new_filehandle(*TEMPLATE);
    $t->param('ADJECTIVE', 'very');
    like ($t->output, qr/very/ ); 
    close(TEMPLATE);
}

new_file: {
    $t = HTML::Template::Compiled->new_file('t/templates/simple.tmpl');
    $t->param('ADJECTIVE', 'very');
    like ($t->output, qr/very/ ); 
}

new_scalar_ref: {
    $t = HTML::Template::Compiled->new_scalar_ref(
        \'IIII am a <TMPL_VAR NAME="ADJECTIVE"> simple template.'
    );
    $t->param('ADJECTIVE', 'very');
    like ($t->output, qr/very/ ); 
}

new_array_ref: {
    $t = HTML::Template::Compiled->new_array_ref(
        ['I am a <TMPL_VAR NAME="ADJECTIVE"> simple template.']
    );
    $t->param('ADJECTIVE', 'very');
    like ($t->output, qr/very/ ); 
}


type_filename: {
    $t = HTML::Template::Compiled->new_file('t/templates/simple.tmpl');
    my $t = HTML::Template::Compiled->new(
        type => 'filename',
        source => 't/templates/simple.tmpl',
    );
    $t->param('ADJECTIVE', 'very');
    like ($t->output, qr/very/ ); 
}

short: {
    use HTML::Template::Compiled short => 1;
    my $htc = HTC(
        scalarref => \"foo",
    );
    my $out = $htc->output;
    cmp_ok($out, 'eq', "foo", "HTC() shortcut");
}

{
    eval {
        my $t = HTML::Template::Compiled->new(
            type => 'filename',
        );
    };
    my $err = $@;
    cmp_ok($err, '=~', qr{\QHTML::Template::Compiled->new() called with 'type' parameter set, but no 'source'});
}

{
    eval {
        my $t = HTML::Template::Compiled->new(
            type => 'nonsense',
            source => 't/templates/simple.tmpl',
        );
    };
    my $err = $@;
    cmp_ok($err, '=~', qr{\QHTML::Template::Compiled->new() : type parameter must be set to 'filename', 'arrayref', 'scalarref' or 'filehandle'});
}

{
    eval {
        my $t = HTML::Template::Compiled->new_file(
            't/templates/simple.tmpl',
            scalarref => \'test',
        );
    };
    my $err = $@;
    cmp_ok($err, '=~', qr{\QHTML::Template::Compiled->new called with multiple (or no) template sources specified});
}

{
    eval {
        my $t = HTML::Template::Compiled->new_file(
            '',
            scalarref => \'test',
        );
    };
    my $err = $@;
    cmp_ok($err, '=~', qr{\QHTML::Template::Compiled->new called with empty filename parameter});
}
