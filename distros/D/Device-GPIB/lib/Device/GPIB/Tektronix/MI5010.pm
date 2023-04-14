# MI5010.pm
# Perl module to control a Tektronix MI5010 and submodules by GPIB
#
# Fast responses to reads requires the MI5010 to be configured for LF/EOI
# with GPIB configuraiotn switch at rear

# Author: Mike McCauley (mikem@airspayce.com),
# Copyright (C) AirSpayce Pty Ltd
# $Id: $

package Device::GPIB::Tektronix::MI5010;
@ISA = qw(Device::GPIB::Tektronix);
use Device::GPIB::Tektronix;
use strict;

sub new($$$)
{
    my ($class, $device, $address) = @_;

    my $self = $class->SUPER::new($device, $address);

    if ($self->id() !~ /TEK\/MI5010/)
    {
	warn "Not a Tek MI5010 at $self->{Address}: $self->{Id}";
	return;
    }
    # Device specific error and Spoll strings
    # from page 5-1
    $self->{ErrorStrings} = {
	0   => 'No errors or events',
	101 => 'Command header error',
	102 => 'Header delimiter error',
	103 => 'Command argument error',
	104 => 'Argument delimiter error',
	105 => 'Nonnumeric argument (numeric expected)',
	106 => 'Missing argument',
	107 => 'Invalid message unit delimiter',
	203 => 'I/O buffers full, output dumped',
	204 => 'Settings conflict',
	205 => 'Argument out of range',
	206 => 'Group execute trigger ignored',
	220 => 'Select error: no card in that slot',
	341 => 'RAM error on card in slot 1',
	342 => 'RAM error on card in slot 2',
	343 => 'RAM error on card in slot 3',
	344 => 'RAM error on card in slot 4',
	345 => 'RAM error on card in slot 5',
	346 => 'RAM error on card in slot 6',
	347 => 'RAM error on card in slot 7',
	348 => 'RAM error on card in slot 8',
	349 => 'RAM error on card in slot 9',
	361 => 'ROM error on card in slot 1',
	362 => 'ROM error on card in slot 2',
	363 => 'ROM error on card in slot 3',
	364 => 'ROM error on card in slot 4',
	365 => 'ROM error on card in slot 5',
	366 => 'ROM error on card in slot 6',
	367 => 'ROM error on card in slot 7',
	368 => 'ROM error on card in slot 8',
	369 => 'ROM error on card in slot 9',
	401 => 'Power on',
	402 => 'Operation Complete',
	403 => 'User request',
	605 => 'Time-of-day clock no initialised and WAIT UNTI command was to be executed',
	741 => 'Power on errors on card in slot 1',
	742 => 'Power on errors on card in slot 2',
	743 => 'Power on errors on card in slot 3',
	744 => 'Power on errors on card in slot 4',
	745 => 'Power on errors on card in slot 5',
	746 => 'Power on errors on card in slot 6',
	747 => 'Power on errors on card in slot 7',
	748 => 'Power on errors on card in slot 8',
	749 => 'Power on errors on card in slot 9',
	771 => 'Hardware errors on card in slot 1',
	772 => 'Hardware errors on card in slot 2',
	773 => 'Hardware errors on card in slot 3',
	774 => 'Hardware errors on card in slot 4',
	775 => 'Hardware errors on card in slot 5',
	776 => 'Hardware errors on card in slot 6',
	777 => 'Hardware errors on card in slot 7',
	778 => 'Hardware errors on card in slot 8',
	779 => 'Hardware errors on card in slot 9',
	791 => 'Armed condition warning on card in slot 1',
	792 => 'Armed condition warning on card in slot 2',
	793 => 'Armed condition warning on card in slot 3',
	794 => 'Armed condition warning on card in slot 4',
	795 => 'Armed condition warning on card in slot 5',
	796 => 'Armed condition warning on card in slot 6',
	797 => 'Armed condition warning on card in slot 7',
	798 => 'Armed condition warning on card in slot 8',
	799 => 'Armed condition warning on card in slot 9',
    };
    $self->{SpollStrings} = {
	0  => 'No errors or events',
	97 => 'Command error',
	98 => 'Execution error',
	99 => 'Internal error',
	65 => 'Power on',
	66 => 'Operation Complete',
	67 => 'User request',
	102 => 'Time-of-day clock no initialised and WAIT UNTI command was to be executed',
	225 => 'Power on errors on card in slot x',
	226 => 'Hardware errors on card in slot x',
	192 => 'Armed condition warning on card in slot 1',
	193 => 'Armed condition warning on card in slot 2',
	194 => 'Armed condition warning on card in slot 3',
	195 => 'Armed condition warning on card in slot 4',
	196 => 'Armed condition warning on card in slot 5',
	197 => 'Armed condition warning on card in slot 6',
	198 => 'Armed condition warning on card in slot 7',
	199 => 'Armed condition warning on card in slot 8',
	200 => 'Armed condition warning on card in slot 9',
    };
    
    return $self;
}

# INit the time-of-day clock
sub setLocalTime($$$)
{
    my ($self, $time, $hertz) = @_;

    $time = time() unless defined $time;
    my ($sec, $min, $hour) = localtime($time);
    my $cmd = sprintf("TIME %02d:%02d:%02d", $hour, $min, $sec);
    $cmd .= ",$hertz" if defined $hertz;
    $self->send($cmd);
}

sub getTime($)
{
    my ($self) = @_;

    my $time = $self->getGeneric('TIME');
    if ($time =~ /(.*),(.*)/)
    {
	return ($1, $2);
    }
    return; # Error
}

sub setUntil($$)
{
    my ($self, $time) = @_;

    $time = time() unless defined $time;
    my ($sec, $min, $hour) = localtime($time);
    my $cmd = sprintf("UNTI %02d:%02d:%02d", $hour, $min, $sec);
    $self->send($cmd);
}

sub getUntil($)
{
    my ($self) = @_;
    return $self->getGeneric('UNTI');
}

sub select($$$)
{
    my ($self, $slot, $name) = @_;

    my $cmd = "SEL $slot";
    $cmd .= " $name" if defined $name;
    $self->send($cmd);
}

;
