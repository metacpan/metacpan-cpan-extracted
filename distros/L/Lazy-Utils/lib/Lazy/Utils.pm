package Lazy::Utils;
=head1 NAME

Lazy::Utils - Utility functions

=head1 VERSION

version 1.17

=head1 SYNOPSIS

	use Lazy::Utils;
	 
	trim($str);
	ltrim($str);
	rtrim($str);
	file_get_contents($path, $prefs);
	file_put_contents($path, $contents, $prefs);
	shellmeta($s, $nonquoted);
	system2($cmd, @argv);
	bash_readline($prompt);
	cmdargs($prefs, @argv);
	whereis($name, $path);
	file_cache($tag, $expiry, $coderef);
	get_pod_text($file_name, $section, $exclude_section);

=head1 DESCRIPTION

Collection of utility functions all of exported by default.

=cut
use strict;
use warnings;
use v5.10.1;
use feature qw(switch);
no if ($] >= 5.018), 'warnings' => 'experimental';
use FindBin;
use JSON;
use Pod::Simple::Text;
use Term::ReadKey;


BEGIN
{
	require Exporter;
	our $VERSION     = '1.17';
	our @ISA         = qw(Exporter);
	our @EXPORT      = qw(trim ltrim rtrim file_get_contents file_put_contents shellmeta system2 _system
		bash_readline bashReadLine cmdargs commandArgs cmdArgs whereis whereisBin file_cache fileCache
		get_pod_text getPodText);
	our @EXPORT_OK   = qw();
}


=head1 Functions

=head2 trim($str)

trims given string

$str: I<string will be trimed>

return value: I<trimed string>

=cut
sub trim
{
	my ($s) = @_;
	$s =~ s/^\s+|\s+$//g;
	return $s
}

=head2 ltrim($str)

trims left given string

$str: I<string will be trimed>

return value: I<trimed string>

=cut
sub ltrim
{
	my ($s) = @_;
	$s =~ s/^\s+//;
	return $s
}

=head2 rtrim($str)

trims right given string

$str: I<string will be trimed>

return value: I<trimed string>

=cut
sub rtrim
{
	my ($s) = @_;
	$s =~ s/\s+$//;
	return $s
}

=head2 file_get_contents($path, $prefs)

gets all contents of file in string type

$path: I<path of file>

$prefs: I<preferences in HashRef, by default undef>

=over

utf8: I<opens file-handle as :utf8 mode, by default 0>

=back

return value: I<file contents in string type, otherwise undef because of errors>

=cut
sub file_get_contents
{
	my ($path, $prefs) = @_;
	$prefs = {} unless ref($prefs) eq 'HASH';
	my $result = do
	{
		local $/ = undef;
		my $mode = "";
		$mode .= " :utf8" if $prefs->{utf8};
		open my $fh, "<$mode", $path or return;
		my $result = <$fh>;
		close $fh;
		$result;
	};
	return $result;
}

=head2 file_put_contents($path, $contents, $prefs)

puts all contents of file in string type

$path: I<path of file>

$contents: I<file contents in string type>

$prefs: I<preferences in HashRef, by default undef>

=over

utf8: I<opens file-handle as :utf8 mode, by default 0>

=back

return value: I<success 1, otherwise undef>

=cut
sub file_put_contents
{
	my ($path, $contents, $prefs) = @_;
	return if not defined($contents) or ref($contents);
	$prefs = {} unless ref($prefs) eq 'HASH';
	my $result = do
	{
		local $\ = undef;
		my $mode = "";
		$mode .= " :utf8" if $prefs->{utf8};
		open my $fh, ">$mode", $path or return;
		my $result = print $fh $contents;
		close $fh;
		$result;
	};
	return $result;
}

=head2 shellmeta($s, $nonquoted)

escapes metacharacters of interpolated shell string

$s: I<interpolated shell string>

$nonquoted: I<also escapes whitespaces and * character for non-quoted interpolated shell string, by default 0>

return value: I<escaped string>

=cut
sub shellmeta
{
	my ($s, $nonquoted) = @_;
	return unless defined $s;
	$s =~ s/(\\|\"|\$)/\\$1/g;
	$s =~ s/(\s|\*)/\\$1/g if $nonquoted;
	return $s;
}

=head2 system2($cmd, @argv)

B<_system($cmd, @argv)> I<OBSOLETE>

alternative implementation of perls core system subroutine that executes a system command

$cmd: I<command>

@argv: I<command line arguments>

return value: I<exit code of command. 511 if fatal error occurs>

returned $?: I<return code of wait call like on perls system call>

returned $!: I<system error message like on perls system call>

=cut
sub system2
{
	my $pid;
	if (not defined($pid = fork))
	{
		return 511;
	}
	if (not $pid)
	{
		no warnings FATAL => 'exec';
		exec(@_);
		exit 511;
	}
	if (waitpid($pid, 0) <= 0)
	{
		return 511;
	}
	return $? >> 8;
}
sub _system
{
	return system2(@_);
}

=head2 bash_readline($prompt)

B<bashReadLine($prompt)> I<OBSOLETE>

reads a line from STDIN using Bash

$prompt: I<prompt, by default ''>

return value: I<line>

=cut
sub bash_readline
{
	my ($prompt) = @_;
	$prompt = "" unless defined($prompt);
	my $in = \*STDIN;
	unless (-t $in)
	{
		my $line = <$in>;
		chomp $line if defined $line;
		return $line;
	}
	local $/ = "\n";
	my $cmd = '/usr/bin/env bash -c "read -p \"'.shellmeta(shellmeta($prompt)).'\" -r -e && echo -n \"\$REPLY\" 2>/dev/null"';
	$_ = `$cmd`;
	return (not $?)? $_: undef;
}
sub bashReadLine
{
	return bash_readline(@_);
}

=head2 cmdargs([$prefs, ]@argv)

B<commandArgs([$prefs, ]@argv)> I<OBSOLETE>

B<cmdArgs([$prefs, ]@argv)> I<OBSOLETE>

resolves command line arguments

valuableArgs is off, eg;

	--opt1 --opt2=val2 cmd param1 param2 param3
	-opt1 -opt2=val2 cmd param1 param2 param3
	-opt1 -opt2=val2 cmd param1 -- param2 param3
	-opt1 cmd param1 -opt2=val2 param2 param3
	-opt1 cmd param1 -opt2=val2 -- param2 param3
	cmd -opt1 param1 -opt2=val2 param2 param3
	cmd -opt1 param1 -opt2=val2 -- param2 param3

valuableArgs is on, eg;

	-opt1 -opt2=val2 cmd param1 param2 param3
	-opt1 -opt2 val2 cmd param1 param2 param3
	-opt1 -opt2 -- cmd param1 param2 param3
	cmd -opt1 -opt2 val2 param1 param2 param3
	cmd -opt1 -opt2 -- param1 param2 param3
	cmd param1 -opt1 -opt2 val2 param2 param3
	cmd param1 -opt1 -opt2 -- param2 param3

$prefs: I<preferences in HashRef, optional>

=over

valuableArgs: I<accepts option value after option if next argument is not an option, by default 0>

noCommand: I<use first parameter instead of command, by default 0>

optionAtAll: I<DEPRECATED: now, it is always on. accepts options after command or first parameter otherwise evaluates as parameter, by default 0>

=back

@argv: I<command line arguments>

return value: eg;

	{ --opt1 => '', --opt2 => 'val2', command => 'cmd', parameters => ['param1', 'param2', 'param3'] }
	{ -opt1 => '', -opt2 => 'val2', command => 'cmd', parameters => ['param1', 'param2', 'param3'] }
	{ -opt1 => '', -opt2 => '', command => 'cmd', parameters => ['param1', 'param2', 'param3'] }

=cut
sub cmdargs
{
	my $prefs = {};
	$prefs = shift if @_ >= 1 and ref($_[0]) eq 'HASH';
	my @argv = @_;
	my %result;
	$result{command} = undef;
	$result{parameters} = undef;

	my @parameters;
	my $opt;
	my $long;
	while (@argv)
	{
		my $argv = shift @argv;
		next unless defined($argv) and not ref($argv);

		if ($long)
		{
			push @parameters, $argv;
			next;
		}

		if (substr($argv, 0, 2) eq '--')
		{
			if (length($argv) == 2)
			{
				$opt = undef;
				$long = 1;
				next;
			}
			my @arg = split('=', $argv, 2);
			$result{$arg[0]} = $arg[1];
			$opt = undef;
			unless (defined($result{$arg[0]}))
			{
				$result{$arg[0]} = "";
				$opt = $arg[0];
			}
			next;
		}

		if (substr($argv, 0, 1) eq '-' and length($argv) != 1)
		{
			my @arg = split('=', $argv, 2);
			$result{$arg[0]} = $arg[1];
			$opt = undef;
			unless (defined($result{$arg[0]}))
			{
				$result{$arg[0]} = "";
				$opt = $arg[0];
			}
			next;
		}

		if ($prefs->{valuableArgs} and $opt)
		{
			$result{$opt} = $argv;
			$opt = undef;
			next;
		}
		$opt = undef;

		push @parameters, $argv;
	}

	$result{command} = shift @parameters if not $prefs->{noCommand};
	$result{parameters} = \@parameters;

	return \%result;
}
sub commandArgs
{
	return cmdargs(@_);
}
sub cmdArgs
{
	return cmdargs(@_);
}

=head2 whereis($name, $path)

B<whereisBin($name, $path)> I<OBSOLETE>

searches valid binary in search path

$name: I<binary name>

$path: I<search path, by default "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin">

return value: I<array of binary path founded in search path>

=cut
sub whereis
{
	my ($name, $path) = @_;
	return () unless $name;
	$path = "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" unless $path;
	return grep(-x $_, map("$_/$name", split(":", $path)));
}
sub whereisBin
{
	return whereis(@_);
}

=head2 file_cache($tag, $expiry, $coderef)

B<fileCache($tag, $expiry, $coderef)> I<OBSOLETE>

gets most recent cached value in file cache by given tag and caller function if there is cached value in expiry period. Otherwise tries to get current value using $coderef, puts value in cache and cleanups old cache values.

$tag: I<tag for cache>

$expiry: I<cache expiry period>

=over

E<lt>0: I<always gets most recent cached value if there is any cached value. Otherwise tries to get current value using $coderef, puts and cleanups.>

=0: I<never gets cached value. Always tries to get current value using $coderef, puts and cleanups.>

E<gt>0: I<gets most recent cached value in cache if there is cached value in expiry period. Otherwise tries to get current value using $coderef, puts and cleanups.>

=back

$coderef: I<code reference to get current value>

return value: I<cached or current value, otherwise undef if there isn't cached value and current value doesn't get>

=cut
sub file_cache
{
	my ($tag, $expiry, $coderef) = @_;
	my $result;
	my $now = time();
	my @cleanup;
	my $caller = (caller(1))[3];
	$caller = (caller(0))[0] unless $caller;
	$caller = (caller(0))[3].",$caller";
	my $tag_encoded = "";
	for (0..(bytes::length($tag)-1))
	{
		my $c = bytes::substr($tag, $_, 1);
		if ($c =~ /\W/)
		{
			$c = uc(sprintf("%%%x", bytes::ord($c)));
		}
		$tag_encoded .= $c;
	}
	my $tmp_base = "/tmp/";
	my $tmp_prefix = $caller;
	$tmp_prefix =~ s/\Q::\E/-/g;
	$tmp_prefix .= ".$tag_encoded,";
	for my $tmp_path (sort {$b cmp $a} glob("${tmp_base}$tmp_prefix*"))
	{
		if (my ($epoch, $pid) = $tmp_path =~ /^\Q${tmp_base}$tmp_prefix\E(\d*)\.(\d*)/)
		{
			if ($expiry < 0 or ($expiry > 0 and $now-$epoch < $expiry))
			{
				if (not defined($result))
				{
					my $tmp;
					$tmp = file_get_contents($tmp_path);
					if ($tmp)
					{
						if ($tmp =~ /^SCALAR\n(.*)/)
						{
							$result = $1;
						} else
						{
							eval { $result = from_json($tmp, {utf8 => 1}) };
						}
					}
				}
				next;
			}
		}
		unshift @cleanup, $tmp_path;
	}
	if (not defined($result))
	{
		$result = $coderef->() if ref($coderef) eq 'CODE';
		if (defined($result))
		{
			my $tmp;
			unless (ref($result))
			{
				$tmp = "SCALAR\n$result";
			} else
			{
				eval { $tmp = to_json($result, {utf8 => 1, pretty => 1}) } if ref($result) eq "ARRAY" or ref($result) eq "HASH";
			}
			if ($tmp and file_put_contents("${tmp_base}tmp.$tmp_prefix$now.$$", $tmp) and rename("${tmp_base}tmp.$tmp_prefix$now.$$", "${tmp_base}$tmp_prefix$now.$$"))
			{
				pop @cleanup;
				for (@cleanup)
				{
					unlink($_);
				}
			}
		}
	}
	return $result;
}
sub fileCache
{
	return file_cache(@_);
}

=head2 get_pod_text($file_name, $section, $exclude_section)

B<getPodText($file_name, $section, $exclude_section)> I<OBSOLETE>

gets a text of pod contents in given file

$file_name: I<file name of searching pod, by default running file>

$section: I<searching head1 section of pod, by default undef gets all of contents>

$exclude_section: I<excludes section name, by default undef>

return value: I<text of pod in string or array by line, otherwise undef if an error occurs>

=cut
sub get_pod_text
{
	my ($file_name, $section, $exclude_section) = @_;
	$file_name = "$FindBin::Bin/$FindBin::Script" unless $file_name;
	return unless -e $file_name;
	my $parser = Pod::Simple::Text->new();
	my $text;
	$parser->output_string(\$text);
	eval { $parser->parse_file($file_name) };
	return if $@;
	utf8::decode($text);
	$section = ltrim($section) if $section;
	my @text = split(/^/m, $text);
	my $result;
	my @result;
	for my $line (@text)
	{
		chomp $line;
		if (defined($section) and not defined($result))
		{
			if ($line eq $section)
			{
				unless ($exclude_section)
				{
					$result = "$line\n";
					push @result, $line;
				} else
				{
					$result = "";
				}
			}
			next;
		}
		last if defined($section) and $line =~ /^\S+/;
		$result = "" unless defined($result);
		$result .= "$line\n";
		push @result, $line;
	}
	return @result if wantarray;
	return $result;
}
sub getPodText
{
	return get_pod_text(@_);
}


1;
__END__
=head1 INSTALLATION

To install this module type the following

	perl Makefile.PL
	make
	make test
	make install

from CPAN

	cpan -i Lazy::Utils

=head1 DEPENDENCIES

This module requires these other modules and libraries:

=over

=item *

JSON

=item *

Pod::Simple::Text

=back

=head1 REPOSITORY

B<GitHub> L<https://github.com/orkunkaraduman/Lazy-Utils>

B<CPAN> L<https://metacpan.org/release/Lazy-Utils>

=head1 AUTHOR

Orkun Karaduman (ORKUN) <orkun@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017  Orkun Karaduman <orkunkaraduman@gmail.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
