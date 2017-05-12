#! perl

# Wxhtml.pm -- WxHtml backend for Balans/Result reports
# Author          : Johan Vromans
# Created On      : Thu Feb  7 14:20:53 2008
# Last Modified By: Johan Vromans
# Last Modified On: Sat Jun 19 00:34:10 2010
# Update Count    : 7
# Status          : Unknown, Use with caution!

package EB::Report::Balres::Wxhtml;

use strict;
use warnings;
use base qw(EB::Report::Reporter::WxHtml);

sub style {
    my ($self, $row, $cell) = @_;

    my $stylesheet = {
	d     => {
	    acct   => { link => "gbk://" },
	},
	d2    => {
	    acct   => { link => "gbk://" },
	    desc   => { indent => 2      },
	},
	h1    => {
	    _style => { colour => 'red',
			size   => '+2',
		      }
	},
	h2    => {
	    _style => { colour => 'red'  },
	    desc   => { indent => 1,},
	},
	t1    => {
	    _style => { colour => 'blue',
			size   => '+1',
		      }
	},
	t2    => {
	    _style => { colour => 'blue' },
	    desc   => { indent => 1      },
	},
	v     => {
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

