use v5.16;
use warnings;
use utf8;
use Test::More 0.98;
use File::Temp qw(tempdir);

use IO::Factotum;

# An object which gives the content of a file: upper case for a file
# of the name *.txt, and nothing for the others
package Upper {
    sub new { bless { called => [] }, shift }
    sub file {
        my($obj, $file) = @_;
        push @{$obj->{called}}, $file;
        return undef unless $file =~ /\.txt\z/;
        open my $fh, '<:raw', $file or return undef;
        local $/;
        uc <$fh>;
    }
}

# One which dies
package Dies { sub new { bless {}, shift } sub file { die "oops\n" } }

# One which marks every file
package Mark {
    sub new { bless { mark => $_[1] }, $_[0] }
    sub file {
        my($obj, $file) = @_;
        open my $fh, '<:raw', $file or return undef;
        local $/;
        $obj->{mark} . <$fh>;
    }
}

package main;

my $dir = tempdir(CLEANUP => 1);

sub put {
    my($name, $text) = @_;
    open my $fh, '>:utf8', "$dir/$name" or die "$name: $!";
    print $fh $text;
    close $fh;
    "$dir/$name";
}

sub slurp {
    my $fh = shift;
    local $/;
    scalar <$fh>;
}

put 'a.txt', "one\ntwo\n";
put 'a.c',   "int x;\n";
put 'j.txt', "あいう\n";

subtest 'an object gives the content' => sub {
    IO::Factotum::clear();
    my $upper = Upper->new;
    IO::Factotum::register(with => $upper);
    my $fh = IO::Factotum::open_input("$dir/a.txt");
    isa_ok $fh, 'IO::Handle';
    is slurp($fh), "ONE\nTWO\n", 'the content is that of the object';
    is slurp(IO::Factotum::open_input("$dir/a.c")), "int x;\n",
        'a file the object gives nothing for is read as it is';
    is_deeply $upper->{called}, [ "$dir/a.txt", "$dir/a.c" ], 'called with the name of the file';

    my @line = IO::Factotum::open_input("$dir/a.txt")->getlines;
    is_deeply \@line, [ "ONE\n", "TWO\n" ], 'lines';
};

subtest 'bytes and characters' => sub {
    IO::Factotum::clear();
    IO::Factotum::register(with => Mark->new('> '));
    my $fh = IO::Factotum::open_input("$dir/j.txt");
    binmode $fh, ':utf8';
    is slurp($fh), "> あいう\n", 'bytes are given as they are';

    # characters are written as UTF-8
    IO::Factotum::clear();
    IO::Factotum::register(with => Mark->new('→ '));
    $fh = IO::Factotum::open_input("$dir/a.c");
    binmode $fh, ':utf8';
    is slurp($fh), "→ int x;\n", 'characters';
};

subtest 'errors' => sub {
    IO::Factotum::clear();
    IO::Factotum::register(with => Dies->new);
    is slurp(IO::Factotum::open_input("$dir/a.txt")), "one\ntwo\n",
        'an object which dies leaves the file as it is';
    is IO::Factotum::open_input("$dir/nosuchfile"), undef, 'a file which is not there';
    ok $!, 'with $! set';

    ok !eval { IO::Factotum::register(with => 'Upper'); 1 }, 'with must be an object';
    ok !eval { IO::Factotum::register(with => bless {}, 'NoFile'); 1 },
        'which has the method file';
    like $@, qr/register: with must be an object which has the method file/, 'message';
    ok !eval { IO::Factotum::register(with => Upper->new, command => [ 'cat' ]); 1 },
        'not with a command';
    ok !eval { IO::Factotum::register(); 1 }, 'something is required';
};

subtest 'with other converters' => sub {
    # in the order they were registered: the first which gives the
    # content is used, and an object which gives nothing passes
    IO::Factotum::clear();
    IO::Factotum::register(with => Upper->new);
    IO::Factotum::register(match => qr/\.c\z/, command => [ $^X, '-pe', 's/int/long/' ]);
    IO::Factotum::register(with => Mark->new('# '));
    is slurp(IO::Factotum::open_input("$dir/a.txt")), "ONE\nTWO\n", 'the object first';
    is slurp(IO::Factotum::open_input("$dir/a.c")), "long x;\n", 'the command, after the object passed';

    # match limits the files of an object
    IO::Factotum::clear();
    IO::Factotum::register(match => qr/\.c\z/, with => Mark->new('# '));
    is slurp(IO::Factotum::open_input("$dir/a.c")), "# int x;\n", 'match: the file';
    is slurp(IO::Factotum::open_input("$dir/a.txt")), "one\ntwo\n", 'match: another file';
};

subtest 'the standard input' => sub {
    IO::Factotum::clear();
    IO::Factotum::register(with => Mark->new('# '));
    is IO::Factotum::open_input('-'), *STDIN{IO}, 'is STDIN itself';
};

IO::Factotum::clear();
done_testing;
