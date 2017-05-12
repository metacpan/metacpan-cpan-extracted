# -*- perl -*-
#

package Mail::IspMailGate::Filter::Dummy;

require 5.004;
use strict;

require Mail::IspMailGate::Filter;

@::Mail::IspMailGate::Filter::Dummy::ISA = qw(Mail::IspMailGate::Filter);

sub setSign { "ispMailGate-Dummy"; };

sub doFilter($$) {
    # do nothing;
    '';
}
