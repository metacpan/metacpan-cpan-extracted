package Getopt::Long::GUI;

# Copyright 2005, Sparta, Inc.
# All rights reserved.

use strict;
use Text::Wrap;
use Getopt::Long;
use QWizard;

our $VERSION="0.1";

require Exporter;

our @ISA = qw(Exporter Getopt::Long);
our @EXPORT = qw(GetOptions);
our $GUI_qw;
our $verbose;
our @ARGVsaved;

sub GetOptions(@) {


    # If the user didn't specify any arguments, we display a GUI for them.
    if ($#main::ARGV == -1) {
	
	# they called us with no options, offer them a GUI screen full
	my @names;
	my %names;
	my @qs;
	my ($st, $cb, @opts) = ((ref($_[0]) eq 'HASH') ?
				(1, 1, @_) : (0, 2, @_));
	my %GUI_info;
	for (my $i = $st; $i <= $#opts; $i += $cb) {
	    my ($spec, $desc, %rest);
	    if (ref($opts[$i]) eq 'ARRAY') {
		$spec = $opts[$i][0];
		$desc = $opts[$i][1];
		%rest = @{$opts[$i]}[2..$#{$opts[$i]}];
	    } elsif ($opts[$i] eq '') {
		push @qs,"";
		next;
	    } else {
		$spec = $opts[$i];
	    }

	    if ($spec =~ /^GUI:(.*)/) {
		my $guiname = $1;
		if ($guiname =~ /guionly/) {
		    push @qs, @{$opts[$i]}[1..$#{$opts[$i]}];
		} elsif ($guiname =~ /separator/) {
		    push @qs, { type => 'label', text => $opts[$i][1]};
		} else {
		    @{$GUI_info{$guiname}} = @{$opts[$i]}[1..$#{$opts[$i]}];
		}
		next;
	    }

	    # regexp stolen (and modified) from Getopt::Long
	    # XXX: copy copyright
	    $spec =~ m;^
		   # $1 = whole name pattern
                   (
                     # $2 = Option name
                     (\w+[-\w]* )
                     # $3 = first name, or "?"
                     (?: \| (\? | \w[-\w]* )? )?
                     # Alias names, or "?"
                     (?: \| (?: \? | \w[-\w]* )? )*
                   )?
                   # $4 = arguments
                   (
                     # Either modifiers ...
                     [!+]
                     |
                     # ... or a value/dest specification
                     [=:] [ionfs] [@%]?
                     |
                     # ... or an optional-with-default spec
                     : (?: -?\d+ | \+ ) [@%]?
                   )?
			  $;x;

	    # map option pieces into variables
	    my ($pat, $optname, $firstname, $args) = ($1, $2, $3, $4);


	    # calculate the option name to use from the list of names.
	    my $name = (length($optname) == 1 ? 
			((length($firstname) > 1) ? $firstname : $optname) :
			$optname);

	    # if no description, we copy the name and use that.
	    $desc = $name if (!$desc);

	    # remember the name of the option we're working on
	    push @names,$name;
	    $names{$name} = $args;

	    # calculate a default value based on the passed in hash
	    # ref or variable reference.
	    my $defval = (($cb == 1) ? 
			  (exists($_[0]{$optname}) ? $_[0]{$optname} : undef) :
			  $opts[$i+1]);

	    # Now constructure the needed GUI question
	    if ($rest{'question'}) {
		# if a QWizard question definition was passed to us, use that.
		if (ref($rest{'question'}) ne 'ARRAY') {
		    $rest{'question'} = [$rest{'question'}];
		}
		map {
		    $_->{'name'} = $name if ($_->{'name'} eq '');
		    $_->{'text'} = $desc if ($_->{'text'} eq '');
		    $_->{'default'} = $defval if ($_->{'default'} eq '');
		} @{$rest{'question'}};
		push @qs, @{$rest{'question'}};

	    } elsif ($desc =~ /^!GUI/) {
		# if the description was marked as not-for-the-GUI, don't
		# dispaly aynthing and skip it but remember the parameter name.
		push @qs, {type => 'hidden', name => $name, default => $defval};

	    } elsif (!$args || $args =~ /[!+]/) {
		# The option was a boolean flag: use a checkbox
		push @qs,
		  {
		   'text' => $desc,
		   'type' => 'checkbox',
		   values => [1, undef],
		   default => (($defval)?1:undef),
		   'name' => $name,
		  };
	    } elsif ($args =~ /i/) {
		# The option was an integer, use a entry with a forced
		# integer type check
		push @qs,
		  {
		   'text' => $desc,
		   'type' => 'text',
		   default => $defval,
		   'name' => $name,
		   check_value => (($rest{'required'}) ? 
				   \&qw_integer : \&qw_optional_integer),
		  };
	    } elsif ($args =~ /[sf]/) {
		# The option was a string or float, allow anything.
		# XXX: deal with floats seperately
		push @qs,
		  {
		   'text' => $desc,
		   'type' => 'text',
		   default => $defval,
		   'name' => $name,
		  };
	    } else {
		# In theory we probably shouldn't get here.  But fake
		# it if we do.
		push @qs,
		  {
		   'text' => $desc,
		   'type' => 'text',
		   default => $defval,
		   'name' => $name,
		  };
	    }

	    # if the required flag was set, force a requirement check.
	    if ($rest{'required'} && !exists($qs[$#qs]{'check_answer'})) {
		$qs[$#qs]{'check_value'} = \&qw_required_field;
	    }
	}

	# Prompt for remaining arguments (or don't if requested to
	# skip it).  Normally this would be stuff handled beyond the
	# realm of the Getopt processing like file-names, etc.
	if ($GUI_info{'nootherargs'}) {
	    push @qs, "", { type => 'hidden', name => '__otherargs' };
	} else {
	    push @qs, "", { type => 'text',
			    width => 80,
			    name => '__otherargs',
			    text => "Other Arguments" };
	}

	# construct the QWizard GUI primaries from the above information
	my $pris;

	# include other primary information passed to us
	if (exists($GUI_info{'otherprimaries'})) {
	    %$pris = @{$GUI_info{'otherprimaries'}};
	}

	# our master primary
	$pris->{'getopts'} =
	  {
	   questions => \@qs,
	   title => "Select options for $main::0",
	   actions => [[sub {
			    my $qw = shift;
			    for (my $i = 0; $i <= $#{$_[0]}; $i++) {
				if (qwparam($_[0][$i])) {
				    if (!$_[1]{$_[0][$i]} ||
					$_[1]{$_[0][$i]} =~ /[+!]/) {
					push @main::ARGV,
					  "--" . $_[0][$i];
				    } else {
					push @main::ARGV,
					  "--" . $_[0][$i],
					    qwparam($_[0][$i]);
				    }
				}
			    }
			    push @main::ARGV,
			      split(/\s+/,qwparam('__otherargs'));
			    return 'OK';
			}, \@names, \%names]],
	  };

	# add in an post_answers clauses to the master primary
	if ($GUI_info{'post_answers'}) {
	    @{$pris->{'getopts'}{'post_answers'}} =
	      @{$GUI_info{'post_answers'}};
	}

	# add in an actions clauses to the master primary
	if ($GUI_info{'actions'}) {
	    unshift @{$pris->{'getopts'}{'actions'}}, @{$GUI_info{'actions'}};
	}

	# Finally, construct the QWizard GUI class...
	my $qw = new QWizard(primaries => $pris,
			  no_confirm => 1,
			  title => $main::0);


	# ... remember it ...
	$GUI_qw = $qw;

	# ... and tell it to go
	$qw->magic('getopts', @{$GUI_info{'submodules'}});


	# ... if we aren't finished processing then exit.  This should
	# only happen if we're in a CGI script where we're not done yet.
	if (($qw->{'state'} != $QWizard::states{'ACTING'} &&
	     $qw->{'state'} != $QWizard::states{'FINISHED'}) ||
	    $qw->{'state'} == $QWizard::states{'CANCELED'}) {
	    # we're not done or have been cancelled!  exit!
	    exit;
	}

	
	# if there are any final hook routines to call, do so.
	if ($GUI_info{'hook_finished'}) {
	    foreach my $h (@{$GUI_info{'hook_finished'}}) {
		$h->();
	    }
	}
    }

    # map the options passed to us to ones that are compliant with
    # Getopt::Long
    my @opts = MapToGetoptLong(@_);

    # save the arguments we contstructed for future use.
    @ARGVsaved = @main::ARGV;

    # display the results to the user if verbose was requested.
    if ($verbose) {
	print STDERR "passing $#main::ARGV args to Getopt::Long: ",
	  join(",",@main::ARGV),"\n";
    }

    # finally, pass on to the original Getopt::Long routine.
    return Getopt::Long::GetOptions(@opts);
}

sub MapToGetoptLong {
    my ($st, $cb, @opts) = ((ref($_[0]) eq 'HASH') 
			    ? (1, 1, $_[0]) : (0, 2));
    for (my $i = $st; $i <= $#_; $i += $cb) {
	if ($_[$i]) {
	    next if (ref($_[$i]) eq 'ARRAY' && $_[$i][0] =~ /^GUI:/);
	    push @opts, ((ref($_[$i]) eq 'ARRAY') ? $_[$i][0] : $_[$i]);
	    push @opts, $_[$i+1] if ($cb == 2);
	}
    }
    return @opts;
}

=pod

=head1 NAME

Getopt::Long::GUI

=head1 SYNOPSIS

  use Getopt::Long::GUI;

  GetOptions(\%opts,
	     ["h|help", "Show help for command line options"],
	     ["some-flag=s", "perform some flag based on a value"]);

  # or

  GetOptions(["h|help", "Show help for command line options"] => \$help,
	     ["some-flag=s", "perform some flag based on a value"] => \$flag);


=head1 DESCRIPTION

This module is a wrapper around Getopt::Long that extends the value of
the originial Getopt::Long module to add a simple graphical user
interface option screen if no arguments are passed to the program.
Thus, the arguments to actually use are built based on the results of
the user interface. If arguments were passed to the program, the user
interface is not shown and the program executes as it normally would
and acts just as if Getopt::Long::GetOptions had been called instead.

=head1 USAGE

The Getopt::Long::GUI module works identically to the Getopt::Long
module, but does offer a few extra features.

=head2 Option format:

Option strings passed should be formatted in one of the following ways:

=over

=item Empty String

Empty strings are ignored by the non-GUI version of the command, but
are treated as vertical separators between questions when displaying
the GUI screen.

=item Standard flag specification string

   EG: "some-flag|optional-flag=s"

This is the standard method by which Getopt::Long does things and is
merely treated the same way here.  In this case, the text presented to
the user screen will be the first name in the list ("some-flag") in
the above option.  The type of wdget displayed with the text will
depend on the optional =s/i/whatever flag and will be either a
checkbox, entry box, ...

=item Array Reference

   EG: ["some-flag|optional-flag=s", 'Prompt text', OTHER],

The values passed in this array are as follows:

=over

=item 0: Standard flag specification string

Same as always, and as above.

=item 1: Prompt text about flag

The help text that should be shown to the user in the graphical
interface.  In the example above rather than "some-flag" being shown,
"Prompt text" will be shown next to the widget instead.

If the prompt text is equal to "!GUI" then this option will not be
displayed (automatically at least) within the GUI.

=item 2...: OTHER options

=over

=item required => 1

Forces a screen option to be filled out by the user.

=back

[others TBD]

=back

=back

=head1 Special Flag Names

Flags that start with GUI: are not passed to the normal Getopt::Long
routines and are instead for internal GUI digestion only.  If the GUI
screen is going to be displayed (remember: the user didn't specify any
options), these extra options control how the GUI behaves.

=over

=item GUI:guionly

  EG:  ['GUI:guionly', { type => 'checkbox', name => 'myguiflag'}]

Specifies a valid QWizard question(s) to only be shown when the gui is
displayed, and the specification is ignored during normal command line
usage.

=item GUI:separator

  EG:  ['GUI:separator', 'Task specific options:']

Inserts a label above a set of options to identify them as a group.

=item GUI:nootherargs

  EG:  ['GUI:nootherargs', 1]

Normally the GUI screen shows a "Other Arguments:" option at the
bottom of the main GUI screen to allow users to entry additional flags
(needed for file names, etc, and other non-option arguments to be
passed).  If you're going to handle the additional arguments yourself
in some way (using either some GUI:guionly or (GUI:otherprimaries and
GUI:submodules) flags), then you should specify this so the other
arguments field is not shown.  You're expected, in your self-handling
code, to set the __otherargs QWizard parameter to the final arguments
that should be passed on.

=item GUI:otherprimaries

  EG:  ['GUI:otherprimaries', primaryname => 
                              { title => '...', questions => [...] }]

Defines other primaries to be added to the QWizard primary set.

=item GUI:submodules

  EG:  ['GUI:submodules', 'primaryname']

Defines a list of other primaries that should be called after the
initial one.

=item GUI:post_answers

  EG:  ['GUI:post_actions', sub { do_something(); }]

Defines an option for QWizard post_answers subroutines to run.

=item GUI:actions

  EG:  ['GUI:post_actions', sub { do_something(); }]

Defines an option for QWizard actions subroutines to run.

=item GUI:actions

  EG:  ['GUI:hook_finished', sub { do_something(); }]

Defines subroutine(s) to be called after the GUI has completely finished.

=item GUI:

=back

=head1 PORTABILITY

If programs desire to not require this module, the following code
snippit can be used instead which will not fail even if this module is
not available.  To be used this way, the LocalGetOptions and
LocalOptionsMap functions should be copied to your perl script.

  LocalGetOptions(\%opts,
	          ["h|help", "Show help for command line options"],
	          ["some-flag=s", "perform some flag based on a value"]);

  sub LocalGetOptions {
      if ($#ARGV == -1 && eval {require Getopt::Long::GUI;}) {
  	import Getopt::Long::GUI;
  	return GetOptions(@_);
      } else {
  	require Getopt::Long;
  	import Getopt::Long;
      }
      GetOptions(LocalOptionsMap(@_));
  }

  sub LocalOptionsMap {
      my ($st, $cb, @opts) = ((ref($_[0]) eq 'HASH') 
  			    ? (1, 1, $_[0]) : (0, 2));
      for (my $i = $st; $i <= $#_; $i += $cb) {
  	if ($_[$i]) {
	    next if (ref($_[$i]) eq 'ARRAY' && $_[$i][0] =~ /^GUI:/);
  	    push @opts, ((ref($_[$i]) eq 'ARRAY') ? $_[$i][0] : $_[$i]);
  	    push @opts, $_[$i+1] if ($cb == 2);
  	}
      }
      return @opts;
  }

=cut

1;
