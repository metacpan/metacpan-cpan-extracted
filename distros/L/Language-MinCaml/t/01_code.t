use strict;
use Test::More tests => 30;

my $class = 'Language::MinCaml::Code';

use_ok($class);

### test new
{
    my $code = $class->new;
    isa_ok($code, $class);
    is($code->{buffer}, q{});
    is($code->line, 0);
    is($code->column, 0);
    is($code->{next_line}, undef);
}

### test from_string
{
    my $code = $class->from_string("hoge\nfuga\nhige\n");
    isa_ok($code, $class);
    is($code->{buffer}, 'hoge');
    is($code->line, 1);
    is($code->column, 1);
}

{
    my $code = $class->from_string('');
    isa_ok($code, $class);
    is($code->{buffer}, '');
    is($code->line, 0);
    is($code->column, 0);
}

### test from_file
{
    my $code = $class->from_file('t/assets/test.ml');
    isa_ok($code, $class);
    is($code->{buffer}, 'hoge');
    is($code->line, 1);
    is($code->column, 1);
}

{
    my $code = $class->from_file('t/assets/test_empty.ml');
    isa_ok($code, $class);
    is($code->{buffer}, '');
    is($code->line, 0);
    is($code->column, 0);
}


### test buffer
{
    my $code = $class->from_string("hoge\nfuga\nhige\n");
    is($code->buffer, 'hoge');
}

{
    my $code = $class->from_string('');
    is($code->buffer, '');
}

### test forward
{
    my $code = $class->from_string("hoge\nfuga\nhige\n");
    $code->forward(3);
    is($code->column, 4);
    is($code->line, 1);

    $code->forward(1);
    is($code->column, 1);
    is($code->line, 2);
}

{
    my $code = $class->from_string('');
    $code->forward(3);
    is($code->column, 0);
    is($code->line, 0);
}

