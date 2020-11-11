use strict;
use Test::More 0.98;
use Test::Exception;
use Getopt::Kingpin;
use Getopt::Kingpin::Command;

subtest 'parse() return' => sub {
    local @ARGV;
    push @ARGV, qw(post --server 127.0.0.1 --image=abc.jpg);

    my $kingpin = Getopt::Kingpin->new();
    my $post = $kingpin->command("post", "post image");
    my $server = $post->flag("server", "")->string();
    my $image = $post->flag("image", "")->file();

    my $cmd = $kingpin->parse;

    is ref $cmd, "Getopt::Kingpin::Command";
    is $cmd, "post";

    is ref $post, "Getopt::Kingpin::Command";
    is ref $server, "Getopt::Kingpin::Flag";
    is ref $image, "Getopt::Kingpin::Flag";

    is $server, "127.0.0.1";
    is $image, "abc.jpg";
};

subtest 'parse() with arguments' => sub {
    my @argv;
    push @argv, qw(post --server 127.0.0.1 --image=abc.jpg);

    my $kingpin = Getopt::Kingpin->new();
    my $post = $kingpin->command("post", "post image");
    my $server = $post->flag("server", "")->string();
    my $image = $post->flag("image", "")->file();

    my $cmd = $kingpin->parse(@argv);

    is ref $cmd, "Getopt::Kingpin::Command";
    is $cmd, "post";

    is ref $post, "Getopt::Kingpin::Command";
    is ref $server, "Getopt::Kingpin::Flag";
    is ref $image, "Getopt::Kingpin::Flag";

    is $server, "127.0.0.1";
    is $image, "abc.jpg";
};

subtest 'parse() with arrayref arguments' => sub {
    my @argv;
    push @argv, qw(post --server 127.0.0.1 --image=abc.jpg);

    my $kingpin = Getopt::Kingpin->new();
    my $post = $kingpin->command("post", "post image");
    my $server = $post->flag("server", "")->string();
    my $image = $post->flag("image", "")->file();

    my $cmd = $kingpin->parse(\@argv);

    is ref $cmd, "Getopt::Kingpin::Command";
    is $cmd, "post";

    is ref $post, "Getopt::Kingpin::Command";
    is ref $server, "Getopt::Kingpin::Flag";
    is ref $image, "Getopt::Kingpin::Flag";

    is $server, "127.0.0.1";
    is $image, "abc.jpg";
};

subtest 'parse() with empty arrayref will ignore @ARGV' => sub {
    local @ARGV;
    push @ARGV, qw(post --server 127.0.0.1 --image=abc.jpg);

    my $kingpin = Getopt::Kingpin->new();

    my $cmd = $kingpin->parse([]);
    
    is ref $cmd, 'Getopt::Kingpin';
};

done_testing;

