use strict;
use Test::More 0.98;
use Test::Exception;
use Capture::Tiny ':all';
use Getopt::Kingpin;
use Getopt::Kingpin::Command;
use File::Basename;

subtest 'command (flag)' => sub {
    local @ARGV;
    push @ARGV, qw(post --server 127.0.0.1 --image=abc.jpg);

    my $kingpin = Getopt::Kingpin->new();
    my $post = $kingpin->command("post", "post image");
    my $server = $post->flag("server", "")->string();
    my $image = $post->flag("image", "")->file();

    my $cmd = $kingpin->parse;

    is $cmd, "post";
    is $cmd->flags->get("server"), "127.0.0.1";
    is $cmd->flags->get("image"), "abc.jpg";

    is ref $post, "Getopt::Kingpin::Command";
    is ref $server, "Getopt::Kingpin::Flag";
    is ref $image, "Getopt::Kingpin::Flag";

    is $server, "127.0.0.1";
    is $image, "abc.jpg";
};

subtest 'command (arg)' => sub {
    local @ARGV;
    push @ARGV, qw(post 127.0.0.1 abc.jpg);

    my $kingpin = Getopt::Kingpin->new();
    my $post = $kingpin->command("post", "post image");
    my $server = $post->arg("server", "")->string();
    my $image = $post->arg("image", "")->file();

    my $cmd = $kingpin->parse;

    is $cmd, "post";
    is $cmd->args->get("server"), "127.0.0.1";
    is $cmd->args->get("image"), "abc.jpg";

    is ref $post, "Getopt::Kingpin::Command";
    is ref $server, "Getopt::Kingpin::Arg";
    is ref $image, "Getopt::Kingpin::Arg";

    is $server, "127.0.0.1";
    is $image, "abc.jpg";
};

subtest 'command (flag and arg)' => sub {
    local @ARGV;
    push @ARGV, qw(post --server 127.0.0.1 abc.jpg);

    my $kingpin = Getopt::Kingpin->new();
    my $post = $kingpin->command("post", "post image");
    my $server = $post->flag("server", "")->string();
    my $image = $post->arg("image", "")->file();

    $kingpin->parse;

    is ref $post, "Getopt::Kingpin::Command";
    is ref $server, "Getopt::Kingpin::Flag";
    is ref $image, "Getopt::Kingpin::Arg";

    is $server, "127.0.0.1";
    is $image, "abc.jpg";
};

subtest 'command help' => sub {
    local @ARGV;
    push @ARGV, qw(--help);

    my $kingpin = Getopt::Kingpin->new();
    $kingpin->terminate(sub {return @_});
    my $post = $kingpin->command("post", "post image");
    my $server = $post->flag("server", "")->string();
    my $image = $post->arg("image", "")->file();

    my $expected = sprintf <<'...', basename($0);
usage: %s [<flags>] <command> [<args> ...]

Flags:
  --help  Show context-sensitive help.

Commands:
  help [<command>...]
    Show help.

  post [<flags>] [<image>]
    post image


...

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };
    is $exit, 0;
    is $stdout, $expected;
};

subtest 'command help' => sub {
    local @ARGV;
    push @ARGV, qw(--help);

    my $kingpin = Getopt::Kingpin->new();
    $kingpin->terminate(sub {return @_});
    my $post = $kingpin->command("post", "post image");
    my $server = $post->flag("server", "")->string();
    my $image = $post->arg("image", "")->file();
    my $get  = $kingpin->command("get", "get image");

    my $expected = sprintf <<'...', basename($0);
usage: %s [<flags>] <command> [<args> ...]

Flags:
  --help  Show context-sensitive help.

Commands:
  help [<command>...]
    Show help.

  post [<flags>] [<image>]
    post image

  get
    get image


...

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };
    is $exit, 0;
    is $stdout, $expected;
};

subtest 'command help' => sub {
    local @ARGV;
    push @ARGV, qw(--help);

    my $kingpin = Getopt::Kingpin->new();
    $kingpin->terminate(sub {return @_});
    my $post = $kingpin->command("post", "post image");
    my $server = $post->flag("server", "")->string();
    my $get  = $kingpin->command("get", "get image");

    my $expected = sprintf <<'...', basename($0);
usage: %s [<flags>] <command> [<args> ...]

Flags:
  --help  Show context-sensitive help.

Commands:
  help [<command>...]
    Show help.

  post [<flags>]
    post image

  get
    get image


...

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };
    is $exit, 0;
    is $stdout, $expected;
};

subtest 'command help 2' => sub {
    local @ARGV;
    push @ARGV, qw(help);

    my $kingpin = Getopt::Kingpin->new();
    $kingpin->terminate(sub {return @_});
    my $post = $kingpin->command("post", "post image");
    my $server = $post->flag("server", "")->string();
    my $get  = $kingpin->command("get", "get image");

    my $expected = sprintf <<'...', basename($0);
usage: %s [<flags>] <command> [<args> ...]

Flags:
  --help  Show context-sensitive help.

Commands:
  help [<command>...]
    Show help.

  post [<flags>]
    post image

  get
    get image


...

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };
    is $exit, 0;
    is $stdout, $expected;
};

subtest 'command help 3' => sub {
    local @ARGV;
    push @ARGV, qw(--help post);

    my $kingpin = Getopt::Kingpin->new();
    $kingpin->terminate(sub {return @_});
    my $post = $kingpin->command("post", "post image");
    my $server = $post->flag("server", "")->string();
    my $get  = $kingpin->command("get", "get image");

    my $expected = sprintf <<'...', basename($0);
usage: %s post [<flags>]

post image

Flags:
  --help           Show context-sensitive help.
  --server=SERVER

...

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };
    is $exit, 0;
    is $stdout, $expected;
};

subtest 'command help 3' => sub {
    local @ARGV;
    push @ARGV, qw(post --help);

    my $kingpin = Getopt::Kingpin->new();
    $kingpin->terminate(sub {return @_});
    my $post = $kingpin->command("post", "post image");
    my $server = $post->flag("server", "")->string();
    my $get  = $kingpin->command("get", "get image");

    my $expected = sprintf <<'...', basename($0);
usage: %s post [<flags>]

post image

Flags:
  --help           Show context-sensitive help.
  --server=SERVER

...

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };
    is $exit, 0;
    is $stdout, $expected;
};

subtest 'command help 3' => sub {
    local @ARGV;
    push @ARGV, qw(help post);

    my $kingpin = Getopt::Kingpin->new();
    $kingpin->terminate(sub {return @_});
    my $post = $kingpin->command("post", "post image");
    my $server = $post->flag("server", "")->string();
    my $get  = $kingpin->command("get", "get image");

    my $expected = sprintf <<'...', basename($0);
usage: %s post [<flags>]

post image

Flags:
  --help           Show context-sensitive help.
  --server=SERVER

...

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };
    is $exit, 0;
    is $stdout, $expected;
};

subtest 'command help 3' => sub {
    local @ARGV;
    push @ARGV, qw(help post --server=SERVER);

    my $kingpin = Getopt::Kingpin->new();
    $kingpin->terminate(sub {return @_});
    my $post = $kingpin->command("post", "post image");
    my $server = $post->flag("server", "")->string();
    my $get  = $kingpin->command("get", "get image");

    my $expected = sprintf <<'...', basename($0);
usage: %s post [<flags>]

post image

Flags:
  --help           Show context-sensitive help.
  --server=SERVER

...

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };
    is $exit, 0;
    is $stdout, $expected;
};

subtest 'command help 3' => sub {
    local @ARGV;
    push @ARGV, qw(--help post);

    my $kingpin = Getopt::Kingpin->new();
    $kingpin->terminate(sub {return @_});
    my $post = $kingpin->command("post", "post image");
    my $server = $post->flag("server", "")->string();
    my $get  = $kingpin->command("get", "get image");

    my $expected = sprintf <<'...', basename($0);
usage: %s post [<flags>]

post image

Flags:
  --help           Show context-sensitive help.
  --server=SERVER

...

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };
    is $exit, 0;
    is $stdout, $expected;
};

subtest 'command help 4' => sub {
    local @ARGV;
    push @ARGV, qw(help get);

    my $kingpin = Getopt::Kingpin->new();
    $kingpin->terminate(sub {return @_});
    my $post = $kingpin->command("post", "post image");
    my $server = $post->flag("server", "")->string();
    my $get  = $kingpin->command("get", "get image");

    my $expected = sprintf <<'...', basename($0);
usage: %s get

get image

Flags:
  --help  Show context-sensitive help.

...

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };
    is $exit, 0;
    is $stdout, $expected;
};

subtest 'command help 5' => sub {
    local @ARGV;
    push @ARGV, qw(--help post);

    my $kingpin = Getopt::Kingpin->new();
    $kingpin->terminate(sub {return @_});
    my $post = $kingpin->command("post", "");
    my $server = $post->arg("server", "server address")->string();
    my $get  = $kingpin->command("get", "get image");

    my $expected = sprintf <<'...', basename($0);
usage: %s post [<server>]

Flags:
  --help  Show context-sensitive help.

Args:
  [<server>]  server address

...

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };
    is $exit, 0;
    is $stdout, $expected;
};

subtest 'command help 6' => sub {
    local @ARGV;
    push @ARGV, qw(--help);

    my $kingpin = Getopt::Kingpin->new();
    $kingpin->terminate(sub {return @_});
    my $post = $kingpin->command("post", "post image");
    my $server = $post->flag("server", "server address")->string();
    my $get  = $kingpin->command("get", "get image");
    my $xyz  = $get->command("xyz", "set xyz");

    my $expected = sprintf <<'...', basename($0);
usage: %s [<flags>] <command> [<args> ...]

Flags:
  --help  Show context-sensitive help.

Commands:
  help [<command>...]
    Show help.

  post [<flags>]
    post image

  get xyz
    set xyz


...

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };
    is $exit, 0;
    is $stdout, $expected;
};

subtest 'command help 6' => sub {
    local @ARGV;
    push @ARGV, qw(--help);

    my $kingpin = Getopt::Kingpin->new();
    $kingpin->terminate(sub {return @_});
    my $post = $kingpin->command("post", "post image");
    my $server = $post->flag("server", "server address")->string();
    my $get  = $kingpin->command("get", "get image");
    my $xyz  = $get->command("xyz", "set xyz");
    my $abc  = $get->command("abc", "set abc");

    my $expected = sprintf <<'...', basename($0);
usage: %s [<flags>] <command> [<args> ...]

Flags:
  --help  Show context-sensitive help.

Commands:
  help [<command>...]
    Show help.

  post [<flags>]
    post image

  get xyz
    set xyz

  get abc
    set abc


...

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };
    is $exit, 0;
    is $stdout, $expected;
};

subtest 'command help 6' => sub {
    local @ARGV;
    push @ARGV, qw(--help get);

    my $kingpin = Getopt::Kingpin->new();
    $kingpin->terminate(sub {return @_});
    my $post = $kingpin->command("post", "post image");
    my $server = $post->flag("server", "server address")->string();
    my $get  = $kingpin->command("get", "get image");
    my $xyz  = $get->command("xyz", "set xyz");

    my $expected = sprintf <<'...', basename($0);
usage: %s get <command> [<args> ...]

get image

Flags:
  --help  Show context-sensitive help.

Subcommands:
  get xyz
    set xyz

...

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };
    is $exit, 0;
    is $stdout, $expected;
};

subtest 'command help 7' => sub {
    local @ARGV;
    push @ARGV, qw(--help register);

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});

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

subtest 'command help 7-2' => sub {
    local @ARGV;
    push @ARGV, qw(register --help);

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});

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

subtest 'command help 7-3' => sub {
    local @ARGV;
    push @ARGV, qw(help register);

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});

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

subtest 'command help 8' => sub {
    local @ARGV;
    push @ARGV, qw(--help post);

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});

    my $register      = $kingpin->command('register', 'Register a new user.');
    my $register_nick = $register->arg('nick', 'Nickname for user.')->required->string;
    my $register_name = $register->arg('name', 'Name for user.')->required->string;

    my $post        = $kingpin->command('post', 'Post a message to a channel.');
    my $postImage   = $post->flag('image', 'Image to post.')->file;
    my $postChannel = $post->arg('channel', 'Channel to post to.')->required->string;
    my $postText    = $post->arg('text', 'Text to post.')->string_list;

    my $expected = sprintf <<'...', basename($0);
usage: %s post [<flags>] <channel> [<text>...]

Post a message to a channel.

Flags:
  --help         Show context-sensitive help.
  --image=IMAGE  Image to post.

Args:
  <channel>  Channel to post to.
  [<text>]   Text to post.

...

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };
    is $exit, 0;
    is $stdout, $expected;
};

subtest 'command help 8-2' => sub {
    local @ARGV;
    push @ARGV, qw(post --help);

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});

    my $register      = $kingpin->command('register', 'Register a new user.');
    my $register_nick = $register->arg('nick', 'Nickname for user.')->required->string;
    my $register_name = $register->arg('name', 'Name for user.')->required->string;

    my $post        = $kingpin->command('post', 'Post a message to a channel.');
    my $postImage   = $post->flag('image', 'Image to post.')->file;
    my $postChannel = $post->arg('channel', 'Channel to post to.')->required->string;
    my $postText    = $post->arg('text', 'Text to post.')->string_list;

    my $expected = sprintf <<'...', basename($0);
usage: %s post [<flags>] <channel> [<text>...]

Post a message to a channel.

Flags:
  --help         Show context-sensitive help.
  --image=IMAGE  Image to post.

Args:
  <channel>  Channel to post to.
  [<text>]   Text to post.

...

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };
    is $exit, 0;
    is $stdout, $expected;
};

subtest 'command help 8-3' => sub {
    local @ARGV;
    push @ARGV, qw(help post);

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});

    my $register      = $kingpin->command('register', 'Register a new user.');
    my $register_nick = $register->arg('nick', 'Nickname for user.')->required->string;
    my $register_name = $register->arg('name', 'Name for user.')->required->string;

    my $post        = $kingpin->command('post', 'Post a message to a channel.');
    my $postImage   = $post->flag('image', 'Image to post.')->file;
    my $postChannel = $post->arg('channel', 'Channel to post to.')->required->string;
    my $postText    = $post->arg('text', 'Text to post.')->string_list;

    my $expected = sprintf <<'...', basename($0);
usage: %s post [<flags>] <channel> [<text>...]

Post a message to a channel.

Flags:
  --help         Show context-sensitive help.
  --image=IMAGE  Image to post.

Args:
  <channel>  Channel to post to.
  [<text>]   Text to post.

...

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };
    is $exit, 0;
    is $stdout, $expected;
};

subtest 'command help 9-1' => sub {
    local @ARGV;
    push @ARGV, qw(--verbose register NICK NAME --age 100);

    my $kingpin = Getopt::Kingpin->new;
    my $verbose = $kingpin->flag("verbose", "set verbose mode")->bool;

    my $register      = $kingpin->command('register', 'Register a new user.');
    my $register_age  = $register->flag('age', 'Age for user.')->int;
    my $register_nick = $register->arg('nick', 'Nickname for user.')->required->string;
    my $register_name = $register->arg('name', 'Name for user.')->required->string;

    my $cmd = $kingpin->parse;

    is $cmd, "register";
    is $verbose, 1;
    is $register_age, 100;
    is $register_nick, "NICK";
    is $register_name, "NAME";
};

subtest 'command help 9-2' => sub {
    local @ARGV;
    push @ARGV, qw(register NICK NAME --age 100 --verbose);

    my $kingpin = Getopt::Kingpin->new;
    my $verbose = $kingpin->flag("verbose", "set verbose mode")->bool;

    my $register      = $kingpin->command('register', 'Register a new user.');
    my $register_age  = $register->flag('age', 'Age for user.')->int;
    my $register_nick = $register->arg('nick', 'Nickname for user.')->required->string;
    my $register_name = $register->arg('name', 'Name for user.')->required->string;

    my $cmd = $kingpin->parse;

    is $cmd, "register";
    is $verbose, 1;
    is $register_age, 100;
    is $register_nick, "NICK";
    is $register_name, "NAME";
};

subtest 'command help 9-3 help' => sub {
    local @ARGV;
    push @ARGV, qw(help register);

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});
    my $verbose = $kingpin->flag("verbose", "set verbose mode")->bool;

    my $register      = $kingpin->command('register', 'Register a new user.');
    my $register_age  = $register->flag('age', 'Age for user.')->int;
    my $register_nick = $register->arg('nick', 'Nickname for user.')->required->string;
    my $register_name = $register->arg('name', 'Name for user.')->required->string;

    my $expected = sprintf <<'...', basename($0);
usage: %s register [<flags>] <nick> <name>

Register a new user.

Flags:
  --help     Show context-sensitive help.
  --verbose  set verbose mode
  --age=AGE  Age for user.

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

subtest 'command help 9-4 help' => sub {
    local @ARGV;
    push @ARGV, qw(--help register);

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});
    my $verbose = $kingpin->flag("verbose", "set verbose mode")->bool;

    my $register      = $kingpin->command('register', 'Register a new user.');
    my $register_age  = $register->flag('age', 'Age for user.')->int;
    my $register_nick = $register->arg('nick', 'Nickname for user.')->required->string;
    my $register_name = $register->arg('name', 'Name for user.')->required->string;

    my $expected = sprintf <<'...', basename($0);
usage: %s register [<flags>] <nick> <name>

Register a new user.

Flags:
  --help     Show context-sensitive help.
  --verbose  set verbose mode
  --age=AGE  Age for user.

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

subtest 'command help 9-4 help' => sub {
    local @ARGV;
    push @ARGV, qw(register --help);

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});
    my $verbose = $kingpin->flag("verbose", "set verbose mode")->bool;

    my $register      = $kingpin->command('register', 'Register a new user.');
    my $register_age  = $register->flag('age', 'Age for user.')->int;
    my $register_nick = $register->arg('nick', 'Nickname for user.')->required->string;
    my $register_name = $register->arg('name', 'Name for user.')->required->string;

    my $expected = sprintf <<'...', basename($0);
usage: %s register [<flags>] <nick> <name>

Register a new user.

Flags:
  --help     Show context-sensitive help.
  --verbose  set verbose mode
  --age=AGE  Age for user.

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

subtest 'command help hash' => sub {
    local @ARGV;
    push @ARGV, qw(register --help);

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});
    my $verbose = $kingpin->flag("verbose", "set verbose mode")->bool;

    my $register = $kingpin->command('register', 'Register a new user.');
    $register->flag('test1', 'Test 1.')->string_hash;
    $register->flag('test2', 'Test 2.')->placeholder('VAL')->string_hash;
    $register->flag('test3', 'Test 3.')->placeholder('K=V')->string_hash;
    $register->arg('test4', 'Test 4.')->string_hash;

    my $expected = sprintf <<'...', basename($0);
usage: %s register [<flags>] [<KEY=test4>]

Register a new user.

Flags:
  --help             Show context-sensitive help.
  --verbose          set verbose mode
  --test1 KEY=VALUE  Test 1.
  --test2 KEY=VAL    Test 2.
  --test3 K=V        Test 3.

Args:
  [<KEY=test4>]  Test 4.

...

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };
    is $exit, 0;
    is $stdout, $expected;
};


done_testing;

