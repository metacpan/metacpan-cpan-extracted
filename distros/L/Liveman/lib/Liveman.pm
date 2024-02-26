package Liveman;
use 5.22.0;
use common::sense;

our $VERSION = "3.1";

use Cwd::utf8 qw/getcwd/;
use File::Basename qw/dirname/;
use File::Find::Wanted qw/find_wanted/;
use File::Spec qw//;
use File::Slurper qw/read_text write_text/;
use File::Path qw/mkpath rmtree/;
use Locale::PO qw//;
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
            $self->transform($md, $test) if !-e $test
                || $mdmtime > (stat $test)[9];
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
                if(!-e "README.md" || (stat $name)[9] > (stat "README.md")[9]) {
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

# Обрезает строки вначале и все пробельные символы в конце
sub _first_line_trim ($) {
	local ($_) = @_;
    s/^([\t ]*\n)*//;
    s/\s*$//;
    $_
}

# Преобразует из строчного формата
sub _from_str ($) {
    local ($_) = @_;
    s/^"(.*)"$/$1/s;
    s/\\(.)/ $1 eq "n"? "\n": $1 eq "t"? "\t": $1 /ge;
    $_
}

# Загрузка po
sub load_po {
	my ($self, $md, $from, $to) = @_;

    @$self{qw/from to/} = ($from, $to);

    return $self unless $md;

    my ($volume, $chains) = File::Spec->splitpath($md, 1);
    my @dirs = File::Spec->splitdir($chains);
    $dirs[0] = 'i18n'; # Удаляем lib
    $dirs[$#dirs] =~ s!\.md$!\.$from-$to.po!;

    $self->{po_file} = File::Spec->catfile(@dirs);
    my $i18n = File::Spec->catfile(@dirs[0..$#dirs-1]);
    mkpath($i18n);

    my $manager = $self->{po_manager} = Locale::PO->new;
    my $po = -e $self->{po_file}? $manager->load_file_ashash($self->{po_file}, "utf8"): {};

    my %po;
    my $lineno = 0;
    for(keys %$po) {
        my $val = $po->{$_};
        $po{_first_line_trim(_from_str($_))} = $val;
    }

    $self->{po} = \%po;

	$self
}

# Сохранение po
sub save_po {
	my ($self) = @_;

    return $self unless $self->{from};

    my @po = grep $_->{__used}, sort { $a->{loaded_line_number} <=> $b->{loaded_line_number} } values %{$self->{po}};

    $self->{po_manager}->save_file_fromarray($self->{po_file}, \@po, "utf8");

	$self
}

# Функция переводит текст с одного языка на другой используя утилиту trans
sub trans {
	my ($self, $text, $lineno) = @_;

    $text = _first_line_trim($text);

    return $text if $text eq "";

    my $po = $self->{po}{$text};
    $po->{__used} = 1, $po->loaded_line_number($lineno), return _from_str($po->msgstr) if defined $po;

    my $dir = File::Spec->catfile(File::Spec->tmpdir, ".liveman");
    mkpath($dir);
    my $trans_from = File::Spec->catfile($dir, $self->{from});
    my $trans_to = File::Spec->catfile($dir, $self->{to});
    write_text($trans_from, $text);

    if(system "trans -b $self->{from}:$self->{to} < $trans_from > $trans_to") {
        die "trans: failed to execute: $!" if $? == -1;
        die printf "trans: child died with signal %d, %s coredump",
            ($? & 127), ($? & 128) ? 'with' : 'without'
                if $? & 127;
        die printf "trans: child exited with value %d", $? >> 8;
    }

    my $trans = _first_line_trim(read_text($trans_to));

    $po = Locale::PO->new(
        -msgid => $text,
        -msgstr => $trans,
        -loaded_line_number => $lineno,
    );

    $po->{__used} = 1;
    $self->{po}{$text} = $po;

    $trans
}

# Заголовки не переводим
# Так же разбиваем по параграфам
sub trans_paragraph {
	my ($self, $paragraph, $lineno) = @_;

    join "", map {
        /^(#|\s*$)/n ? $_: join "", "\n", $self->trans(_first_line_trim($_), $lineno += 0.001), "\n\n"
    } split /((?:[\t\ ]*\n){2,})/, $paragraph
}

# Трансформирует md-файл в тест и документацию
sub transform {
    my ($self, $md, $test) = @_;
    $test //= $self->test_path($md);

    print "🔖 $md ", colored("↦", "white"), " $test ", colored("...", "white"), " ";

    my $markdown = read_text($md);

    my $from; my $to;
    $markdown =~ s/^!(\w+):(\w+)[\t ]*\n/$from = $1; $to = $2; "\n"/e;
    $self->load_po($md, $from, $to);

    my @pod; my @test; my $title = 'Start'; my $close_subtest; my $use_title = 1;

    my @text = split /^(```\w*[ \t]*(?:\n|\z))/mo, $markdown;

    for(my $i=0; $i<@text; $i+=4) {
        my ($mark, $sec1, $code, $sec2) = @text[$i..$i+4];

        push @pod, markdown_to_pod($from? $self->trans_paragraph($mark, $i): $mark);
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

    $self->save_po;

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

Liveman - compiler from markdown to tests and documentation

=head1 VERSION

3.1

=head1 SYNOPSIS

File lib/Example.md:

	Дважды два:
	\```perl
	2*2  # -> 2+2
	\```

Test:

	use Liveman;
	
	my $liveman = Liveman->new(prove => 1);
	
	# Компилировать lib/Example.md файл в t/example.t 
	# и добавить pod-документацию в lib/Example.pm
	$liveman->transform("lib/Example.md");
	
	$liveman->{count}   # => 1
	-f "t/example.t"    # => 1
	-f "lib/Example.pm" # => 1
	
	# Компилировать все lib/**.md файлы со временем модификации, превышающим соответствующие тестовые файлы (t/**.t):
	$liveman->transforms;
	$liveman->{count}   # => 0
	
	# Компилировать без проверки времени модификации
	Liveman->new(compile_force => 1)->transforms->{count} # => 1
	
	# Запустить тесты с yath:
	my $yath_return_code = $liveman->tests->{exit_code};
	
	$yath_return_code           # => 0
	-f "cover_db/coverage.html" # => 1
	
	# Ограничить liveman этими файлами для операций, преобразований и тестов (без покрытия):
	my $liveman2 = Liveman->new(files => [], force_compile => 1);

=head1 DESCRIPTION

The problem with modern projects is that documentation is divorced from testing.
This means that the examples in the documentation may not work, and the documentation itself may lag behind the code.

Liveman compiles C<lib/**.md> files into C<t/**.t> files
and adds documentation in the module's C<__END__> section to the C<lib/**.pm> files.

Use the C<liveman> command to compile test documentation in your project directory and run the tests:

liveman

Run it coated.

The C<-o> option opens a code coverage report by tests in the browser (coverage report file: C<cover_db/coverage.html>).

Liveman replaces C<our $VERSION = "...";> in C<lib/**.pm> from C<lib/**.md> from the B<VERSION> section if it exists.

If the B<minil.toml> file exists, then Liveman will read C<name> from it and copy the file with that name and C<.md> extension into C<README.md>.

If you need the documentation in C<.md> to be written in one language, and C<pod> in another, then at the beginning of C<.md> you need to indicate C<!from:to> (from which language to translate, for example, for this file: C<!ru:en>).

Headings (lines starting with #) are not translated. Also, do not translate blocks of code.
And the translation itself is carried out paragraph by paragraph.

Files with translations are stored in the C<i18n> directory, for example, C<lib/My/Module.md> -> C<i18n/My/Module.ru-en.po>. Translation is carried out using the C<trans> utility (it must be installed on the system). Translation files can be corrected, because if the translation is already in the file, then it is taken.

B<Warning!> Be careful and review C<git diff> after editing C<.md> so as not to lose the corrected translations in C<.po>.

=head2 TYPES OF TESTS

Section codes without a specified programming language or with C<perl> are written as code in the file C<t/**.t>. And a comment with an arrow (# -> ) turns into a C<Test::More> test.

=head3 C<is>

Compare two equivalent expressions:

	"hi!" # -> "hi" . "!"
	"hi!" # → "hi" . "!"

=head3 C<is_deeply>

Compare two expressions for structures:

	["hi!"] # --> ["hi" . "!"]
	"hi!" # ⟶ "hi" . "!"

=head3 C<is> with extrapolate-string

Compare expression with extrapolated string:

	my $exclamation = "!";
	"hi!2" # => hi${exclamation}2
	"hi!2" # ⇒ hi${exclamation}2

=head3 C<is> with nonextrapolate-string

Compare an expression with a non-extrapolated string:

	'hi${exclamation}3' # \> hi${exclamation}3
	'hi${exclamation}3' # ↦ hi${exclamation}3

=head3 C<like>

Tests the regular expression included in the expression:

	'abbc' # ~> b+
	'abc'  # ↬ b+

=head3 C<unlike>

It checks the regular expression excluded from the expression:

	'ac' # <~ b+
	'ac' # ↫ b+

=head2 EMBEDDING FILES

Each test runs in a temporary directory, which is deleted and created when the test runs.

The format of this directory is /tmp/.liveman/I<project>/I<path-to-test>/.

The section of code on the line with the md file prefix B<< File C<path>: >> will be written to a file when tested at runtime.

The code section in the md file prefix line B<< File C<path> is: >> will be compared to the file using the C<Test::More::is> method.

File experiment/test.txt:

	hi!

The experiment/test.txt file is:

	hi!

B<Attention!> An empty line between the prefix and the code is not allowed!

These prefixes can be in both English and Russian.

=head1 METHODS

=head2 new (%param)

Constructor. Has arguments:

=over

=item 1. C<files> (array_ref) - list of md files for the C<transforms> and C<tests> methods.

=item 2. C<open> (boolean) — open the coverage in the browser. If the B<opera> browser is installed on your computer, the C<opera> command will be used to open it. Otherwise - C<xdg-open>.

=item 3. C<force_compile> (boolean) - do not check the modification time of md files.

=item 4. C<options> - add parameters on the command line for verification or proof.

=item 5. C<prove> - use proof (the C<prove> command to run tests), rather than the C<yath> command.

=back

=head2 test_path ($md_path)

Get the path to the C<t/**.t> file from the path to the C<lib/**.md> file:

	Liveman->new->test_path("lib/PathFix/RestFix.md") # => t/path-fix/rest-fix.t

=head2 transform ($md_path, [$test_path])

Compiles a C<lib/**.md> file into a C<t/**.t> file.

It also replaces the B<pod> documentation in the C<__END__> section in the C<lib/**.pm> file and creates a C<lib/**.pm> file if it does not exist.

The lib/Example.pm file is:

	package Example;
	
	1;
	
	__END__
	
	=encoding utf-8
	
	Дважды два:
	
		2*2  # -> 2+2
	

The file C<lib/Example.pm> was created from the file C<lib/Example.md>, as described in the C<SINOPSIS> section of this document.

=head2 transforms ()

Compile C<lib/**.md> files into C<t/**.t> files.

All if C<< $self-E<gt>{files} >> is not set, or C<< $self-E<gt>{files} >>.

=head2 tests ()

Run tests (C<t/**.t> files).

All if C<< $self-E<gt>{files} >> is not set, or C<< $self-E<gt>{files} >> only.

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Liveman module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
