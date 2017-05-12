# IUP application using LED specification from separate file

#XXX TODO - not sure what is the best way to use LED definition from perl (if it makes any sense at all)

use strict;
use warnings;

use IUP ':all';
use FindBin;

# callback handler
sub my_cb {
  IUP->Message("Test callback handler");
  return IUP_DEFAULT;
}

# callbacks - key names should correspond to element names used in LED definition
my $callbacks = {
  dlg => { K_ANY=>\&my_cb },
};

# hash for storing element references
my $elements = { };

# LED filename
my $led = "$FindBin::Bin/sample.led";
die "LED file '$led' does not exist\n" unless -f $led;
my $rv = IUP->LoadLED($led);
die "LED file '$led' load failed: $rv\n" if $rv;

# set callbacks
for my $name (keys %$callbacks) {
  for my $cb (keys %{$callbacks->{$name}}) {
    if (my $elem = IUP->GetByName($name)) {
      $elem->SetCallback($cb, $callbacks->{$name}->{$cb});
      #we have to keep reference to perl object - otherwise it gets completely DESTROYed
      $elements->{$name} = $elem;
    }
    else {
      warn "Warning: element name '$name' not loaded from LED definition\n";
    }
  }
}

# get the main window
my $dlg = IUP->GetByName('dlg') or die "Invalid main dialog name\n";

# start the application
$dlg->Show();
IUP->MainLoop();
