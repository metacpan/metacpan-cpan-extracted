package Iodef::Pb::Format::Csv;
use base 'Iodef::Pb::Format';

use strict;
use warnings;

sub write_out {
    my $self = shift;
    my $args = shift;
    
    my $array = $self->SUPER::to_keypair($args);
    
    my $config = $args->{'config'};

    my @config_search_path      = ( 'claoverride', $args->{'query'}, 'client' );
    
    my $cfg_fields              = $args->{'fields'}             || $self->SUPER::confor($config, \@config_search_path, 'fields',            undef);
    my $cfg_csv_noseperator     = $args->{'csv_noseperator'}    || $self->SUPER::confor($config, \@config_search_path, 'csv_noseperator',   undef);
    my $cfg_csv_noheader        = $args->{'csv_noheader'}       || $self->SUPER::confor($config, \@config_search_path, 'csv_noheader',      undef);
    my $cfg_suppress_blanks     = $args->{'suppress_blanks'}    || $self->SUPER::confor($config, \@config_search_path, 'suppress_blanks',   undef);
    my $cfg_unique_only         = $args->{'unique_only'}        || $self->SUPER::confor($config, \@config_search_path, 'unique_only',       undef);

    my @header = keys(%{@{$array}[0]});
    if($cfg_fields){
        @header = @$cfg_fields;
    }

    @header = sort { $a cmp $b } @header;
    my $body = '';
    my %bodyhash;
    my @bodyarray;
    foreach my $a (@$array){
        delete($a->{'message'}); 
        # there's no clean way to do this just yet
        foreach (@header){
            if($a->{$_} && !ref($a->{$_})){
                # deal with , in the field
                if($cfg_csv_noseperator){
                    $a->{$_} =~ s/,/ /g;
                    $a->{$_} =~ s/\s+/ /g;
                } else {
                    $a->{$_} =~ s/,/_/g;
                }
                # strip out non-ascii (typically unicode) chars
                # there are better ways to do this, but this works for now
                $a->{$_} =~ tr/\000-\177//cd;
            }
        }

        # the !ref() bits skip things like arrays and hashref's for now...
	my $tmp = join(',', map { ($a->{$_} && !ref($a->{$_})) ? $a->{$_} : ''} @header); 

	# If we're suppressing blank entries we need to use the tmp variable because we want look at the result of the join
	next if ( $cfg_suppress_blanks && $tmp =~ /^[\s,]*$/ );

	if ( $cfg_unique_only ) {
	    $bodyhash{$tmp} = '';
	} else {
	    push @bodyarray, $tmp;
	}
    }
    if ( $cfg_unique_only ) {
	@bodyarray = keys(%bodyhash);
    }

    my $text = '';
    $text = '# '.join(',',@header)."\n" unless($cfg_csv_noheader);
    $text .= join("\n",@bodyarray)."\n";

    return $text;
}
1;
