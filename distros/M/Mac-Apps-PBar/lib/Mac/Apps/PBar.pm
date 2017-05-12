#!perl -w
package Mac::Apps::PBar;
require 5.00201;
use vars qw($VERSION @ISA @EXPORT $be $evt);
use strict;
no strict 'refs';
use Exporter;
use Carp;
use Mac::AppleEvents;
use Mac::Apps::Launch;
@ISA = qw(Exporter);
@EXPORT = ();
$VERSION = sprintf("%d.%02d", q$Revision: 1.30 $ =~ /(\d+)\.(\d+)/);
$be = '';


sub new {
	 my $pkg = shift;
	 my $title = shift;
	 my $ppos = shift;
	 $pkg = \*$pkg;
	 bless $pkg;

	 ${*$pkg}{'windobj'} = "obj{want:type(cwin),
	 from:null(), form:indx, seld:long(1)}";

	 ${*$pkg}{'progobj'} = "obj{want:type(PBar),
	 from:${*$pkg}{'windobj'}, form:indx, seld:long(1)}";
	 
	 $pkg->launch_pbar;

	 $evt = AEBuildAppleEvent('core', 'crel', typeApplSignature, 'PBar', 0, 0,
	 "kocl: type(cwin), prdt:{ pnam: Ò$titleÓ , ppos:[$ppos] }") or die $^E;
	 $pkg->runEvent($evt);

	 $pkg;
}

sub launch_pbar {
	LaunchApps(['PBar'],1);
}

sub data {
	my $pkg = shift;
	my $str = shift;
	my $dat = shift;
	if (!$dat && keys %$str) {
		my $s;
		foreach $s (keys %$str) {
			$pkg->_procData($s,$$str{$s});
		}
	} elsif ($str && $dat) {
		$pkg->_procData($str,$dat);
	}		
}

sub _procData {
	my $pkg = shift;
	my $str = shift;
	my $dat = shift;
	my $obj = "obj{want:type(prop), from:${*$pkg}{'progobj'},
	form:prop, seld:type($str)}";
	my $evt = AEBuildAppleEvent('core', 'setd', typeApplSignature,
	'PBar', 0, 0, "'----':$obj, data:Ò$datÓ ") or die $^E;
	$pkg->runEvent($evt)
}

sub close_window {
	my $pkg = shift;
	my $evt = AEBuildAppleEvent('aevt', 'quit', typeApplSignature,
  'PBar', 0, 0, "'----':''") or die $^E;
	$pkg->runEvent($evt)
}

sub runEvent {
	 my $pkg = shift;
	 my $evt = shift;
	#print AEPrint($evt), "\n";
	 my $rep = AESend($evt, kAEWaitReply) or die $^E;
	#print AEPrint($rep), "\n\n";
	 AEDisposeDesc $evt;
	 AEDisposeDesc $rep;

}


1;

__END__

=head1 NAME

Mac::Apps::PBar - An AppleEvent Module for Progress Bar 1.0.1

=head1 SYNOPSIS

	use Mac::Apps::PBar;
	$bar = Mac::Apps::PBar->new('FTP DOWNLOAD', '100, 50');
	$bar->data({
		Cap1=>'file: BigFile.tar.gz',
		Cap2=>'size: 1,230K',
		MinV=>'0',
		MaxV=>'1230',
	});
	for(0..10) {
		$n = $_*123;
		$bar->data(Valu, $n);
		sleep(1);
	}
	sleep(5);
	$bar->close_window;

=head1 DESCRIPTION

Progress Bar is a small AppleScriptable utility written by Gregory H. Dow. This
module, C<PBar.pm>, generates Apple Event calls using AEBuild in place of AppleScript.
Because the Apple Event Manager is not involved, Progress Bar updates more quickly.

In most applications the time taken to up date the Progress Bar must be kept to
a minimum. On this machine (68030 CPU) An C<AppleScript> update to the progress bar
takes about 0.72 seconds. Using C<PBar.pm> the time is reduced to 0.10 seconds;
a seven-fold improvement.

Progress Bar 1.0.1 is found by a search for the creator type C<PBar> and launched
automatically. To minimise the time taken for the search, C<Progress Bar 1.0.1> should
be kept in the same volume as C<PBar.pm>. 

=head2 CREATING A NEW PROGRESS BAR

Progress Bar 1.0.1 is launced and a new Progress bar created by:

	 $bar = Mac::Apps::PBar->new('NAME', 'xpos, ypos');

where the arguments to the C<new> constructor have the following meanings:

=over 4

=item First argument

is a string for the title bar of the Progress Bar window.

=item Second argument

is a string C<'xpos, ypos'> defining the position of the top left-hand corner 
of the window in pixels. The pair of numbers and the comma should be enclosed
in single quotes as shown.

=back

=head2 SENDING DATA

Values are sent to the C<Progress Bar> by the C<data> sub-routine using the
variable names in the C<aete resource> for each of the C<Progress Bar> properties.
There are five property values for the C<PBar> class. The syntax is:

	$bar->data('property', 'value')

or

	$bar->data({'property', 'value', 'property', 'value'})

The second method is suggested.

=over 4

=item B<Minimum value>  C<'MinV'>

This is the value of the displayed parameter corresponding to the origin of the
bar. Often it is zero, but may take other values (for instance a temperature bar
in degrees Fahrenheit might start at 32).

=item B<Maximum value>  C<'MaxV'>

This is the value corresponding to the full extent of the bar. It can take any
value, such as the size of a file in KB, or 100 for a percentage variable. Bar
increments are integers, hence discrimination is finer the larger the value of
C<MaxV>.

=item B<Current value>  C<'Valu'>

This is the value which sets the progress bar to the position corresponding to
the current value of the parameter displayed. The value must obviously lie
somewhere between C<MinV> and C<MaxV>.

=item B<Upper caption>  C<'Cap1'>

This string, immediately under the title bar, can be set to anything appropriate
for the application.

=item B<Lower caption>  C<'Cap2'>

The lower caption string can either be set to a constant value (e.g. C<File size = 1234K>)
or up-dated with the bar. For instance it might be appropriate to set C<'Cap2'>
as follows:

	$n = $max_value - $current_value;
	$bar->data({Cap2=>"remaining $n"});

Note the double quotes so that the value of C<$n> is interpolated.

It should be remembered however that it will take twice as long to update both
C<Cap2> and C<Valu> as just to update the bar C<Valu> by itself. In applications
where speed is of the essence, just the bar value C<Valu> should be changed.

=back

=head2 SEE ALSO

The following documents, which are relevant to AEBuild, may be of interest:

=over 4

=item AEGizmos_1.4.1

Written by Jens Peter Alfke this gives a description of AEBuild on which the
MacPerl AEBuildAppleEvent is based. Available from:

	ftp://dev.apple.com/
	devworld/Tool_Chest/Interapplication_Communication/
	AE_Tools_/AEGizmos_1.4.1

=item aete.convert

A fascinating MacPerl script by David C. Schooley which extracts the aete
resources from scriptable applications. It is an invaluable aid for the
construction ofAEBuild events. Available from:

	ftp://ftp.ee.gatech.edu/
	pub/mac/Widgets/
	aete.converter_1.1.sea.hqx

=item AE_Tracker

This a small control panel which allows some or all AE Events to be tracked at
various selectable levels of information. It is relatively difficult to decipher
the output but AE_Tracker can be helpful. Available from:

	ftp://ftp.amug.org/
	pub/amug/bbs-in-a-box/files/system7/a/
	aetracker2.0.sit.hqx

=item Inside Macintosh

Chapter 6 "Resolving and Creating Object Specifier Records" . The summary can
be obtained from:

	http://gemma.apple.com/
	dev/techsupport/insidemac/IAC/
	IAC-287.html

=item Progress Bar 1.0.1

Obtainable from Info-Mac archives as:

	info-mac/dev/osa/progress-bar-1.0.1.hqx

=back

References are valid as of May 1997.

=head1 AUTHORS

Chris Nandor F<E<lt>pudge@pobox.comE<gt>>
http://pudge.net/

Alan Fry F<E<lt>ajf@afco.demon.co.ukE<gt>>

Copyright (c) 1998 Chris Nandor and Alan Fry.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.  Please see the Perl Artistic License.

=head1 HISTORY

=over 4

=item Version 1.3, 3 January 1998

General cleanup.  Now requires MacPerl 5.1.4r4.

=item Version 1.2, 13 October 1997

Switched to Mac::Apps::Launch package.

=item Version 1.1, 16 September 1997

Put in the hashref methods to change multiple data in one call.

=back

=cut
