package Getopt::Helpful;

use strict;
use warnings;
use Carp;

use Storable qw(dclone);
our $VERSION = '0.04';

=pod

=head1 NAME

Getopt::Helpful - Integrated option hash / help messages.

=head1 STATE

This module is still under development, but is being publish on CPAN to
satisfy some code which depends on it.  The interface may change in a
future version and some of the functionality is not yet complete.

=head1 SYNOPSIS

This module provides methods which integrate help messages into a
Getopt::Long option spec.  This gathers documentation and declaration
into one place and allows you to utilize perl code to state the default
values of options in your online help messages (helping you utilize the
single-point-of-truth principle.)

Additionally, it provides DWIM methods (Get) which allow you to cut some
standard error-checking code from your scripts.  There is even a handy
usage() method which eliminates that silly block of code from the
beginning.

  #!/usr/bin/perl

  use warnings;
  use strict;

  use Getopt::Helpful;
  my $var1 = "default";
  my $req_arg;

  # declare this as 'our' or $main::verbose
  our $verbose = 0;

  # every option must be passed into the constructor...
  my $hopt = Getopt::Helpful->new(
    usage => 'CALLER <argument> [options]',
    [
      'var=s', \$default,
      '<setting>',
      "setting for \$var1 (default: '$var1')"
    ],
    [
      'a|arg', \$req_arg,
      '<argument>',
      'required argument'
    ],
    '+verbose',
    '+help',
    );

  # call GetOptions() behind the scenes (with error-checking)
  $hopt->Get();
  $req_arg or ($req_arg = shift);

  # usage() called with a message results in non-zero exit code
  $req_arg or $hopt->usage('missing required argument');
  $verbose and warn "doing stuff now\n";
  # now do stuff...

=head1 AUTHOR

Eric L. Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com

=head1 COPYRIGHT

This module is copyright (C) 2004-2006 by Eric L. Wilhelm.

=head1 LICENSE

This module is distributed under the same terms as Perl.  See the Perl
source package for details.

You may use this software under one of the following licenses:

  (1) GNU General Public License
    (found at http://www.gnu.org/copyleft/gpl.html)
  (2) Artistic License
    (found at http://www.perl.com/pub/language/misc/Artistic.html)

=head1 Modifications

The source code of this module is made freely available and
distributable under the GPL or Artistic License.  Modifications to and
use of this software must adhere to one of these licenses.  Changes to
the code should be noted as such and this notification (as well as the
above copyright information) must remain intact on all copies of the
code.

Additionally, while the author is actively developing this code,
notification of any intended changes or extensions would be most helpful
in avoiding repeated work for all parties involved.  Please contact the
author with any such development plans.

=head1 SEE ALSO

  Getopt::Long

=cut

########################################################################

=head1 Constructor

The helper object's values should be completely filled upon creation.
The new() function accepts the following three types of arguments:

=head2 new

The constructor is (currently) the only interface to add contents to the
$helper object.

=head3 Array references

This is the most generic form of option specification.  The first two
columns should be exactly the same as the hash that you would usually
use to feed Getopt::Long.  The second two columns are for printing
helpful information.

  #  spec        ,  ref  , example    ,  message
  [ 'a|argname=s', \$arg, '<argument>', 'a value for argument'],

=head3 Key => Value arguments

The key => value arguments let you specify values which control specific
features.

=over

=item usage

The 'usage' key will be used to create a customized usage message for
the usage() function.  The value may contain the string 'CALLER' which
will be replaced with the value of $0.  This is very helpful when you
have a program that behaves differently under different names (such as
when called through a symlink.)  If you specify a usage message, you
still need to request the '+help' builtin or include another option
which will trigger the $helper->usage() call.

  usage => 'CALLER inputfile outputfile [options]'

=back

=head3 Builtins

The following builtin options are available by using a '+<builtin>'
string instead of an array reference in the constructor:

  '+help'     ->  'h|help'     - calls main::usage() (also see usage())
  '+verbose'  ->  'v|verbose'  - increments $main::verbose
  '+debug'    ->  'd|debug'    - increments $main::debug

If you are using strict, you will want to declare these variables as
'our $verbose' and 'our $debug' (or initialize them as $main::verbose,
etc.)

=head3 Example

  our $debug = 0;
  my $helper = Getopt::Helpful->new(
    usage => 'CALLER <filename> [options]',
    ['choice=s', \$choice, '<choice>', 'your choice (default $choice)'],
    '+debug', # let's user toggle $main::debug
    '+help',  # use a builtin
    );

=cut
sub new {
	my $caller = shift;
	my $class = ref($caller) || $caller;
	my $self = {has => {}, opts => {}};
	bless($self, $class);
	my @rows = @_;
	my %builtins = $self->builtins();
	for(my $i = 0; $i < @rows; $i++) {
		my $row = $rows[$i];
		## warn "work at $row ($i)\n";
		# array refs are used unchecked...
		unless(ref($row) eq "ARRAY") {
			## warn "work at $row\n";
			if($row =~ s/^\+//) { # request for a builtin
				$builtins{$row} or
					croak("$row is not one of ",
						join(", ", sort(keys(%builtins))), "\n");
				# tracking of builtins which are used:
				$self->{has}{$row}++;
				$rows[$i] = $builtins{$row};
			}
			else { # allows "usage => $string," syntax
				# assume it is a config key
				my ($key, $val) = splice(@rows, $i, 2);
				## warn "val: $val\n";
				## warn "remainder: @rows\n";
				# XXX some kind of error-checking here?
				$self->{opts}{$key} = $val;
				$i--;
				next;
			}
		}
		# FIXME some tracking of user-defined options would be nice
	}
    $self->{table} = [@rows];
	return($self);
} # end subroutine new definition
########################################################################

=head1 DWIM

Do What I Mean methods.

=head2 Get

Calls GetOptions() with the options builtin to $helper (and optionally a
list of other helpers or a hash of plain-old options.)

If GetOptions() returns false, we die (hinting at how to get help if
'+help' was one of the options given to the constructor.)

  $helper->Get();
  # multiple helper objects:
  $helper->Get(@other_helpers);

  # mixed method (hash ref must come first)
  $helper->Get(\%opts, @other_helpers);

=cut
sub Get {
	my $self = shift;
	my @others = @_;
	#package main; # XXX what was the point of that?
	require Getopt::Long;
	my %opts = $self->opts();
	# XXX this area needs some test coverage, but is still waiting on
	# Getopt::Crazy to get done.
	foreach my $obj (@others) {
		eval {$obj->can('opts');};
		if(! $@) {
			# if it can('opts'), just do that
			%opts = (%opts, $obj->opts);
		}
		else {
			# it had better be a hash or it is useless here
			(ref($obj) eq ("HASH")) or croak("non-helpful object");
			%opts = (%opts, %$obj);
		}
	}
	# XXX should we save @ARGV? (probably so...)
	#     (it is required if we're going to make help behave properly,
	#     and for config-file processing.)
	@ARGV = $self->juggle_list(\@ARGV, \%opts);
	# XXX why bother with Getopt::Long at this point?
	unless(Getopt::Long::GetOptions(%opts)) {
		# does -h work?
		my $message = ($self->{has}{help} ? " (-h for help)" : "");
		die "invalid options$message\n";
	}
} # end subroutine Get definition
########################################################################

=head2 Get_from

Equivalent to Get(@extra), but treats @args as a localized @ARGV.

  $hopt->Get_from(\@args, @extra);

=cut
sub Get_from {
	my $self = shift;
	my ($args, @extra) = @_;
	local @ARGV = @$args;
	$self->Get(@extra);
	@$args = @ARGV;
} # end subroutine Get_from definition
########################################################################

=head2 ordered

Not finished yet.  The idea is to have one or more arguments that may be
just an ordered list on the command line so that your program could be
called as:

  program infile outfile --option "these are options"

or

  program -o outfile -i infile  --option "these are options"

Still working on what this should look like, whether it should die if
these things are unset, where it should set them (in the references?),
how to set default values, etc...

  $helper->ordered('first_option+r7qe', 'second_option');

=cut
sub ordered {
	my $self = shift;
	die "not finished";
} # end subroutine ordered definition
########################################################################

=head1 Methods

=head2 opts

Makes a hash of the first two columns of the table.  Better to use Get()
instead.

  GetOptions(
    $helper->opts()
    ) or die "invalid arguments (-h for help)\n";

=cut
sub opts {
	my $self = shift;
	my @other;
	if($self->{conf_table}) {
		@other = @{$self->{conf_table}};
	}
    my %hash = map({$_->[0] => $_->[1]} @{$self->{table}}, @other);
	# print "hash has keys: ", join(", ", keys(%hash)), "\n";
    return(%hash);
} # end subroutine opts definition
########################################################################

=head2 help_table

Returns a list of array refs of the first, third, and fourth columns of
the table (e.g. you don't need the variable refs for this.)

  my @table = $helper->help_table();

=cut
sub help_table {
	my $self = shift;
    return(map({[$_->[0], $_->[2], $_->[3]]} @{$self->{table}}));
} # end subroutine help_table definition
########################################################################

=head2 help_string

Returns join()ed string of the help table, with columnation and other
fancy stuff (though it could stand to be a bit fancier.)

  $helper->help_string();

If any arguments are passed, help will only be printed for the options
which match those arguments.

  $helper->help_string('foo', 'bar');

=cut
sub help_string {
	my $self = shift;
    # First, we switch the Getopt::Long string to something that is more
    # readable (also, duplicate rows for negatable options?)
    # Then, we must go through the entire table and calculate the lengths of
    # each column
	my %only;
	if(@_) {
		# s/// creates expected behavior?
		%only = map({$_ =~ s/^-+//; $_ => 1} @_);
	}
	my @stringtable;
	foreach my $row ($self->help_table) {
		my ($type, @var) = spec_parse($row->[0]);
		# print "got type ($type) with: ", join(", ", @var), "\n";
		# NOTE man pages seem to start at column 8 and allow 6 for arg
		# before breaking to a newline (follow suit?)
		my $item = $row->[1];
		defined($item) or ($item = '');
		unless(length($item)) {
			if(defined($type)) {
				my $auto = $row->[0];
				# just strip
				# XXX refactor this to use the longest of the @var
				$auto =~ s/^(.*\|)//;
				$auto =~ s/(?:=|:).*$//;
				$item = "<$auto>";
			}
		}
		my $help = $row->[2];
		## warn "var consists of ", join(" and ", map({"'$_'"} @var)), "\n";
		if(%only) {
			my $okay = 0;
			foreach my $var (@var) {
				my $check = $var;
				$check =~ s/^-*//;
				if($only{$check}) {
					$okay = 1;
					last;
				}
			}
			$okay or next;
		}
		push(@stringtable, [join(", ", @var), $item, $help]);
	}
	my $string = "\n" . " " x 2 . "options:\n";
	if(%only) {
		# XXX problems are caused because --help triggers immediate call
		# XXX to usage!  How to fix this? (think we have to return() or
		# XXX build a sane message about how we're helpless.)
		# @stringtable or die;
	}
	foreach my $row (@stringtable) {
		$string .= "    " . join(" ", @{$row}[0,1]) . "\n" .
			" " x 8 . $row->[2] . "\n\n";
	}

	return($string);
} # end subroutine help_string definition
########################################################################

=head1 Internal Methods

=head2 builtins

Returns a hash of builtin options.

  %builtins = $helper->builtins();

=cut
sub builtins {
	my $self = shift;
	# Q:  Why is this in a subroutine?
	# A:  To put $self in scope.

	# XXX add a BEGIN block which looks for optional modules?
	# (this would be the key to optionalizing dependencies for the
	# --with-config, etc right?)
	return(
		help => [
			'h|help',
				sub { (defined(&main::usage) ? main::usage() : $self->usage())},
				'', 'show this help message'
			],
		verbose => [
		# XXX nobody is checking whether v is already used!
		# going to have to implement that in Getopt::Crazy
			'v|verbose',
				sub {$main::verbose ||= 0;$main::verbose++;},
				'', 'be verbose'
			],
		debug => [
			'd|debug',
				sub {$main::debug ||= 0;$main::debug++;},
				'', 'enable debugging messages'
			],
		);
} # end subroutine builtins definition
########################################################################

=head2 usage

If main::usage() is not declared, this method will be called  instead
(when the -h or --help flag is used.)

This is (currently) only able to leverage the values of one $helper (the
one where '+help' was declared.)

  # print to stdout and exit with 0 status:
  $helper->usage();

  # print $message and minimal usage on stderr and exit with non-zero
  $helper->usage($message);

The usage message can be controlled by the usage => $string option of
the new() constructor.  If the usage string is empty, a default of
"CALLER" is used.  The following strings have special meaning in the
usage string.

=over

=item CALLER

If the optional usage string contains the (case-sensitive) string
"CALLER", this will be replaced by the calling program's ($0) basename
(this is useful when you may want to change the name of a program or
alias to it with symlinks.)

  usage => "CALLER <filename>"

=item Specific Help

If there is anything in @main::ARGV which matches one of the options
(less the leading dashes (or it would have already been stripped by
GetOptions)), only the help for those options will be returned.  What
this does is allow your users to say something like:

  program --help option-name

And get a compact help message for only that option.

=back

=cut
sub usage {
	my $self = shift;
	my $code = 0;
	my $usage = $self->{opts}{usage} || "CALLER";
	if(@_) {
		$code = 1;
		warn("\n   ABORT!  ", join("\n", @_) , "\n\n");
	}
	my $caller = $0;
	$caller =~ s#.*/##;
	$usage =~ s/CALLER/$caller/;
	my $string = "usage:\n $usage\n";
	my @args;
	if(@main::ARGV) {
		# 'program --help option-name' support
		$string = '';
		@args = @main::ARGV;
	}
	if($code) {
		warn "$string\n";
	}
	else {
		$string .= $self->help_string(@args);
		print "$string\n";
	}
	exit($code);
} # end subroutine usage definition
########################################################################

=head2 juggle_list

Juggles an argument list to put help at the front (all arguments before
-h or --help are removed.)

  @list = $self->juggle_list(\@list, \%opts);

=cut
sub juggle_list {
	# XXX note: this is just a workaround to the way that Getopt::Long works
	my $self = shift;
	my ($list, $opts) = @_;
	unless($opts->{'h|help'}) {
		return(@$list);
	}
	my @ret = ();
	for(my $i = $#$list; $i >= 0; $i--) {
		my $it = $list->[$i];
		unshift(@ret, $it);
		($it eq "-h") and last;
		($it eq "--help") and last;
	}
	return(@ret);
} # end subroutine juggle_list definition
########################################################################

=head1 Functions

=head2 spec_parse

Parses the specification according to a minimalistic usage of
Getopt::Long, returning an array of the variations and a type
character (if the =s, =f, or =i items were found.)

  ($type, @variations) = spec_parse($spec);

=cut
sub spec_parse {
	my $spec = shift;
	my @var;
	if($spec =~ s/(.*)\|//) {
		my $short = $1;
		$short = '-' . $short;
		push(@var, $short);
	}
	my $type = undef();
	my $negatable;
	if($spec =~ s/(?:=|:)(.*)$//) {
		$type = $1;
	}
	elsif($spec =~ s/!$//) {
		$negatable = 1;
	}
	push(@var, "--$spec");
	if($negatable) {
		push(@var, "--no$spec");
	}
	return($type, @var);
} # end subroutine spec_parse definition
########################################################################


1;
