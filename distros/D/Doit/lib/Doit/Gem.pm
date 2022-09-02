# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2017,2018 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

package Doit::Gem;

use strict;
use warnings;
our $VERSION = '0.011';

use Doit::Log;

sub new { bless {}, shift }
sub functions { qw(gem_install_gems gem_missing_gems) }

sub gem_install_gems {
    my($self, @gems) = @_;
    my @missing_gems = $self->gem_missing_gems(@gems);
    if (@missing_gems) {
	$self->system('gem', 'install', @missing_gems);
    }
    @missing_gems;
}


sub gem_missing_gems {
    my($self, @gems) = @_;

    my @missing_gems;

    if (@gems) {
	my $res = $self->info_qx({quiet => 1}, qw(gem list), @gems);
	my %existing_gems;
	my $max_warnings;
	for my $line (split /\n/, $res) {
	    next if $line eq '';
	    next if $line eq '*** LOCAL GEMS ***';
	    if ($line =~ m{^(\S+)\s+\((.*)\)$}) {
		$existing_gems{$1} = $2;
	    } else {
		if (++$max_warnings <= 5) {
		    warning "Cannot parse line '$line' from gem list ...";
		} else {
		    warning "Too many parse warnings";
		}
	    }
	}
	for my $gem (@gems) {
	    if (!exists $existing_gems{$gem}) {
		push @missing_gems, $gem;
	    }
	}
    }

    @missing_gems;
}

1;

__END__
