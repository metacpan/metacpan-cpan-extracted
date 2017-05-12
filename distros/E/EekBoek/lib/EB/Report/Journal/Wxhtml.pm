#! perl

# Wxhtml.pm -- WxHtml backend for Journal reports.
# Author          : Johan Vromans
# Created On      : Thu Feb  7 14:21:31 2008
# Last Modified By: Johan Vromans
# Last Modified On: Sat Jun 19 00:37:27 2010
# Update Count    : 9
# Status          : Unknown, Use with caution!

package EB::Report::Journal::Wxhtml;

use strict;
use warnings;
use base qw(EB::Report::Reporter::WxHtml);

sub style {
    my ($self, $row, $cell) = @_;

    my $stylesheet = {
	head    => {
	    _style => { colour => 'red'  },
	},
	chead    => {
	    _style => { colour => 'red'  },
	    rel    => { link => "crd://" },
	},
	dhead    => {
	    _style => { colour => 'red'  },
	    rel    => { link => "deb://" },
	},
	total    => {
	    _style => { colour => 'blue',
		      }
	},
	data    => {
	    desc => { indent => '+2' },
	    acct => { link => "gbk://" },
	    bsk  => { indent => '+2' },
	},
	cdata    => {
	    desc => { indent => '+2' },
	    acct => { link => "gbk://" },
	    bsk  => { indent => '+2' },
	    rel  => { link => "crd://" },
	},
	ddata    => {
	    desc => { indent => '+2' },
	    acct => { link => "gbk://" },
	    bsk  => { indent => '+2' },
	    rel  => { link => "deb://" },
	},
    };

    $cell = "_style" unless defined($cell);
    return $stylesheet->{$row}->{$cell};
}

1;

