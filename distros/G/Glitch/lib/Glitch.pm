package Glitch;
our $VERSION = '0.06';
use 5.006; use strict; use warnings;
use Data::Dumper; use feature qw/state/;
state (%META);

BEGIN {
        $Data::Dumper::Deparse = 1;
}

sub import {
	my ($pkg, %import) = @_;
	if (keys %import) {
		$META{config_parser} = delete $import{glitch_config_parser} if defined $import{glitch_config_parser};
		%import = (_parse_config(delete $import{glitch_config}), %import) if (defined $import{glitch_config}); 
		if (defined $import{glitch_logger}) {
			$META{logger} = delete $import{glitch_logger};
			$META{logger_enabled} = !!1;
		}
		for (qw/glitch_logger_enabled glitch_logger_format glitch_logger_method glitch_stringify_format/) {
			if (defined $import{$_}) {
				(my $name = $_) =~ s/^glitch_//;
				$META{$name} = delete $import{$_};
			}
		}
		$META{stringify} = { %{$META{stringify} || {}}, %{ delete $import{glitch_stringify} } }
			if defined $import{glitch_stringify};
		_build_glitch(
			name => $_,
			%{ $import{$_} },
			map { $_ => '' } ("file", "filepath", "line", "stacktrace", "module")
		) for sort keys %import;
	}
	do {
		no strict 'refs';
		my $package = caller();
		*{"${package}::glitch"} = \&glitch;
	};
}

sub glitch {
	my %options = (
		name => shift,
		_stack(),
		@_
	);
	_build_glitch(%options) if (!$META{glitches}{$options{name}});
	die _log($META{glitches}{$options{name}}->new(%options));
}

sub logger {
	$META{logger} = $_[0];
}

sub logger_enabled {
	$META{logger_enabled} = !!$_[0];
}

sub logger_format {
	$META{logger_format} = $_[0];
}

sub logger_method {
	$META{logger_method} = $_[0];
}

sub _log {
	if ($META{logger_enabled} && $META{logger}) {
		my $ref = ref $META{logger};
		my $glitch = $META{logger_format} ? $_[0]->stringify($META{logger_format}) : $_[0];
		my $cb = $META{logger_method} || 'err';
		($ref eq 'CODE') ? $META{logger}->($glitch) : $META{logger}->$cb($glitch);
	}
	return $_[0];
}


sub _build_glitch {
	my (%options) = @_;
	my $class = sprintf q|%s::%s|, $options{object_name} ||= 'Glitch', $options{name};
	my @methods = map { my $struct = $_ =~ m/(file|filepath|line|stacktrace|module)/ ? "''" :  _stringify_struct($options{$_}); "sub $_ { return \$_[0]->{$_} || $struct; }" } sort keys %options;
	unshift @methods, 'sub new { my $self = shift; return bless {@_}, $self; }';
	my $format = $META{stringify_format} ||= 'default';
	push @methods, 'sub keys { my $keys = ' . _stringify_struct([sort keys %options]) . '; return wantarray ? @{ $keys } : $keys; }';
	push @methods, 'sub hash { my %hash; $hash{$_} = $_[0]->$_ for ( @{ $_[0]->keys } ); return \%hash }';
	push @methods, 'sub stringify { my $type = sprintf "stringify_%s", ($_[1] || "' . $format . '"); return $_[0]->$type(); }';
	$META{stringify}{default} ||= 'return $_[0]->message . " at " . $_[0]->filepath . " line " . $_[0]->line . "\n";';
	$META{stringify}{json} ||= 'require JSON; JSON->new->encode($_[0]->hash);';
	push @methods, sprintf "sub stringify_%s { %s }", $_, $META{stringify}{$_} for sort keys %{$META{stringify}};
	my $package = sprintf(q|package %s;
use overload '""' => \&stringify;
%s
1;|, $class, join( "\n", @methods) );
	eval $package;
	die $@ if ($@);
	$META{glitches}{$options{name}} = $class;
	return 1;
}

sub _stringify_struct {
        my ( $struct ) = @_;
        return 'undefined' unless defined $struct;
        $struct = ref $struct ? Dumper $struct : "'$struct'";
        $struct =~ s/\$VAR1 = //;
        $struct =~ s/\s*\n*\s*package Glitch\;|use warnings\;|use strict\;//g;
        $struct =~ s/{\s*\n*/{/;
        $struct =~ s/;$//;
        return $struct;
}

sub _stack {
	my @caller; my $i = 0; my @stack;
	while(@caller = caller($i++)){
		next if $caller[0] eq 'Glitch';
		$stack[$i+1]->{module} = $caller[0];
		$stack[$i+1]->{filepath} = $caller[1];
		$stack[$i+1]->{file} = $1 if $caller[1] =~ /([^\/]+)$/;;
		$stack[$i+1]->{line} = $1 if $caller[2] =~ /(\d+)/;
		$stack[$i]->{sub} = $1 if $caller[3] =~ /([^:]+)$/;
	}
	my $msg = $stack[-1];
	$msg->{stacktrace} = join '->', reverse map {
		my $module = $_->{module} !~ m/^main$/ ? $_->{module} : $_->{file};
		$_->{sub} 
			? $module . '::' . $_->{sub} . ':' . $_->{line}
			: $module . ':' . $_->{line} 
	} grep {
		$_ && $_->{module} && $_->{line} && $_->{file}
	} @stack;
	delete $msg->{stacktrace} unless $msg->{stacktrace};
	return %{$msg};
}

sub _parse_config {
	my ($config, %out) = @_;
	if (ref $config) {
		map {
			%out = _parse_config($_, %out)
		} @{$config};
		return %out;
	}
	open my $fh, '<', $config or glitch('glitchInternal1', message => 'Cannot open file for writing', error => $!);
	my $content = do { local $/; <$fh> };
	close $fh;
	$content = $META{config_parser} ? $META{config_parser}->($content) : eval $content;
	glitch("glitchInternal2", message => 'Cannot parse file', error => $@) if ($@);
	return (%out, %{$content || {}});
}

=head1 NAME

Glitch - Exception Handling.

=head1 VERSION

Version 0.06

=cut

=head1 SYNOPSIS

	package Foo;

	use Glitch;

	sub bar {
		do { ... } or glitch('one', message => 'Create a new glitch error message');

		... later in your code you can then reuse glitch 'one'

		do { ... } or glitch('one');
	}

...

	package Foo;

	use Glitch (
		one => {
			message => 'Create a new glitch error message'
		},
		two => {
			message => 'A different glitch error message',
			fileName => '',
		}
	);

	sub bar {
		eval {
			do { ... } or glitch('one');
			...
			do { ... } or glitch('two', fileName => 'abc');
		};
		if ($@) {
			do { ... } if $@->name eq 'one';
			do { ... } if $@->name eq 'two';
		}
	}

	1;

...

	package Glitches;

	use Glitch (
		glitch_logger => sub {
			open my $fh, '>', 'glitch.log';
			print $fh $_[0] . "\n";
			close $fh;	
		},
		glitch_stringify_format => 'json',
		one => {
			message => 'Create a new glitch error message'
		},
		two => {
			message => 'A different glitch error message',
			fileName => '',
		}
	);

	1;

	package Foo;

	use Glitch;
	use Glitches;

	sub bar {
		eval {
			do { ... } or glitch('one');
			...
			do { ... } or glitch('two', fileName => 'abc');
		};
		if ($@) {
			if ($@->name eq 'one') { ... }
			elsif ($@->name eq 'two') { ... }
		}
	}

	1;

...

	# glitch.conf
	{
		"one": {
			"message": "this is a error message"
		},
		"two": {
			"message": "this is another error messsage"
		}
	}	

	package Foo;
	use JSON;
	use Glitch (
		glitch_config => 'glitch.conf'
		glitch_config_parser => sub {
			JSON->new->decode($_[0]);
		}
	);

	sub bar {
		eval {
			do { ... } or glitch('one');
			...
			do { ... } or glitch('two');
		};
		if ($@) {
			if ($@->name eq 'one') { ... }
			elsif ($@->name eq 'two') { ... }
		}
	}

=head1 EXPORT

=head2 glitch

=cut

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-glitch at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Glitch>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Glitch

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Glitch>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Glitch>

=item * Search CPAN

L<https://metacpan.org/release/Glitch>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Glitch
