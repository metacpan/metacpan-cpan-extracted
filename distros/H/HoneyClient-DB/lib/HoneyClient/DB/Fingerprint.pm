use HoneyClient::DB;
use HoneyClient::DB::File;
use HoneyClient::DB::Regkey;
use HoneyClient::DB::Note;
use strict;

=head1 NAME

HoneyClient::DB::Fingerprint - HoneyClient Compromise Fingerprint Object

=head1 DESCRIPTION

  HoneyClient::DB::Fingerprint describes a Fingerprint to be reported by a
  HoneyClient at the time of a compromise. This class assists insertion into
  and queries from the HoneyClient database.

=head1 SYNOPSIS

  # Create a new Fingerprint
  my $fingerprint = new HoneyClient::DB::Fingerprint({
      vmid		=> '1234567890ABCDEF1234567890',
      filesystem		=> \@file_array,
      registry => \@regkey_array,
      date		=> '2007-05-22 01:24:19',
  });
  
  $fingerprint->insert();
  
  # Search for Fingerprint containing a specific vmid
  my $fp_results = HoneyClient::DB::Fingerprint->select({
  	vmid => '1234567890ABCDEF1234567890',
  });

=head1 REQUIRES

Perl5.8.8, HoneyClient::DB, Digest::MD5, Carp

=cut


package HoneyClient::DB::Fingerprint;

use base("HoneyClient::DB");
use Digest::MD5;

BEGIN {

    #our ($UNIQUE_NOT,$UNIQUE_SELF,$UNIQUE_MULT) = (0,1,2);
    #our (%fields,%types,%check,%required);

    our %fields = (
        string => {
            vmid => {
                required => 1,
            },
            CVEnum => {
            },
            lasturl => {
                required => 1,
            	key => $HoneyClient::DB::KEY_UNIQUE_MULT,
            },
            hashsum => {
            	required => 1,
            	key => $HoneyClient::DB::KEY_UNIQUE_MULT,
            }
        },
        array => {
	        filesystem => {
                objclass => 'HoneyClient::DB::File',
            },
            registry => {
                objclass => 'HoneyClient::DB::Regkey',
            },
#            process => {
#                objclass => 'HoneyClient::DB::Process',
#            },
            notes => {
                objclass => 'HoneyClient::DB::Note',
            },
        },
        int => [qw(filesystem_count registry_count process_count)],
        timestamp => {
            time => {
                init_val => 'CURRENT_TIMESTAMP()',
            },
        },
    );
}
sub new {
	my ($class,$self) = @_;
	$self->{hashsum} = _create_hashsum($self);
	$class->SUPER::new($self);
}
sub insert {
	my $self = shift;
	foreach ('filesystem','registry','process') {
		if (exists $self->{$_}) {
			$self->{"${_}_count"} = scalar(@{$self->{$_}});
		}
	}
	$self->SUPER::insert();#::insert($self);
}

sub _create_hashsum {
	my $self = shift;
	# Create a string from the fingerprint attributes and HASH it.
    my $file_string = join ("",
    	sort(
    		map { 
                if ($_->{status} == $HoneyClient::DB::STATUS_DELETED) {
                    $_->{name};
                }
                else {
                    # Handle situation in which file is deleted before it is summed.
                    #TODO: Change 'UNKNOWN' to a constant value shared by Integrity code and DB
                    if ($_->{content}->{md5} eq 'UNKNOWN') {
                        $_->{content}->{md5} .= $_->{name};
                    }
                    if ($_->{content}->{sha1} eq 'UNKNOWN') {
                        $_->{content}->{sha1} .= $_->{name};
                    }
                    $_->{content}->{md5}.$_->{content}->{sha1};
                } 
            } @{$self->{filesystem}}
    	)
	);
	my $regkey_string = join ("",
    	sort(
        	map { $_->{key_name}.$_->{status} } @{$self->{registry}}
    	)
	);
	# TODO: Implement Process
	#my $proc_string = join ("",
    #	sort (
    #    	map { $_->{name} } @{$self->{process}}
    #	)
	#);
	my $sum = $file_string.$regkey_string; # .$proc_string;
    return Digest::MD5->new->add($sum)->hexdigest;
}

1;
