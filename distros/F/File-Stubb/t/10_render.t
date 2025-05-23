#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Stubb::Render;

use File::Path qw(remove_tree);
use File::Spec;
use File::Temp qw(tempfile);

my $TEMPLATES = File::Spec->catfile(qw/t data templates/);

my $TMP = do {
    my ($h, $n) = tempfile;
    close $h;
    $n;
};

my $SUBST = {
    one => 1,
    two => 2,
    three => 3,
};

sub slurp {

    my ($file) = @_;

    local $/ = undef;
    open my $fh, '<', $file
        or die "Failed to open $file for reading: $!\n";
    my $slurp = <$fh>;
    close $fh;

    return $slurp;

}

my $render;
my @created;
my $targets;
my $path;

$render = File::Stubb::Render->new(
    template => File::Spec->catfile($TEMPLATES, 'none.stubb'),
    subst => $SUBST,
);

isa_ok($render, 'File::Stubb::Render');

is(
    $render->template,
    File::Spec->catfile($TEMPLATES, 'none.stubb'),
    'template ok'
);

is_deeply(
    $render->subst,
    $SUBST,
    'substitution parameters ok'
);

ok(!$render->hidden, 'hidden ok');
ok($render->follow_symlinks, 'follow_symlinks ok');
ok(!$render->copy_perms, 'copy_perms ok');
ok($render->defaults, 'defaults ok');

$targets = $render->targets;

is_deeply(
    $targets,
    {
        basic => [],
        perl  => [],
        shell => [],
    },
    'targets() ok'
);

@created = $render->render($TMP);

is_deeply(
    \@created,
    [ $TMP ],
    'render() ok'
);

is(
    slurp($TMP),
    <<'HERE',
This is
just a normal
text file
HERE
    'Plain rendering ok'
);

unlink $TMP;

$render = File::Stubb::Render->new(
    template => File::Spec->catfile($TEMPLATES, 'basic.stubb'),
    subst => $SUBST,
);

isa_ok($render, 'File::Stubb::Render');

$targets = $render->targets;

is_deeply(
    $targets,
    {
        basic => [ qw(four one three two) ],
        perl  => [],
        shell => [],
    },
    'targets() ok'
);

$path = $render->render_path('^^one^^-^^two^^-^^three^^');

is(
    $path,
    '1-2-3',
    'render_path() ok'
);

@created = $render->render($TMP);

is_deeply(
    \@created,
    [ $TMP ],
    'render() ok'
);

is(
    slurp($TMP),
    <<'HERE',
My favorite number: 1
My third favorite number: 3
My three favorite numbers: 1, 2, 3, 4
HERE
    'Basic target rendering ok'
);

unlink $TMP;

$render = File::Stubb::Render->new(
    template => File::Spec->catfile($TEMPLATES, 'conditional.stubb'),
    subst => $SUBST,
);

isa_ok($render, 'File::Stubb::Render');

$targets = $render->targets;

is_deeply(
    $targets,
    {
        basic => [ qw(four one three two) ],
        perl  => [],
        shell => [],
    },
    'targets() ok'
);

@created = $render->render($TMP);

is_deeply(
    \@created,
    [ $TMP ],
    'render() ok'
);

is(
    slurp($TMP),
    <<'HERE',
My favorite number: 1
My third favorite number: 3
My three favorite numbers: 1, 2, 3, 
HERE
    'Conditional target rendering ok'
);

unlink $TMP;

$render = File::Stubb::Render->new(
    template => File::Spec->catfile($TEMPLATES, 'perl.stubb'),
    subst => $SUBST,
);

isa_ok($render, 'File::Stubb::Render');

$targets = $render->targets;

is_deeply(
    $targets,
    {
        basic => [],
        perl  => [
            q!$_{ one } + 1!,
            q!$_{ three } ** 2!,
            q!join ' ', @_{ qw(one two three) }!,
            q!$_{ four }!,
        ],
        shell => [],
    },
    'targets() ok'
);

@created = $render->render($TMP);

is_deeply(
    \@created,
    [ $TMP ],
    'render() ok'
);

is(
    slurp($TMP),
    <<'HERE',
My favorite number +1: 2
My third favorite number squared: 9
My three favorite numbers: 1 2 3
Maybe a number? 
HERE
    'Perl target rendering ok'
);

unlink $TMP;

SKIP: {

    qx/echo "" 2>&1/;
    skip('echo failed', 4) unless ($? >> 8) == 0;

    if ($^O eq 'MSWin32') {

        $render = File::Stubb::Render->new(
            template => File::Spec->catfile($TEMPLATES, 'win-shell.stubb'),
            subst => $SUBST,
        );

        isa_ok($render, 'File::Stubb::Render');

        $targets = $render->targets;

        is_deeply(
            $targets,
            {
                basic => [],
                perl  => [],
                shell => [
                    q!echo %one%!,
                    q!echo %three%!,
                    q!echo %one% %two% %three%!,
                    q!echo %four%!,
                ],
            },
            'targets ok'
        );

        @created = $render->render($TMP);

        is_deeply(
            \@created,
            [ $TMP ],
            'render() ok'
        );

        is(
            slurp($TMP),
            <<'HERE',
My favorite number: 1
My third favorite number: 3
My three favorite numbers: 1 2 3
Maybe a number? %four%
HERE
            'Shell target rendering ok'
        );

    } else {

        $render = File::Stubb::Render->new(
            template => File::Spec->catfile($TEMPLATES, 'shell.stubb'),
            subst => $SUBST,
        );

        isa_ok($render, 'File::Stubb::Render');

        $targets = $render->targets;

        is_deeply(
            $targets,
            {
                basic => [],
                perl  => [],
                shell => [
                    q!echo "$one"!,
                    q!echo "$three"!,
                    q!echo "$one $two $three"!,
                    q!echo "$four"!,
                ],
            },
            'targets() ok'
        );

        @created = $render->render($TMP);

        is_deeply(
            \@created,
            [ $TMP ],
            'render() ok'
        );

        is(
            slurp($TMP),
            <<'HERE',
My favorite number: 1
My third favorite number: 3
My three favorite numbers: 1 2 3
Maybe a number? 
HERE
            'Shell target rendering ok'
        );

    }

    unlink $TMP;

}

$render = File::Stubb::Render->new(
    template => File::Spec->catfile($TEMPLATES, 'escape.stubb'),
    subst => $SUBST,
);

isa_ok($render, 'File::Stubb::Render');

$targets = $render->targets;

is_deeply(
    $targets,
    {
        basic => [ qw(four one three two) ],
        perl  => [],
        shell => [],
    },
    'targets() ok'
);

@created = $render->render($TMP);

is_deeply(
    \@created,
    [ $TMP ],
    'render() ok'
);

is(
    slurp($TMP),
    <<'HERE',
My favorite number: $1
My third favorite number: #3
My three favorite numbers: !1, ?2, $3
Maybe a number? ?4
HERE
    'Escaped target rendering ok'
);

unlink $TMP;

$render = File::Stubb::Render->new(
    template => File::Spec->catfile($TEMPLATES, 'not.stubb'),
    subst => $SUBST,
);

isa_ok($render, 'File::Stubb::Render');

$targets = $render->targets;

is_deeply(
    $targets,
    {
        basic => [],
        perl  => [],
        shell => [],
    },
    'targets() ok'
);

@created = $render->render($TMP);

is_deeply(
    \@created,
    [ $TMP ],
    'render() ok'
);

is(
    slurp($TMP),
    <<'HERE',
My favorite number: !^^ one ^^
My third favorite number: !^^ three ^^
My three favorite numbers: !^^ one ^^, !^^ two ^^, !^^ three ^^
HERE
    'Non-target rendering ok'
);

unlink $TMP;

$render = File::Stubb::Render->new(
    template => File::Spec->catfile($TEMPLATES, 'dir.stubb'),
    subst => $SUBST,
);

isa_ok($render, 'File::Stubb::Render');

$targets = $render->targets;

is_deeply(
    $targets,
    {
        basic => [ qw(one three two) ],
        perl  => [],
        shell => [],
    },
    'targets() ok'
);

@created = $render->render($TMP);

is_deeply(
    \@created,
    [
        $TMP,
        map { File::Spec->catfile($TMP, $_) } qw(
            1.txt
            2
            2/3.txt
        ),
    ],
    'Directory rendering ok'
);

remove_tree($TMP, { safe => 1 });

$render = File::Stubb::Render->new(
    template => File::Spec->catfile($TEMPLATES, 'dir-json.stubb')
);

isa_ok($render, 'File::Stubb::Render');

is_deeply(
    $render->subst,
    $SUBST,
    'Substitution parameters ok'
);

ok($render->hidden, 'hidden ok');
ok(!$render->follow_symlinks, 'follow_symlinks ok');
ok($render->copy_perms, 'copy_perms ok');

$targets = $render->targets;

is_deeply(
    $targets,
    {
        basic => [ qw(one three two) ],
        perl  => [],
        shell => [],
    },
    'targets() ok'
);

@created = $render->render($TMP);

is_deeply(
    \@created,
    [
        $TMP,
        map { File::Spec->catfile($TMP, $_) } qw(
            .1.txt
            2
            2/.3.txt
        ),
    ],
    'Directory rendering ok'
);

remove_tree($TMP, { safe => 1 });

$render = File::Stubb::Render->new(
    template        => File::Spec->catfile($TEMPLATES, 'dir-json.stubb'),
    render_hidden   => 0,
    follow_symlinks => 1,
    copy_perms      => 0,
    defaults        => 0,
);

isa_ok($render, 'File::Stubb::Render');

is_deeply(
    $render->subst,
    {},
    'Substitution parameters ok'
);

ok(!$render->hidden, 'hidden ok');
ok($render->follow_symlinks, 'follow_symlinks ok');
ok(!$render->copy_perms, 'copy_perms ok');

@created = $render->render($TMP);

is_deeply(
    \@created,
    [
        $TMP,
        map { File::Spec->catfile($TMP, $_) } qw(
            ^^two^^
        ),
    ],
    'Directory rendering ok'
);

remove_tree($TMP, { safe => 1 });

subtest('ignore_config ok' => sub {

    $render = File::Stubb::Render->new(
        template => File::Spec->catfile($TEMPLATES, 'dir-json.stubb'),
        ignore_config => 1,
    );

    isa_ok($render, 'File::Stubb::Render');

    is_deeply(
        $render->subst,
        {},
        'Substitution parameters ok'
    );

    ok(!$render->hidden, 'hidden ok');
    ok($render->follow_symlinks, 'follow_symlinks ok');
    ok(!$render->copy_perms, 'copy_perms ok');

});

done_testing;

END {
    if (-d $TMP) {
        remove_tree($TMP, { safe => 1 });
    } elsif (-f $TMP) {
        unlink $TMP;
    }
}

# vim: expandtab shiftwidth=4
