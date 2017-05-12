package Ham::Reference::Phonetics;

# --------------------------------------------------------------------------
# Ham::Reference::Phonetics - A quick reference for the ITU Phonetic
# Alphabet
# 
# Copyright (c) 2008-2010 Brad McConahay N8QQ.
# Cincinnat, Ohio USA
#
# This module is free software; you can redistribute it and/or
# modify it under the terms of the Artistic License 2.0. For
# details, see the full text of the license in the file LICENSE.
# 
# This program is distributed in the hope that it will be
# useful, but it is provided "as is" and without any express
# or implied warranties. For details, see the full text of
# the license in the file LICENSE.
# --------------------------------------------------------------------------

use warnings;
use strict;

use vars qw($VERSION);
 
our $VERSION = '0.02';

my $phonetics = {};
$phonetics->{itu} =
{
	'a' => 'Alfa',
	'b' => 'Bravo',
	'c' => 'Charlie',
	'd' => 'Delta',
	'e' => 'Echo',
	'f' => 'Foxtrot',
	'g' => 'Golf',
	'h' => 'Hotel',
	'i' => 'India',
	'j' => 'Juliett',
	'k' => 'Kilo',
	'l' => 'Lima',
	'm' => 'Mike',
	'n' => 'November',
	'o' => 'Oscar',
	'p' => 'Papa',
	'q' => 'Quebec',
	'r' => 'Romeo',
	's' => 'Sierra',
	't' => 'Tango',
	'u' => 'Uniform',
	'v' => 'Victor',
	'w' => 'Whiskey',
	'x' => 'X-Ray',
	'y' => 'Yankee',
	'z' => 'Zulu'
};

sub new
{
    my $class = shift;
    my %args = @_;
    my $self = {};
    bless $self, $class;
	$self->{phonetic_set} = lc($args{phonetic_set}) || 'itu';
	$self->{space} = $args{space} || '';
    return $self;
}

sub get
{
	my $self = shift;
	my $string = shift;
	return undef if !$string;
	$string = lc($string);
	my $p = '';
	foreach my $letter (split '',$string) {
		if ($phonetics->{$self->{phonetic_set}}->{$letter})
		{
			$p .= $phonetics->{$self->{phonetic_set}}->{$letter}.' ';
		} elsif ($letter eq ' ') {
			$p .= $self->{space};
			$p .= ' ' if $self->{space};
		}
	}
	$p =~ s/\s$//;
	return $p;
}

sub get_arrayref
{
	my $self = shift;
	my $string = shift;
	return undef if !$string;
	$string = lc($string);
	my $p = ();
	foreach my $letter (split '',$string) {
		if ($phonetics->{$self->{phonetic_set}}->{$letter})
		{
			push( @$p, $phonetics->{$self->{phonetic_set}}->{$letter});
		} elsif ($letter eq ' ' and $self->{space}) {
			push( @$p, $self->{space} );
		}
	}
	return $p;
}

sub get_hashref
{
	my $self = shift;
	return $phonetics->{$self->{phonetic_set}};
}

1;

=head1 NAME

Ham::Reference::Phonetics - A quick reference for the ITU Phonetic Alphabet.

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

 use Ham::Reference::Phonetics;

 my $phonetics = Ham::Reference::Phonetics->new(
 	space => '<space>'
 );

 # use the get() function to get a string of phonetics

 print $phonetics->get('abc xyz');
 print "\n";

 # use the get_array() function to get an array of phonetics
 # with each one in an element

 my $arrayref = $phonetics->get_arrayref('abc xyz');
 foreach (@$arrayref) {
 	print "$_\n";
 }

 # use a hash reference to get all phonetics
 # the following will display all letters and corresponding phonetics

 my $hashref = $phonetics->get_hashref();
 foreach (sort keys %$hashref)
 {
 	print "$_ = $hashref->{$_}\n";
 }

=head1 DESCRIPTION

The C<Ham::Reference::Phonetics> module is a quick reference to the ITU phonetic alphabet
suggested by the ARRL for Amateur Radio use.  Other phonetic alphabets may be included in the
future.  Some can already be found in C<Lingua::Alphabet::Phonetic>.

=head1 CONSTRUCTOR

=head2 new()

 Usage    : my $phonetics = Ham::Reference::Phonetics->new();
 Function : creates a new Ham::Reference::Phonetics object
 Returns  : A Ham::Reference::Phonetics object
 Args     : an anonymous hash:
            key           required?   value
            -------       ---------   -----
            phonetic_set  no          select the phonetic alphabet set
                                      the only set for now, and the default set
                                      is itu
            space         no          set a string to represent a space when
                                      using methods to convert to phonetics
                                      default is an empty string

=head1 METHODS

=head2 get()

 Usage    : my $string = $phonetics->get( 'this is my string' );
 Function : converts a string to a string of corresponding phonetic words
 Returns  : a string
 Args     : a string

=head2 get_arrayref()

 Usage    : my $arrayref = $phonetics->get_arrayref( 'this is my string' );
 Function : converts a string to an array reference of corresponding phonetic words
            one phonetic word per element
 Returns  : an array reference
 Args     : a string

=head2 get_hashref()

 Usage    : my $hashref = $phonetics->get_hashref();
 Function : get the phonetic alphabet in a hash referenece
 Returns  : a hash reference
 Args     : n/a

=head1 ACKNOWLEDGEMENTS

The ITU phonetic alphabet for Amateur Radio use was taken from http://www.arrl.org/FandES/field/forms/fsd220.html#alphabet,
courtesy of the American Radio Relay League.

=head1 SEE ALSO

Other phonetic alphabets can found in C<Lingua::Alphabet::Phonetic>.

=head1 AUTHOR

Brad McConahay N8QQ, C<< <brad at n8qq.com> >>

=head1 COPYRIGHT & LICENSE

C<Ham::Reference::Phonetics> is Copyright (C) 2008-2010 Brad McConahay N8QQ.

This module is free software; you can redistribute it and/or
modify it under the terms of the Artistic License 2.0. For
details, see the full text of the license in the file LICENSE.

This program is distributed in the hope that it will be
useful, but it is provided "as is" and without any express
or implied warranties. For details, see the full text of
the license in the file LICENSE.


