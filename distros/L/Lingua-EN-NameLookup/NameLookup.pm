# $Header$
# $Log$
#
package Lingua::EN::NameLookup;
use warnings;
use strict;

use vars qw($VERSION);
$VERSION = '0.01';

use Text::Soundex;
use Carp;

sub new {
        my $this = shift;
        my $class = ref($this) || $this;
        my $self = {};
        bless $self, $class;
        return $self;
}

sub lookup {
        my ($self,$name) = @_;
        my $code = soundex($name);
	return 0 if (!$code);
        return 0 if (!exists($self->{$code}));
	foreach my $item (sort @{ $self->{$code}}) {
		return 0 if ($item gt $name);
		return 1 if ($item eq $name);
	}
        return 0;
}

sub ilookup {
        my ($self,$name) = @_;
        my $code = soundex($name);
	return 0 if (!$code);
        return 0 if (!exists($self->{$code}));
	foreach my $item (sort @{ $self->{$code}}) {
		return 1 if ($item =~ /$name/i);
	}
        return 0;
}
              
sub add {
        my ($self,$name) = @_;
        my $code = soundex($name);
        if (!exists($self->{$code})) {
                $self->{$code} = [ $name ];
        } else {
                my @array = @{ $self->{$code}};
                push @array,$name;
                $self->{$code} = [ sort(@array) ];
        }
}
              
sub dump {
        my ($self,$filename) = @_;
        unless (open(_DICT,">$filename")) {
		warn "Can't open $filename for dump $!";
		return 0;
	}
        foreach my $family ( sort keys %$self ) {
                print _DICT "$family ",join(":",sort(@{ $self->{$family} })),"\n";
        }
        close(_DICT);
	return 1;
}

sub load {
        my ($self,$filename) = @_;
        %$self = ();
        unless (open(_DICT,"$filename")) {
		warn "Can't open $filename for load $!";
		return 0;
	}
        while (<_DICT>) {
                chomp;
                next unless s/^([A-Z]\d{3})\s*//;
                $self->{$1} = [ split(/:/) ];
        }
        close(_DICT);
	return 1;
}

sub init {
        my ($self,$filename) = @_;
        %$self = ();
        unless (open(_DICT,"$filename")) {
		warn "Can't open $filename for init $!";
		return 0;
	}
        while (<_DICT>) {
                chomp;
                my $code = soundex($_);
                push @{ $self->{"$code"} }, "$_";
        }
        close(_DICT);
	return 1;
}

sub print {
        my ($self) = @_;
        foreach my $family ( sort keys %$self ) {
                print "$family: ",join(" ",sort(@{ $self->{$family} })),"\n"
        }
}

sub report {
	my ($self) = @_;
	my $key_count = 0;
	my $longest_array = 0;
	my $name_count = 0;
	foreach my $key (keys %$self) {
		$key_count++;
		my @array = @{$self->{$key}};
		my $array_length = $#array;
		$name_count += $array_length;
		$longest_array = $array_length if ($array_length > $longest_array);
	}
	$longest_array++;
        return ($key_count, $name_count, $longest_array);
}

1;

=pod
=head1 Name 

Lingua::EN::NameLookup - a simple dictionary search and manipulation class.

=head1 Synopsis

        use Lingua::EN::NameLookup;
        $dict = new Lingua::EN::NameLookup;
        $dict->load("mydict.dat");
        $res = $dict->lookup("FOO");
        $res = $dict->ilookup("Foo");
        $dict->add("Bar");
        $dict->dump("mynewdict.dat");

=head1 Description

This class provides the ability to search and manipulate a simple dictionary.
It was originally designed for checking surnames encountered during the
preparation of census indices. It works best with small data sets and where the
names in the data set generate many distinct soundex values. The dictionary is
maintained in memory and hence the memory usage depends on the number of names.

=head2 Technique

Here's how data is stored in the dictionary:

Firstly the soundex value of the name is calculated. If there is no key in the
hash with the soundex then the name is stored as a one element array. If there
already is a key in the hash with the soundex the name is added to the end of
the existing array. Then the array is sorted and stored back in the hash. Hence
for a name such as BARLOW we might have the following in the hash:

B640 => (BARIL, BARLEY, BARLOW, BERLE,...)

Here's how we look up a name:

First the soundex of the name is calculated. If there is no key in the hash
with that soundex then the name is not in the dictionary. If there is a key in
the hash with that soundex then the array is retrieved and searched for the
name. Since we know that the array is sorted then the search can terminate as
soon as an array element greater than the name being searched for is found as
we then know that it cannot be in the array. This speeds things up when the
individual arrays are large.

=head1 Methods

=head2 new

Creates a dictionary object and initialises it (to be empty). Options are
passed as keyword value pairs. Recognised options are:

=head2 lookup($name)

Looks up the name in the dictionary, returns true if it is found or false if it
is not found.

=head2 ilookup($name)

Looks up the name in the dictionary but with a case insensitive match, returns
true if it is found or false if it is not found. Not as efficient as lookup.

=head2 add($name)

Add one name to the dictionary. Probably called after B<lookup> q.v. has failed
to find a name.

=head2 dump($file)

Dumps the dictionary to a file suitable for subsequent reading by B<load> q.v.
Each line of the file looks like:

soundex name1:name2:name3...

If the file cannot be opened for writing then this method will croak.

=head2 load($file)

Load the dictionary from a file produced by B<dump> q.v. This is more efficient
than using the B<init> method as it saves having to calculate the soundex for
each name. Each line of the file looks like:

soundex name1:name2:name3...

If the file cannot be opened for reading then this method will croak.

=head2 init($file)

Initialise the dictionary from a file containing one name on each line.

If the file cannot be opened for reading then this method will croak.

=head2 print

Produce a human readable form of the dictionary on standard output. This method
was originally designed for debugging but may have other uses.

=head2 report

Returns a list containing the number of keys in the hash, the number of names
in the hash and the length of the longest has entry. This method was originally
designed for performance testing but may have other uses.

=head1 Copyright

Copyright (c) 2002 Pete Barlow <pbarlow@cpan.org>. All rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
