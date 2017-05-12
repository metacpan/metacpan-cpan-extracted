package HTML::Template::Pro::WrapAssociate;

use strict;
use Carp;
use vars qw($VERSION @ISA);

sub _wrap {
    my ($class, $associate_object, $is_case_sensitive, $is_strict_compatibility) = @_;
    if (ref($associate_object) && UNIVERSAL::can($associate_object,'param')) {
	my %hash;
	if ($is_case_sensitive) {
	    tie %hash, $class, $associate_object;
	} else {
	    foreach my $key ($associate_object->param()) {
		$hash{lc($key)} = $associate_object->param($key);
	    }
	}
	return \%hash;
    } elsif (!$is_strict_compatibility && UNIVERSAL::isa($associate_object,'HASH')) {
	if ($is_case_sensitive) {
	    return $associate_object;
	} else {
	    my %hash;
	    foreach my $key (keys(%$associate_object)) {
		$hash{lc($key)} = $associate_object->{$key};
	    }
	    return \%hash;
	}
    } else {
	Carp::croak "bad value for associate: HTML::Template::Pro->new called with associate option, containing object of type " . ref($associate_object) . " which lacks a param() method and does not look like a hash!";
    }
}

sub param {
    my $this = shift;
    return $this->[0]->param(@_);
}

sub TIEHASH {
    my ($class, $associate) = @_;
    my $self=[$associate,[]];
    return bless $self, $class;
};

sub FETCH {
    my ($this, $key) = @_;
    return $this->[0]->param($key);
}

sub EXISTS {
    my ($this, $key) = @_;
    return defined($this->[0]->param($key));
}

sub FIRSTKEY{
    my ($this) = @_;
    my @param=$this->[0]->param();
    $this->[1]=\@param;
    return shift @{$this->[1]};
}

sub NEXTKEY{
    my ($this) = @_;
    return shift @{$this->[1]};
}

sub STORE{}
sub DELETE{}
sub CLEAR{}
sub SCALAR{}

1;

__END__

#head1 NAME

HTML::Template::Pro::WrapAssociate - internal wrapper for associated objects

#head1 DESCRIPTION

Original HTML::Template has an 'associate' option, that allows to specify
an extra places whare to look for a variable value. They should have custom
'param' interface method, see L<HTML::Template::PerlInterface> for details.

This module wraps an object with custom 'param' interface method 
into a magic tied hash.

Note that this module is for internal use only.

#head1 AUTHOR

I. Vlasenko, E<lt>viy@altlinux.orgE<gt>

#head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2009 by I. Yu. Vlasenko.
Pieces of code in Pro.pm and documentation of HTML::Template are
copyright (C) 2000-2002 Sam Tregar (sam@tregar.com)

The template syntax, interface conventions and a large piece of documentation 
of HTML::Template::AssociateProWrapper are based on CPAN module HTML::Template 
by Sam Tregar, sam@tregar.com.

This library is free software; you can redistribute it and/or modify it 
under either the LGPL2+ or under the same terms as Perl itself, 
either Perl version 5.8.4 or, at your option, any later version of Perl 5 
you may have available.

#cut
