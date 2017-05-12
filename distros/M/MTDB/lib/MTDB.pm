#
# MTDB.pm (Mark Thomson's DataBase)
# store multi-level hash structure in single level tied hash
#  and save that to a flat text database optionally with encryption
# Copyright (c) May 2002 Mark Ralf Thomson. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
# Contains code from MLDBM.pm written by Gurusamy Sarathy and Raphael Manfredi

####################################################################

require 5.004;
package MTDB::Serializer;	## deferred
use Carp;

sub new { bless {}, shift };

sub serialize { confess "deferred" };

sub deserialize { confess "deferred" };


#
# Attributes:
#
#    dumpmeth:
#	the preferred dumping method.
#
#    removetaint:
#	untainting flag; when true, data will be untainted after
#	extraction from the database.
#
#    key:
#	the magic string used to recognize non-natively stored data.
#
# Attribute access methods:
#
#	These defaults allow readonly access. Sub-class may override
#	them to allow write access if any of these attributes
#	makes sense for it.
#

sub DumpMeth	{
    my $s = shift;
    confess "can't set dumpmeth with " . ref($s) if @_;
    $s->_attrib('dumpmeth');
}

sub RemoveTaint	{
    my $s = shift;
    confess "can't set untaint with " . ref($s) if @_;
    $s->_attrib('removetaint');
}

sub Key	{
    my $s = shift;
    confess "can't set key with " . ref($s) if @_;
    $s->_attrib('key');
}

sub _attrib {
    my ($s, $a, $v) = @_;
    if (ref $s and @_ > 2) {
	$s->{$a} = $v;
	return $s;
    }
    $s->{$a};
}

####################################################################

package MTDB;
use Crypt::CBC; 
require Tie::Hash;
@MTDB::ISA = 'Tie::Hash';

use vars qw($VERSION);

$VERSION = '0.1';

use Carp;

$MTDB::Serializer	= 'Data::Dumper'	unless $MTDB::Serializer;
$MTDB::Key		= 'MTDB'		unless $MTDB::Key;
$MTDB::DumpMeth		= ""			unless $MTDB::DumpMeth;
$MTDB::RemoveTaint	= 0			unless $MTDB::RemoveTaint;

my $loadpack = sub {
    my $pack = shift;
    $pack =~ s|::|/|g;
    $pack .= ".pm";
    eval { require $pack };
    if ($@) {
	carp "MTDB error: " . 
	  "Please make sure $pack is a properly installed package.\n" .
	    "\tPerl says: \"$@\"";
	return -9;
    }
    1;
};

sub TIEHASH {
	my $class = shift;
	my %params = @_;
	my(@_hdat,$name,$wert);
	
	my $self = {};
	bless $self, $class;
	

	$self->{__param}{FILE} = $params{FILE} || 'data.db';
	$self->{__param}{CRYPT} = $params{CRYPT} || 0;
	$self->{__param}{MODE} = $params{MODE} || 0664;
	$self->{__param}{LOCK} = $params{LOCK} || 0;
	$self->{__param}{CREATE} = $params{CREATE} || 0;
	$self->{__param}{SAFER} = $params{SAFER} || 0;

	if (!-e $self->{__param}{FILE}) {
		if (!$self->{__param}{CREATE}) {return -1;}

		open(HF,">$self->{__param}{FILE}") || return -3;
		close HF;
		if(!chmod 0755, $self->{__param}{FILE}) { return -2;}
	}
	my $szr = $MTDB::Serializer;
	unless (ref $szr) 
	{
		$szr = "MTDB::Serializer::$szr"	# allow convenient short names
		  	unless $szr =~ /^MTDB::Serializer::/;
		&$loadpack($szr) or return -10;
		$szr = $szr->new($MTDB::DumpMeth,
				 $MTDB::RemoveTaint,
				 $MTDB::Key);
    	}
	$self->Serializer($szr);
    
    if ($self->{__param}{CRYPT}) 
    {
       $self->{__param}{DCOBJ} = Crypt::CBC->new( 
                   {	'key'		   => $self->{__param}{CRYPT},
  				'cipher'	   => 'Blowfish',
  				'iv'		   => '?pr?Nt:}',
  				'regenerate_key'   => 0,
  				'padding'	   => 'space',
                      'prepend_iv'       => 0,
  		}	);
        croak ("Error - crypt key: self->{__param}{DCOBJ} - $!") if (!$self->{__param}{DCOBJ});
    }
	open(HF,"<$self->{__param}{FILE}") || return -4;
	flock(HF,1) if ($self->{__param}{LOCK});
	@_hdat = <HF>;
	close (HF);
	
	foreach (@_hdat) 
   	 {  
       		chomp $_;
                 $_ = $self->{__param}{DCOBJ}->decrypt_hex($_) if ($self->{__param}{DCOBJ});
                ($name, $wert) = split( /\t/ , $_ );
       		$wert =~ s/\\n/\n/g;
	        	$wert =~ s/\\t/\t/g;
    	
    		$self->{$name} = $wert;
    	}
	undef @_hdat;

	return $self;

}

sub new		{ &TIEHASH }

sub FETCH {
	my ($self, $key) = @_;
    my($temp);
	return undef if ($key eq '__param');

    if(exists ($self->{$key}))
	{
	    $temp = $self->{__param}{SR}->deserialize($self->{$key});
        if (  exists($temp->{$self->{__param}{KEY}}) &&  exists($self->{__param}{PHRASE}))
          {  $self->decrypt_r($temp->{$self->{__param}{KEY}}); }
        return $temp;
    }
    
	#$self->{$key} = undef;
	#return $self->{__param}{SR}->deserialize($self->{$key});

    return undef;
	
}

sub STORE {
	my ($self, $key, $value) = @_;
	
	if ((exists $self->{$key} && $self->{$key} == $value) 
		|| $key eq '__param')
	{ return undef; }

    if ( exists($value->{$self->{__param}{KEY}}) &&  exists($self->{__param}{PHRASE}))
          {  $self->encrypt_r($value->{$self->{__param}{KEY}}); } #ref

	$value = $self->{__param}{SR}->serialize($value);

   	$self->{$key} = $value;
}

sub encrypt_r 
{
    my ($self) = shift; 
    my ($rkey) = shift;
    my ($key,$value);
    if (ref($rkey) eq 'HASH')
    {
        while (($key, $value) = each %$rkey) 
	    {
                if (ref($rkey->{$key}) eq 'HASH')
                    { $self->encrypt_r($value); }
	            else {$rkey->{$key} = $self->encrypt($value); }
        }
    }
     else {return $self->encrypt($rkey);}
}

sub decrypt_r 
{
    my ($self) = shift; 
    my ($rkey) = shift;
    my ($key,$value);
    if (ref($rkey) eq 'HASH')
    {
        while (($key, $value) = each %$rkey) 
	    {
                if (ref($rkey->{$key}) eq 'HASH')
                    {$self->decrypt_r($value); }
	            else {$rkey->{$key} = $self->decrypt($value);}
        }
    }
     else {return $self->decrypt($rkey);}
}

sub encrypt
{
    my ($self,$text) = @_;
   	$text = $self->{__param}{COBJ}->encrypt($text);
    return $text;
}

sub decrypt
{
    my ($self,$text) = @_;
    $text = $self->{__param}{COBJ}->decrypt($text);
    return $text;
}



sub FIRSTKEY {
	my $self = shift;
	my $it_pair;

	my @hkeys = keys %$self;
	$self->{__param}{ITERATOR} = \@hkeys;

	$it_pair = shift @{$self->{__param}{ITERATOR}};
	if($it_pair eq '__param') {
	 $it_pair = shift @{$self->{__param}{ITERATOR}}; 
	}
	return $it_pair;
}

sub NEXTKEY {
	my $self = shift;
	my $it_pair;
	
	$it_pair = shift @{$self->{__param}{ITERATOR}};
	if($it_pair eq '__param') {
	 $it_pair = shift @{$self->{__param}{ITERATOR}}; 
	}
	return $it_pair;
}

sub EXISTS {
	my ($self, $key) = @_;

	return exists $self->{$key};
}

sub DELETE {
	my ($self, $key) = @_;

	delete $self->{$key} if exists $self->{$key};
}

sub sync {
	my $self = shift;
	my($key, $value);
	open(HF,">$self->{__param}{FILE}") || return undef;
	flock(HF,2) if ($self->{__param}{LOCK});
 	while (($key, $value) = each %$self) 
	{
		if($key eq '__param') { next; }
          $value =~ s/\n/\\n/g;
		$value =~ s/\t/\\t/g;
          if($self->{__param}{DCOBJ})
          {print HF $self->{__param}{DCOBJ}->encrypt_hex("$key\t$value")."\n"; }
          else { print HF "$key\t$value\n"; }		
	}
	close HF;

	if (defined $self->{__param}{MODE}) {
		chmod $self->{__param}{MODE}, $self->{__param}{FILE}
			or return undef;
	}
}

sub CLEAR {
	my $self = shift;
	my($key, $value);
	$self->sync() if(!$self->{__param}{SAFER});
	while (($key, $value) = each %$self) 
	{
		if($key eq '__param') { next; }
		delete $self->{$key};		
	}
	
}

sub DESTROY {
	my $self = shift;
	undef %$self;
}


sub setkey { 
    my $self = shift; 

    $self->{__param}{KEY} = shift;

}

sub setphrase { 
    my $self = shift;
    
    $self->{__param}{PHRASE} = shift;
    undef $$self->{__param}{COBJ} if (exists ($self->{__param}{COBJ}));
    $self->{__param}{COBJ} = Crypt::CBC->new( 
                   {	'key'		   => $self->{__param}{PHRASE},
  				'cipher'	   => 'Blowfish',
  				'iv'		   => 'T*_0yx%|',
  				'regenerate_key'   => 0,
  				'padding'	   => 'space',
                      'prepend_iv'       => 0,
  		}	);
        croak ("Error - crypt key: $self->{__param}{COBJ} - $!") if (!$self->{__param}{COBJ});
    
}


# delegate messages to the underlaying Serializer
sub DumpMeth	{ my $self = shift; $self->{__param}{SR}->DumpMeth(@_); }
sub RemoveTaint	{ my $self = shift; $self->{__param}{SR}->RemoveTaint(@_); }
sub Key		{ my $self = shift; $self->{__param}{SR}->Key(@_); }

# get/set the Serializer object
sub Serializer	{ my $self = shift; @_ ? ($self->{__param}{SR} = shift) : $self->{__param}{SR}; }

sub import {
    my (undef,$szr) = @_;
    $MTDB::Serializer = $szr if defined $szr and $szr;

}

1;
__END__

=pod

=head1 NAME

MTDB - Multidimensional Transparent hash DataBase

also kwon as:

MTDB - Mark Thomson's DataBase

=head1 SYNOPSIS

 # Load the package
 use MTDB qw($serializer);

 # Bind the hash to the class
 $db = tie %hash, 'MTDB',
         FILE => $file,
         SAFER => 1;

 # Save to disk all changed records
 $db->sync(); 

 # Get all record keys
 @array = keys %hash; 

 # Check if a record exists
 exists $hash{$foo};
 
 $bar = $hash{$foo};
 exists $bar->{$foobar};

 # Get a field
 $bla = $hash{$key};
 $scalar = $bla->{$key2}->[0];
 $scalar = $bla->{$key2}->{$key3};

 # Assign to a field
 $bla->{$key2}->{$key3} = $value;
 #store in mainhash
 $hash{$key} = $bla;
 # save to disc
 $db->sync();

=head1 DESCRIPTION

The B<MTDB> provides a hash-table-like interface to a ASCII
database.

The ASCII database stores the records into one file:

After you've tied the hash you can access this database like the MLDBM

To bind the %hash to the class MTDB you have to use the tie
function:

	tie %hash, 'MTDB', param1 => $param1, ...;

The parameters are:

=over 4

=item FILE

The File where the hash(-records) will be stored and readed from.
The default value is data.db

=item MODE

Filemode assigned to saved files. 

If this parameter is not supplied the db-files will have the
default permissions.

=item LOCK

If you set this parameter to 1 MTDB will perform basic locking.
The Databasefile will be exclusive locked when syncing (writing) them.

The default value is 0, i.e. the database won't be locked.

=item CREATE

If the DB-File not exists and this parameter is supplied, the file will
be created, otherwise tie fails.
If this parameter is supplied and the file exists already, nothing happens.

=item SAFER

If you want a more safe database, turn this parameter on. The Database will 
only sync then you request $obj->sync(), otherthise on program-end sync()
will be executed automatically.

=item CRYPT

If you specified a (at least) 8 bit key, the complete database will be 
stored encrypted.

=back

The data will be saved to disk when the hash is destroyed (and garbage
collected by perl), so if you need for safety to write the updated data
you can call the B<sync> method to do it.

You can also specifie an antoencryption for a specified hash-key.

=head1 EXAMPLES

 $db = tie %h, 'MTDB',
	FILE => 'data.db',
        MODE => 0644,
        CREATE => 1;

 $name = $h{'za'};
 $name2 = $h{'tt'};
 $name->{'name'}[0] = 'William T. Riker';
 $name2->{'name'}[0] = 'Thomas Riker';
 $name->{'friend'}[1] = 'Jean-Luc Picard';
 $h{'za'} = $name;
 $h{'tt'} = $name2;

 # Fetch all keys in database
 while (($key, $value) = each %$h) 
 {
	print "$key and $value->{'name'}[0]\n";
		
 }

 my $root = $h{'za'}; 
 for my $k (keys %$root) 
	{
            print $k->[0];		# William T. Riker
    }


 # Encryption for a spezified key in *all* hashs 
$db->setkey('personal');	 # means the first subkey
$db->setphrase('0123456789ABCEDF');
$troi = $h{'troi'};
$riker = $h{'riker'};
$troi->{'personal'}->{'foo'}='secret';	# will be stored encrypted
$troi->{'personal'}->{'bar'}->{'friend'} = 'Barcley';	# will be also stored encrypted
$troi->{'foo'}->{'personal'}->{'friend'} = 'Barcley';	# will not be stored encrypted
$riker->{'personal'}->{'foo'} = 'worf';	# will be stored encrypted 

=head1 REQUIRED MODULES


C<Carp>

C<Crypt::CBC>

C<Crypt::Blowfish>

C<Tie::Hash>

C<vars>

=head1 BUGS

=over 4

=item 1.

Adding or altering substructures to a hash value is not entirely transparent
in current perl.  If you want to store a reference or modify an existing
reference value in the MTDB, it must first be retrieved and stored in a
temporary variable for further modifications.  In particular, something like
this will NOT work properly:

	$hash{key}{subkey}[3] = 'stuff';	# won't work

Instead, that must be written as:

	$tmp = $hash{key};			# retrieve value
	$tmp->{subkey}[3] = 'stuff';
	$hash{key} = $tmp;			# store value

This limitation exists because the perl TIEHASH interface currently has no
support for multidimensional ties.

=item 2.

The B<Data::Dumper> serializer uses eval().  A lot.  Try the B<Storable>
serializer, which is generally the most efficient.

=back

=head1 WARNINGS

=over 4

=item 1.

MTDB does well with data structures that are not too deep and not
too wide.  You also need to be careful about how many C<FETCH>es your
code actually ends up doing.  Meaning, you should get the most mileage
out of a C<FETCH> by holding on to the highest level value for as long
as you need it.  Remember that every toplevel access of the tied hash,
for example C<$hash{foo}>, translates to a MTDB C<FETCH()> call.

Too often, people end up writing something like this:

        tie %h, 'MTDB', ...;
        for my $k (keys %{$h{something}}) {
            print $h{something}{$k}[0]{foo}{bar};  # FETCH _every_ time!
        }

when it should be written this for efficiency:

        tie %h, 'MTDB', ...;
        my $root = $h{something};                  # FETCH _once_
        for my $k (keys %$root) {
            print $k->[0]{foo}{bar};
        }


=back

=head1 AUTHOR

Mark Ralf Thomson

mark-thomson at gmx dot net

=head1 SUPPORT

You can send bug reports and suggestions for improvements on this module
to me. However, I can't promise to offer any other support for this script.

=head1 COPYRIGHT

MTDB was developed by Mark Ralf Thomson
Copyright 2002 by Mark Ralf Thomson. All Rights reserved.

Based up on MLDBM written by Gurusamy Sarathy and Raphael Manfredi

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 VERSION

Version 0.1		August 2002

=head1 SEE ALSO

perl(1), perltie(1), perlfunc(1), Data::Dumper(3), FreezeThaw(3), Storable(3).

=cut



