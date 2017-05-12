#==============================================================================a#

package Mac::Tie::PList;
our $VERSION = '0.03';

#==============================================================================a#

=head1 NAME

Mac::Tie::PList - Parse Apple NSDictionary objects (e.g. Preference Lists)
 

=head1 SYNOPSIS

use Mac::Tie::PList;

    my $plist = Mac::Tie::PList->new_from_file("/Library/Preferences/.GlobalPreferences.plist");

    while ((my $key,$val) = each %$plist) {
    	print "$key => $val\n";
    }


=head1 DESCRIPTION

This module allows you to parse NSDictionary objects, as used in PList files, as tied perl
objects. It uses the L<Foundation> perl/objective-c bridge and so both xml1 and binary1
formats are currently supported.

The objects are mapped as follows:

	NSNumber NSBoolean NSString => perl tied scalar
	NSArray => perl tied array
	NSDictionary => perl tied hash
	NSDate => perl tied string - returns seconds since 1970
	NSData => *WARNING* The returned sting format is not decided yet
	
NOTE: Currently the module only provided read access to the data. Write access is
planned in the future.

=over 4

=cut

#==============================================================================a#

use strict;
use warnings;
use Carp;
use Foundation;
use File::Temp qw(tempfile);

=item my $hash_ref = Mac::Tie::PList->new($data)

Parses data and creates a new tied hash based on the data provided as a string.

=cut

sub new {
	my ($obj,$xml) = @_;
	my ($tmp_fh,$tmp_file) = tempfile();
	$tmp_fh->print($xml);
	$tmp_fh->close();
	my $plist = $obj->new_from_file($tmp_file);
	unlink($tmp_file);
	return $plist;
}


=item my $hash_ref = Mac::Tie::PList->new_from_file($filename)

Parses data and creates a new tied hash based on the contents of a file.

=cut

	
sub new_from_file {
	my ($obj,$file) = @_;
	my $plist_obj = NSDictionary->dictionaryWithContentsOfFile_($file);
	if ($plist_obj && $$plist_obj)  {
		tie my %plist, 'Mac::Tie::PList::Hash', $plist_obj;
		return \%plist;
	} else {
		return;
	}
}


sub _tie_plist {
	my ($plist_obj) = @_;
	if ($plist_obj->isKindOfClass_(NSArray->class) ) {
		tie my @plist, 'Mac::Tie::PList::Array', $plist_obj;
		return \@plist;
	} elsif (
		($plist_obj->isKindOfClass_(NSCFNumber->class)) ||
		($plist_obj->isKindOfClass_(NSCFBoolean->class)) ||
		($plist_obj->isKindOfClass_(NSCFData->class)) ||
		($plist_obj->isKindOfClass_(NSDate->class)) ||
		($plist_obj->isKindOfClass_(NSCFString->class)) 
	) {
		tie my $plist, 'Mac::Tie::PList::Scalar', $plist_obj;
		return $plist;
	} elsif ($plist_obj->isKindOfClass_(NSDictionary->class) ) {
		tie my %plist, 'Mac::Tie::PList::Hash', $plist_obj;
		return \%plist;
	} else {
		carp "Unknown type: $plist_obj\n";
		return;
	}
}


#==============================================================================a#

package Mac::Tie::PList::Hash;

use strict;
use warnings;
use Carp;
use Foundation;
use Tie::Hash;
use base qw(Tie::Hash);

sub TIEHASH {
        my ($class,$plist_obj)  = @_;
        return bless {plist_obj=>$plist_obj, hash=>{} }, $class;
}

sub FETCH {
        my ($obj,$key)  = @_;
	if ($obj->{hash}->{$key}) {
		return $obj->{hash}->{$key};
	} else {
		if ($obj->{plist_obj} && ${$obj->{plist_obj}})  {
        		my $sub_obj  = $obj->{plist_obj}->objectForKey_($key);
        		if ($sub_obj && $$sub_obj ) {
                		return $obj->{hash}->{$key} = Mac::Tie::PList::_tie_plist($sub_obj);
        		} else {
                		return;
        		}
		}
	}
}

sub FIRSTKEY {
        my ($obj)  = @_;
        my @keys;
	if ($obj->{plist_obj} && ${$obj->{plist_obj}})  {
        	my $keys_array = $obj->{plist_obj}->allKeys;
        	for (my $i=0; $i<$keys_array->count; $i++) {
                	my $key_obj = $keys_array->objectAtIndex_($i);
                	if ($key_obj && $$key_obj) { 
                        	push @keys,$key_obj->description->UTF8String;
                	}
        	}
	}

        $obj->{keys} = \@keys;
        return $obj->NEXTKEY;
}

sub NEXTKEY {
        my ($obj)  = @_;
        return shift @{$obj->{keys}};
}


#==============================================================================#

package Mac::Tie::PList::Scalar;

use strict;
use warnings;
use Carp;
use Foundation;
use Tie::Scalar;
use base qw(Tie::Scalar);

sub TIESCALAR {
        my ($class,$plist_obj)  = @_;
        return bless {plist_obj => $plist_obj}, $class;
}

sub FETCH {
        my ($obj)  = @_;

	if ($obj->{plist_obj} && ${$obj->{plist_obj}})  {
		if ($obj->{plist_obj}->isKindOfClass_(NSDate->class) ) {
			return $obj->{plist_obj}->timeIntervalSince1970;
		# TODO Data is in what format? Perl should return a packed string
		#} elsif ($obj->{plist_obj}->isKindOfClass_(NSData->class) ) {
		#	return pack "c*", $obj->{plist_obj}->bytes;
		} else {
			return $obj->{plist_obj}->description->UTF8String;
		}
	} else {
		return;
	}
}


#==============================================================================#

package Mac::Tie::PList::Array;

use strict;
use warnings;
use Carp;
use Foundation;
use Tie::Array;
use base qw(Tie::Array);

sub TIEARRAY {
        my ($class,$plist_obj)  = @_;
        return bless {plist_obj=>$plist_obj, array=>[]}, $class;
}

sub FETCH {
        my ($obj,$n)  = @_;

	if ($obj->{array}->[$n]) {
		return $obj->{array}->[$n];
	} else {
        	my $sub_obj  = $obj->{plist_obj}->objectAtIndex_($n);
        	if ($sub_obj && $$sub_obj ) {
                	return $obj->{array}->[$n] = Mac::Tie::PList::_tie_plist($sub_obj);
        	} else {
                	return;
        	}
	}
}

sub FETCHSIZE {
	my ($obj) = @_;

	if ($obj->{plist_obj} && ${$obj->{plist_obj}})  {
		return $obj->{plist_obj}->count;
        } else {
               	return;
	}
}


#==============================================================================#

=back

=head1 SEE ALSO

This module is based on code from the following O'Reilly article:

	http://www.macdevcenter.com/pub/a/mac/2005/07/29/plist.html

The Objective C Bridge is descibed at:

	http://developer.apple.com/documentation/Darwin/Reference/ManPages/man3/PerlObjCBridge.3pm.html

Further details of NSDictionary's is available here:

	http://developer.apple.com/documentation/Cocoa/Reference/Foundation/ObjC_cla
ssic/Classes/NSDictionary.html

=head1 AUTHOR

Gavin Brock, E<lt>gbrock@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Gavin Brock

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut


#
# That's all folks..
#==============================================================================#

1;
