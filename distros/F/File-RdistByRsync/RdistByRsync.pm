
package File::RdistByRsync;

use Parse::RecDescent;
use Getopt::Declare;
use File::Find;
use File::Slurp;
require Exporter;

@ISA = Exporter;
@EXPORT = qw(parse_rdist rdist rsync);

our($VERSION);
$VERSION = 0.3;

use strict;

my $rsync_command = 'rsync';
my $rsh_command = 'rsh';

my $debug = 1;

my $parser;
my $vars;
my $distributes,
my $timestamptests;

#
# This module has to deal with a few problems:
#
#	1.  Parsing the rdist distfile  
#
#	2.  Expanding the rdist variables
#	
#	3.  Parsing the rdist command line
#
#	4.  Converting except_pat regular expressions into
#	    globs or lists of files
#
#	5.  Invoking rdist
#
#	6.  Handling post-change commands (rdist 'special')
#


#
# Parse an rdist distfile
# 

sub parse_rdist 
{
	my ($d, %opts) = @_;

	define_parser() unless $parser;

	my $lines = ($d =~ tr/\n/\n/);

	($vars, $distributes) = @{$parser->distfile(\$d)};

	if ($opts{DEFINES}) {
		for my $k (keys %{$opts{DEFINES}}) {
			$vars->{$k} = $opts{DEFINES}{$k};
		}
	}

	my $rem = $d;
	$rem =~ s,[\s\n\r]+,,;
	if ($rem) {
		my $remaining = ($d =~ tr/\n/\n/);
		my $stopped = $lines - $remaining + 2;
		die "Could not parse distfile, stopped at line $stopped\n";
	}

	for my $d (@$distributes) {
		$d->{HOSTS} = [ expand_list(@{$d->{HOSTS}}) ];
		$d->{FILES} = [ expand_list(@{$d->{FILES}}) ];
		$d->{EXCEPT} = [ expand_list(@{$d->{EXCEPT}}) ];
		$d->{RSYNC_OPTION} = [ expand_list(@{$d->{RSYNC_OPTION}}) ];
		for my $s (@{$d->{SPECIAL}}) {
			$s->{FILES} = [ expand_list(@{$s->{FILES}}) ];
			$s->{COMMAND} = expand_val($s->{COMMAND});
		}
		if ($d->{INSTALL}) {
			if (@{$d->{INSTALL}}) {
				for my $i (@{$d->{INSTALL}}) {
					$i->{DESTINATION} = expand_val($i->{DESTINATION});
				}
			} else {
				$d->{INSTALL} = [
					{
						DESTINATION => '',
						FLAGS => {},

					},
				];
			}
		} else {
			$d->{TSFILE} = expand_val($d->{TSFILE});
		}
	}

	if ($opts{TARGETS} && @{$opts{TARGETS}}) {
		my @found_label;
		my @t = @{$opts{TARGETS}};
		my %t;
		@t{@t} = @t;
		for my $i (@$distributes) {
			push(@found_label, $i)
				if $i->{LABEL} && $t{$i->{LABEL}};
		}
		if (@found_label) {
			$distributes = \@found_label;
		} else {
			# now we need to muck through the distributes.. yuck
			for my $d (@$distributes) {
				$d->{FILES} = [ grep $t{$_}, map { glob } @{$d->{FILES}} ];
			}
		}
	}

use Data::Dumper;
#print Dumper($distributes);
	return @$distributes;
}

#
# Variable expansion in a rdist list context.  A variable
# can expand to multiple items
#

sub expand_list
{
	my (@v) = @_;
	my @r;
	for my $val (@v) {
		if ($val =~ m/^\$\{([^{}]+)\}$/ || $val =~ /^\$(\w)$/) {
			if (defined $vars->{$1}) {
				push(@r, expand_list(@{$vars->{$1}}));
			} else {
				warn "no variable $1 defined!"
			}
			next;
		}
		push(@r, expand_val($val));
	}
	return $r[0] unless wantarray;
	return @r;
}


#
# Expand any variables inside a string.  Variable expansion
# can make the string grow, but cannot add elements to
# any surrounding list (if there is one)
#

sub expand_val
{
	my ($val) = @_;
	#
	# \ is an escape character in rdist distfiles.  It can
	# escape $ and itself.   Presumably, other things too.
	# I'm not sure what the right behavior is.
	#
	my $nv = '';
	pos($val) = 0;
	while (pos($val) < length($val)) {
		(($val =~ /\G([^\\\$]*)/gc) || ($val =~ /\G\\(.)/gc))
			&& do { 
				$nv .= $1; 
				next; 
			};
		(($val =~ /\G\$(\w)/) || ($val =~ /\G\$\{(.+?)\}/)) 
			&& do { 
				$nv .= expand_var($1); 
				next; 
			};
		die "illegal variable expansion in $val";
	}
	return $nv;
}

#
# This is used for variables that occur inside strings
# rather than all by themselves in a list.
#

sub expand_var
{
	my ($var) = @_;
	if (defined $vars->{$var}) {
		my $r;
		for my $val (@{$vars->{$var}}) {
			$r .= expand_val($val);
		}
		return $r;
	} else {
		warn "no variable $var defined!";
		if (length($var) eq 1) {
			return "\$$var";
		} else {
			return "\${$var}";
		}
	}
}

my %host;

sub rdist
{
	my (@argv) = @_;

	local(@ARGV) = @argv;

	our(@hosts);
	our(%definitions);
	our(@rsync_options);
	our(@targets);
	our($cflag);

	local(@hosts);
	local(%definitions);
	local(@rsync_options);
	local(@targets);
	local($cflag);

	my $rdist_cmdline_grammar = <<'END';
		
		-f <distfile:if>	Use the specified distfile

		-c <files>... [<user>@]<host>:[<path>]	Interpret the rest of the aguments as a mini distfile
					{ 
						our($cflag);
						$cflag = {
							HOSTS => [ $user 
								? "$user\@$host" 
								: $host ],
							FILES => [ @files ],
							INSTALL => [
								{
									DESTINATION => $path,
									FLAGS => {},
								},
							],
						};
					}

		-P <rshcmd>		Use rshcmd instead of rsh for remote access

		-d <var>=<value>	Set the variable to the value
					[repeatable]
					{
						our(%definitions);
						$definitions{$var} = $value;
					}

		-h			Follow symbolic links

		-i			Ignore unresolved links

		-m <host>		Limit which meachines are updated
					[repeatable]
					{
						our(@hosts);
						push(@hosts, $host);
					}
		
		-n			Print the commands w/o executing them

		-q			Quite mode.

		-R			Remove extraneous files.

		-v			Verify only

		-w			Whole mode.  The file name is appended to the dest.

		-y			Younger mode.  Only update older files.

		-D			Debug mode

		-r <rsync_option>	Pass option through to rsync command line
					[repeatable]
					{
						our(@rsync_options);
						push(@rsync_options, 
							$rsync_option);
					}

		--<rsync_option>	Pass long option through to rsync command line
					[repeatable]
					{
						our(@rsync_options);
						push(@rsync_options, 
							"--$rsync_option");
					}

		<names>...		Labels or files to update
					{
						
						our(@targets);
						push(@targets, @names);
					}

END

	my $args = new Getopt::Declare($rdist_cmdline_grammar);
#Dumper(\$args);
	die "argparse probelm" unless $args;

	$debug = $args->{'-D'};

	my $distfile;

	if ($args->{'-c'}) {
		return ($args, $cflag);
	} elsif ($args->{'-f'} eq '-') {
		$distfile = join('', <STDIN>);
	} elsif ($args->{'-f'}) {
		$distfile = read_file($args->{'-f'});
	} elsif (-e 'distfile') {
		$distfile = read_file('distfile');
	} elsif (-e 'Distfile') {
		$distfile = read_file('Distfile');
	} else {
		die "no distfile found or specified";
	}

	my @distributes = parse_rdist($distfile, 'DEFINES' => \%definitions,
		'TARGETS' => \@targets);

	return ($args, {
			HOSTS	=> \@hosts,
			DEFINES	=> \%definitions,
			RSYNCOPT=> \@rsync_options,
			TARGETS	=> \@targets,
			CFLAG	=> $cflag,
		}, @distributes);
}

sub rsync
{
	my (@argv) = @_;

	my ($args, $extras, @distributes) = rdist(@argv);

	expand_globs(@distributes);

	convert_pats_to_globs(@distributes);

	my @hosts = @{$extras->{HOSTS}};
	my %hosts;
	@hosts{@hosts} = @hosts;

	for my $d (@distributes) {
		next unless @{$d->{FILES}};
#print Dumper($d);
#print "OKF=@{$d->{FILES}}\n";
		for my $h (@{$d->{HOSTS}}) {
			next if @hosts && ! $hosts{$h};
			for my $i (@{$d->{INSTALL}}) {
				if ($i->{DESTINATION} && $i->{DESTINATION} !~ /:$/) {
					do_rsync($args, $d, $h, $i, $i->{DESTINATION}, undef, $extras);
				} else {
					do_rsync($args, $d, $h, $i, "$i->{DESTINATION}/", qr|^/|, $extras);
					do_rsync($args, $d, $h, $i, "$i->{DESTINATION}", qr|^[^/]|, $extras);
				}
			}
		}
	}

use Data::Dumper;
#print Dumper($vars);
#print Dumper(@distributes);
}

sub do_rsync
{
	my ($args, $d, $host, $i, $dest, $filefilter, $extras) = @_;

	my @ra;
	my @unlink;

	return unless @{$d->{FILES}};
#print "OF=@{$d->{FILES}}\n";

	my (@files) = $filefilter
		? grep(/$filefilter/, @{$d->{FILES}})
		: @{$d->{FILES}};
#print "FILES=@files\n";
	
	return unless @files;

	if ($d->{EXCEPT}) {
		my $tmpfile = get_tmpfile();

		my @e;

		my @excepts = @{$d->{NEW_EXCEPT}};
		while (my($type, $p) = splice(@excepts, 0, 2)) {
			if ($type eq 'EXCEPT') {
				push(@e,"- $p");
			} elsif ($type eq 'EXCEPT_GLOB') {
				push(@e,"- $p");
			} elsif ($type eq 'RSYNC_INCLUDE') {
				push(@e,"+ $p");
			} elsif ($type eq 'RSYNC_EXCLUDE') {
				push(@e,"- $p");
			} else {
				die "unknown except type: '$type' (with '$p')";
			}
		}
		if (@e > 200) {
			write_file($tmpfile, join("\n", @e) . "\n");
			push(@ra, "--exclude-from=$tmpfile");
			push(@unlink, $tmpfile);
		} else {
			for my $e (@e) {
				push(@ra, "--exclude=$e");
			}
		}
	}

	my @notify = @{$d->{NOTIFY}};
	my @special = @{$d->{SPECIAL}};

	push(@ra, "--perms");
	push(@ra, "--owner");
	push(@ra, "--group");
	push(@ra, "--devices");
	push(@ra, "--times");

	if ($args->{'-R'} || $i->{FLAGS}{R}) {
		push(@ra, "--delete");
		push(@ra, "--delete-after");
	}

	# push(@ra, "--force");
	push(@ra, "--hard-links");  # slow, but the alternative is bad
	push(@ra, "--recursive");

	if ($args->{'-w'} || $i->{FLAGS}{w} || $dest eq '/' || $dest eq '') {
		if (@files == 1 && $files[0] !~ /[\]\[\*\?\{\}]/) {
			$dest .= "/" unless $dest =~ m,/$,;
			my $f = $files[0];
			$f =~ s,^/,,;
			$dest .= $f;
		} else {
			push(@ra, "--relative");
		}
	}

	if ($args->{'-v'}) {
		push(@ra, "--dry-run");
		push(@ra, "--verbose")
			unless $args->{'-q'};
	}

	if ($args->{'-P'}) {
		push(@ra, "--rsh=$args->{-P}");
	}

	if ($args->{'-h'} || $i->{FLAGS}{h}) {
		push(@ra, "--copy-links");
	} else {
		push(@ra, "--links");
	}

	if ($args->{'-y'} || $i->{FLAGS}{y}) {
		push(@ra, "--update");
	}

	if ($args->{'-q'} && ! @notify && ! @special) {
		push(@ra, "--quiet");
	} else {
		push(@ra, "--verbose");
	}

	push(@ra, @{$d->{RSYNC_OPTION}});

	push(@ra, @{$extras->{RSYNCOPT}});

	push(@ra, @files);

	if ($dest =~ /:/) {
		push(@ra, $dest);
	} else {
		push(@ra, "$host:$dest");
	}

	my $output = get_tmpfile();
	push(@unlink, $output);

	if ($args->{'-n'}) {
		print "+ $rsync_command @ra\n";
	} elsif (@notify || @special) {
		for my $ra (@ra) {
			$ra =~ s/'/'"'"'/g;
			$ra = "'$ra'" unless $ra =~ /^\w+$/;
		}
		my $tee = "| tee $output";

		$tee = "> $output" 
			if $args->{'-q'};

		system("set -x; ($rsync_command @ra 2>&1) | tee $output");

		my %special;
		for my $s (@special) {
			for my $f (@{$s->{FILES}}) {
				$special{$f} = []
					unless $special{$f};
				push(@{$special{$f}}, $s->{COMMAND});
			}
		}

		my $o = read_file($output);
		for(;;) {
			$o =~ /\G(.*)[\n\r]*/gcm || last;
			my $line = $1;
			if ($line =~ /^\S+$/) {
				next unless $special{$line};
				for my $c (@{$special{$line}}) {
					my $rsh = $args->{'-P'} || $rsh_command;

					#
					# Proper quoting through three layers of shell
					# is a right proper pain. 
					#

					my $cc = $c;
					my $ccsr = q{'"'"'"'"'"'"'"'"'};
					my %lr = (
						"'" => $ccsr,
						'"' => q{"'"'"},
					);
					$cc =~ s/'/$ccsr/g;
					$line =~ s/(['"])/$lr{$1}/g;
					my $x = '';
					$x = '-x' if $debug;
					my $cmd = qq{$rsh $host 'sh -a $x -c '"'"'FILE="$line"; $cc'"'"};
					print "+ $cmd\n"
						if $debug;
					next if $args->{'-v'};
					system($cmd);
				}
			}
		}
	} else {
		print "+ $rsync_command @ra\n";
		system($rsync_command, @ra);
	}

	for my $u (@unlink) {
		unlink($u)
			unless $debug;
	}
}

my $tfcount;
sub get_tmpfile
{
	$tfcount++;
	return "$ENV{HOME}/#rdist2rsync.$$.$tfcount";
}

#
# 'except_pat' doesn't translate to rdist very well because except_pat
# is specified with regular expressions but rsync uses globbing for
# excludes.
#
sub convert_pats_to_globs
{
	my (@distribute) = @_;
	for my $d (@distribute) {
		my @new;
		my @excepts = @{$d->{EXCEPT}};
		my $has_regex;
		my @re;
		while (my($type, $p) = splice(@excepts, 0, 2)) {
			if ($type ne 'EXCEPT_PAT') {
				push(@new, $type, $p);
				next;
			} 

			my $glob_okay = 1;
			my $glob = '';
			my $plevel = 0;
			my $last_okay = 1;
			my $lp;
			
			pos($p) = 0;
			if ($p =~ /\G\^/gc) {
				# beginning is anchored
			} elsif ($p =~ /\G\//gc) {
				# beginning may be a fullpath
				$glob = '/';
			} else {
				$glob = '*';
			}
			while (pos($p) < length($p)) {
				$p =~ /\G\\(.)/gc && do {
						$glob .= '?';
						next;
					};
				$p =~ /\G\.\*/gc && do {
						$glob .= '*';
						next;
					};
				$p =~ /\G\.\+/gc && do {
						$glob .= '?*';
						next;
					};
				$p =~ /\G\./gc && do {
						$glob .= '?';
						next;
					};
				$p =~ /\G\((?!\?)/gc && do {
						$plevel++;
						$glob .= '{'; # }
						next;
					};
				$p =~ /\G\(\?/gc && do {
						warn "regex not standard (see re_format(7)): $p";
						$glob_okay = 0;
						next;
					};
				$p =~ /\G\)/gc && do {
						if ($plevel) {
							$plevel--;
							# {
							$glob .= "}";
						} else {
							warn "unbalanced parens in regex: $p";
							$glob .= ')';
						}
						next;
					};
				$p =~ /\G\|/gc && do {
						$glob .= ',' if $plevel;
						next;
					};
				$p =~ /\G,/gc && do {
						$glob .= "[,]" if $plevel;
						next;
					};
				$p =~ /\G[+*?]/gc && do {
						$glob_okay = 0;
						next;
					};
				$p =~ /\G(?<=.)\^/gc && do {
						$glob_okay = 0;
						next;
					};
				$p =~ /\G\$(?=.)/gc && do {
						$glob_okay = 0;
						next;
					};
				$p =~ /\G\$\z/gc && do {
						last;
					};
				$p =~ /\G\{\d+(?:,\d+)?\}/gc && do {
						$glob_okay = 0;
						next;
					};
				$p =~ /\G\{/gc && do {
						# }
						$glob .= "[{]"; # }
						next;
					};
				$p =~ /\G(\[\^.+?\])/gc && do {

						$glob .= $1;
						next;
					};
				$p =~ /\G(\[(.+?)\])/gc && do {
						$glob .= $1;
						next;
					};
				$p =~ /\G([^]\$\\*+?{}().]+)/gc && do {
						$glob .= $1;
						next;
					};
				my $before = substr($p, 0, pos($p));
				my $after = substr($p, pos($p), length($p)-pos($p));
				die "could not parse regex: '$before<PROBLEM HERE>$after'";
			} continue {
				if ($last_okay != $glob_okay) {
					my $before = substr($p, 0, $lp);
					my $during = substr($p, $lp, pos($p)-$lp);
					my $after = substr($p, pos($p), length($p)-pos($p));
					print STDERR "TRANSITION TO NOT-OKAY: '$before<OKAY>$during<NOT_OKAY>$after\n"
						if $debug;
					$last_okay = $glob_okay;
				} 
				$lp = pos($p);
			}
					
			if ($glob_okay) {
				if ($p =~ /\$\z/) {
					# ending is anchored
				} else {
					$glob .= '*';
				}
				$glob =~ s/\*\*+/*/g;
				push(@new, 'EXCEPT_GLOB', $glob);
			} else {
				push(@new, 'EXCEPT_REGEX', $p);
				push(@re, qr/$p/);
				$has_regex = 1;
			}
		}

		my (@matches) = ([]) x scalar(@re);

		my $matchfunc = sub {
			for (my $i = 0; $i < @re; $i++) { 
				next unless $File::Find::name =~ /$re[$i]/;
				push(@{$matches[$i]}, $File::Find::name);
			}
			# it would be nice to short-circuit the find if we
			# can, but that's a bit of work.  I'll leave that
			# as an exercise for the reader...
		};

		if (@re) {
			find($matchfunc, @{$d->{FILES}});
			my @nn;
			while (my($type, $p) = splice(@new, 0, 2)) {
				if ($type eq 'EXCEPT_REGEX') {
					my $match = shift(@matches);
					for my $erf (@$match) {
						push(@nn, 'EXCEPT', $erf);
						print "replacing except_pat '$p' with '$erf'\n"
							if $debug;
					}
				} else {
					push(@nn, $type, $p);
				}
			}
			@new = @nn;
		}

		$d->{NEW_EXCEPT} = \@new;
	}
}

#
# We need to expand all the FILES lists that may include
# globs into actual lists of files. 
#
sub expand_globs
{
	my (@distribute) = @_;

	for my $d (@distribute) {
		$d->{FILES} = [ map { glob } @{$d->{FILES}} ];
		for my $s (@{$d->{SPECIAL}}) {
			$s->{FILES} = [ map { glob } @{$s->{FILES}} ];
		}
	}
}

sub define_parser
{
	$::RD_HINT = 1
		if $debug;

	my $grammar = <<'END';

		{
			# startup actions...
			my %vars;
			my @distributes;
		}

		distfile: component(s)
			{ [\%vars, \@distributes ] }

		component: definition | distribution | timestamptest | comment

		comment: /#[^\n]*/
			{ '' }

		definition: identifier '=' <commit> name_list 
			{ 
				$vars{$item{identifier}} = $item{name_list};
				0;
			}

		variable: '${' identifier '}'
			{ join('', @item[1..$#item]) }

		identifier: /[a-z]\w*/i

		name_list: name 
				{ [ $item{name} ] }
		name_list: '(' <commit> name(s?) ')' 
				{ $item{name} }

		name: comment
			| variable 
			| hostname 
			| filename 
			| email

		email: user '@' hostname
			{ $item{user} . '@' . $item{hostname}; }

		filename: m{[^;()\s]+}

		hostname: m{[a-z](?:[\.\w]*\w)?}

		user: m{[\w.]+}

		timestamptest: label(?) source_list '::' <commit> time_stamp_file command_list
			{
				my @l = @{$item{label}};
				push(@distributes, {
					LABEL => $l[0],
					FILES => $item{source_list},
					TSFILE => $item{time_stamp_file},
					%{$item{command_list}},
				});
			}

		distribution: label(?) source_list '->' destination_list command_list
			{
				my @l = @{$item{label}};
				push(@distributes, {
					LABEL => $l[0],
					FILES => $item{source_list},
					HOSTS => $item{destination_list},
					%{$item{command_list}},
				});
			}

		label: identifier ':'
			{ $item{identifier} }

		source_list: source 
				{ [ $item{source} ] }
		source_list: '(' <commit> source(s?) ')'
				{ $item{source} }

		source: comment 
			| variable 
			| filename 

		destination_list: destination 
				{ [ $item{destination} ] }
		destination_list: '(' <commit> destination(s?) ')' 
				{ $item{destination} }

		destination: comment 
			| variable 
			| hostname 

		command_list: command(s?)
			{
				$return = {
					INSTALL => [],
					NOTIFY => [],
					EXCEPT => [],
					SPECIAL => [],
					RSYNC_OPTION => [],
				};
				for my $c (@{$item{command}}) {
					next unless $c;
					my $cmd = shift @$c;
					if ($cmd eq 'INSTALL') {
						my $dest = pop(@$c);
						my %flags;
						for my $os (@$c) {
							for my $of (split('', $os)) {
								$flags{$of} = 1;
							}
						}
						push(@{$return->{$cmd}}, {
							DESTINATION => $dest,
							FLAGS => \%flags,
						});
					} elsif ($cmd eq 'SPECIAL') {
						my $command = pop(@$c);
						push(@{$return->{$cmd}}, {
							COMMAND => $command,
							FILES => $c,
						});
					} elsif ($cmd eq 'EXCEPT' 
						|| $cmd eq 'EXCEPT_PAT'
						|| $cmd eq 'RSYNC_INCLUDE'
						|| $cmd eq 'RSYNC_EXCLUDE') 
					{
						for my $arg (@$c) {
							push(@{$return->{EXCEPT}}, $cmd, $arg);
						}
					} elsif ($cmd eq 'NOTIFY') {
						push(@{$return->{$cmd}}, @$c);
					} elsif ($cmd eq 'RSYNC_OPTION') {
						push(@{$return->{$cmd}}, @$c);
					} else {
						die;
					}
				}
			}

		command: comment
				{ 0 }
		command: 'notify' <commit> name_list ';'
				{ [ 'NOTIFY', @{$item{name_list}} ] }
		command: /except(?!_)/ <commit> name_list ';'
				{ [ 'EXCEPT', @{$item{name_list}} ] }
		command: 'except_pat' <commit> pattern_list ';'
				{ [ 'EXCEPT_PAT', @{$item{pattern_list}} ] }
		command: 'special' <commit> name_list string ';'
				{ [ 'SPECIAL', @{$item{name_list}}, $item{string} ] }
		command: 'install' <commit> option(s?) opt_dest_name(?) ';'
				{ [ 'INSTALL', @{$item{option}}, join('',@{$item{opt_dest_name}}) ] }
		command: 'rsync_include' <commit> pattern_list ';'
				{ [ 'RSYNC_INCLUDE', @{$item{pattern_list}} ] }
		command: 'rsync_exclude' <commit> pattern_list ';'
				{ [ 'RSYNC_EXCLUDE', @{$item{pattern_list}} ] }
		command: 'rsync_option' <commit> rsync_option_list ';'
				{ [ 'RSYNC_OPTION', @{$item{pattern_list}} ] }

		option: '-' <commit> option_flags

		option_flags: m{[Rhivwyb]+}

		opt_dest_name: filename
			| hostname ':' <commit> filename
			| user '@' <commit> hostname ':' filename

		rsync_option_list: rsync_option
				{ [ $item{rsync_option} ] }
		rsync_option_list: '(' rsync_option(s) ')'
				{ $item{rsync_option} }

		rsync_option: string

		rsync_option: /[^;"()]/

		pattern_list: pattern 
				{ [ $item{pattern} ] }
		pattern_list: '(' pattern(s) ')'
				{ $item{pattern} }

		pattern: comment 
			| filename 
			| variable 

		string: '"' <skip: ''> string_middle <skip: ''> '"'
			{ $item{string_middle} }

		string_middle: /(\\.|[^\\"])*/s

		time_stamp_file: m{\S+}
END
	
	if ($debug) {
		$parser = Precompile Parse::RecDescent ($grammar, 'ParseRdistParser');
		require ParseRdistParser;
		$parser = ParseRdistParser->new();
	} else {
		$parser = new Parse::RecDescent $grammar
	}
}

1;
