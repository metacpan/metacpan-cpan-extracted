package Liveman::Cpanfile;

use common::sense;

use File::Find::Wanted qw/find_wanted/;
use File::Slurper qw/read_text write_text/;

# Конструктор
sub new {
	my $cls = shift;
	bless {@_}, ref $cls || $cls
}

# Пакет из пути
sub pkg_from_path(;$) {
	my ($pkg) = @_? @_: $_;
	my @pkg = File::Spec->splitdir($pkg);
	shift @pkg if $pkg[0] eq "lib"; # Удаляем lib/
	$pkg[$#pkg] =~ s!\.\w+$!!; # Удаляем расширение
	join "::", @pkg
}

# Список файлов scripts/* и bin/*
sub sc {
	my ($self) = @_;
	@{$self->{sc} //= [sort(find_wanted(sub { -f $_ and -x _ }, "scripts", "bin"))]}
}

# Список файлов lib/*.pm
sub pm {
	my ($self) = @_;
	@{$self->{pm} //= [sort(find_wanted(sub { /\.pm$/ and -f $_ }, "lib"))]}
}

# Список пакетов проекта
sub mod {
	my ($self) = @_;
	@{$self->{mod} //= [map pkg_from_path, $self->pm]}
}

# Список *.md файлов
sub md {
	my ($self) = @_;
	@{$self->{md} //= [sort(find_wanted(sub { /\.md$/ and -f $_ }, "lib"))]}
}

# Список внедрённых в *.md пакетов
sub md_mod {
	my ($self) = @_;
	@{$self->{md_mod} //= [do {
		my %mod;
		for my $md ($self->md) {
			open my $f, '<', $md or die "Can't open $md: $!";
			while(<$f>) {
				if(/^```perl\s*$/ ... /^```$/) {
					$mod{$1}++ while /\bpackage\s+([a-zA-Z_]\w*(?:::[a-zA-Z_]\w*)*)/g;
				}
			}
			close $f;
		}
		sort keys %mod
	}]}
}

# Список пакетов, используемых в скриптах и модулях
sub _used_mod {
	my ($s) = @_;
	my @mod;
	
	push @mod, pkg_from_path $1 while $s =~ /\brequire\s*['"]([\w\/\.]+)['"]/g;
	push @mod, $1 while $s =~ /\b(?:use|require)\s+([a-zA-Z_]\w*(?:::[a-zA-Z_]\w*)*)/g;
	
	@mod
}

# Список зависимостей явно указанных в скриптах и модулях (- mod)
sub deps {
	my ($self) = @_;
	@{$self->{deps} //= [do {
		my %mod;
		for my $pl ($self->pm, $self->sc) {
			open my $f, '<', $pl or die "Can't open $pl: $!";
			while(<$f>) {
				next if /^\s*#/;
				last if /^(__END__|__DATA__)\s*$/;
			
				$mod{$_}++ for _used_mod($_);
			}
			close $f;
		}

		delete @mod{$self->mod};
		sort keys %mod
	}]}
}

# Список зависимостей из тестов (- mod - deps - md_mod)
sub t_deps {
	my ($self) = @_;
	@{$self->{t_deps} //= [do {
		my %mod;

		require Liveman;
		$mod{$_}++ for _used_mod($Liveman::TEST_HEAD);
	
		for my $md ($self->md) {
			open my $f, '<', $md or die "Can't open $md: $!";
			while(<$f>) {
				if(/^```perl\s*$/ ... /^```$/) {
					$mod{$_}++ for _used_mod($_);
				}
			}
			close $f;
		}

		delete @mod{$self->mod};
		delete @mod{$self->md_mod};
		delete @mod{$self->deps};
		sort keys %mod
	}]}
}

# Возвращает примерный cpanfile
sub cpanfile {
	my ($self) = @_;

	my $requires = join "\n", map "requires '$_';", $self->deps;
	my $t_requires = join "", map "\trequires '$_';\n", $self->t_deps;

	<< "END";
requires 'perl', '5.22.0';

on 'develop' => sub {
	requires 'App::cpm';
	requires 'CPAN::Uploader';
	requires 'Data::Printer', '1.000004';
	requires 'Minilla', 'v3.1.19';
	requires 'Liveman', '1.0';
	requires 'Software::License::GPL_3';
	requires 'V';
	requires 'Version::Next';
};

on 'test' => sub {\n$t_requires};

$requires
END
}

1;

__END__

=encoding utf-8

=head1 NAME

Liveman::Cpanfile - Perl project dependency analyzer

=head1 SYNOPSIS

	use Liveman::Cpanfile;
	
	chmod 0755, $_ for qw!scripts/test_script bin/tool!;
	
	$::cpanfile = Liveman::Cpanfile->new;
	
	$::cpanfile->cpanfile # -> << 'END'
	requires 'perl', '5.22.0';
	
	on 'develop' => sub {
		requires 'App::cpm';
		requires 'CPAN::Uploader';
		requires 'Data::Printer', '1.000004';
		requires 'Minilla', 'v3.1.19';
		requires 'Liveman', '1.0';
		requires 'Software::License::GPL_3';
		requires 'V';
		requires 'Version::Next';
	};
	
	on 'test' => sub {
		requires 'Car::Auto';
		requires 'Carp';
		requires 'Cwd';
		requires 'File::Basename';
		requires 'File::Find';
		requires 'File::Path';
		requires 'File::Slurper';
		requires 'File::Spec';
		requires 'Scalar::Util';
		requires 'Test::More';
		requires 'Turbin';
		requires 'open';
	};
	
	requires 'Data::Printer';
	requires 'List::Util';
	requires 'common::sense';
	requires 'strict';
	requires 'warnings';
	END

=head1 DESCRIPTION

C<Liveman::Cpanfile> parses the structure of a Perl project and extracts dependency information from source code, tests, and documentation. The module automatically detects which modules are used and helps keep the C<cpanfile> up to date.

=head1 SUBROUTINES

=head2 new ()

Constructor.

=head2 pkg_from_path ()

Converts a file path to a Perl package name.

	Liveman::Cpanfile::pkg_from_path('lib/My/Module.pm') # => My::Module
	Liveman::Cpanfile::pkg_from_path('lib/My/App.pm')    # => My::App

=head2 sc ()

Returns a list of executable scripts in the C<scripts/> and C<bin/> directories.

Scripts/test_script file:

	#!/usr/bin/env perl
	require Data::Printer;

bin/tool file:

	#!/usr/bin/env perl
	use List::Util;



	[$::cpanfile->sc] # --> [qw!bin/tool scripts/test_script!]

=head2 pm ()

Returns a list of Perl modules in the C<lib/> directory.

File lib/My/Module.pm:

	package My::Module;
	use strict;
	use warnings;
	1;

File lib/My/Other.pm:

	package My::Other;
	use common::sense;
	1;



	[$::cpanfile->pm]  # --> [qw!lib/My/Module.pm lib/My/Other.pm!]

=head2 mod ()

Returns a list of project package names corresponding to the modules in the C<lib/> directory.

	[$::cpanfile->mod]  # --> [qw/My::Module My::Other/]

=head2 md ()

Returns a list of Markdown documentation files (C<*.md>) in C<lib/>.

File lib/My/Module.md:

	# My::Module
	
	This is a module for experiment with package My::Module.
	\```perl
	package My {}
	package My::Third {}
	use My::Other;
	use My;
	use Turbin;
	use Car::Auto;
	\```



	[$::cpanfile->md]  # --> [qw!lib/My/Module.md!]

=head2 md_mod ()

List of packages embedded in C<*.md>.

	[$::cpanfile->md_mod]  # --> [qw!My My::Third!]

=head2 deps ()

List of dependencies explicitly specified in scripts and modules without project packages.

	[$::cpanfile->deps]  # --> [qw!Data::Printer List::Util common::sense strict warnings!]

=head2 t_deps ()

List of dependencies from tests except:

=over

=item 1. Dependencies of scripts and modules.

=item 2. Project packages.

=item 3. Packages embedded in C<*.md>.

=back

	[$::cpanfile->t_deps]  # --> [qw!Car::Auto Carp Cwd File::Basename File::Find File::Path File::Slurper File::Spec Scalar::Util Test::More Turbin open!]

=head2 cpanfile ()

Returns the text cpanfile with dependencies for the project.

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Liveman::Cpanfile module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.
