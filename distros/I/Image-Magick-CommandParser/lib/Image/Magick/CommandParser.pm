package Image::Magick::CommandParser;

use strict;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.

use Data::Section::Simple 'get_data_section';

use File::Glob;
use File::Slurper 'read_lines';

use Log::Handler;

use Moo;

use Set::Array;

use Set::FA::Element;

use Types::Standard qw/Any ArrayRef HashRef Str/;

has built_in_images =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has built_in_patterns =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has command =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has dfa =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has field =>
(
	default  => sub{return []},
	is       => 'rw',
	isa      => ArrayRef,
	required => 0,
);

has image_formats =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has logger =>
(
	default  => sub{return undef},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has maxlevel =>
(
	default  => sub{return 'notice'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has minlevel =>
(
	default  => sub{return 'error'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has pseudo_image_formats =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has stack =>
(
	default  => sub{return []},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

my($myself); # For use inside functions.

our $VERSION = '1.04';

# -----------------------------------------------

sub BUILD
{
	my($self)	= @_;
	$myself		= $self;

	if (! defined $self -> logger)
	{
		$self -> logger(Log::Handler -> new);
		$self -> logger -> add
		(
			screen =>
			{
				maxlevel       => $self -> maxlevel,
				message_layout => '%m',
				minlevel       => $self -> minlevel,
				utf8           => 1,
			}
		);
	}

} # End of BUILD.

# ----------------------------------------------
# Warning: this a function, not a method.

sub action
{
	my($dfa)	= @_;
	my($name)	= 'action';
	my($match)	= $dfa -> match;

	$myself -> log(debug => "'$name' matched '$match'");

	if (substr($match, 0, 1) eq '@')
	{
		my($field) = $myself -> field;

		$myself -> field([join(' ', read_lines substr($match, 1) ), @$field]);
	}
	else
	{
		$myself -> stack -> push
		({
			token	=> $match,
			type	=> $name,
		});
	}


} # End of action.

# ----------------------------------------------
# Warning: this a function, not a method.

sub close_parenthesis
{
	my($dfa)	= @_;
	my($name)	= 'close_parenthesis';
	my($match)	= $dfa -> match;

	$myself -> log(debug => "'$name' matched '$match'");

	$myself -> stack -> push
	({
		token	=> $match,
		type	=> $name,
	});

} # End of close_parenthesis.

# ----------------------------------------------
# Warning: this a function, not a method.

sub done
{
	my($dfa)	= @_;
	my($name)	= 'done';
	my($match)	= $dfa -> match;

	$myself -> log(debug => "'$name' matched '$match'");

	$myself -> stack -> push
	({
		token	=> $match,
		type	=> $name,
	});

} # End of done.

# ----------------------------------------------
# Warning: this a function, not a method.

sub file_glob
{
	my($dfa)	= @_;
	my($name)	= 'input_file';
	my($match)	= $dfa -> match;

	$myself -> log(debug => "'$name' matched '$match'");

	# Warning! Do not use (sort bsd_glob($match) ), when bs_glob() returns the unglobbed 'colors/*s*.png'
	# in test 47.
	# You can use (sort map{$_} bsd_glob($match) ) but the result is ASCII sorted (by default) anyway.

	for my $file (File::Glob::bsd_glob($match) )
	{
		$myself -> stack -> push
		({
			token	=> $file,
			type	=> $name,
		});
	}

} # End of file_glob.

# ----------------------------------------------
# Warning: this a function, not a method.

sub input_file
{
	my($dfa)	= @_;
	my($name)	= 'input_file';
	my($match)	= $dfa -> match;

	$myself -> log(debug => "'$name' matched '$match'");

	$myself -> stack -> push
	({
		token	=> $match,
		type	=> $name,
	});

} # End of input_file.

# ----------------------------------------------
# Warning: this a function, not a method.

sub kommand
{
	my($dfa)	= @_;
	my($name)	= 'command';
	my($match)	= $dfa -> match;

	$myself -> log(debug => "'$name' matched '$match'");

	$myself -> stack -> push
	({
		token	=> $match,
		type	=> $name,
	});

} # End of kommand.

# --------------------------------------------------

sub log
{
	my($self, $level, $s) = @_;

	$self -> logger -> log($level => $s) if ($self -> logger);

} # End of log.

# --------------------------------------------------

sub new_machine
{
	my($self)	= @_;
	my($list)	= get_data_section('built_in_images');

	$self -> built_in_images(join('|', split(/\n/, $list) ) );

	my($built_in_images) = $self -> built_in_images;

	# Warning: Do not sort these formats. Things like 'o' must come after all /o.+/.

	$list = get_data_section('image_formats');

	$self -> image_formats(join('|', split(/\n/, $list) ) );

	my($image_formats) = $self -> image_formats;

	$list = get_data_section('built_in_patterns');

	$self -> built_in_patterns(join('|', split(/\n/, $list) ) );

	my($built_in_patterns) = $self -> built_in_patterns;

	$list = get_data_section('pseudo_image_formats');

	$self -> pseudo_image_formats(join('|', split(/\n/, $list) ) );

	my($pseudo_image_formats)	= $self -> pseudo_image_formats;
	my($transitions)			=
	[
		# Current state			Regexp testing input					New state
		#
		# Warning: If you patch 'action', copy the patch down to 'action_1'.

		['action',				'^$',									'done'],
		['action',				'[-+][a-zA-Z]+',						'action_1'],
		['action',				'\(',									'open_parenthesis'],
		['action',				'\)',									'close_parenthesis'],
		['action',				'[\"\'].*[\"\']',						'parameter'],
		['action',				'\@.+',									'action_1'],
		['action',				'\d+%x\d+%[!<>^]?(?:[-+]\d+[-+]\d+)?',	'parameter'],
		['action',				'x\d+%[!<>^]?(?:[-+]\d+[-+]\d+)?',		'parameter'],
		['action',				'\d+%(?:x\d+)?[!<>^]?(?:[-+]\d+[-+]\d+)?',	'parameter'],
		['action',				'\d+x\d+%?[!<>^]?(?:[-+]\d+[-+]\d+)?',	'parameter'],
		['action',				'-?\d+.*',								'parameter'],
		['action',				"magick:(?:$built_in_images)",			'output_file'],
		['action',				"(?:$built_in_images):",				'output_file'],
		['action',				".+\\.(?:$image_formats)",				'output_file'],
		['action',				"(?:$image_formats):-",					'output_file'],
		['action',				'[a-zA-Z][-a-zA-Z]+:[a-zA-Z]+',			'operator'],
		['action',				'[a-zA-Z][-a-zA-Z]+',					'parameter'],

		# Warning: If you patch 'action_1', copy the patch up to 'action'.

		['action_1',			'^$',									'done'],
		['action_1',			'[-+][a-zA-Z]+',						'action'],
		['action_1',			'\(',									'open_parenthesis'],
		['action_1',			'\)',									'close_parenthesis'],
		['action_1',			'[\"\'].*[\"\']',						'parameter'],
		['action_1',			'\@.+',									'action'],
		['action_1',			'\d+%x\d+%[!<>^]?(?:[-+]\d+[-+]\d+)?',	'parameter'],
		['action_1',			'x\d+%[!<>^]?(?:[-+]\d+[-+]\d+)?',		'parameter'],
		['action_1',			'\d+%(?:x\d+)?[!<>^]?(?:[-+]\d+[-+]\d+)?',	'parameter'],
		['action_1',			'\d+x\d+%?[!<>^]?(?:[-+]\d+[-+]\d+)?',	'parameter'],
		['action_1',			'-?\d+.*',								'parameter'],
		['action_1',			"magick:(?:$built_in_images)",			'output_file'],
		['action_1',			"(?:$built_in_images):",				'output_file'],
		['action_1',			".+\\.(?:$image_formats)",				'output_file'],
		['action_1',			"(?:$image_formats):-",					'output_file'],
		['action_1',			'[a-zA-Z][-a-zA-Z]+:[a-zA-Z]+',			'operator'],
		['action_1',			'[a-zA-Z][-a-zA-Z]+',					'parameter'],

		['command',				'^$',									'done'],
		['command',				'.*(?:\\*|\\?)',						'file_glob'],
		['command',				'rgb:(?:.+)',							'input_file'],
		['command',				"magick:(?:$built_in_images)",			'input_file'],
		['command',				"(?:$built_in_images):",				'input_file'],
		['command',				"pattern:(?:$built_in_patterns)",		'input_file'],
		['command',				"(?:$pseudo_image_formats):(?:.*)",		'input_file'],
		['command',				".+\\.(?:$image_formats)",				'input_file'],
		['command',				'^-$',									'input_file'],
		['command',				"(?:$image_formats):-",					'input_file'],
		['command',				"(?:$image_formats):fd:\\d+",			'input_file'],
		['command',				'fd:\\d+',								'input_file'],
		['command',				'[-+][a-zA-Z]+',						'action'],

		['done',				'^$',									'done'],

		['file_glob',			'^$',									'done'],
		['file_glob',			'\(',									'open_parenthesis'],
		['file_glob',			'.*(?:\\*|\\?)',						'file_glob'],
		['file_glob',			'rgb:(?:.+)',							'input_file_1'],
		['file_glob',			"magick:(?:$built_in_images)",			'input_file_1'],
		['file_glob',			"(?:$built_in_images):",				'input_file_1'],
		['file_glob',			"pattern:(?:$built_in_patterns)",		'input_file_1'],
		['file_glob',			"(?:$pseudo_image_formats):(?:.*)",		'input_file_1'],
		['file_glob',			".+\\.(?:$image_formats)",				'input_file_1'],
		['file_glob',			'^-$',									'input_file_1'],
		['file_glob',			"(?:$image_formats):-",					'input_file_1'],
		['file_glob',			"(?:$image_formats):fd:\\d+",			'input_file_1'],
		['file_glob',			'fd:\\d+',								'input_file_1'],
		['file_glob',			'[-+][a-zA-Z]+',						'action'],
		['file_glob',			'[a-zA-Z][-a-zA-Z]+:[a-zA-Z]+',			'operator'],

		# Warning: If you patch 'input_file', copy the patch down to 'input_file_1'.

		['input_file',			'^$',									'done'],
		['input_file',			'.*(?:\\*|\\?)',						'file_glob'],
		['input_file',			'\(',									'open_parenthesis'],
		['input_file',			'rgb:(?:.+)',							'input_file_1'],
		['input_file',			"magick:(?:$built_in_images)",			'input_file_1'],
		['input_file',			"(?:$built_in_images):",				'input_file_1'],
		['input_file',			"pattern:(?:$built_in_patterns)",		'input_file_1'],
		['input_file',			"(?:$pseudo_image_formats):(?:.*)",		'input_file_1'],
		['input_file',			".+\\.(?:$image_formats)",				'input_file_1'],
		['input_file',			'^-$',									'input_file_1'],
		['input_file',			"(?:$image_formats):-",					'input_file_1'],
		['input_file',			"(?:$image_formats):fd:\\d+",			'input_file_1'],
		['input_file',			'fd:\\d+',								'input_file_1'],
		['input_file',			'[-+][a-zA-Z]+',						'action'],
		['input_file',			'[a-zA-Z][-a-zA-Z]+:[a-zA-Z]+',			'operator'],

		# Warning: If you patch 'input_file_1', copy the patch up to 'input_file'.

		['input_file_1',		'^$',									'done'],
		['input_file_1',		'.*(?:\\*|\\?)',						'file_glob'],
		['input_file_1',		'\(',									'open_parenthesis'],
		['input_file_1',		'rgb:(?:.+)',							'input_file'],
		['input_file_1',		"magick:(?:$built_in_images)",			'input_file'],
		['input_file_1',		"(?:$built_in_images):",				'input_file'],
		['input_file_1',		"pattern:(?:$built_in_patterns)",		'input_file'],
		['input_file_1',		"(?:$pseudo_image_formats):(?:.*)",		'input_file'],
		['input_file_1',		".+\\.(?:$image_formats)",				'input_file'],
		['input_file_1',		'^-$',									'input_file'],
		['input_file_1',		"(?:$image_formats):-",					'input_file'],
		['input_file_1',		"(?:$image_formats):fd:\\d+",			'input_file'],
		['input_file_1',		'fd:\\d+',								'input_file'],
		['input_file_1',		'[-+][a-zA-Z]+',						'action'],
		['input_file_1',		'[a-zA-Z][-a-zA-Z]+:[a-zA-Z]+',			'operator'],

		['close_parenthesis',	'^$',									'done'],
		['close_parenthesis',	'\(',									'open_parenthesis'],
		['close_parenthesis',	'[a-zA-Z][-a-zA-Z]+:[a-zA-Z]+',			'operator'],
		['close_parenthesis',	'[-+][a-zA-Z]+',						'action'],
		['close_parenthesis',	".+\\.(?:$image_formats)",				'output_file'],
		['close_parenthesis',	"(?:$image_formats):-",					'output_file'],

		['open_parenthesis',	'^$',									'done'],
		['open_parenthesis',	'\)',									'close_parenthesis'],
		['open_parenthesis',	'[a-zA-Z][-a-zA-Z]+:[a-zA-Z]+',			'operator'],
		['open_parenthesis',	'[-+][a-zA-Z]+',						'action'],
		['open_parenthesis',	".+\\.(?:$image_formats)",				'output_file'],
		['open_parenthesis',	"(?:$image_formats):-",					'output_file'],

		['operator',			'^$',									'done'],
		['operator',			'[-+][a-zA-Z]+',						'action'],
		['operator',			".+\\.(?:$image_formats)",				'output_file'],
		['operator',			"(?:$image_formats):-",					'output_file'],

		['output_file',			'^$',									'done'],

		['parameter',			'^$',									'done'],
		['parameter',			'\(',									'open_parenthesis'],
		['parameter',			'\)',									'close_parenthesis'],
		['parameter',			'[-+][a-zA-Z]+',						'action'],
		['parameter',			'[a-zA-Z][-a-zA-Z]+:[a-zA-Z]+',			'operator'],
		['parameter',			".+\\.(?:$image_formats)",				'output_file'],
		['parameter',			"(?:$image_formats):-",					'output_file'],

		['start',				'(?:convert|mogrify)',					'command'],
	];

	# Crank up the DFA.

	$self -> dfa
	(
		Set::FA::Element -> new
		(
			accepting	=> ['done'],
			actions		=>
			{
				action =>
				{
					entry	=> \&action,
				},
				action_1 =>
				{
					entry	=> \&action,
				},
				close_parenthesis =>
				{
					entry	=> \&close_parenthesis,
				},
				command =>
				{
					entry	=> \&kommand,
				},
				done =>
				{
					entry	=> \&done,
				},
				file_glob =>
				{
					entry	=> \&file_glob,
				},
				input_file =>
				{
					entry	=> \&input_file,
				},
				input_file_1 =>
				{
					entry	=> \&input_file,
				},
				open_parenthesis =>
				{
					entry	=> \&open_parenthesis,
				},
				operator =>
				{
					entry	=> \&operator,
				},
				output_file =>
				{
					entry	=> \&output_file,
				},
				parameter =>
				{
					entry	=> \&parameter,
				},
			},
			die_on_loop	=> 1,
			maxlevel	=> $self -> maxlevel,
			start		=> 'start',
			transitions	=> $transitions,
		)
	);

} # End of new_machine.

# ----------------------------------------------
# Warning: this a function, not a method.

sub open_parenthesis
{
	my($dfa)	= @_;
	my($name)	= 'open_parenthesis';
	my($match)	= $dfa -> match;

	$myself -> log(debug => "'$name' matched '$match'");

	$myself -> stack -> push
	({
		token	=> $match,
		type	=> $name,
	});

} # End of open_parenthesis.

# ----------------------------------------------
# Warning: this a function, not a method.

sub output_file
{
	my($dfa)	= @_;
	my($name)	= 'output_file';
	my($match)	= $dfa -> match;

	$myself -> log(debug => "'$name' matched '$match'");

	$myself -> stack -> push
	({
		token	=> $match,
		type	=> $name,
	});

} # End of output_file.

# ----------------------------------------------
# Warning: this a function, not a method.

sub operator
{
	my($dfa)	= @_;
	my($name)	= 'operator';
	my($match)	= $dfa -> match;

	$myself -> log(debug => "'$name' matched '$match'");

	$myself -> stack -> push
	({
		token	=> $match,
		type	=> $name,
	});

} # End of operator.

# ----------------------------------------------
# Warning: this a function, not a method.

sub parameter
{
	my($dfa)	= @_;
	my($name)	= 'parameter';
	my($match)	= $dfa -> match;

	$myself -> log(debug => "'$name' matched '$match'");

	$myself -> stack -> push
	({
		token	=> $match,
		type	=> $name,
	});

} # End of parameter.

# ------------------------------------------------

sub result
{
	my($self) = @_;

	return join(' ', map{$$_{token} } $self -> stack -> print);

} # End of result.

# ------------------------------------------------

sub run
{
	my($self, %options) = @_;

	# The reason for resetting these each time is so the object can be reused.

	$self -> new_machine;
	$self -> stack(Set::Array -> new);

	# Strip off any output file name.

	my($command)			= $options{command} ? $options{command} : $self -> command;
	$command				=~ s/^\s+//;
	$command				=~ s/\s+$//;
	my($output_file_name)	= '';
	my($image_regexp)		= '^.+\s+(.+?\.(?:' . join('|', split/\n/, get_data_section('image_formats') ) . '))$';
	$image_regexp			= qr/$image_regexp/;

	if ($command =~ $image_regexp)
	{
		$output_file_name	= $1;
		$command			= substr($command, 0, - length($output_file_name) - 1);

		$self -> log(debug => "Output file: $output_file_name");
	}

	$self -> command($command);

	my(@field)	= split(/\s+/, $command);
	my($limit)	= $#field;

	# Reconstruct strings like 'a b' which have been split just above.
	# This code does not handle escaped spaces.

	my($quote);

	for (my $j = 0; $j < $limit; $j++)
	{
		next if (substr($field[$j], 0, 1) !~ /([\"\'])/); # The \ are for UltraEdit's syntax hiliter.

		$quote	= $1;
		my($k)	= $j;

		while ( (++$k <= $limit) && ($field[$k] !~ /$quote$/) ) {};

		if ($k <= $limit)
		{
			splice(@field, $j, $k - $j + 1, join(' ', @field[$j .. $k]) );

			$limit -= $k - $j;
		}
	}

	# Here we jam @field into an attribute of the object because input like @include.me
	# means the contents of that file have to be interpolated into the input stream.
	# The interpolation takes place in function (not method) parameter().
	# And we use $finished to allow for stand-alone 0 to be a field.

	$self -> field([@field]);

	my($finished) = 0;

	my($field);

	while (! $finished)
	{
		$field = shift @{$self -> field};

		if (! defined $field)
		{
			$finished = 1;
		}
		else
		{
			$self -> dfa -> step($field);
		}
	}

	$self -> log(info => '# At end, current state: ' . $self -> dfa -> current);
	$self -> log(info => "# Processed input string: $command");

	if (length($output_file_name) > 0)
	{
		$myself -> stack -> push
		({
			token	=> $output_file_name,
			type	=> 'output_file_name',
		});
	}

	# Return 0 for success and 1 for failure.

	return 0;

} # End of run.

# ------------------------------------------------

1;

=pod

=head1 NAME

C<Image::Magick::CommandParser> - Parse any command line acceptable to convert or mogrify

=head1 Synopsis

This is scripts/synopsis.pl:

	#!/usr/bin/env perl

	use strict;
	use warnings;
	use warnings qw(FATAL utf8);

	use Image::Magick::CommandParser;

	# ----------------------------------------------

	my($command)	= 'convert colors/*s*.png -append output.png';
	my($processor)	= Image::Magick::CommandParser -> new
	(
		command		=> $command,
		maxlevel	=> 'notice',
	);

	$processor -> run;

	print 'Input:  ', $command, "\n";
	print 'Result: ', $processor -> result, "\n";

With its output (after running in the distro dir, with access to colors/*.png):

	Input:  convert colors/*s*.png -append output.png
	Result: convert colors/fuchsia.png colors/silver.png -append output.png

=head1 Description

C<Image::Magick::CommandParser> is a stand-alone parser for command lines acceptable to the
L<Imagemagick|https://imagemagick.org> programs C<convert> and C<mogrify>.

It aims to handle all constructs supported by Imagemagick itself, but it's vital to understand
that this module does not use any component of Imagemagick. Hence the I<stand-alone> just above.

In particular the output is a stack, accessible via the C<< $object -> stack >> method, which
returns an array of hashrefs.

The stack is managed by an object of type L<Set::Array>. See the L</FAQ> for details.

The result - as a space-separated string of tokens detected in the command - is returned by
L</result()>.

The actual parsing is done with L<Set::FA::Element>.

Consult the L</FAQ> and t/test.t for specific examples of command line options supported. A few of
them are included here:

=over 4

=item o All command options of the form [-+][a-zA-Z]+

=item o Redirecting input from files

=over 4

=item o convert magick:rose -label @t/label.1.txt -format "%l label" rose.png

=back

=item o File globbing

=over 4

=item o convert colors/*s*.png -append output.png

=back

=item o Explicit image format

=over 4

=item o convert rgb:camera.image -size 320x85 output.png

=back

=item o Built-in images and patterns

=over 4

=item o convert pattern:bricks -size 320x85 output.png

=back

=item o Standard input and output

=over 4

=item o convert gif:- -size 320x85 output.png

=item o convert magick:logo -size 320x85 gif:-

=back

=item o File handle numbers

=over 4

=item o convert fd:3 png:fd:4 gif:fd:5 fd:6 -append output.png

=back

=item o The apparently endless variations of the geometry parameter

Samples:

=over 4

=item o 320x85

=item o 50%

=item o 60%x40

=item o 320x85+0+0

=item o 60x40%+0+0

=item o 50%!+0+0

=back

=item o Built-in special files

Samples:

=over 4

=item o logo:

=item o magick:rose

=back

=item o Output label format strings

=over 4

=item o convert magick:rose -label "%wx%h" -format "%l label" rose.png

=back

=item o The image stack and cloning

=over 4

=item o convert label.gif ( +clone -shade 110x90 -normalize -negate +clone -compose Plus -composite ) button.gif

=item o convert label.gif +clone 0,4,5 button.gif

=back

=back

Imagemagick has a web page, L<http://imagemagick.org/script/command-line-processing.php>, dedicated
to the features available in its command line processing code. Please report any cases where this
module does not support one of those features. But see L</Trouble-shooting> before reporting an
issue, since there I list a few special cases.

=head1 Installation

Install C<Image::Magick::CommandParser> as you would for any C<Perl> module:

Run:

	cpanm Image::Magick::CommandParser

or run:

	sudo cpan Image::Magick::CommandParser

or unpack the distro, and then:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Constructor and Initialization

Call C<new()> as C<< my($parser) = Image::Magick::CommandParser -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<Image::Magick::CommandParser>.

Key-value pairs accepted in the parameter list (see also the corresponding methods
[e.g. L</command([$string])>]):

=over 4

=item o command => $string

The command string to process.

Default: ''.

=item o logger => $logger_object

Specify a logger object.

The default value triggers creation of an object of type L<Log::Handler> which outputs to the
screen.

To disable logging, just set I<logger> to the empty string.

Default: undef.

=item o maxlevel => $level

This option is only used if an object of type L<Log::Handler> is created. See I<logger> above.

See also L<Log::Handler::Levels>.

Nothing is printed by default.

Default: 'notice'. Typical value is 'debug' and 'info'.

=item o minlevel => $level

This option is only used if an object of type L<Log::Handler> is created. See I<logger> above.

See also L<Log::Handler::Levels>.

Default: 'error'.

No lower levels are used.

=back

=head1 Methods

=head2 command([$string])

Here, the [] indicate an optional parameter.

Get or set the command line string to be processed.

=head2 log($level, $s)

Calls $self -> logger -> log($level => $s) if ($self -> logger).

=head2 logger([$logger_object])

Here, the [] indicate an optional parameter.

Get or set the logger object.

To disable logging, just set logger to the empty string.

This logger is passed to L<GraphViz2>.

Note: C<logger> is a parameter to new().

=head2 maxlevel([$string])

Here, the [] indicate an optional parameter.

Get or set the value used by the logger object.

This option is only used if an object of type L<Log::Handler> is created. See
L<Log::Handler::Levels>.

Note: C<maxlevel> is a parameter to new().

=head2 minlevel([$string])

Here, the [] indicate an optional parameter.

Get or set the value used by the logger object.

This option is only used if an object of type L<Log::Handler> is created. See
L<Log::Handler::Levels>.

Note: C<minlevel> is a parameter to new().

=head2 new()

The constructor. See L</Constructor and Initialization>.

=head2 result()

Returns a string of space-separated tokens, as output by the parser.

There is C<result()> in its entirety:

	sub result
	{
		my($self) = @_;

		return join(' ', map{$$_{token} } $self -> stack -> print);

	} # End of result.

=head2 run()

Returns 0 for success and 1 for failure.

Run the parser on the command provided by C<< new(command => '...') >> or provided by calling
L</command([$string])> before calling C<run()>.

If the return value is 0, call L</result()> to get a string corresponding to the input, or process
the stack directly by calling L</stack()>.

Globs etc in the input will be represented by multiple items in the stack.

=head2 stack()

This returns an object of type L<Set::Array>, which you can use to iterate over the items output
by the parser.

See L</result()> just above for how to use this object.

=head1 FAQ

=head2 What is the format of stack items?

They are hashrefs, with these keys:

=over 4

=item o token

This is the token extracted from the command line.

Note: In the cases of file globbing and redirection of input from a file, these tokens are I<after>
expansion of such items.

=item o type

This is my classification of the type of token detected. The values taken by C<type> are:

=over 4

=item o action

=item o close_parenthesis

=item o command

=item o done

In this case, the C<token> will be the empty string.

=item o input_file

This is used for both explicit file names and for each file name produced by expanding globs.

=item o open_parenthesis

=item o output_file

=item o operator

=item o parameter

=back

=back

=head2 Why do you use pairs of states such as 'action' and 'action_1'?

The way L<Set::FA::Element> was designed, it will not move from a state to the same state when the
input matches. So, to trigger the entry or exit subs, I have to rock back-and-forth between 2
states which are more-or-less identical.

=head1 Trouble-shooting

=head2 Installation failure

I had a failure when installing the module on my laptop for the 1st time. The problem was that,
somehow, during the installation of L<Image::Magick>, root had become the owner of a directory
under the control of perlbrew. To fix this, I had to do:

	sudo chown ron:ron /home/ron/perl5/perlbrew/perls/perl-5.20.2/lib/site_perl/5.20.2/x86_64-linux/auto/Image/Magick

=head2 Regions specified as '@100000' are not supported

So, you must put the '@' at the end of the region:

	convert magick:logo -resize '10000@' wiz10000.png

=head2 Frame references are not supported

So, this won't work:

	convert 'images.gif[0]' image.png

=head1 See Also

L<Imager>

L<Image::Magick::Chart>

L<Image::Magick::PolyText>

L<Image::Magick::Tiler>

L<Set::Array>

L<Set::FA::Element>

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/Image-Magick-CommandParser>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Image::Magick::CommandParser>.

=head1 Author

C<Image::Magick::CommandParser> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2016.

My homepage: L<http://savage.net.au/>

=head1 Copyright

Australian copyright (c) 2016, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut

__DATA__
@@ built_in_images
granite
logo
netscape
rose
wizard

@@ built_in_patterns
bricks
checkerboard
circles
crosshatch
crosshatch30
crosshatch45
fishscales
gray0
gray5
gray10
gray15
gray20
gray25
gray30
gray35
gray40
gray45
gray50
gray55
gray60
gray65
gray70
gray75
gray80
gray85
gray90
gray95
gray100
hexagons
horizontal
horizontal2
horizontal3
horizontalsaw
hs_bdiagonal
hs_cross
hs_diagcross
hs_fdiagonal
hs_horizontal
hs_vertical
left30
left45
leftshingle
octagons
right30
right45
rightshingle
smallfishscales
vertical
vertical2
vertical3
verticalbricks
verticalleftshingle
verticalrightshingle
verticalsaw

@@ image_formats
3fr
aai
ai
art
arw
avi
avs
a
bgra
bgro
bgr
bmp2
bmp3
bmp
brf
b
cals
cal
canvas
caption
cin
cip
clip
cmyka
cmyk
cr2
crw
cur
cut
c
data
dcm
dcr
dcx
dds
dfont
dng
dot
dpx
dxt1
dxt5
epdf
epi
eps
eps2
eps3
epsf
epsi
erf
fax
fits
fractal
fts
g3
gif
gif87
gradient
gray
gv
g
h
hald
hdr
histogram
hrz
html
htm
icb
icon
ico
iiq
info
inline
ipl
isobrl
isobrl6
jng
jnx
jpeg
jpe
jpg
jps
json
k
k25
kdc
label
m
m2v
m4v
mac
magick
map
mask
matte
mat
mef
miff
mkv
mng
mono
mov
mp4
mpc
mpeg
mpg
mrw
msl
msvg
mtv
mvg
nef
nrw
null
orf
otb
otf
o
palm
pal
pam
pango
pattern
pbm
pcds
pcd
pcl
pct
pcx
pdb
pdfa
pdf
pef
pes
pfa
pfb
pfm
pgm
picon
pict
pix
pjpeg
plasma
png00
png24
png32
png48
png64
png8
png
pnm
ppm
preview
ps2
ps3
psb
psd
ps
pwp
radial-gradient
raf
ras
raw
rgba
rgbo
rgb
rgf
rla
rle
rmf
rw2
r
screenshot
scr
sct
sfw
sgi
shtml
sixel
six
sparse-color
sr2
srf
stegano
sun
svgz
svg
text
tga
thumbnail
tile
tim
ttc
ttf
txt
ubrl6
ubrl
uil
uyvy
vda
vicar
vid
viff
vips
vst
wbmp
wmv
wpg
x3f
xbm
xcf
xc
xpm
xps
xv
xwd
x
y
ycbcra
ycbcr
yuv

@@ pseudo_image_formats
canvas
caption
clip
clipboard
fractal
gradient
hald
histogram
label
map
mask
matte
null
pango
plasma
preview
print
scan
radial_gradient
scanx
screenshot
stegano
tile
unique
vid
win
x
