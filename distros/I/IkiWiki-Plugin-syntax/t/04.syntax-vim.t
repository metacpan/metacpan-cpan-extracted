#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw(no_plan);

use lib qw(lib t/lib);
use IkiWiki q(2.0);

use MyTestTools qw(:css);

my $class = 'IkiWiki::Plugin::syntax::Vim';

use_ok($class);

my $engine = $class->new();

SKIP: {
    skip "Syntax::Highlight::Engine::Vim not installed" if not $engine;

    isa_ok($engine, $class );

    my $source = <<'EOF';
    /* This is a foo program */
    int a = 3;
    printf("%d\n",a);
EOF

    my $output = eval {
        $engine->syntax_highlight( language    => 'c',
                                            source      => $source,
                                            linenumbers => 1,
                                            bars        => 1, );
        };

    if ($@) {            
        if (my $ex = Syntax::X::Engine->caught()) {
            if ($ex->isa('Syntax::X::Engine::Use')) {
                skip('Text::VimColor is not installed');
            }
            elsif ($ex->isa('Syntax::X::Engine::Language')) {
                skip('Language C syntaxis not supported in Vim');
            }
        }
        fail('Unknown exception');
    }        

    my $regex_ln = build_css_regex('synLineNumber','\d+');                                    
    like($output, $regex_ln, "Source text with line numbers");

    my $regex_bar = build_css_regex('synBar');
    like($output, $regex_bar, "Source text with bar lines");

    check_results( $output, 
            synBar          =>  2,
            synLineNumber   =>  3,
            synType         =>  1,
            synComment      =>  1,
            synConstant     =>  3,      );
}



