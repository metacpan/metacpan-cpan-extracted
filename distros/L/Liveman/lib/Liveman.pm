package Liveman;
use 5.22.0;
use common::sense;

our $VERSION = "2.0";

use Cwd::utf8 qw/getcwd/;
use File::Basename qw/dirname/;
use File::Find::Wanted qw/find_wanted/;
use File::Spec qw//;
use File::Slurper qw/read_text write_text/;
use File::Path qw/mkpath rmtree/;
use Markdown::To::POD qw/markdown_to_pod/;
use Term::ANSIColor qw/colored/;
use Text::Trim qw/trim/;


# Конструктор
sub new {
    my $cls = shift;
    my $self = bless {@_}, $cls;
    delete $self->{files} if $self->{files} && !scalar @{$self->{files}};
    $self
}

# Пакет из пути
sub _pkg($) {
    my ($pkg) = @_;
    my @pkg = File::Spec->splitdir($pkg);
    shift @pkg; # Удаляем lib/
    $pkg[$#pkg] =~ s!\.\w+$!!; # Удаляем расширение
    join "::", @pkg
}

# Получить путь к тестовому файлу из пути к md-файлу
sub test_path {
    my ($self, $md) = @_;

    my ($volume, $chains) = File::Spec->splitpath($md, 1);
    my @dirs = File::Spec->splitdir($chains);

    shift @dirs; # Удаляем lib
    $dirs[$#dirs] =~ s!\.md$!\.t!;

    my $md = File::Spec->catfile("t", map { lcfirst($_) =~ s/[A-Z]/"-" . lc $&/gre } @dirs);

    $md
}

# Трансформирует md-файлы
sub transforms {
    my ($self) = @_;
    my $mds = $self->{files} // [ find_wanted(sub { /\.md$/ }, "lib") ];

    $self->{count} = 0;

    if($self->{compile_force}) {
        $self->transform($_) for @$mds;
    } else {
        for my $md (@$mds) {
            my $test = $self->test_path($md);
            my $mdmtime = (stat $md)[9];
            die "Нет файла $md" if !$mdmtime;
            $self->transform($md, $test) if !-e $test || -e $test && $mdmtime > (stat $test)[9];
        }
    }

    if(-f "minil.toml" && -r "minil.toml") {
        my $is_copy; my $name;
        eval {
            my $minil = read_text("minil.toml");
            ($name) = $minil =~ /^name = "([\w:-]+)"/m;
            $name =~ s!(-|::)!/!g;
            $name = "lib/$name.md";
            if(-f $name && -r $name) {
                if(!-e "README.md" || -e "README.md"
                    && (stat $name)[9] > (stat "README.md")[9]) {
                    write_text "README.md", read_text $name;
                    $is_copy = 1;
                }
            }
        };
        if($@) {warn $@}
        elsif($is_copy) {
            print "📘 $name ", colored("↦", "white"), " README.md ", colored("...", "white"), " ", colored("ok", "bright_green"), "\n";
        }
    }

    $self
}

# Эскейпинг для qr!!
sub _qr_esc {
    $_[0] =~ s/!/\\!/gr
}

# Эскейпинг для строки в двойных кавычках
sub _qq_esc {
    $_[0] =~ s!"!\\"!gr
}

# Эскейпинг для строки в одинарных кавычках
sub _q_esc {
    $_[0] =~ s!'!\\'!gr
}

# Строка кода для тестирования
sub _to_testing {
    my ($line, %x) = @_;

    return $x{code} if $x{code} =~ /^\s*#/;

    my $expected = $x{expected};
    my $q = _q_esc($line =~ s!\s*$!!r);
    my $code = trim($x{code});

    if(exists $x{is_deeply}) { "::is_deeply scalar do {$code}, scalar do {$expected}, '$q';\n" }
    elsif(exists $x{is})   { "::is scalar do {$code}, scalar do{$expected}, '$q';\n" }
    elsif(exists $x{qqis}) { my $ex = _qq_esc($expected); "::is scalar do {$code}, \"$ex\", '$q';\n" }
    elsif(exists $x{qis})  { my $ex = _q_esc($expected);  "::is scalar do {$code}, '$ex', '$q';\n" }
    elsif(exists $x{like})  { my $ex = _qr_esc($expected);  "::like scalar do {$code}, qr!$ex!, '$q';\n" }
    elsif(exists $x{unlike})  { my $ex = _qr_esc($expected);  "::unlike scalar do {$code}, qr!$ex!, '$q';\n" }
    else { # Что-то ужасное вырвалось на волю!
        "???"
    }
}

# Трансформирует md-файл в тест и документацию
sub transform {
    my ($self, $md, $test) = @_;
    $test //= $self->test_path($md);

    print "🔖 $md ", colored("↦", "white"), " $test ", colored("...", "white"), " ";

    my $markdown = read_text($md);

    my @pod; my @test; my $title = 'Start'; my $close_subtest; my $use_title = 1;

    my @text = split /^(```\w*[ \t]*(?:\n|\z))/mo, $markdown;

    for(my $i=0; $i<@text; $i+=4) {
        my ($mark, $sec1, $code, $sec2) = @text[$i..$i+4];

        push @pod, markdown_to_pod($mark);
        push @test, $mark =~ s/^/# /rmg;

        last unless defined $sec1;
        $i--, $sec2 = $code, $code = "" if $code =~ /^```[ \t]*$/;

        die "=== mark ===\n$mark\n=== sec1 ===\n$sec1\n=== code ===\n$code\n=== sec2 ===\n$sec2\n\nsec2 ne ```" if $sec2 ne "```\n";

        $title = trim($1) while $mark =~ /^#+[ \t]+(.*)/gm;

        push @pod, "\n", ($code =~ s/^/\t/gmr), "\n";

        my ($infile, $is) = $mark =~ /^(?:File|Файл)[ \t]+(.*?)([\t ]+(?:is|является))?:[\t ]*\n\z/m;
        if($infile) {
            my $real_code = $code =~ s/^\\(```\w*[\t ]*$)/$1/mgro;
            if($is) { # тестируем, что текст совпадает
                push @test, "\n{ my \$s = '${\_q_esc($infile)}'; open my \$__f__, '<:utf8', \$s or die \"Read \$s: \$!\"; my \$n = join '', <\$__f__>; close \$__f__; ::is \$n, '${\_q_esc($real_code)}', \"File \$s\"; }\n";
            }
            else { # записываем тект в файл
                #push @test, "\n{ my \$s = main::_mkpath_('${\_q_esc($infile)}'); open my \$__f__, '>:utf8', \$s or die \"Read \$s: \$!\"; print \$__f__ '${\_q_esc($real_code)}'; close \$__f__ }\n";
                push @test, "#\@> $infile\n", $real_code =~ s/^/#>> /rgm, "#\@< EOF\n";
            }
        } elsif($sec1 =~ /^```(?:perl)?[ \t]*$/) {

            if($use_title ne $title) {
                push @test, "done_testing; }; " if $close_subtest;
                $close_subtest = 1;
                push @test, "subtest '${\ _q_esc($title)}' => sub { ";
                $use_title = $title;
            }

            my $test = $code =~ s{^(?<code>.*)#[ \t]*((?<is_deeply>-->|⟶)|(?<is>->|→)|(?<qqis>=>|⇒)|(?<qis>\\>|↦)|(?<like>~>|↬)|(?<unlike><~|↫))\s*(?<expected>.+?)[ \t]*\n}{ _to_testing($&, %+) }grme;
            push @test, "\n", $test, "\n";
        }
        else {
            push @test, "\n", $code =~ s/^/# /rmg, "\n";
        }
    }

    push @test, "\n\tdone_testing;\n};\n" if $close_subtest;
    push @test, "\ndone_testing;\n";

    my @pwd_dirs = File::Spec->splitdir(getcwd());
    my $project_name = $pwd_dirs[$#pwd_dirs];

    my @test_dirs = File::Spec->splitdir($test);

    my $test_dir = File::Spec->catfile(@test_dirs[0..$#test_dirs-1]);

    mkpath($test_dir);
    shift @test_dirs; # Удаляем t/
    $test_dirs[$#test_dirs] =~ s!\.t$!!; # Удаляем .t

    local $ENV{TMPDIR}; # yath устанавливает свою TMPDIR, нам этого не надо
    my $test_path = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs));

    my $test_head1 = << 'END';
use common::sense;
use open qw/:std :utf8/;

use Carp qw//;
use File::Basename qw//;
use File::Slurper qw//;
use File::Spec qw//;
use File::Path qw//;
use Scalar::Util qw//;

use Test::More 0.98;

BEGIN {
    $SIG{__DIE__} = sub {
        my ($s) = @_;
        if(ref $s) {
            $s->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $s;
            die $s;
        } else {
            die Carp::longmess defined($s)? $s: "undef"
        }
    };

    my $t = File::Slurper::read_text(__FILE__);
    my $s = 
END

my $test_head2 = << 'END2';
    ;
    File::Path::rmtree($s) if -e $s;
    File::Path::mkpath($s);
    chdir $s or die "chdir $s: $!";

    while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) {
        my ($file, $code) = ($1, $2);
        $code =~ s/^#>> //mg;
        File::Path::mkpath(File::Basename::dirname($file));
        File::Slurper::write_text($file, $code);
    }

}
END2

    $test_head1 =~ y!\r\n!  !;
    $test_head2 =~ y!\r\n!  !;

    write_text $test, join "", $test_head1, "'", _q_esc($test_path), "'", $test_head2, @test;

    # Создаём модуль, если его нет
    my $pm = $md =~ s/\.md$/.pm/r;
    if(!-e $pm) {
        my $pkg = _pkg($pm);
        write_text $pm, "package $pkg;\n\n1;";
    }

    # Трансформируем модуль (pod и версия):
    my $pod = join "", @pod;
    my $module = read_text $pm;
    $module =~ s!(\s*\n__END__[\t ]*\n.*)?$!\n\n__END__\n\n=encoding utf-8\n\n$pod!sn;

    # Меняем версию:
    my $v = uc "version";
    my ($version) = $markdown =~ /^#[ \t]+$v\s+([\w\.-]{1,32})\s/m;
    $module =~ s!^(our\s*\$$v\s*=\s*)["']?[\w.-]{1,32}["']?!$1"$version"!m if defined $version;
    write_text $pm, $module;

    $self->{count}++;

    print colored("ok", "bright_green"), "\n";

    $self
}

# Запустить тесты
sub tests {
    my ($self) = @_;

    my $cover = "/usr/bin/site_perl/cover";
    $cover = 'cover' if !-e $cover;

    my $yath = "/usr/bin/site_perl/yath";
    $yath = 'yath' if !-e $yath;

    my $options = $self->{options};

    if($self->{files}) {
        my @tests = map $self->test_path($_), @{$self->{files}};
        local $, = " ";
        $self->{exit_code} = system $self->{prove}
            ? "prove -Ilib $options @tests"
            : "$yath test -j4 $options @tests";
        return $self;
    }

    my $perl5opt = $ENV{PERL5OPT};

    system "$cover -delete";
    if($self->{prove}) {
        local $ENV{PERL5OPT} = "$perl5opt -MDevel::Cover";
        $self->{exit_code} = system "prove -Ilib -r t $options";
        #$self->{exit_code} = system "prove --exec 'echo `pwd`/lib && perl -MDevel::Cover -I`pwd`/lib' -r t";
    } else {
        $self->{exit_code} = system "$yath test -j4 --cover $options";
    }
    return $self if $self->{exit_code};
    system "$cover -report html_basic";
    system "(opera cover_db/coverage.html || xdg-open cover_db/coverage.html) &> /dev/null" if $self->{open};
    return $self;
}

1;

__END__

=encoding utf-8

=head1 NAME

Liveman - markdown compiller to test and pod

=head1 VERSION

2.0

=head1 SYNOPSIS

File lib/Example.md:

	Twice two:
	\```perl
	2*2  # -> 2+2
	\```

Test:

	use Liveman;
	
	my $liveman = Liveman->new(prove => 1);
	
	# compile lib/Example.md file to t/example.t and added pod to lib/Example.pm
	$liveman->transform("lib/Example.md");
	
	$liveman->{count}   # => 1
	-f "t/example.t"    # => 1
	-f "lib/Example.pm" # => 1
	
	# compile all lib/**.md files with a modification time longer than their corresponding test files (t/**.t)
	$liveman->transforms;
	$liveman->{count}   # => 0
	
	# compile without check modification time
	Liveman->new(compile_force => 1)->transforms->{count} # => 1
	
	# start tests with yath
	my $yath_return_code = $liveman->tests->{exit_code};
	
	$yath_return_code           # => 0
	-f "cover_db/coverage.html" # => 1
	
	# limit liveman to these files for operations transforms and tests (without cover)
	my $liveman2 = Liveman->new(files => [], force_compile => 1);

=head1 DESCRIPION

The problem with modern projects is that the documentation is disconnected from testing.
This means that the examples in the documentation may not work, and the documentation itself may lag behind the code.

Liveman compile C<lib/**>.md files to C<t/**.t> files
and it added pod-documentation to section C<__END__> to C<lib/**.pm> files.

Use C<liveman> command for compile the documentation to the tests in catalog of your project and starts the tests:

 liveman

Run it with coverage.

Option C<-o> open coverage in browser (coverage file: C<cover_db/coverage.html>).

Liveman replace C<our $VERSION = "...";> in C<lib/**.pm> from C<lib/**.md> if it exists in pm and in md.

If exists file B<minil.toml>, then Liveman read C<name> from it, and copy file with this name and extension C<.md> to README.md.

=head2 TYPES OF TESTS

Section codes C<noname> or C<perl> writes as code to C<t/**.t>-file. And comment with arrow translates on test from module C<Test::More>.

The test name set as the code-line.

=head3 C<is>

Compare two expressions for equivalence:

	"hi!" # -> "hi" . "!"
	"hi!" # → "hi" . "!"

=head3 C<is_deeply>

Compare two expressions for structures:

	"hi!" # --> "hi" . "!"
	"hi!" # ⟶ "hi" . "!"

=head3 C<is> with extrapolate-string

Compare expression with extrapolate-string:

	my $exclamation = "!";
	"hi!2" # => hi${exclamation}2
	"hi!2" # ⇒ hi${exclamation}2

=head3 C<is> with nonextrapolate-string

Compare expression with nonextrapolate-string:

	'hi${exclamation}3' # \> hi${exclamation}3
	'hi${exclamation}3' # ↦ hi${exclamation}3

=head3 C<like>

It check a regular expression included in the expression:

	'abbc' # ~> b+
	'abc'  # ↬ b+

=head3 C<unlike>

It check a regular expression excluded in the expression:

	'ac' # <~ b+
	'ac' # ↫ b+

=head2 EMBEDDING FILES

Each test is executed in a temporary directory, which is erased and created when the test is run.

This directory format is /tmp/.liveman/I<project>/I<path-to-test>/.

Code section in md-file prefixed line B<< File C<path>: >> write to file in rintime testing.

Code section in md-file prefixed line B<< File C<path> is: >> will be compared with the file by the method C<Test::More::is>.

File experiment/test.txt:

	hi!

File experiment/test.txt is:

	hi!

B<Attention!> An empty string between the prefix and the code is not allowed!

Prefixes maybe on russan: C<Файл path:> and C<Файл path является:>.

=head1 METHODS

=head2 new (%param)

Constructor. Has arguments:

=over

=item 1. C<files> (array_ref) — list of md-files for methods C<transforms> and C<tests>.

=item 2. C<open> (boolean) — open coverage in browser. If is B<opera> browser — open in it. Else — open via C<xdg-open>.

=item 3. C<force_compile> (boolean) — do not check the md-files modification time.

=item 4. C<options> — add options in command line to yath or prove.

=item 5. C<prove> — use prove, but use'nt yath.

=back

=head2 test_path ($md_path)

Get the path to the C<t/**.t>-file from the path to the C<lib/**.md>-file:

	Liveman->new->test_path("lib/PathFix/RestFix.md") # => t/path-fix/rest-fix.t

=head2 transform ($md_path, [$test_path])

Compile C<lib/**.md>-file to C<t/**.t>-file.

And method C<transform> replace the B<pod>-documentation in section C<__END__> in C<lib/**.pm>-file. And create C<lib/**.pm>-file if it not exists.

File lib/Example.pm is:

	package Example;
	
	1;
	
	__END__
	
	=encoding utf-8
	
	Twice two:
	
		2*2  # -> 2+2
	

File C<lib/Example.pm> was created from file C<lib/Example.md> described in section C<SINOPSIS> in this document.

=head2 transforms ()

Compile C<lib/**.md>-files to C<t/**.t>-files.

All if C<< $self-E<gt>{files} >> is empty, or C<< $self-E<gt>{files} >>.

=head2 tests ()

Tests C<t/**.t>-files.

All if C<< $self-E<gt>{files} >> is empty, or C<< $self-E<gt>{files} >> only.

=head1 AUTHOR

Yaroslav O. Kosmina LL<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Liveman module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
