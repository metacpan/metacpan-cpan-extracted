use strict;
use Test::More 0.98;
use Getopt::Kingpin;
use Capture::Tiny ':all';
use File::Basename;


subtest 'hidden' => sub {
    # from : t/20_flag_keys.t
    local @ARGV;
    push @ARGV, qw(--name kingpin -- path);

    my $kingpin = Getopt::Kingpin->new();
    $kingpin->flag("hidden1", "")->hidden->string();
    $kingpin->flag("bbb", "")->string();
    $kingpin->flag("hidden2", "")->hidden->string();
    $kingpin->flag("ccc", "")->string();
    $kingpin->flag("hidden3", "")->hidden->string();
    $kingpin->flag("aaa", "")->string();
    $kingpin->flag("hidden4", "")->hidden->string();
    $kingpin->flag("eee", "")->string();
    $kingpin->flag("hidden5", "")->hidden->string();
    $kingpin->flag("ddd", "")->string();
    $kingpin->flag("hidden6", "")->hidden->string();

    my @keys = $kingpin->flags->keys;
    is +(scalar @keys), 6;
    is $keys[0], "help";
    is $keys[1], "bbb";
    is $keys[2], "ccc";
    is $keys[3], "aaa";
    is $keys[4], "eee";
    is $keys[5], "ddd";

};

subtest 'hidden + command help 7-2' => sub {
    # from : t/23_command.t
    local @ARGV;
    push @ARGV, qw(register --help);

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});
    $kingpin->flag("hidden1", "")->hidden->string();

    my $register      = $kingpin->command('register', 'Register a new user.');
    my $register_nick = $register->arg('nick', 'Nickname for user.')->required->string;
    my $register_name = $register->arg('name', 'Name for user.')->required->string;

    my $post        = $kingpin->command('post', 'Post a message to a channel.');
    my $postImage   = $post->flag('image', 'Image to post.')->file;
    my $postChannel = $post->arg('channel', 'Channel to post to.')->required->string;
    my $postText    = $post->arg('text', 'Text to post.')->string_list;

    my $expected = sprintf <<'...', basename($0);
usage: %s register <nick> <name>

Register a new user.

Flags:
  --help  Show context-sensitive help.

Args:
  <nick>  Nickname for user.
  <name>  Name for user.

...

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };
    is $exit, 0;
    is $stdout, $expected;
};

done_testing;
