package Finance::Bank::SentinelBenefits::Csv401kConverter::SymbolMap;
$Finance::Bank::SentinelBenefits::Csv401kConverter::SymbolMap::VERSION = '1.0';
use Modern::Perl;

=head1 NAME

Finance::Bank::SentinelBenefits::Csv401kConverter::SymbolMap - fuzzy lookup 
of security descriptions to symbols

=head1 VERSION

version 1.0

=head1 SYNOPSIS

This class is necessary because Sentinel does not always supply the symbol
in the download, so it can become necessary to do a lookup based on the 
description field that they supply to find the correct security symbol.

=cut

use Moose;
use Scalar::Util qw{ openhandle };

=head1 Constructor

=head2 new()

    my $st = Bank::SentinelBenefits::Csv401kConverter::SymbolMap->new({
        symbol_map => $HashRef[Str] | FileHandle });

Can be initialzed either from a hash mapping of the form description -> symbol
or a comma delimited file of the same type.

=cut

=head1 Internal accessors

=head2 $foo->symbol_map()

This is either a hash ref of strings, mapping descriptions to symbols,
 or a filehandle pointing to a file of the format C<'description','symbol>

Not really for external use

=head2 $foo->_true_symbol_map()

This is a hash ref of strings, mapping descriptions to symbols.  Internal use only.

=cut
has 'symbol_map' => ( 
    is       => 'ro',
    isa      => 'HashRef[Str] | FileHandle',
    required => 1,
);

has '_true_symbol_map' => (
    is       => 'rw',
    isa      => 'HashRef[Str]',
    init_arg => undef,
);

=head1 Methods

=head2 $foo->get_symbol($description)

Takes a security description.  Returns either the symbol, if
lookup is successful, or undef;

=cut

sub get_symbol{
    my $self = shift;
    my $description = shift;

    my $ref = $self->_true_symbol_map();

    my $symbol = $ref->{$description};

    return $symbol if $symbol;
    
    foreach my $key(keys(%$ref)){
	if( $description =~/$key/ ){
	    return $ref->{$key};
	}
    }

    return;
}

sub BUILD {
    my $self = shift;
    
    my $symmap = $self->symbol_map();

    my %newmap;
    my $fh = openhandle ($symmap);

    if (not defined $fh){
	#it's a hash ref of str, clone it to avoid pesky people trying to mess with it later
	foreach my $key(keys(%$symmap)){
	    $newmap{$key} = $symmap->{$key};
	}
    }else{
	#it's a file handle, the file must be in the format
	#description,symbol

	while(<$fh>){
	    chomp;
	    my @parts = split /,/;

	    $newmap{$parts[0]} = $parts[1];
	}
    }

    #Was going to lock it down, but maybe it's more useful to 
    #leave it unlocked in case someone has a legit use case to 
    #fiddle with it at runtime
    $self->_true_symbol_map(\%newmap);
}

no Moose;

__PACKAGE__->meta->make_immutable;

# Copyright 2009-2011 David Solimano
# This file is part of Finance::Bank::SentinelBenefits::Csv401kConverter

# Finance::Bank::SentinelBenefits::Csv401kConverter is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# Finance::Bank::SentinelBenefits::Csv401kConverter is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with Finance::Bank::SentinelBenefits::Csv401kConverter.  If not, see <http://www.gnu.org/licenses/>.


1;
