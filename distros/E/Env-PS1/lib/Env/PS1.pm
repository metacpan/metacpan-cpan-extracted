package Env::PS1;

use strict;
use Carp;
use AutoLoader 'AUTOLOAD';

our $VERSION = 0.06;

our $_getpwuid = eval { getpwuid($>) }; # Not supported on some platforms

sub import {
	my $class = shift;
	return unless @_;
	my ($caller) = caller;
	for (@_) {
		/^\$(.+)/ or croak qq/$class can't export "$_", try "\$$_"/;
		no strict 'refs';
		tie ${"$caller\::$1"}, $class, $1;
	}
}

sub TIESCALAR {
	my ($class, $var) = @_;
	my $self = bless {
		var    => $var || 'PS1',
		format => '',
	}, $class;
	$self->cache();
	return $self;
}

sub STORE {
	my $self = shift;
	if (ref $$self{var}) { ${$$self{var}} = shift }
	else { $ENV{$$self{var}} = shift }
}

sub FETCH {
	my $self = shift;
	my $format = ref($$self{var}) ? ${$$self{var}} : $ENV{$$self{var}} ;
	$format =~ s#(\\\\)|(?<!\\)\$(?:(\w+)|\{(.*?)\})#
		$1 ? '\\\\' : $2 ? $ENV{$2} : $ENV{$3}
	#ge;
        unless ($format eq $$self{format} and exists $ENV{CLICOLOR}
                and $ENV{CLICOLOR} eq $$self{clicolor}) {
		@$self{qw/format clicolor/} = ($format, $ENV{CLICOLOR});
		$$self{cache} = [ $self->cache($format) ];
	}
	my $string = join '', map { ref($_) ? $_->() : $_ } @{$$self{cache}};
        $string =~ s#\$\((.+)\)#
          `$1`;
        #ge;
	return $string;
}

sub sprintf {
	my $format = pop;
	$format =~ s#(\\\\)|(?<!\\)\$(?:(\w+)|\{(.*?)\})#
		$1 ? '\\\\' : $2 ? $ENV{$2} : $ENV{$3}
	#ge;
	return join '', map { ref($_) ? $_->() : $_ } Env::PS1->cache($format);
}

our @user_info; # ($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$dir,$shell,$expire)
our %map; # for custom stuff
our %alias = (
	'$' => 'dollar',
	'@' => 'D', t => 'D', T => 'D', A => 'D',
);

sub cache {
	my ($self, $format) = @_;
	return '' unless defined $format; # get rid of uninitialised warnings
	@user_info = getpwuid($>) if $_getpwuid;
	my @parts;
	#print "# string: $format\n";
	while ($format =~ s/^(.*?)(\\\\|\\([aenr]|0\d\d)|\\(.)|!)//s) {
		push @parts, $1 || '';
		if ($2 eq '\\\\') { push @parts, '\\' } # stripped when \! is substitued
		elsif ($2 eq '!') { push @parts, '!!' } # posix prompt escape :$
		elsif ($3) { push @parts, eval qq/"\\$3"/ }
		elsif (exists $map{$4}) {
			my $item = $map{$4};
			if (ref $item and $format =~ s/^\{(.*?)\}//) {
				push @parts, $item->($1); # obscure foo
			}
			else { push @parts, $item }
	       	}
		elsif (grep {$4 eq $_} qw/C D P/) { # special cases
			my $sub = $4 ;
			$format =~ s/^\{(.*?)\}//;
			push @parts, $self->$sub($sub, $1);
		}
		elsif ($4 eq '[' or $4 eq ']') { next }
		else {
			my $sub = exists($alias{$4}) ? $alias{$4} : uc($4) ;
			push @parts, $self->can($sub) ? ($self->$sub($4)) : $4;
		}
	}
	push @parts, $format;
	my @cache = ('');
	for (@parts) { # optimise: join strings, push code refs
		if (ref $_ or ref $cache[-1]) { push @cache, $_ }
		else { $cache[-1] .= $_ }
	}
	return @cache;
}

## format subs

sub U { $user_info[0] || $ENV{USER} || $ENV{LOGNAME} }

sub W { 
	return sub { $ENV{PWD} eq $ENV{HOME} ? "~" : $ENV{PWD} } if $_[1] eq 'w';
	return sub {
		return '/' if $ENV{PWD} eq '/';
                if($ENV{PWD} eq $ENV{HOME}) {
                  return "~";
                }
		$ENV{PWD} =~ m#([^/]*)/?$#;
		return $1;
	};
}

## others defined below for Autoload

1;

__END__

=head1 NAME

Env::PS1 - prompt string formatter

=head1 SYNOPSIS

	# use the import function
	use Env::PS1 qw/$PS1/;
	$ENV{PS1} = '\u@\h \$ ';
	print $PS1;
	$readline = <STDIN>;

	# or tie it yourself
	tie $prompt, 'Env::PS1', 'PS1';

	# you can also tie a scalar ref
	$format = '\u@\h\$ ';
	tie $prompt, 'Env::PS1', \$format;

=head1 DESCRIPTION

This package supplies variables that are "tied" to environment variables like
'PS1' and 'PS2', if read it takes the contents of the variable as a format string
like the ones B<bash(1)> uses to format the prompt.

It is intended to be used in combination with the various ReadLine packages.

=head1 EXPORT

You can request for arbitrary variables to be exported, they will be
tied to the environment variables of the same name.

=head1 TIE

When you C<tie> a variable you can supply one argument which can either be
the name of an environement variable or a SCALAR reference. This argument
defaults to 'PS1'.

=head1 METHODS

=over 4

=item C<sprintf($format)>

Returns the formatted string.

Using this method all the time is a lot B<less> efficient then
using the tied variable, because the tied variable caches parts
of the format that remain the same anyway.

=back

=head1 FORMAT

The format is copied mostly from bash(1) because that's what it is supposed
to be compatible with. We made some private extensions which obviously are
not portable.

Note that this is not the prompt format as specified by the posix specification,
that would only know "!" for the history number and "!!" for a literal "!".

Apart from the escape sequences you can also use environment variables in
the format string; use C<$VAR> or C<${VAR}>.

The following escape sequences are recognized:

=over 4

=item \a

The bell character, identical to "\007"

=item \d

The date in "Weekday Month Date" format

=item \D{format}

The date in strftime(3) format, uses L<POSIX>

=cut

sub D  {
	return sub {
		my $t = localtime;
		$t =~ m/^(\w+\s+\w+\s+\d+)/;
		return $1;
	} if $_[1] eq 'd';

	use POSIX qw(strftime);
	my $format =
		($_[1] eq 't') ? '%H:%M:%S' :
		($_[1] eq 'T') ? '%I:%M:%S' :
		($_[1] eq '@') ? '%I:%M %p' :
		($_[1] eq 'A') ? '%H:%M'    : $_[2] ;

	return sub { strftime $format, localtime };
}

=item \e

The escape character, identical to "\033"

=item \n

Newline

=item \r

Carriage return

=item \s

The basename of $0

=cut

sub S {
	$0 =~ m#([^/]*)$#;
	return $1 || '';
}

=pod

=item \t

The current time in 24-hour format, identical to "\D{%H:%M:%S}"

=item \T

The current time in 12-hour format, identical to "\D{%I:%M:%S}"

=item \@

The current time in 12-hour am/pm format, identical to "\D{%I:%M %p}"

=item \A

The current time in short 24-hour format, identical to "\D{%H:%M}"

=item \u

The username of the current user

=item \w

The current working directory

=item \W

The basename of the current working directory

=item \$

"#" for effective uid is 0 (root), else "$"

=cut

sub dollar { $user_info[2] ? '$' : '#' }

=item \0dd

The character corresponding to the octal number 0dd

=item \\

Literal backslash

=item \H

Hostname, uses L<Sys::Hostname>

=item \h

First part of the hostname

=cut

sub H {
	use Sys::Hostname;
	no warnings;
	*H = sub {
		my $h = &hostname;
		$h =~ s#\..*$## if $_[1] eq 'h';
		return $h;
	};
	return &H;
}

=item \l

The basename of the (output) terminal device name,
uses POSIX, but won't be really portable.

=cut

sub L { # How platform dependent is this ?
	use POSIX qw/ttyname/;
	no warnings;
	*L = sub {
		my $t = ttyname(*STDOUT);
		$t =~ s#.*/## if $_[1] eq 'l';
		return $t;
	};
	return &L;
}

=item \[ \]

These are used to encapsulate a sequence of non-printing chars.
Since we don't need that, they are removed.

=back

=head2 Extensions

The following escapes are extensions not supported by bash, and are not portable:

=over 4

=item \L

The (output) terminal device name, uses POSIX, but won't be really portable.

=item \C{colour}

Insert the ANSI sequence for named colour.
Known colours are: black, red, green, yellow, blue, magenta, cyan and white;
background colours prefixed with "on_".
Also known are reset, bold, dark, underline, blink and reverse, although the
effect depends on the terminla you use.

Unless you want the whole commandline coloured you should 
end your prompt with "\C{reset}".

Of course you can still use the "raw" ansi escape codes for these colours.

Note that "bold" is sometimes also known as "bright", so "\C{bold,black}"
will on some terminals render dark grey.

If the environment variable C<CLICOLOR> is defined but false colours are
switched off automaticly.

=cut

sub C {
	our %colours = ( # Copied from Term::ANSIScreen
		'clear'      => 0,    'reset'      => 0,
		'bold'       => 1,    'dark'       => 2,
		'underline'  => 4,    'underscore' => 4,
		'blink'      => 5,    'reverse'    => 7,
		'concealed'  => 8,

		'black'      => 30,   'on_black'   => 40,
		'red'        => 31,   'on_red'     => 41,
		'green'      => 32,   'on_green'   => 42,
		'yellow'     => 33,   'on_yellow'  => 43,
		'blue'       => 34,   'on_blue'    => 44,
		'magenta'    => 35,   'on_magenta' => 45,
		'cyan'       => 36,   'on_cyan'    => 46,
		'white'      => 37,   'on_white'   => 47,
	);
	no warnings;
	*C = sub {
		return if defined $ENV{CLICOLOR} and ! $ENV{CLICOLOR};
		my @attr = split ',', $_[2];
		#print "# $_[2] => \\e[" . join(';', map {$colours{lc($_)}} @attr) . "m\n";
		return "\e[" . join(';', map {$colours{lc($_)}} @attr) . "m";
	};
	C(@_);
}

=item \P{format}

Proc information.

I<All of these are unix specific>

=over 4

=item %a

Acpi AC status '+' or '-' for connected or not, linux specific

=item %b

Acpi battery status in mWh, linux specific

=item %L

Load average

=item %l

First number of the load average

=item %t

Acpi temperature, linux specific

=item %u

Uptime

=item %w

Number of users logged in

=back

=cut

# $ uptime
# 17:38:53 up  3:24,  2 users,  load average: 0.04, 0.10, 0.13

sub P {
	my ($self, undef, $format) = @_;
	my %code;
	$format =~ s/\%(.)/$code{$1}++; "'.\$proc{$1}.'"/ge;
	my @subs = grep exists($code{$_}), qw/a b t/;

	return sub {
		my %proc;
		for my $s (@subs) {
			my $sub = "P_$s";
			$proc{$s} = $self->$sub();
		}
		if (open UP, 'uptime|') {
			my $up = <UP>;
			close UP;
			$up =~ /up\s*(\d+:\d+)/ and $proc{u} = $1;
			$up =~ /(\d+)\s*user/     and $proc{w} = $1;
			$up =~ /((\d+\.\d+),\s*\d+\.\d+,\s*\d+\.\d+)/
				and @proc{'L', 'l'} = ($1, $2);
		}
		#use Data::Dumper; print "'$format'", Dumper \%proc, "\n";
		eval "'$format'"; # all in single quote, except for escapes
	}
}

sub P_a {
	open(AC,'/proc/acpi/ac_adapter/AC/state') or return '?';
	my $a = <AC>;
	close AC;
	return ( ($a =~ /on/) ? '+' : '-' );
}

sub P_b {
	open(BAT,'/proc/acpi/battery/BAT0/state') or return '?';
	my ($b) = grep /^remaining capacity:/, (<BAT>);
	close BAT;
	$b =~ /(\d+)/;
	return $1 || '0';
}

sub P_t {
	open(TH, '/proc/acpi/thermal_zone/THM/temperature') or return '?';
	my $t = <TH>;
	close TH;
	$t =~ /(\d+)/;
	return $1 || '0';
}

=back

=head2 Not implemented escapes

The following escapes are not implemented, because they are application specific.

=over 4

=item \j

The number of jobs currently managed by the application.

=item \v

The version of the application.

=item \V

The release number of the application, version + patchelvel

=item \!

The history number of the next command.

This escape gets replaced by literal '!' while a literal '!' gets replaces by '!!';
this makes the string a posix compatible prompt, thus it will work if your readline
module expects a posix prompt.

=item \#

The command number of the next command (like history number, but minus the
lines read from the history file).

=back

=head2 Customizing

If you want to overload escapes or want to supply values for the application
specific escapes you can put them in C<%Env::PS1::map>, the key is the escape letter,
the value either a string or a CODE ref. If you map a CODE ref it normally is called 
every time the prompt string is read. When the escape is followed by an argument
in the format string (like C<\D{argument}>) the CODE ref is called only once when the
string is cached, but in that case it may in turn return a CODE ref.

=head1 BUGS

Please mail the author if you encounter any bugs.

=head1 AUTHOR

Jaap Karssenberg || Pardus [Larus] E<lt>pardus@cpan.orgE<gt>

This module is currently maintained by Ryan Niebur E<lt>rsn@cpan.orgE<gt>

Copyright (c) 2004 Jaap G Karssenberg. All rights reserved.
Copyright (c) 2009 Ryan Niebur.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Env>,
L<Term::ReadLine::Zoid>

=cut

