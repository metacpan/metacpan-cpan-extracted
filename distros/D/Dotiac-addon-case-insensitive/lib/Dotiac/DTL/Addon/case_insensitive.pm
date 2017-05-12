###############################################################################
#case-insensitive.pm
#Last Change: 2009-02-09
#Copyright (c) 2009 Marc-Seabstian "Maluku" Lucksch
#Version 0.4
####################
#This file is an addon to the Dotiac::DTL project. 
#http://search.cpan.org/perldoc?Dotiac::DTL
#
#case-insensitive.pm is published under the terms of the MIT license, which  
#basically means "Do with it whatever you want". For more information, see the 
#license.txt file that should be enclosed with this distribution. A copy of
#the license is (at the time of writing) also available at
#http://www.opensource.org/licenses/mit-license.php .
###############################################################################


package Dotiac::DTL::Addon::case_insensitive;
use strict;
use warnings;

#If it is not already loaded.
require Dotiac::DTL::Core;

our $VERSION=0.4;

my $old;

our %keymap=();

sub import { 
	no warnings qw/redefine/;
	$old = \&Dotiac::DTL::devar_var;
	*Dotiac::DTL::devar_var=\&devar_var;

}
sub unimport {
	no warnings qw/redefine/;
	*Dotiac::DTL::devar_var = $old;
}

sub devar_var {
	my $name=shift;
	my $n=$name;
	return Dotiac::DTL::Value->safe(undef) unless defined $name;
	my $lcn = lc($name);
	my $param=shift;
	my $f=substr $name,0,1;
	my $l=substr $name,-1,1;
	my $escape=shift;

	return Dotiac::DTL::Value->safe(substr $name,1,-1) if $f eq "'" and $l eq "'" or $f eq '"' and $l eq '"';
	return Dotiac::DTL::Value->safe(Dotiac::DTL::descap(substr $name,1,-1)) if $f eq "`" and $l eq "`";

	if ($lcn eq "block.super" and $param->{"block.super"}) {
		return Dotiac::DTL::Value->safe($param->{"block.super"}->string($param,@_)) if Scalar::Util::blessed($param->{"block.super"});
		return Dotiac::DTL::Value->safe($param->{"block.super"}->($param,@_)) if ref $param->{"block.super"} eq "CODE";
	}
	return Dotiac::DTL::Value->new($param->{$name},!$escape) if exists $param->{$name};
	return Dotiac::DTL::Value->new($param->{$Dotiac::DTL::Addon::case_insensitive::keymap{$lcn}},!$escape) if defined $Dotiac::DTL::Addon::case_insensitive::keymap{$lcn} and exists($param->{$Dotiac::DTL::Addon::case_insensitive::keymap{$lcn}});
	foreach my $k (keys %{$param}) {
		if (lc($k) eq $lcn) {
			$Dotiac::DTL::Addon::case_insensitive::keymap{$lcn}=$k;
			return Dotiac::DTL::Value->new($param->{$k},!$escape);
		}
	}
	my @tree=split/\./,$name;
	$name=shift @tree;
	$lcn = lc($name);
	if (exists $param->{$name}) {
		$param=$param->{$name};
	}
	elsif (defined $Dotiac::DTL::Addon::case_insensitive::keymap{$lcn} and exists $param->{$Dotiac::DTL::Addon::case_insensitive::keymap{$lcn}}) {
		$param=$param->{$Dotiac::DTL::Addon::case_insensitive::keymap{$lcn}};
	}
	else {
		my $found=0;
		foreach my $k (keys %$param) {
			if (lc($k) eq $lcn) {
				$Dotiac::DTL::Addon::case_insensitive::keymap{$lcn}=$k;
				$found=1;
				$param=$param->{$k};
				last;
			}
		}
		unless ($found) {
			return Dotiac::DTL::Value->safe($n) if $n!~/[^\d\-\.\,\e]/;
			foreach my $k (keys %Dotiac::DTL::cycle) {
				if (lc($k) eq $lcn and $Dotiac::DTL::cycle{$k}->[1]) {
					return Dotiac::DTL::Value->safe("") if $Dotiac::DTL::included{"cycle_$k"}++;
					my $r=devar_raw($Dotiac::DTL::cycle{$k}->[2]->[$Dotiac::DTL::cycle{$k}->[0]-1 % $Dotiac::DTL::cycle{$k}->[1]],$param,$escape,@_);
					$Dotiac::DTL::included{"cycle_$k"}=0;
					return $r;
				}
			}
			return Dotiac::DTL::Value->safe(undef) ;
		}
	}
	while (defined(my $name = shift @tree)) {
		$lcn = lc($name);
		my $r = Scalar::Util::reftype($param);
		if ($r) {
			if ($r eq "HASH") {
				if (not exists $param->{$name}) {
					my $found=0;
					foreach my $k (keys %{$param}) {
						if (lc($k) eq $lcn) {
							$found=1;
							$param=$param->{$k};
							last;
						}
					}
					next if $found;
					return Dotiac::DTL::Value->safe(undef) unless Scalar::Util::blessed($param);
				}
				else {
					$param=$param->{$name};
					next;
				}
			}
			elsif ($r eq "ARRAY") {
				if ($name=~m/\D/) {
					return Dotiac::DTL::Value->safe(undef) unless Scalar::Util::blessed($param);
				}
				else {
					if (not exists $param->[$name]) {
						return Dotiac::DTL::Value->safe(undef) unless Scalar::Util::blessed($param);
					}
					else {
						$param=$param->[$name];
						next;
					}
				}
			}
		}
		if (Scalar::Util::blessed($param)) {
			return Dotiac::DTL::Value->safe(undef) unless $Dotiac::DTL::ALLOW_METHOD_CALLS; 
			my $found=0;
			foreach my $k ($param->dotiac_get_all_methods()) {
				if (lc($k) eq $lcn) {
					$found=1;
					$param=$param->$k();
					last;
				}
			}
			if (not $found and $param->can("__getitem__")) {
				my $x;
				eval {
					$x=$param->__getitem__($name);
					1;
				} or return Dotiac::DTL::Value->safe(undef);
				if (defined $x) {
					$param=$x;
					next;
				}
			}
			return Dotiac::DTL::Value->safe(undef) unless $found;
			next;
		}
		return Dotiac::DTL::Value->safe($n) if $n!~/[^\d\-\.\,\e]/;
		return Dotiac::DTL::Value->safe(undef);
	}
	return Dotiac::DTL::Value->new($param,!$escape);
}


package UNIVERSAL;

use strict;

sub dotiac_get_all_methods {
	my ($class, undef) = @_;
	$class = ref $class || $class;
	my %classes_seen;
	my %methods;
	my @class = ($class);

	no strict 'refs';
	while ($class = shift @class) {
	    next if $classes_seen{$class}++;
	    unshift @class, @{"${class}::ISA"};
	    # Based on methods_via() in perl5db.pl
	    for my $method (grep { # not /^[(_]/ and  # Has to be removed, sadly
				  defined &{${"${class}::"}{$_}}} 
			    keys %{"${class}::"}) {
		$methods{$method} = wantarray ? undef : $class->can($method); 
	    }
	}

	wantarray ? keys %methods : \%methods;
}

1;

__END__

=head1 NAME

Dotiac::DTL::Addon::case_insensitive: Ignore case of Dotiac variables

=head1 SYNOPSIS

Load from a Dotiac::DTL-template:

	{% load case-insensitive %}

Load in Perl file for all templates:

	use Dotiac::DTL::Addon::case_insensitive; #Note the underline instead of the minus

=head1 INSTALLATION

via CPAN:

	perl -MCPAN -e "install Dotiac::DTL::Addon::case_insensitive"

or get it from L<https://sourceforge.net/project/showfiles.php?group_id=249411&package_id=306751>, extract it and then run in the extracted folder:

	perl Makefile.PL
	make test
	make install

=head1 DESCRIPTION

This will make variable lookups become case-insensitive.

	{{ Data }} == {{ DAtA }} == {{ DaTa }} == ...
	{{ var.Foo }} == {{ var.foo }} == {{ var.FOO }} == ...

L<Filter and tag names stay case sensitive>.

=head1 INTERNALS

=head2 devar_var

This function of L<Dotiac::DTL::Core> will be overwritten.

=head2 dotiac_get_all_methods

Addon to UNIVERSAL, which gets all methods, stolen from the perl 6 RFC 335 (L<http://dev.perl.org/perl6/rfc/335.html>);

=head1 BUGS

This will make Dotiac slower.

Please report any bugs or feature requests to L<https://sourceforge.net/tracker2/?group_id=249411&atid=1126445>

=head1 SEE ALSO

L<Dotiac::DTL>, L<Dotiac::DTL::Addon>, L<http://www.dotiac.com>, L<http://www.djangoproject.com>

=head1 AUTHOR

Marc-Sebastian Lucksch

perl@marc-s.de

=cut
