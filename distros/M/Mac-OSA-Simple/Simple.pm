package Mac::OSA::Simple;

use strict;
use vars qw(
	$VERSION $REVISION @ISA
	@EXPORT @EXPORT_OK %EXPORT_TAGS
	%ScriptComponents
);

use Carp;
use Exporter;

use File::Basename;
use MacPerl ();
use Mac::AppleEvents::Simple ':all';
use Mac::Components;
use Mac::Memory;
use Mac::OSA 1.03;
use Mac::Processes;
use Mac::Resources 1.03;

@ISA = qw(Exporter);
@EXPORT = qw(
	frontier applescript osa_script
	compile_frontier compile_applescript compile_osa_script
	load_osa_script %ScriptComponents
);
@EXPORT_OK = @Mac::OSA::EXPORT;
%EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

$REVISION = '$Id: Simple.pm,v 1.8 2003/11/09 18:38:21 pudge Exp $';
$VERSION = '1.09';

tie %ScriptComponents, 'Mac::OSA::Simple::Components';

sub frontier            { _doscript('LAND', $_[0])          }
sub applescript         { _doscript('ascr', $_[0])          }
sub osa_script          { _doscript(@_[0, 1])               }

sub compile_frontier    { _compile_script('LAND', $_[0])    }
sub compile_applescript { _compile_script('ascr', $_[0])    }
sub compile_osa_script  { _compile_script(@_[0, 1])         }

sub load_osa_script     { _load_script(@_[0, 1, 2])         }

sub execute {
	my($self) = @_;
	my $value = my $return = '';

	$value = OSAExecute($self->{COMP}, $self->{ID}, 0, 0)
		or _mydie() && return;

	if ($value) {
		$return = OSADisplay($self->{COMP}, $value, typeChar, 0)
			or _mydie() && return;
		OSADispose($self->{COMP}, $value);
	}

	$self->{RETURN} = $return && $return->isa('AEDesc')
        	? $return->get : 1;

	AEDisposeDesc($return) if $return;

	return $self->{RETURN};
}

{ my $target; # define only once
sub call {
	my($self, $cid, $eid, $args, $mode) = @_;
	$mode = kOSAModeNull unless defined $mode;

	$target ||= { typeProcessSerialNumber() => kCurrentProcess() };

	my $format;
	if (ref($args) eq 'ARRAY') { # no record support yet
		$format = '[';
		$format .= join(', ', map { 'TEXT(@)' } 1 .. @$args);
		$format .= ']';
	} elsif (! ref($args)) {
		$format = 'TEXT(@)';
		$args = [ $args ];
	} else {
		carp "Only scalars and lists supported in call()";
	}

	my $event = build_event($cid, $eid, $target, "'----':$format", @$args);

	$event->{REP} = OSADoEvent(
		$self->{COMP}, $event->{EVT}, $self->{ID}, $mode
	) or _mydie() && return;

	return $event->get;
}
}

sub dispose {
	my($self) = @_;

	if ($self->{ID} && $self->{COMP}) {
		OSADispose($self->{COMP}, $self->{ID});
		delete $self->{ID};
		delete $self->{COMP};
	}

	if ($self->{SCRIPT}) {
		AEDisposeDesc($self->{SCRIPT});
		delete $self->{SCRIPT};
	}

	return 1;
}

sub save {
	my($self, $file, $resid, $name) = @_;

	my $scpt = $self->compiled or _mydie() && return;
	$self->{FILETYPE} ||= $^O eq 'MacOS' ? 'rsrc' : 'data';

	my $res;
	if (($self->{FILETYPE} && $self->{FILETYPE} eq 'rsrc') || (!$self->{FILETYPE} && $^O eq 'MacOS')) {
		$resid = defined($resid) ? $resid : ($self->{RESID} || 128);
		$name  = defined($name)  ? $name  : 'MacPerl Script';

		unless ($res = FSpOpenResFile($file, 0)) {
			FSpCreateResFile($file, 'ToyS', 'osas', 0) or _mydie() && return;
			$res = FSpOpenResFile($file, 0) or _mydie() && return;
		}

		my $foo = Get1Resource(kOSAScriptResourceType, $resid);
		if (defined $foo) {
			RemoveResource($foo) or _mydie() && return;
		}

		AddResource($scpt, kOSAScriptResourceType, $resid, $name)
			or _mydie() && return;

		UpdateResFile($res) or _mydie() && return;
		CloseResFile($res);

	} else {
		local $\;
		open my $fh, '>', $file;
		print $fh $scpt->get;
		close $fh;
		MacPerl::SetFileInfo('ToyS', 'osas', $file);
	}

	return 1;
}

sub source {
	my($self, $source, $text) = @_;
    
	$source = OSAGetSource($self->{COMP}, $self->{ID}, typeChar)
		or _mydie() && return;

	$self->{SOURCE} = $source && $source->isa('AEDesc')
        	? $source->get : '';

	AEDisposeDesc($source);

	$self->{SOURCE} =~ s/\015/\n/g unless $^O eq 'MacOS';
	$self->{SOURCE};
}

sub compiled {
	my($self, $script) = @_;

	$script = OSAStore($self->{COMP}, $self->{ID},
		typeOSAGenericStorage, 0)
		or _mydie() && return;

	push @{$self->{AEDESC}}, $script;

	return $script->data;
}

sub _doscript {
	my($c, $text) = @_;

	my $self = _compile_script($c, $text) or _mydie() && return;
	my $return = $self->execute;
	_mydie() && return unless defined $return;
	$self->dispose;

	return $return;
}

sub _load_script {
	my($scpt, $resid, $xtra) = @_;

	my $c = kOSAGenericScriptingComponentSubtype;
	my $self = bless {
		COMP => $ScriptComponents{$c},
		TYPE => $c
	}, __PACKAGE__;

	my $res;
	if (!ref $scpt) {
		# we used to support three-arg format; use third arg if supplied
		$resid = defined($xtra) ? $xtra
			: defined($resid) && $resid != 1 ? $resid
			: 128;
		my $file = $scpt;
		undef $scpt;

		if ($^O eq 'MacOS') {
			$res = FSpOpenResFile($file, 0) or _mydie() && return;
			$scpt = Get1Resource(kOSAScriptResourceType, $resid)
				or _mydie() && return;
		} else {
			$res = FSpOpenResFile($file, 0);
			$scpt = Get1Resource(kOSAScriptResourceType, $resid) if $res;

			if (!$scpt) {
				open my $fh, '<', $file or _mydie() && return;
				$scpt = new Handle do {
					local $/;
					<$fh>;
				};
			}
		}

		if ($res) {
			$self->{FILETYPE} = 'rsrc';
			$self->{RESID}    = $resid;
		} else {
			$self->{FILETYPE} = 'data';
			$self->{RESID}    = undef;
		}
	}

	my $desc = AECreateDesc(typeOSAGenericStorage, $scpt->get)
		or _mydie() && return;

	$self->{ID} = OSALoad($self->{COMP}, $desc, 0)
		or _mydie() && return;

	AEDisposeDesc($desc) if $desc;
	CloseResFile($res) if $res;

	return $self;
}

sub _compile_script {
	my($c, $text) = @_;

	my $comp = $ScriptComponents{$c} or return;

	my $self = bless {
		COMP   => $comp,
        	SOURCE => $text,
        	TYPE   => $c
        }, __PACKAGE__;

	return $self->_compile;
}

sub _compile {
	my($self) = @_;

	$self->{SCRIPT} = AECreateDesc(typeChar, $self->{SOURCE})
		or _mydie() && return;

	$self->{ID} = OSACompile($self->{COMP}, $self->{SCRIPT}, kOSAModeCompileIntoContext)
		or _mydie() && return;

	return $self;
}

sub _mydie {
	# maybe do something here some day
	1;
}

sub DESTROY {
	my($self) = @_;

	if (exists($self->{ID}) || exists($self->{SCRIPT})) {
		$self->dispose;
	}

	if ($self->{AEDESC}) {
		for (@{$self->{AEDESC}}) {
			AEDisposeDesc($_) if $_;
		}
	}

	undef $self;
}

END {
	foreach my $comp (keys %ScriptComponents) {
		CloseComponent($ScriptComponents{$comp});
	}
}

package Mac::OSA::Simple::Components;

BEGIN {
	use Carp;
	use Tie::Hash ();
	use Mac::Components;
	use Mac::OSA;
	use vars qw(@ISA);
	@ISA = qw(Tie::StdHash);
}

# { # if we don't do this, we fail if we fork ... weird
# 	my $x = 0;
# 	1 while ($x = FindNextComponent($x, kOSAComponentType));
# }
# 
# sub FETCH {
# 	my($self, $comp) = @_;
# 	if ($self->{pid}) {
# 		if ($self->{pid} != $$) {
# 			delete @{$self}{keys %$self};
# 		}
# 	} else {
# 		$self->{pid} = $$;
# 	}

sub FETCH {
	my($self, $comp) = @_;

	my $c = $comp;
	if ($comp eq kOSAGenericScriptingComponentSubtype) {
		$c = 0;
		$c++ while exists $self->{$c};  # get unique key
	}

	if (!$self->{$c}) {
		my $comp = OpenDefaultComponent(kOSAComponentType, $comp)
			or Mac::OSA::Simple::_mydie() && return;
		$self->{$c} = $comp;
	}
	$self->{$c};
}

package Mac::OSA::Simple;  # odd "fix" for AutoSplit

1;

__END__

=head1 NAME

Mac::OSA::Simple - Simple access to Mac::OSA

=head1 SYNOPSIS

    #!perl -wl
    use Mac::OSA::Simple;
    osa_script('LAND', <<'EOS');
      dialog.getInt ("Duration?",@examples.duration);
      dialog.getInt ("Amplitude?",@examples.amplitude);
      dialog.getInt ("Frequency?",@examples.frequency);
      speaker.sound (examples.duration, examples.amplitude,
          examples.frequency)
    EOS

    print frontier('clock.now()');

    applescript('beep 3');

=head1 DESCRIPTION

You can access scripting components via the tied hash
C<%ScriptComponents> which is automatically exported.  Components are
only opened if they have not been already, and are closed when the
program exits.  It is normally not necessary to use this hash, as it is
accessed internally when needed.

Also usually not necessary, but possibly useful, are all the functions
and constants from Mac::OSA, available with the EXPORT_TAG "all".

B<NOTE>: Examples below show use of $^E.  On Mac OS, this will return the
signed Mac OS error number in numeric context, and the Mac OS error message
in string context.  But on Mac OS X, $^E support is unimplemented.  $! and $^E
will both return the I<unsigned> error number.  You can get the correct error
number by adding 0 (such as C<$! + 0>), and you can use L<Mac::Errors> to get
the error text (this will also work under Mac OS):

	use Mac::Errors '$MacError';
	my $res = FSpOpenResFile($file, 0) or die $MacError;

See L<Mac::Errors> on the CPAN for more information.


=head2 Functions

The following functions are automatically exported.

=over 4

=item osa_script(SCRIPTCOMPONENT, SCRIPTTEXT)

Compiles and executes SCRIPTTEXT, using four-char SCRIPTCOMPONENT.
Component is opened and closed behind the scenes, and SCRIPTTEXT
is compiled, executed, and disposed of behind the scenes.  If
the script returns data, the function returns the data, else it
returns 1 or undef on failure.

=item applescript(SCRIPTTEXT)

=item frontier(SCRIPTTEXT)

Same thing as C<osa_script> with SCRIPTCOMPONENT already set
('ascr' for AppleScript, 'LAND' for Frontier).


=item compile_osa_script(SCRIPTCOMPONENT, SCRIPTTEXT)

Compiles script as C<osa_script> above, but does not execute it.
Returns Mac::OSA::Simple object.  See L<"Methods"> for more information.

=item compile_applescript(SCRIPTTEXT)

=item compile_frontier(SCRIPTTEXT)

Same thing as C<compile_osa_script> with SCRIPTCOMPONENT already set.


=item load_osa_script(HANDLE)

=item load_osa_script(FILE [, RESOURCEID])

In the first form, load compiled OSA script using data in Handle
(same data as returned by C<compiled> method; see L<Mac::Memory>).
In the second form, gets
script from FILE using RESOURCEID (which is 128 by default).  Returns
Mac::OSA::Simple object.

B<NOTE>: Because of a change in the parameters for this function,
a RESOURCEID value of 1 will not be recognized as a resource ID
(the old parameter list had a value of 1 mean "load from file").
If you need to use a resource ID of 1, pass it in as both the
second and third parameter.  Sorry.  Why would you use 1 for
a resource ID, anyway??

Example:

    use Mac::OSA::Simple qw(:all);
    use Mac::Resources;
    $res = FSpOpenResFile($file, 0) or die $^E;
    $scpt = Get1Resource(kOSAScriptResourceType, 128)
        or die $^E;
    $osa = load_osa_script($scpt);
    $osa->execute;
    CloseResFile($res);

Same thing:

    use Mac::OSA::Simple;
    $osa = load_osa_script($file);
    $osa->execute;

Another example:

    use Mac::OSA::Simple;
    $osa1 = compile_applescript('return "foo"');
    print $osa1->execute;

    # make copy of script in $osa1 and execute it
    $osa2 = load_osa_script($osa1->compiled);
    print $osa2->execute;

See L<"Methods"> for more information.

=back


=head2 Methods

This section describes methods for use on objects returned by
C<compile_osa_script> and its related functions and C<load_osa_script>.

=over 4

=item compiled

Returns a Handle containing the raw compiled form of the script
(see L<Mac::Memory>).

=item dispose

Disposes of OSA script.  Done automatically if not called explicitly.

=item execute

Executes script.  Can be executed more than once.

=item call(CLASS, EVENT, ARGS, MODE)

Calls a handler in the script, identified by CLASS and EVENT IDs.
Can be executed more than once.

ARGS can be either a scalar or an arrayref.  MODE can be any combination
of modes from L<Mac::OSA> listed under the "Mode flags" constants.

Here is an example script:

	on \xC7event abcd1234E\xC8 (filename)
	    tell app "Finder"
	       return [URL of file filename, creator type of file filename]
	    end
	end

"abcd" is the CLASS ID, and "1234" is the EVENT ID.  They can be anything, as
long as they don't conflict with something else.  The characters \xC7 and \xC8
can be literal if in the Mac Roman charset, otherwise just use the values like
above.

Parameters are passed to handlers as named values, like "(filename)".  Multiple
parameters can be passed as an arrayref in ARGS, and a list of values is returned:

	my $script = load_osa_script($path_to_script);
	my($url, $creator) = $script->call(qw[abcd 1234], "my file");

You must pass in the same number of variables in ARGS that are expected by the
handler.


=item save(FILE [, ID [, NAME]])

Saves script in FILE with ID and NAME.  ID defaults to 128, NAME
defaults to "MacPerl Script".  DANGEROUS!  Will overwrite
existing resource or file!

Saves to the data fork instead on Mac OS X, unless an ID is provided.

The context used to load a script from disk (resource fork vs. data fork,
resource file vs. data file) will be used to save the script back, if
applicable, so the file's format will be preserved.

=item source

Returns text of script source, if available.

=back


=head2 Script Context

Scripts compiled by this module now compile scripts as
I<script contexts>, which, in part, means they can maintain state
information.  For example:

	use Mac::OSA::Simple;
	my $script = compile_applescript(<<'SCRIPT') or die $^E;
	property foo: 20
	set foo to foo + 1
	SCRIPT
	print $script->execute, "\n" for 0..2;

Returns:
	21
	22
	23

Whereas in previous versions of this module, it would have returned:
	21
	21
	21

For a script that on disk, to maintain state information
in the saved version, remember to call C<$script->save(LIST)>.


=head1 TODO

Work on error handling.  We don't want to die when a toolbox function
fails.  We'd rather return undef and have the user check $^E.

Should C<frontier> and/or C<osa_script('LAND', $script)> launch
Frontier if it is not running?

Add C<run_osa_script>, which could take script data in a Handle or
a path to a script (as with C<load_osa_script>.

Should C<save> have optional parameter for overwriting resource?

Should C<run_osa_script> and C<execute> take arguments?  If so, how?


=head1 AUTHOR

Chris Nandor E<lt>pudge@pobox.comE<gt>, http://pudge.net/

Copyright (c) 1998-2003 Chris Nandor.  All rights reserved.  This program
is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

Mac::OSA, Mac::AppleEvents, Mac::AppleEvents::Simple, macperlcat.

=cut
