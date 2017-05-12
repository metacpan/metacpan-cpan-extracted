package Mac::SleepEvent;

use 5.008008;
use strict;
use warnings;
our $VERSION = '0.02';

=pod

=head1 NAME

Mac::SleepEvent - run Perl code on Mac OS X sleep and wake events

=head1 SYNOPSIS

  use Mac::SleepEvent;
  my $sn = Mac::SleepEvent->new(
   wake   => sub {print "Waking up...\n"},
   sleep  => sub {print "Going to sleep\n"},
   logout => sub {exit(0)},
  );
  $sn->listen;

=head1 DESCRIPTION

Mac::SleepEvent provides callbacks to run code when Mac OS X 
goes to sleep, wakes up, or logs out (same as shutdown). When
the listen method is called, the program will enter a run
loop, awaiting events from the OS.

=head1 CAVEATS

Mac::SleepEvent requires the Foundation module, which is only
included with the OS X system perl.

=head1 METHODS

=item listen

This will start the run loop.

=head1 AUTHORS

Lee Aylward E<lt>leedo@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2009 Lee Aylward.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

require XSLoader;
XSLoader::load('Mac::SleepEvent', $VERSION);

use Foundation;

PerlObjCBridge::preloadSelectors('SleepEvent');

sub new {
  my ($class, %args) = @_;
  my $self = {
    sleep_callback   => $args{'sleep'}  || sub {},
    wake_callback    => $args{'wake'}   || sub {},
    logout_callback  => $args{'logout'} || sub {},
  };
  _setup_appkit();
  return bless $self, $class;
}

sub _setup_appkit {
  my $path = NSString->stringWithCString_('/System/Library/Frameworks/AppKit.framework');
  my $appkit = NSBundle->alloc->init->initWithPath_($path);
  $appkit->load if $appkit;
  if ($appkit->isLoaded) {
    no strict 'refs';
    for my $class (qw(NSWorkspace)) {
      @{$class . '::ISA'} = 'PerlObjCBridge';
    } 
  }
  else {
    die "unable to load AppKit framework";
  }
}

sub listen {
  my $self = shift;
  NSWorkspace->sharedWorkspace->notificationCenter->addObserver_selector_name_object_(
    $self, 'asleep', 'NSWorkspaceWillSleepNotification', undef);
  NSWorkspace->sharedWorkspace->notificationCenter->addObserver_selector_name_object_(
    $self, 'awake', 'NSWorkspaceDidWakeNotification', undef);
  NSWorkspace->sharedWorkspace->notificationCenter->addObserver_selector_name_object_(
    $self, 'logout', 'NSWorkspaceWillPowerOffNotification', undef);
  NSRunLoop->currentRunLoop->run;
}

sub asleep {
  my $self = shift;
  $self->{sleep_callback}();
}

sub awake {
  my $self = shift;
  $self->{wake_callback}();
}

sub logout {
  my $self = shift;
  $self->{logout_callback}();
}

1;
