use strict;
use Test::More 0.98;
use Test::Exception;
use Getopt::Kingpin;


subtest 'default' => sub {
    local @ARGV;
    push @ARGV, qw();

    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->flag('name', 'set name')->default("default name")->string();
    my $xxxx = $kingpin->flag('xxxx', 'set xxxx')->string();

    $kingpin->parse;

    is $name, 'default name';
    is $xxxx, '';
};

subtest 'default (list)' => sub {
    local @ARGV;
    push @ARGV, qw();

    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->flag('name', 'set name')->default(["default name", "default name 2"])->string_list();
    my $xxxx = $kingpin->flag('xxxx', 'set xxxx')->string_list();

    $kingpin->parse;

    is_deeply $name->value, ['default name', 'default name 2'];
    is_deeply $xxxx->value, [];
};

subtest 'default (hash)' => sub {
    local @ARGV;
    push @ARGV, qw();

    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->flag('name', 'set name')->default({"foo"=>"a","bar"=>"b"})->string_hash();
    my $xxxx = $kingpin->flag('xxxx', 'set xxxx')->string_hash();

    $kingpin->parse;

    is_deeply $name->value, {"foo"=>"a","bar"=>"b"};
    is_deeply $xxxx->value, {};
};

subtest 'default arg' => sub {
    local @ARGV;
    push @ARGV, qw();

    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->arg('name', 'set name')->default("default name")->string();
    my $xxxx = $kingpin->arg('xxxx', 'set xxxx')->string();

    $kingpin->parse;

    is $name, 'default name';
    is $xxxx, '';
};

subtest 'default arg (list)' => sub {
    local @ARGV;
    push @ARGV, qw();

    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->arg('name', 'set name')->default(["default name", "default name 2"])->string_list();
    my $xxxx = $kingpin->arg('xxxx', 'set xxxx')->string_list();

    $kingpin->parse;

    is_deeply $name->value, ['default name', 'default name 2'];
    is_deeply $xxxx->value, [];
};

subtest 'default arg (hash)' => sub {
    local @ARGV;
    push @ARGV, qw();

    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->arg('name', 'set name')->default({"foo"=>"a","bar"=>"b"})->string_hash();
    my $xxxx = $kingpin->arg('xxxx', 'set xxxx')->string_hash();

    $kingpin->parse;

    is_deeply $name->value, {"foo"=>"a","bar"=>"b"};
    is_deeply $xxxx->value, {};
};

subtest 'coderef default' => sub {
    local @ARGV;
    push @ARGV, qw();

    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->flag('name', 'set name')->default(sub { "default name" })->string();
    my $xxxx = $kingpin->flag('xxxx', 'set xxxx')->string();

    $kingpin->parse;

    is $name, 'default name';
    is $xxxx, '';
};

subtest 'coderef default (list)' => sub {
    local @ARGV;
    push @ARGV, qw();

    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->flag('name', 'set name')->default(sub { ["default name", "default name 2"] })->string_list();
    my $xxxx = $kingpin->flag('xxxx', 'set xxxx')->string_list();

    $kingpin->parse;

    is_deeply $name->value, ['default name', 'default name 2'];
    is_deeply $xxxx->value, [];
};

subtest 'coderef default (hash)' => sub {
    local @ARGV;
    push @ARGV, qw();

    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->flag('name', 'set name')->default(sub {{"foo"=>"a","bar"=>"b"}})->string_hash();
    my $xxxx = $kingpin->flag('xxxx', 'set xxxx')->string_hash();

    $kingpin->parse;

    is_deeply $name->value, {"foo"=>"a","bar"=>"b"};
    is_deeply $xxxx->value, {};
};

subtest 'coderef default arg' => sub {
    local @ARGV;
    push @ARGV, qw();

    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->arg('name', 'set name')->default(sub { "default name" })->string();
    my $xxxx = $kingpin->arg('xxxx', 'set xxxx')->string();

    $kingpin->parse;

    is $name, 'default name';
    is $xxxx, '';
};

subtest 'coderef default arg (list)' => sub {
    local @ARGV;
    push @ARGV, qw();

    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->arg('name', 'set name')->default(sub { ["default name", "default name 2"] })->string_list();
    my $xxxx = $kingpin->arg('xxxx', 'set xxxx')->string_list();

    $kingpin->parse;

    is_deeply $name->value, ['default name', 'default name 2'];
    is_deeply $xxxx->value, [];
};

subtest 'coderef default arg (hash)' => sub {
    local @ARGV;
    push @ARGV, qw();

    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->arg('name', 'set name')->default(sub {{"foo"=>"a","bar"=>"b"}})->string_hash();
    my $xxxx = $kingpin->arg('xxxx', 'set xxxx')->string_hash();

    $kingpin->parse;

    is_deeply $name->value, {"foo"=>"a","bar"=>"b"};
    is_deeply $xxxx->value, {};
};

# Package for overloaded defaults
sub ov (&) {
    package Local::Overloaded;
    use overload '&{}' => sub { $_[0][0] };
    bless [ @_ ];
}

subtest 'overloaded object default' => sub {
    local @ARGV;
    push @ARGV, qw();

    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->flag('name', 'set name')->default(ov { "default name" })->string();
    my $xxxx = $kingpin->flag('xxxx', 'set xxxx')->string();

    $kingpin->parse;

    is $name, 'default name';
    is $xxxx, '';
};

subtest 'overloaded object default (list)' => sub {
    local @ARGV;
    push @ARGV, qw();

    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->flag('name', 'set name')->default(ov { ["default name", "default name 2"] })->string_list();
    my $xxxx = $kingpin->flag('xxxx', 'set xxxx')->string_list();

    $kingpin->parse;

    is_deeply $name->value, ['default name', 'default name 2'];
    is_deeply $xxxx->value, [];
};

subtest 'overloaded object default (hash)' => sub {
    local @ARGV;
    push @ARGV, qw();

    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->flag('name', 'set name')->default(ov {{"foo"=>"a","bar"=>"b"}})->string_hash();
    my $xxxx = $kingpin->flag('xxxx', 'set xxxx')->string_hash();

    $kingpin->parse;

    is_deeply $name->value, {"foo"=>"a","bar"=>"b"};
    is_deeply $xxxx->value, {};
};

subtest 'overloaded object default arg' => sub {
    local @ARGV;
    push @ARGV, qw();

    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->arg('name', 'set name')->default(ov { "default name" })->string();
    my $xxxx = $kingpin->arg('xxxx', 'set xxxx')->string();

    $kingpin->parse;

    is $name, 'default name';
    is $xxxx, '';
};

subtest 'overloaded object default arg (list)' => sub {
    local @ARGV;
    push @ARGV, qw();

    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->arg('name', 'set name')->default(ov { ["default name", "default name 2"] })->string_list();
    my $xxxx = $kingpin->arg('xxxx', 'set xxxx')->string_list();

    $kingpin->parse;

    is_deeply $name->value, ['default name', 'default name 2'];
    is_deeply $xxxx->value, [];
};

subtest 'overloaded object default arg (hash)' => sub {
    local @ARGV;
    push @ARGV, qw();

    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->arg('name', 'set name')->default(ov {{"foo"=>"a","bar"=>"b"}})->string_hash();
    my $xxxx = $kingpin->arg('xxxx', 'set xxxx')->string_hash();

    $kingpin->parse;

    is_deeply $name->value, {"foo"=>"a","bar"=>"b"};
    is_deeply $xxxx->value, {};
};

subtest 'non-overloaded object default' => sub {
    local @ARGV;
    push @ARGV, qw();

    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->arg('name', 'set name')->default(bless({'x'=>3}, 'Local::SomePackage'));
    my $xxxx = $kingpin->arg('xxxx', 'set xxxx');

    $kingpin->parse;

    is_deeply $name->value, bless({'x'=>3}, 'Local::SomePackage');
    is_deeply $xxxx->value, undef;
};

done_testing;

