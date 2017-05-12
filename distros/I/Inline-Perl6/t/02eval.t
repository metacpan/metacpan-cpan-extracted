use Inline::Perl6;

Inline::Perl6::p6_run("use Test; ok(1);");
Inline::Perl6::p6_run("use Test; ok(2); done-testing();");
