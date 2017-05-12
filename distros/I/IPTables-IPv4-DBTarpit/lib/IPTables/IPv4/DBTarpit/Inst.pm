package IPTables::IPv4::DBTarpit::Inst;

use strict;
use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS @ISA);

$VERSION = do { my @r = (q$Revision: 0.06 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };
require Exporter;
@ISA = qw(Exporter);

@EXPORT_OK   = qw(
	soft_fail
	hard_fail
	ask_yesno
	ask_confirm
	ask_choice
	make_text
	cpfromto
	write_conf
	dialog
	verify
	osname
);
%EXPORT_TAGS = (all => \@EXPORT_OK);

=head1 NAME

IPTables::IPv4::DBTarpit::Inst - support for installation

=head1 SYNOPSIS

  use IPTables::IPv4::DBTarpit::Inst qw(
	soft_fail
	hard_fail
	ask_yesno
	ask_confirm
	ask_choice
	make_text
	cpfromto
	write_conf
	dialog
	verify
	osname
	:all
  }

  $zero = soft_fail($msg);
  (exits) hard_fail($msg);
  $rv = ask_yesno($question, $default);
  ask_confirm($description,$ref_to_setting);
  $option=ask_choice($question,["opt1","opt2"],"default");
  $text = make_text(\%hash);
  $rv = cpfromto($fromfile,$tofile);
  $rv = write_conf($file,$hashref,$prefix);
  dialog($name,$CONFIG,@defaults);
  verify($CONFIG);

=head1 DESCRIPTION

This module exports function used by the installation system scripts.

=over 4

=item * $zero = soft_fail($msg);

Prints out an error message and returns 0.  Usually used to soft-fail
a test like:

  return soft_fail("Couldn't find Postgres...") unless ...;

This is saves a few lines since the alternative would be:

  unless(...) {
    print "Couldn't find Postgres...\n";
    return 0;
  }

=cut

sub soft_fail {
    print join('', @_), "\n";
    return 0;
}

=item * (exits) hard_fail($msg);

Prints out an error message surrounded by lines of hash marks and
exits with code 1.

=cut

sub hard_fail {
    print "#" x 79, "\n\n", join('', @_), "\n", "#" x 79, "\n";
    exit 1;
}

=item * $rv = ask_yesno($question, $default);

Asks the user a yes/no question.  Default to $default if they just
press [return].  Returns 1 for a yes answer and 0 for no, where $default is
set to 1 or 0;

=cut

sub ask_yesno {
    my ($question, $default) = @_;
    my $tries = 1;
    local $| = 1;
    while (1) {	    
	print $question;
	my $answer = <STDIN>;
	chomp($answer);
	return $default if not length $answer;
	return 0 if $answer and $answer =~ /^no?$/i;
	return 1 if $answer =~ /^y(?:es)?$/i;
	print "Please answer \"yes\" or \"no\".\n";
	print "And quit screwing around.\n" if ++$tries > 3;
    }
}    


=item * ask_confirm($description,$ref_to_setting);

Asks the user to confirm a setting.  If they enter a new value asks
"are you sure."  Directly updates the setting and returns when done.

A default setting of "NONE" will force the user to enter a value.

=cut

sub ask_confirm {
    my ($desc, $ref) = @_;
    my $tries = 1;
    local $| = 1;
    while (1) {	    
	print $desc, " [", $$ref, "] ";
	my $answer = <STDIN>;
	chomp($answer);
	if (not length $answer or $answer eq $$ref) {
	    return unless $$ref eq 'NONE';
	    print "No default is available for this question, ",
		"please enter a value.\n";
	    next;
	}
	if (ask_yesno("Are you sure you want to use '$answer'? [yes] ", 1)) {
	    $$ref = $answer;
	    return;
	}
    }
}

=item * $option=ask_choice($question,["opt1","opt2"],"default");

Asks the user to choose from a list of options.  Returns the option
selected.

=cut

sub ask_choice {
    my ($desc, $choices, $default) = @_;
    my $tries = 1;
    local $| = 1;
    while (1) {	    
	print $desc, " [", $default, "] ";
	my $answer = <STDIN>;
	chomp($answer);
	$answer = lc $answer;
	return $default if not length $answer;
	return $answer if grep { $_ eq $answer } @$choices;
	print "Please choose from: ", join(', ', @$choices), "\n";
	print "And quit screwing around.\n" if ++$tries > 3;
    }
}

=item * $text = make_text(\%hash);

Returns a text string suitable of inclusion in a Makefile.

	i.e.

  %hash = (
	VALUE1	=> '/some/path',
	VALUE2	=> 'constant data',
	VALUE3	=> '$(OTHERVAR)',
  );

  returns a text string containing:

  VALUE1 = /some/path
  VALUE2 = constant data
  VALUE3 = $(OTHERVAR)
	
=cut

sub make_text {
  my $hp = shift;
  my $text = '';
  foreach(sort keys %$hp) {
    $text .= "$_ = $hp->{$_}\n";
  }
  return $text;
}

=item * $rv = cpfromto($fromfile,$tofile);

Copies a file "from" "to". Returns false on success. On failure it returns
the name of the offending file that could not be opened with the reason
append as " write" or " read".

=cut

sub cpfromto {
  my($from,$to) = @_;
  my $failed = '';
  if ( -e $from && open(R,$from)) {
    if (open(W,'>'.$to)) {
      while(<R>) {
	print W $_;
      }
      close R;
      close W;
    } else {
      close R;
      $failed = $to . ' write';
    }
  } else {
    $failed = $from . ' read';
  }
  return $failed;
}

=item * $rv = write_conf($file,$hashref,$prefix);

Writes the contents of $hashref to $file. Returns false on success, else
an error string describing the problem is returned. If $prefix is present
then any "key" written must start with $prefix".

  i.e. Takes a hash ref of the form below and writes a file.

  $hashref = {
	VALUE1	=> 'something',
	VALUE2	=> 'something else',
  };

  results are in a file that looks like:

# [file name]  date & time
# This file was automatically generated by [caller file name]
#
# Don't edit this file, edit [caller file name] instead.
#
my $CONFIG = {
	VALUE1	=>	'something',
	VALUE2	=>	'something else',
};
$CONFIG;

=cut

sub write_conf {
  my($file,$hp,$pre) = @_;
  return "argument 2 is not a hash reference" unless ref $hp;
  my $W = local *W;
  return "could not open $file for write"
	unless open($W,'>'.$file);

  $file =~ m|([^/]+)$|;
  my $whoami = (caller)[1];
  print $W qq|# $1  |, scalar localtime(), q|
#
# This configuration file was automatically generated by '|. $whoami .q|'
#
# Don't edit this file, edit '|. $whoami .q|' instead.
#
my $CONFIG = {
|;
  foreach(sort keys %$hp) {
    next if $pre && $_ !~ /^$pre/;
    print $W qq|\t'$_'\t=> '|. $hp->{$_},"',\n";
  }
  print $W "};\n";
  close $W;
  0;
}

=item * dialog($name,$CONFIG,@defaults);

Updates %$CONFIG by engaging in a dialog with the user about module $name 
(only used a prompt).  The user is asked to confirm
or enter a new value for the @default array.

  input:	$name,		text string
		$CONFIG,	hash ref
		@defaults

  $CONFIG = {
        VALUE1  => 'something',
        VALUE2  => 'something else',
  };

  @defaults = (
	# key		
	'VALUE1',  'new thing',	'prompt for new',
	'VALUEA',  'new A',	'prompt for A',
  }

  returns:	nothing

VALUE1 is overwritten and the user prompted for new. VALUE2 is left
untouched, VALUEA is prompted for A. %$CONFIG is updated.

For SpamCannibal users, warns if SPMCNBL_DAEMON_DIR and DBTP_DAEMON_DIR are
not the same.

=cut

my @errmsg = (
'The directories for daemon installation of',
'The database environment for installation of',
'The primary database names for installation of',
'The secondary database names for installation of',
);
my @spam_parms = qw(
	SPMCNBL_DAEMON_DIR
	SPMCNBL_ENVIRONMENT
	SPMCNBL_DB_TARPIT
	SPMCNBL_DB_ARCHIVE
);
my @dbtp_parms = qw(
	DBTP_DAEMON_DIR
	DBTP_ENVHOME_DIR
	DBTP_DB_TARPIT
	DBTP_DB_ARCHIVE
);

sub _warning {
  my($spam,$tarpit,$errmsg) = @_;
  return qq|$errmsg

    spamcannibal => $spam
    dbtarpit     => $tarpit

are not the same. This is usually not the 
case, check carefully before continuing.

|;
}

sub dialog {
  my($name,$CONFIG,@defaults) = @_;
# set up defaults if they are missing
  for (my $i = 0; $i < @defaults; $i += 3) {
    $CONFIG->{$defaults[$i]} = $defaults[$i+1] unless $CONFIG->{$defaults[$i]}
  }

  $_ = (grep /SPAMCANNIBAL/, @defaults) ? '' : q|
	For use with SpamCannibal, set
	the daemon install directory to:

	   /usr/local/spamcannibal/bin
|;
  print qq|
#####################################################
$name comes with a preselected set of defaults 
that should work for almost all installations. 
$_
|;
  foreach(0..$#spam_parms) {
    print _warning($CONFIG->{$spam_parms[$_]},$CONFIG->{$dbtp_parms[$_]},$errmsg[$_])
	if exists $CONFIG->{$spam_parms[$_]} &&
	$CONFIG->{$spam_parms[$_]} ne $CONFIG->{$dbtp_parms[$_]};
  }

  print q
|#####################################################

|;
  for (my $i = 0; $i < @defaults; $i += 3) {
    ask_confirm($defaults[$i+2],\$CONFIG->{$defaults[$i]});
  }
}

=item * verify($CONFIG);

Verifies that conflicting parameters are not present in the configuration.

  input:	$CONFIG	a hashref
  returns:	nothing

Aborts on invalid configuration.

=cut

sub verify {
  my $CONFIG = shift;
  my $fail = 0;
  foreach(0..$#spam_parms) {
    $fail = 1 if exists $CONFIG->{$spam_parms[$_]} && 
		 $CONFIG->{$spam_parms[$_]} ne $CONFIG->{$dbtp_parms[$_]} &&
		! ask_yesno(_warning($CONFIG->{$spam_parms[$_]},$CONFIG->{$dbtp_parms[$_]},$errmsg[$_]) . 
		  'do you wish to continue? [no]: ',0);
  }
  hard_fail('Exiting... you choose NO!') if $fail;
}

=item * $rv = osname();

Returns the operating system name in upper case letters. One or more spaces
in the OS name are replaced with underscore.

=back

=cut

sub osname {
  require POSIX;
  (my $osname = uc ((&POSIX::uname())[0])) =~ s/\s+/_/g;
  return $osname;
}

=head1 EXPORT

	none by default

=head1 EXPORT_OK

        soft_fail
        hard_fail
        ask_yesno
        ask_confirm
        ask_choice
	make_text
	cpfromto
	write_conf
	dialog
	verify
	osname
        :all

=head1 ACKNOWLEDGEMENTS

Portions of this module were originally written by Sam Tregar <stregar@about-inc.com> as part of the
Bricolage distribution. Nice work Sam, thanks!

=head1 AUTHORS

Sam Tregar <stregar@about-inc.com>
Michael Robinton <michael@bizsystems.com>

=head1 COPYRIGHT & LICENSE

    Copyright 2003, Michael Robinton <michael@bizsystems.com>

    Copyright (c) 2001-2003 About.com

    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are
    met:

    *   Redistributions of source code must retain the above copyright
        notice, this list of conditions and the following disclaimer.

    *   Redistributions in binary form must reproduce the above copyright
        notice, this list of conditions and the following disclaimer in the
        documentation and/or other materials provided with the distribution.

    *   Neither the name of the About.com nor the names of its contributors
        may be used to endorse or promote products derived from this
        software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
    IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
    TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
    PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR
    CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
    EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
    PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
    PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
    LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
    NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;
