package Email::Forward::Dispatch::Hooks;
use strict;
use warnings;
use utf8;

sub new { bless +{} ,+shift }

sub is_forward { die "you must override this method(If you wanna forward, return true)" }

sub forward    { die "you must override this method" }

1;

