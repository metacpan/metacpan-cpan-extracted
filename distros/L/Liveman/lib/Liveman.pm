package Liveman;
use 5.22.0;
use common::sense;

our $VERSION = "3.7";

use File::Basename qw/dirname/;
use File::Find::Wanted qw/find_wanted/;
use File::Spec qw//;
use File::Slurper qw/read_text write_text/;
use File::Path qw/mkpath rmtree/;
use Locale::PO qw//;
use Markdown::To::POD qw/markdown_to_pod/;
use Term::ANSIColor qw/colored/;
use Text::Trim qw/trim/;
use Liveman::Cpanfile;
use Liveman::MinillaPod2Markdown;

# Конструктор
sub new {
	my $cls = shift;
	my $self = bless {@_}, $cls;
	delete $self->{files} if $self->{files} && !scalar @{$self->{files}};
	$self->{pod2markdown} = Liveman::MinillaPod2Markdown->new;
	$self
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
			die "Not exists file $md!" if !$mdmtime;
			$self->transform($md, $test) if !-e $test
				|| $mdmtime > (stat $test)[9];
		}
	}

	# minil.toml и README.md
	if(-f "minil.toml" && -r "minil.toml") {
		my $is_copy; my $name;
		eval {
			my $minil = read_text("minil.toml");
			($name) = $minil =~ /^name\s*=\s*"([\w:-]+)"/m;
			$name =~ s!(-|::)!/!g;
			$name = "lib/$name.md";
			if(-f $name && -r $name) {
				if(!-e "README.md" || $self->{compile_force} || (stat $name)[9] > (stat "README.md")[9]) {
					my $readme = $self->{pod2markdown}->parse_from_file($name =~ s/\.\w+$/.pm/r)->as_markdown;
					write_text "README.md", $readme;
					$is_copy = 1;
				}
			}
		};
		if($@) {warn colored("minil.toml", 'red') . ": $@"}
		elsif($is_copy) {
			print colored(" ^‥^", "bright_black"), " $name ", colored("-->", "bright_black"), " README.md ", colored("...", "bright_white"), " ", colored("ok", "bright_green"), "\n";
		}
	}

	$self
}

# Эскейпинг для qr!!
sub _qr_esc($) {
	$_[0] =~ s/!/\\!/gr
}

# Эскейпинг для строки в двойных кавычках
sub _qq_esc($) {
	$_[0] =~ s!"!\\"!gr
}

# Эскейпинг для строки в одинарных кавычках
sub _q_esc($) {
	$_[0] =~ s!'!\\'!gr
}

# Строка кода для тестирования
sub _to_testing {
	my ($line, %x) = @_;

	return $x{code} if $x{code} =~ /^\s*#/;

	my $expected = $x{expected};
	my $q = _q_esc($line =~ s!\s*$!!r);
	my $code = trim($x{code});
	# clear делается, чтобы освободить ресурсы
	my $clear = 'undef $::_g0; undef $::_e0;';
	
	# local делается для того, чтобы в AnyEvent, Coro или Thread переменные не пересекались

	if(exists $x{is_deeply}) { "local (\$::_g0 = do {$code}, \$::_e0 = do {$expected}); ::is_deeply \$::_g0, \$::_e0, '$q' or ::diag ::_struct_diff(\$::_g0, \$::_e0); $clear\n" }
	elsif(exists $x{is}) { "local (\$::_g0 = do {$code}, \$::_e0 = do {$expected}); ::ok defined(\$::_g0) == defined(\$::_e0) && ref \$::_g0 eq ref \$::_e0 && \$::_g0 eq \$::_e0, '$q' or ::diag ::_struct_diff(\$::_g0, \$::_e0); $clear\n" }
	elsif(exists $x{qqis}) { "local (\$::_g0 = do {$code}, \$::_e0 = \"${\_qq_esc $expected}\"); ::ok \$::_g0 eq \$::_e0, '$q' or ::diag ::_string_diff(\$::_g0, \$::_e0); $clear\n" }
	elsif(exists $x{qis}) { "local (\$::_g0 = do {$code}, \$::_e0 = '${\_q_esc $expected}'); ::ok \$::_g0 eq \$::_e0, '$q' or ::diag ::_string_diff(\$::_g0, \$::_e0); $clear\n" }
	elsif(exists $x{like}) { "::like scalar do {$code}, qr{${\_qr_esc $expected}}, '$q'; $clear\n" }
	elsif(exists $x{unlike}) { "::unlike scalar do {$code}, qr{${\_qr_esc $expected}}, '$q'; $clear\n" }
	elsif(exists $x{qqbegins}) { "local (\$::_g0 = do {$code}, \$::_e0 = \"${\_qq_esc $expected}\"); ::ok \$::_g0 =~ /^\${\\quotemeta \$::_e0}/, '$q' or ::diag ::string_diff(\$::_g0, \$::_e0, 1); $clear\n" }
	elsif(exists $x{qqends}) { "local (\$::_g0 = do {$code}, \$::_e0 = \"${\_qq_esc $expected}\"); ::ok \$::_g0 =~ /\${\\quotemeta \$::_e0}\$/, '$q' or ::diag ::string_diff(\$::_g0, \$::_e0, 1); $clear\n" }
	elsif(exists $x{qqinners}) { "local (\$::_g0 = do {$code}, \$::_e0 = \"${\_qq_esc $expected}\"); ::ok \$::_g0 =~ quotemeta \$::_e0, '$q' or ::diag ::string_diff(\$::_g0, \$::_e0, 0); $clear\n" }
	elsif(exists $x{begins}) { "local (\$::_g0 = do {$code}, \$::_e0 = '${\_q_esc $expected}'); ::ok \$::_g0 =~ /^\${\\quotemeta \$::_e0}/, '$q' or ::diag ::string_diff(\$::_g0, \$::_e0, 1); $clear\n" }
	elsif(exists $x{ends}) { "local (\$::_g0 = do {$code}, \$::_e0 = '${\_q_esc $expected}'); ::ok \$::_g0 =~ /\${\\quotemeta \$::_e0}\$/, '$q' or ::diag ::string_diff(\$::_g0, \$::_e0, -1); $clear\n" }
	elsif(exists $x{inners}) { "local (\$::_g0 = do {$code}, \$::_e0 = '${\_q_esc $expected}'); ::ok \$::_g0 =~ quotemeta \$::_e0, '$q' or ::diag ::string_diff(\$::_g0, \$::_e0, 0); $clear\n" }
	elsif(exists $x{error}) { "eval {$code}; local (\$::_g0 = \$\@, \$::_e0 = '${\_q_esc $expected}'); ok defined(\$::_g0) && \$::_g0 =~ /^\${\\quotemeta \$::_e0}/, '$q' or ::diag ::string_diff(\$::_g0, \$::_e0, 1); $clear\n" }
	elsif(exists $x{qqerror}) { "eval {$code}; local (\$::_g0 = \$\@, \$::_e0 = \"${\_qq_esc $expected}\"); ok defined(\$::_g0) && \$::_g0 =~ /^\${\\quotemeta \$::_e0}/, '$q' or ::diag ::string_diff(\$::_g0, \$::_e0, 1); $clear\n" }
	elsif(exists $x{qrerror}) { "eval {$code}; local (\$::_g0 = \$\@, \$::_e0 = qr{${\_qr_esc $expected}}); ok defined(\$::_g0) && \$::_g0 =~ \$::_e0, '$q' or ::diag defined(\$::_g0)? \"Got:\$::_g0\": 'Got is undef'; $clear\n" }
	elsif(exists $x{unqrerror}) { "eval {$code}; local (\$::_g0 = \$\@, \$::_e0 = qr{${\_qr_esc $expected}}); ok defined(\$::_g0) && \$::_g0 !~ \$::_e0, '$q' or ::diag defined(\$::_g0)? \"Got:\$::_g0\": 'Got is undef'; $clear\n" }
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
	return $text if $self->{from} eq "ru" && $text =~ /^[\x00-\x7F]*$/a;

	my $po = $self->{po}{$text};
	$po->{__used} = 1, $po->loaded_line_number($lineno), return _from_str($po->msgstr) if defined $po;

	my $dir = File::Spec->catfile(File::Spec->tmpdir, ".liveman");
	mkpath($dir);
	my $trans_from = File::Spec->catfile($dir, $self->{from});
	my $trans_to = File::Spec->catfile($dir, $self->{to});

	write_text($trans_from, $text);

	my @progress = qw/\\ | \/ -/;
	print $progress[$self->{trans_i}++ % @progress], "\033[D";

	my $cmd = "trans -no-auto -b $self->{from}:$self->{to} < $trans_from > $trans_to";
	if(system $cmd) {
		die "$cmd: failed to execute: $!" if $? == -1;
		die printf "%s: child died with signal %d, %s coredump",
			$cmd, ($? & 127), ($? & 128) ? 'with' : 'without'
				if $? & 127;
		die printf "%s: child exited with value %d", $cmd, $? >> 8;
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

# Переводит markdown в pod
sub markdown2pod {
	my ($self, $markdown) = @_;
	local $_ = markdown_to_pod($markdown);
	s/([\t ])(<[\w:]+>)/$1L$2/g;
	s!L+<https://metacpan.org/pod/([\w:]+)>!L<$1>!ag;
	$_
}

our $TEST_HEAD = << 'END';
use common::sense;
use open qw/:std :utf8/;

use Carp qw//;
use Cwd qw//;
use File::Basename qw//;
use File::Find qw//;
use File::Slurper qw//;
use File::Spec qw//;
use File::Path qw//;
use Scalar::Util qw//;

use Test::More 0.98;

use String::Diff qw//;
use Data::Dumper qw//;
use Term::ANSIColor qw//;

BEGIN {
	$SIG{__DIE__} = sub {
		my ($msg) = @_;
		if(ref $msg) {
			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg;
			die $msg;
		} else {
			die Carp::longmess defined($msg)? $msg: "undef"
		}
	};
	
	my $t = File::Slurper::read_text(__FILE__);
	
	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__)));
	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-%(T_DIRS)]);
	my $project_name = $dirs[$#dirs-%(T_DIRS)];
	my @test_dirs = @dirs[$#dirs-%(T_DIRS)+2 .. $#dirs];

	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};

	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__)));
	
	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests;
	File::Path::mkpath($dir_for_tests);
	
	chdir $dir_for_tests or die "chdir $dir_for_tests: $!";
	
	push @INC, "$project_dir/lib", "lib";
	
	$ENV{PROJECT_DIR} = $project_dir;
	$ENV{DIR_FOR_TESTS} = $dir_for_tests;
	
	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) {
		my ($file, $code) = ($1, $2);
		$code =~ s/^#>> //mg;
		File::Path::mkpath(File::Basename::dirname($file));
		File::Slurper::write_text($file, $code);
	}
}

my $white = Term::ANSIColor::color('BRIGHT_WHITE');
my $red = Term::ANSIColor::color('BRIGHT_RED');
my $green = Term::ANSIColor::color('BRIGHT_GREEN');
my $reset = Term::ANSIColor::color('RESET');
my @diff = (
	remove_open => "$white\[$red",
	remove_close => "$white]$reset",
	append_open => "$white\{$green",
	append_close => "$white}$reset",
);

sub _string_diff {
	my ($got, $expected, $chunk) = @_;
	$got = substr($got, 0, length $expected) if $chunk == 1;
	$got = substr($got, -length $expected) if $chunk == -1;
	String::Diff::diff_merge($got, $expected, @diff)
}

sub _struct_diff {
	my ($got, $expected) = @_;
	String::Diff::diff_merge(
		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump,
		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump,
		@diff
	)
}

END

# Трансформирует md-файл в тест и документацию
sub transform {
	my ($self, $md, $test) = @_;
	local $_;
	$test //= $self->test_path($md);

	print colored(" ^‥^", "bright_black"), " $md ", colored("-->", "bright_black"), " $test ", colored("...", "bright_white"), " ";

	my $markdown = read_text($md);

	my $options;
	$markdown =~ s/^!(.*)\n/$options = $1; "\n"/e;
	my ($from, $to) = $options =~ /(\w+):(\w+)/;
	$self->load_po($md, $from, $to);

	my @pod; my @test; my $title = 'Start'; my $close_subtest; my $use_title = 1;

	my @text = split /^(```\w*[ \t]*(?:\n|\z))/mo, $markdown;

	for(my $i=0; $i<@text; $i+=4) {
		$text[$i] =~ s!([ \t])<(\w+(?:::\w+)*)>!${1}[$2](https://metacpan.org/pod/$2)!g;

		# mark - текст, sec1 - ```perl, code - код, sec2 - ```
		my ($mark, $sec1, $code, $sec2) = @text[$i..$i+4];

		push @pod, $self->markdown2pod($from? $self->trans_paragraph($mark, $i): $mark);
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
				push @test, "::done_testing; }; " if $close_subtest;
				$close_subtest = 1;
				push @test, "subtest '${\ _q_esc($title)}' => sub { ";
				$use_title = $title;
			}

			my $test = $code =~ s{^ (?<code> .* ) \# [\ \t]* (
				 (?<is_deeply>  --> | ⟶ )
				|(?<is>	         -> | → )
				|(?<qqis>        => | ⇒ )
				|(?<qis>   	    \\> | ↦ )
				|(?<qqbegins>  \^=> | ⤇ )
				|(?<qqends>    \$=> | ➾ )
				|(?<qqinners>  \*=> | ⥴ )
				|(?<begins>    \^-> | ↣ )
				|(?<ends>      \$-> | ⇥ )
				|(?<inners>    \*-> | ⥵ )
				|(?<error>	   \@-> | ↯ )
				|(?<qqerror>   \@=> | ⤯ )
				|(?<qrerror>   \@~> | ⇝ )
				|(?<unqrerror> <~\@ | ⇜ )
				|(?<like>        ~> | ↬ )
				|(?<unlike>      <~ | ↫ )
			 ) [\ \t]* (?<expected> .+? ) [\ \t]* \n
			}{ _to_testing($&, %+) }xgrme;
			push @test, "\n", $test, "\n";
		}
		else {
			push @test, "\n", $code =~ s/^/# /rmg, "\n";
		}
	}

	push @test, "\n\t::done_testing;\n\};\n" if $close_subtest;
	push @test, "\n::done_testing;\n";

	my $test_head = $TEST_HEAD =~ y!\r\n!  !r;
	
	my $test_dir = File::Basename::dirname($test);
	mkpath $test_dir;
	my @test_dirs = File::Spec->splitdir($test_dir);
	my %inter = (
		T_DIRS => scalar @test_dirs,
	);
	$test_head =~ s/%\((\w+)\)/$inter{$1}/ge;

	write_text $test, join "", $test_head, @test;

	# Меняем версию:
	my $v = uc "version";
	my ($version) = $markdown =~ /^#[ \t]+$v\s+([\w\.-]{1,32})\s/m;
	
	# Трансформируем модуль (pod и версия):
	my $pod_doc = join "", @pod;
	my $pm = $md =~ s/\.md$/.pm/r;
	if (-e $pm) {
		my $module = read_text $pm;
		$module =~ s!^(our\s*\$$v\s*=\s*)["']?[\w.-]{1,32}["']?!$1"$version"!m if defined $version;
		$module =~ s!(\s*\n__END__[\t ]*\n.*)?$!\n\n__END__\n\n=encoding utf-8\n\n$pod_doc!sn;
		write_text $pm, $module;
	} else {
		my $pod = $md =~ s/\.md$/.pod/r;
		write_text $pod, $pod_doc;
	}

	$self->{count}++;

	$self->save_po;

	my $mark = join "", @text;
	$mark =~ s/^/!$options/ if $options;
	write_text($md, $mark) if $mark ne $markdown;

	print colored("ok", "bright_green"), "\n";

	$self
}

# Запустить тесты
sub tests {
	my ($self) = @_;

	local $ENV{LIVEMAN_TMPDIR} = Cwd::abs_path(File::Spec->catfile($ENV{TMPDIR} // '/tmp'));
	mkpath($ENV{LIVEMAN_TMPDIR});

	my $cover = "/usr/bin/site_perl/cover";
	$cover = 'cover' if !-e $cover;

	my $yath; my $prove;
	my $use_prove = $self->{prove};
	if($use_prove) {
		$prove = "/usr/bin/site_perl/prove";
		$prove = 'prove' if !-e $prove;
	} else {
		$yath = "/usr/bin/site_perl/yath";
		$yath = 'yath' if !-e $yath;
	}
	
	my $options = $self->{options};

	if($self->{files}) {
		my @tests = map $self->test_path($_), @{$self->{files}};
		local $, = " ";
		$self->{exit_code} = system $use_prove
			? "$prove -Ilib $options @tests"
			: "$yath test -j4 $options @tests";
		return $self;
	}

	my $perl5opt = $ENV{PERL5OPT};
	{
		local $ENV{PERL5OPT};
		system "$cover -delete";
		if($use_prove) {
			local $ENV{PERL5OPT} = "$perl5opt -MDevel::Cover";
			$self->{exit_code} = system "$prove -Ilib -r t $options";
			#$self->{exit_code} = system "prove --exec 'echo `pwd`/lib && perl -MDevel::Cover -I`pwd`/lib' -r t";
		} else {
			$self->{exit_code} = system "$yath test -j4 --cover $options";
		}
		return $self if $self->{exit_code};
		system "$cover -report html_basic";
		system "(opera cover_db/coverage.html || xdg-open cover_db/coverage.html) &> /dev/null" if $self->{open};
	}

	require Liveman::CoverBadge;
	eval {
		Liveman::CoverBadge->new->load->save;
	};
	warn $@ if $@;

	return $self;
}

1;

__END__

=encoding utf-8

=head1 NAME

Liveman - compiler from Markdown to tests and documentation

=head1 VERSION

3.7

=head1 SYNOPSIS

File lib/Example.md:

	Twice two:
	\```perl
	2*2  # -> 2+2
	\```

Test:

	use Liveman;
	
	my $liveman = Liveman->new(prove => 1);
	
	$liveman->transform("lib/Example.md");
	
	$liveman->{count}    # -> 1
	-f "t/example.t"     # -> 1
	-f "lib/Example.pod" # -> 1
	
	$liveman->transforms;
	$liveman->{count}   # -> 0
	
	Liveman->new(compile_force => 1)->transforms->{count} # -> 1
	
	my $prove_return_code = $liveman->tests->{exit_code};
	
	$prove_return_code          # -> 0
	-f "cover_db/coverage.html" # -> 1

=head1 DESCRIPION

The problem of modern projects is that the documentation is torn from testing.
This means that the examples in the documentation may not work, and the documentation itself can lag behind the code.

LiveMan compiles C<Lib/**.md> to files C<t/**.t>
And adds the documentation to the C<__END__> module to the files C<lib/**.pm>.

Use the `Liveman 'command to compilation of documentation for tests in the catalog of your project and start tests:

 liveman

Run it with a coating.

The C<-o> option opens a report on covering code with tests in a browser (coating report file:C<cover_db/coverage.html>).

Liveman replaces the C<our $VERSION = "...";> in C<lib/**.pm> from C<lib/**.md> from the section B<VERSION> if it exists.

If the I<* minil.toml *> file exists, then Liveman will read C<NAME> from it and copy the file with this name and extensionC<.md> in C<readme.md>.

If you need the documentation in C<.md> to be written in one language, andC<pod> is on the other, then at the beginning of C<.md> you need to indicateC<!from:to> (from which language to translate, for example, for this file: C<!ru:en>).

Headings (lines on #) - are not translated. Also, without translating the code blocks.
And the translation itself is carried out by paragraphs.

Files with transfers are added to the C<i18n> catalog, for example, C<lib/My/Module.md> -> C<i18n/My/Module.ru-en.po>. Translation is carried out by the C<Trans> utility (it should be installed in the system). Translation files can be adjusted, because if the transfer is already in the file, then it is taken.

B<Attention!> Be careful and after editing C<.md> look at C<git diff> so as not to lose corrected translations in C<.po>.

B<Note:> C<trans -R> will show a list of languages that can be indicated in B<!from:to> on the first line of the document.

The predecessor of C<liveman> is LL<https://github.com/darviarush/miu>.

=head2 TYPES OF TESTS

Section codes without a specified programming language or with C<perl> are written as code in the file C<t/**.t>. And a comment with an arrow (# -> ) turns into a C<Test::More> test.

Supported tests:

=over

=item * C<< -E<gt> >>, C<→> – comparison of scalars;

=item * C<< --E<gt> >>, C<⟶> – comparison of structures;

=item * C<< =E<gt> >>, C<⇒> – comparison with the interpolated string;

=item * C<< \E<gt> >>, C<↦> – comparison with a non-interpolated string;

=item * C<< ^=E<gt> >>, C<⤇> – comparison of the beginning of the scalar with the interpolated string;

=item * C<< $=E<gt> >>, C<➾> – comparison of the end of the scalar with the interpolated string;

=item * C<< *=E<gt> >>, C<⥴> – comparison of the middle of the scalar with the interpolated string;

=item * C<< ^-E<gt> >>, C<↣> – comparison of the beginning of a scalar with a non-interpolated string;

=item * C<< $-E<gt> >>, C<⇥> – comparison of the end of a scalar with a non-interpolated string;

=item * C<< *-E<gt> >>, C<⥵> – comparison of the middle of a scalar with a non-interpolated string;

=item * C<< ~E<gt> >>, C<↬> – matching a scalar with a regular expression (C<$code =~ /.../>);

=item * C<< E<lt>~ >>, C<↫> – negative matching of a scalar with a regular expression (C<$code !~ /.../>);

=item * C<< @-E<gt> >>, C<↯> – comparison of the beginning of the exception with a non-interpolated string;

=item * C<< @=E<gt> >>, C<⤯> – comparison of the beginning of the exception with the interpolated string;

=item * C<< @~E<gt> >>, C<⇝> – matching an exception with a regular expression (C<defined $@ && $@ =~ /.../>);

=item * C<< E<lt>~@ >>, C<⇜> – negative matching of an exception with a regular expression (C<defined $@ && $@ !~ /.../>);

=back

=head3 C<is>

Compare two equivalent expressions:

	"hi!" # -> "hi" . "!"
	"hi!" # → "hi" . "!"

=head3 C<is_deeply>

Compare two expressions for structures:

	["hi!"] # --> ["hi" . "!"]
	"hi!" # ⟶ "hi" . "!"

=head3 C<is> with extrapolate-string

Compare the expression with an extrapolated line:

	my $exclamation = "!";
	"hi!2" # => hi${exclamation}2
	"hi!2" # ⇒ hi${exclamation}2

=head3 C<is> with nonextrapolate-string

Compare the expression with an unexpected line:

	'hi${exclamation}3' # \> hi${exclamation}3
	'hi${exclamation}3' # ↦ hi${exclamation}3

=head3 C<like>

The scalar must be comparable to a regular expression:

	'abbc' # ~> b+
	'abc'  # ↬ b+

=head3 C<unlike>

The scalar must not match the regular expression:

	'ac' # <~ b+
	'ac' # ↫ b+

=head3 C<like> begins with extrapolate-string

The scalar must begin with an extrapolated term:

	my $var = 'b';
	
	'abbc' # ^=> a$var
	'abc'  # ⤇ a$var

=head3 C<like> ends with extrapolate-string

The scalar must end with an extrapolated term:

	my $var = 'c';
	
	'abbc' # $=> b$var
	'abc'  # ➾ b$var

=head3 C<like> inners with extrapolate-string

The scalar must contain the extrapolated term:

	my $var = 'x';
	
	'abxc'  # *=> b$var
	'abxs'  # ⥴ b$var

=head3 C<like> begins with nonextrapolate-string

The scalar must begin with a non-extrapolated term:

	'abbc' # ^-> ab
	'abc'  # ↣ ab

=head3 C<like> ends with nonextrapolate-string

The scalar must end with a non-extrapolated term:

	'abbc' # $-> bc
	'abc'  # ⇥ bc

=head3 C<like> inners with nonextrapolate-string

The scalar must contain a non-extrapolated term:

	'abbc' # *-> bb
	'abc'  # ⥵ b

=head3 C<like> throw begins with nonextrapolate-string

The exception must start with the non-extrapolated term:

	1/0 # @-> Illegal division by zero
	1/0 # ↯ Illegal division by zero

=head3 C<like> throw begins with extrapolate-string

The exception must start with the extrapolated timing:

	my $by = 'by';
	
	1/0 # @=> Illegal division $by zero
	1/0 # ⤯ Illegal division $by zero

=head3 C<like> throw

The exception must be matched to the regular expression:

	1/0 # @~> division\s*by\s*zero
	1/0 # ⇝ division\s*by\s*zero

=head3 C<unlike> throw

The exception doesn't have to be matched by the regular expression (but it should be):

	1/0 # <~@ auto
	1/0 # ⇜ auto

=head2 EMBEDDING FILES

Each test is performed in a temporary catalog, which is removed and created when starting the dough.

The format of this catalog: /tmp/.liveman/I<project>/I<path-to-test>/.

The code section in the line with the MD-file prefix B<< File C<path>: >> is written to the file when testing during execution.

The code section in the md file prefix line B<< File C<path> is: >> will be compared to the file using the C<Test::More::is> method.

experiment/test.txt file:

	hi!

experiment/test.txt file is:

	hi!

B<Attention!> An empty line between the prefix and the code is not allowed!

These prefixes can be both in English and in Russian (C<File [path] (https://metacpan.org/pod/path):> and C<File [path] (https://metacpan.org/pod/path) is:>).

=head1 METHODS

=head2 new (%param)

Constructor. Has arguments:

=over

=item 1. C<Files> (array_ref)-a list of MD files for theC<transforms> and C<tests>.

=item 2. C<open> (boolean) - open the coating in the browser. If the computer is installed on the computer B<Opera>, the C<Opera> command will be used to open. Otherwise-C<xdg-open>.

=item 3. C<force_compile> (boolean)-do not check the time of modification of MD files.

=item 4. C<options> - Add the parameters on the command line for verification or evidence.

=item 5. C<prove> - use the proof (team C<prove> to start tests), and not the C<yath> command.

=back

=head2 test_path ($md_path)

Get the way to C<t/**.t>-file from the way toC<lib/**.md>-file:

	Liveman->new->test_path("lib/PathFix/RestFix.md") # => t/path-fix/rest-fix.t

=head2 transform ($md_path, [$test_path])

Compiles C<lib/**.md>-file inC<t/**.t>-file.

It also replaces the B<pod> documentation in the C<__END__> section in the C<lib/**.pm> file and creates a C<lib/**.pm> file if it exists, otherwise it creates a C<lib/**.pod> file.

When C<transform> was called in C<SYNOPSYS>, a file C<lib/Example.pod> was created.

The lib/Example.pod file is:

	Twice two:
	
		2*2  # -> 2+2
	

Let's create C<lib/Example.pm> and call C<transform>:

	open my $fh, ">", "lib/Example.pm" or die $!;
	print $fh q{package Example;
	
	1;};
	close $fh;
	
	my $liveman = Liveman->new(prove => 1);
	
	$liveman->transform("lib/Example.md");

The lib/Example.pm file is:

	package Example;
	
	1;
	
	__END__
	
	=encoding utf-8
	
	Twice two:
	
		2*2  # -> 2+2
	

=head2 transforms ()

Compile C<lib/**.md> files into C<t/**.t> files.

That's all, if C<< $self-E<gt>{files} >> is not installed, or C<< $self-E<gt>{files} >>.

=head2 tests ()

Launch tests (C<t/**.t>-files).

That's all, if C<< $self-E<gt>{files} >> is not installed, or C<< $self-E<gt>{files} >> only.

=head2 load_po ($md, $from, $to)

Reads the PO-file.

=head2 save_po ()

Saves the PO-file.

=head2 trans ($text, $lineno)

The function translates the text from one language to another using the Trans utility.

=head2 trans_paragraph ($paragraph, $lineno)

It also breaks through paragraphs.

=head1 DEPENDENCIES IN CPANFILE

In your library, which you will test Liveman, you will need to indicate additional dependencies for tests in B<cpanfile>:

	on 'test' => sub {
	    requires 'Test::More', '0.98';
	
	    requires 'Carp';
	    requires 'File::Basename';
	    requires 'File::Path';
	    requires 'File::Slurper';
	    requires 'File::Spec';
	    requires 'Scalar::Util';
	};

It will also be good to indicate and the B<Liveman> in the development section:

	on 'develop' => sub {
	    requires 'Minilla', 'v3.1.19';
	    requires 'Data::Printer', '1.000004';
	    requires 'Liveman', '1.0';
	};

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Liveman Module is Copyright © 2023 Yaroslav O. Kosmina. Rusland. All Rights Reserved.
