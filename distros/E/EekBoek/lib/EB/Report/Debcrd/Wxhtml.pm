#! perl

# Wxhtml.pm -- 
# Author          : Johan Vromans
# Created On      : Thu Feb 7 13:21:53 2008
# Last Modified By: Johan Vromans
# Last Modified On: Sat Jun 19 00:35:31 2010
# Update Count    : 23
# Status          : Unknown, Use with caution!
#! perl

package EB::Report::Debcrd::Wxhtml;

use strict;
use warnings;
use base qw(EB::Report::Reporter::WxHtml);

sub style {
    my ($self, $row, $cell) = @_;

    my $stylesheet = {
	bsk   => {
	    bsknr  => { link => "jnl://" },
	},
	paid  => {
	    bsknr  => { link => "jnl://" },
	},
	h1    => {
	    _style => { colour => 'red',
			size   => '+2',
		      }
	},
	grand => {
	    _style => { colour => 'blue' }
	},
    };

    $cell = "_style" unless defined($cell);
    return $stylesheet->{$row}->{$cell};
}

1;

