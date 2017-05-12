#!/usr/bin/perl -w
use strict;
use Test;

BEGIN { plan tests => 11 }

use HTML::FormWizard;
my $form=HTML::FormWizard->new();
ok(1);

my $x=q/
package Form::TestCGI;

sub new {
	my $y={};
	$y->{prints}=0;
	bless $y;
}

sub print {
	my $self=shift;
	$self->{prints}++;
}

sub param {
	my $self=shift;
	my $param=shift;
	if ($param) {
		return defined($self->{params}->{$param})?($self->{params}->{$param}):();
	} else {
		return scalar keys %{$self->{params}};
	}
}

1;
/;

my $cgi;

$x .= "
package __PACKAGE__;

\$cgi=Form::TestCGI->new();
";

eval $x;

if ($@) {
	print $@;
	ok(0);
} else {
	ok(1);
}

$form->run();
ok(0,$cgi->{prints});

$form->set(-cgi=>$cgi);
$form->run();
ok(1,$cgi->{prints});

$cgi->{params}->{teste}="";
$form->run();
ok(1,$cgi->{prints});

$form->add(
	{ name => 'zbr',
	  needed => 1
	}
);

$form->run();
ok(2,$cgi->{prints});

$cgi->{params}->{zbr}="";
$form->run();
ok(3,$cgi->{prints});

$cgi->{params}->{zbr}="zpto";
ok(3,$cgi->{prints});

$form->add(
	{ name => 'numaro',
	  validate => sub {
	  	my $zbr=shift;
	  	if ($zbr =~ /^\d+$/) {
			return 0;
		} else {
			return "Não é numaro";
		};
	  }
	}
);

$form->run();
ok(4,$cgi->{prints});

$cgi->{params}->{numaro}="xpto";
$form->run();
ok(5,$cgi->{prints});

$cgi->{params}->{numaro}="1234";
$form->run();
ok(5,$cgi->{prints});
