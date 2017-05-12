#!/usr/bin/perl -w
my $RCS_Id = '$Id: midi-tweak,v 1.3 2009/01/10 19:44:48 jv Exp $ ';

# Author          : Johan Vromans
# Created On      : Sun Jul 13 14:37:55 2008
# Last Modified By: Johan Vromans
# Last Modified On: Thu Apr 20 13:58:45 2017
# Update Count    : 53
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;

use MIDI::Tweaks ();

our $VERSION = $MIDI::Tweaks::VERSION;

# Package name.
my $my_package = 'Sciurix';
# Program name and version.
my $my_name = "midi-tweak";

################ Command line parameters ################

use Getopt::Long 2.13;

# Command line options.
my $action;			# what to do
my $int;			# intervals
my $value;			# constant value
my $ratio;			# ratio
my $verbose = 0;		# verbose processing
my $output;			# output file

# Development options (not shown with -help).
my $debug = 0;			# debugging
my $trace = 0;			# trace (show process)
my $test = 0;			# test mode.

################ Presets ################

app_options();

my $TMPDIR = $ENV{TMPDIR} || $ENV{TEMP} || '/usr/tmp';

################ The Process ################

use MIDI::Tweaks 0.04;
use File::Spec;
use File::Basename;

if ( @ARGV > 1 && !(defined($output) && -d $output && -w $output) ) {
  die("With multiple file arguments, --output must be used".
      " to designate an existing directory\n");
}

@ARGV = qw(-) unless @ARGV;

foreach my $file ( @ARGV ) {

    # Create a tweakable Opus.
    my $op = MIDI::Tweaks::Opus->new
      ( $file eq "-"
	? { from_handle => *STDIN{IO} }
        : { from_file   => $file      });

    # Perform action.
    $action->($op);

    # Write the Opus to disk.
    if ( defined($output) && $output ne "-" ) {
	my $result = $output;
	if ( -d $output ) {
	    $file = "stdout.midi" if $file eq "-";
	    $result = File::Spec->catfile($output, basename($file));
	}
	$op->write_to_file($result);
	warn("Wrote: $result\n") if $verbose;
    }
    else {
	$op->write_to_handle(*STDOUT{IO});
    }
}

exit 0;

################ Subroutines ################

sub change_pitch {
    die("Change pitch needs --int\n")
      if defined($value) || defined($ratio) || !defined($int);

    $_[0]->change_pitch({ int => $int });
}

sub change_tempo {
    die("Change tempo needs either --value or --ratio\n")
      if ( defined($value) + defined($ratio) != 1 )
	 || defined($int);

    $_[0]->change_tempo({ value => $value }) if defined $value;
    $_[0]->change_tempo({ ratio => $ratio }) if defined $ratio;
}

sub change_velocity {
    die("Change velocity needs either --value or --ratio\n")
      if ( defined($value) + defined($ratio) != 1 )
	 || defined($int);

    foreach ( $_[0]->tracks ) {
	$_->change_velocity({ value => $value }) if defined $value;
	$_->change_velocity({ ratio => $ratio }) if defined $ratio;
    }
}

sub change_volume {
    die("Change volume needs either --value or --ratio\n")
      if ( defined($value) + defined($ratio) != 1 )
	 || defined($int);

    foreach ( $_[0]->tracks ) {
	$_->change_volume({ value => $value }) if defined $value;
	$_->change_volume({ ratio => $ratio }) if defined $ratio;
    }
}

################ Subroutines ################

sub app_options {
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally

    my $act = sub {
	die("Unknown option: $_[0]\n") if $action;
    };

    if ( !GetOptions(pitch	=> sub { &$act; $action = \&change_pitch },
		     tempo	=> sub { &$act; $action = \&change_tempo },
		     volume	=> sub { &$act; $action = \&change_volume },
		     velocity	=> sub { &$act; $action = \&change_velocity },
		     'int=i'	=> \$int,
		     'ratio=f'  => \$ratio,
		     'value=i'	=> \$value,
		     'output=s'	=> \$output,
		     'ident'	=> \$ident,
		     'verbose'	=> \$verbose,
		     'trace'	=> \$trace,
		     'help|?'	=> \$help,
		     'debug'	=> \$debug,
		    ) or $help )
    {
	app_usage(2);
    }
    app_usage(2) unless $action;
    app_ident() if $ident;

    # Post-processing.
    $trace |= ($debug || $test);

}

sub app_ident {
    print STDERR ("This is $my_package [$my_name $VERSION]\n");
}

sub app_usage {
    my ($exit) = @_;
    app_ident();
    print STDERR <<EndOfUsage;
Usage: $0 { --pitch | --volume | --tempo | --velocity } [options] [file ...]
    --int=NN		with --pitch: number of intervals to transpose
    --value=NN		value to change to
    --ratio=N.NN	ratio to change with
    --output=XXX	output file
    --help		this message
    --ident		show identification
    --verbose		verbose information
EndOfUsage
    exit $exit if defined $exit && $exit != 0;
}

__END__

################ Documentation ################

=head1 NAME

midi-tweak - Tweak MIDI files

=head1 SYNOPSIS

  midi-tweak --pitch    --int=NN                      [file ...]
  midi-tweak --volume   { --ratio=N.NN | --value=NN } [file ...]
  midi-tweak --velocity { --ratio=N.NN | --value=NN } [file ...]
  midi-tweak --tempo    { --ratio=N.NN | --value=NN } [file ...]

=head1 OPTIONS

One of the following options must be supplied:

=over 8

=item B<--pitch>

Changes the pitch with I<NN> intervals. I<NN> may be negative.

This option requires B<--int> to be specified as well.

=item B<--volume>

Changes the volume of all channels to I<NN> or with ratio I<N.NN>.

This option requires either B<--value> or B<--ratio> to be specified
as well.

=item B<--velocity>

Changes the velocity of all notes to I<NN> or with ratio I<N.NN>.

This option requires either B<--value> or B<--ratio> to be specified
as well.

=item B<--tempo>

Changes the tempo I<NN> (beatsa per minute) or with ratio I<N.NN>.

This option requires either B<--value> or B<--ratio> to be specified
as well.

=back

The following options are optional unless required.

=over 8

=item B<--int=>I<NN>

The number of intervals (semitones) to transpose. This may be a
negative number. A fatal error will be generated when a transposed
pitch value would become less than zero, or greater than 127.

=item B<--value=>I<NN>

Change the selected property to the given value. For volume and
velocity the value must be between zero and 127, inclusive. For tempo,
the value gives the number of beats per minute.

=item B<--ratio=>I<N.NN>

Change the selected property with the given ratio. A fatal error will
be generated when the new value would be out of range.

=item B<--output=>I<dir-or-file>

Where the resultant file(s) must be stored. See below.

=item B<--help>

Print a brief help message and exits.

=item B<--ident>

Prints program identification.

=item B<--verbose>

More verbose information.

=item I<file>

Input file(s). Multiple files are possible. If no input files are
given, the program will read standard input. Alternatively, the
special file name C<-> can be used to designate standard input.

=back

=head1 DESCRIPTION

This program will read each input file, apply the selected MIDI::Tweak
function on the contents, and writes the modified file out to disk.

The B<--output> option controls where the modified files are written.

For single-file operation, the specified output option may be
omitted, or designate a file or existing directory. If omitted, the
modified data will be written to standard output. If specified, the
modified data will be written to that file or directory. The
special file name C<-> can be used to designate standard output.

For multi-file operation, the output option must designate an existing
directory, and the modified files will be written there.

If standard input is processed, the corresponding output file name
will be C<stdin.midi>.

=head1 AUTHOR

Johan Vromans, C<< <jv@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-midi-tweaks at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MIDI-Tweaks>. I will
be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

This program is part of the MIDI::Tweaks module.

You can find documentation for this module with the perldoc command.

    perldoc MIDI::Tweaks

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MIDI-Tweaks>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MIDI-Tweaks>

=item * Search CPAN

L<http://search.cpan.org/dist/MIDI-Tweaks>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 Johan Vromans, Squirrel Consultancy. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
