package Device::Cdio::Util;
require 5.8.6;
#
#  Copyright (C) 2006, 2008, 2017 Rocky Bernstein <rocky@cpan.org>
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see L<The GNU General Public
#  License|http://www.gnu.org/licenses/#GPL>.

# These are internal routines. Not all that useful for external consumption.

use strict;
use vars qw($VERSION @EXPORT_OK @ISA );
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(_rearrange _make_attributes _check_arg_count _extra_args);

$VERSION = $Device::Cdio::VERSION;

# Check that we $count (the argument count of arguments passed has
# between $min and $max arguments.
sub _check_arg_count {
    my ($count, $min, $max) = @_;
    my $msg = undef;
    if (!defined($max)) {
	if ($count != $min) {
	    $msg = sprintf("Need to supply exactly %d arguments. (got %d)",
			   $min, $count);
	}
    } elsif ($count < $min) {
	$msg = sprintf("Need to supply at least %d arguments. (got %d)",
		       $min, $count);
    } elsif ($count > $max) {
	$msg = sprintf("Need to supply no more than %d arguments. (got %d)",
		       $max, $count);
    }
    if (defined($msg)) {
	my (undef, $file, $line, $called)= caller(1);
	print "$msg.\n\tCalled $called from file $file at line $line\n";
	return 0;
    }
    return 1;
}

# Check that we $count (the argument count of arguments passed has
# between $min and $max arguments.
sub _extra_args {
    my @args = @_;
    if (@args != 0) {
	my (undef, $file, $line, $called)= caller(1);
	my $arg_count = @args;
	print "$arg_count extraneous parameter given in call\n";
	print "\tCalled $called from file $file at line $line\n";
	return 1;
    }
    return 0;
}

# Taken from CGI::Util
sub _make_attributes {
    my $attr = shift;
    return () unless $attr && ref($attr) && ref($attr) eq 'HASH';
    my $escape =  shift || 0;
    my(@att);
    foreach (keys %{$attr}) {
	my($key) = $_;
	$key=~s/^\-//;     # get rid of initial - if present

	# old way: breaks EBCDIC!
	# $key=~tr/A-Z_/a-z-/; # parameters are lower case, use dashes

	($key="\L$key") =~ tr/_/-/; # parameters are lower case, use dashes

	my $value = $escape ? _simple_escape($attr->{$_}) : $attr->{$_};
	push(@att,defined($attr->{$_}) ? qq/$key="$value"/ : qq/$key/);
    }
    return @att;
}

# Taken from CGI::Util
# Smart rearrangement of parameters to allow named parameter
# calling.  We do the rearangement if:
# the first parameter begins with a -
sub _rearrange {
    my($order,@param) = @_;
    return () unless @param;

    if (ref($param[0]) eq 'HASH') {
	@param = %{$param[0]};
    } else {
	return @param
	    unless (defined($param[0]) && substr($param[0],0,1) eq '-'
		    && $param[0] !~ m{\A-\d+});
    }

    # map parameters into positional indices
    my ($i,%pos);
    $i = 0;
    foreach (@$order) {
	foreach (ref($_) eq 'ARRAY' ? @$_ : $_) { $pos{lc($_)} = $i; }
	$i++;
    }

    my (@result,%leftover);
    $#result = $#$order;  # preextend
    while (@param) {
	my $key = lc(shift(@param));
	$key =~ s/^\-//;
	if (exists $pos{$key}) {
	    $result[$pos{$key}] = shift(@param);
	} else {
	    $leftover{$key} = shift(@param);
	}
    }

    push (@result,_make_attributes(\%leftover,defined $CGI::Q ? $CGI::Q->{escape} : 1)) if %leftover;
    @result;
}

# Also from CGI::Util.pm
sub _simple_escape {
  return unless defined(my $toencode = shift);
  $toencode =~ s{&}{&amp;}gso;
  $toencode =~ s{<}{&lt;}gso;
  $toencode =~ s{>}{&gt;}gso;
  $toencode =~ s{\"}{&quot;}gso;
# Doesn't work.  Can't work.  forget it.
#  $toencode =~ s{\x8b}{&#139;}gso;
#  $toencode =~ s{\x9b}{&#155;}gso;
  $toencode;
}

1; # Magic true value required at the end of a module

__END__

=head1 NAME

Device::Cdio::Util - Internal utilities used by Cdio modules

=head1 SYNOPSIS

none

=head1 DESCRIPTION

no public subroutines

=head1 AUTHOR INFORMATION

Code taken from CGI::Util.pm which reads:
Copyright 1995-1998, Lincoln D. Stein.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Device::Cdio>

=cut
