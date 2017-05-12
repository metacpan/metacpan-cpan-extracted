package HTML::Template::Pro::Extension::CSTART;

$VERSION 			= "0.11";
sub Version 		{ $VERSION; }

use Carp;
use strict;

my %fields_parent 	=
			    (
			    	ecp_compatibility_mode => 0,
			     );
     
my $re_var = q{
          <\s*                           	
          [Tt][Mm][Pp][Ll]_[Cc][Ss][Tt][Aa][Rr][Tt]   	
          \s*>                       		
          (.*?)                        	
        <\s*\/[Tt][Mm][Pp][Ll]_[Cc][Ss][Tt][Aa][Rr][Tt]\s*>};


sub init {
    my $self = shift;
    while (my ($key,$val) = each(%fields_parent)) {
        $self->{$key} = $self->{$key} || $val;
    }
}

sub get_filter {
    my $self = shift;
    return _get_filter($self);
}

sub _get_filter {
	my $self = shift;
	my @ret ;
	# Sorry for this :->. I've an e-commerce project called ecp that
	# use a CSTART modified syntax using html comment
	push @ret,\&_ecp_cstart if ($self->{ecp_compatibility_mode});
	# Standard CSTART syntax
	push @ret,\&_cstart;
	return @ret;
}


# funzione filtro per aggiungere il tag <TMPL_CSTART> 
# da tenere fintanto che la nostra patch non sia inserita nella 
# distribuzione standard del modulo
sub _cstart {
        my $template = shift;
		my $ret = '';
		while ($$template =~m{$re_var}xsg) {
				$ret .= $1;
		}
		$$template = $ret eq '' ? $$template : $ret;
}

sub _ecp_cstart {
   	my $template 	= shift;
    my $brem		='<!' . '--';
    my $eend		='--' . '>';
    my $start 		= qq=$brem\\s*[Cc][Ss][Tt][Aa][Rr][Tt]\\s*$eend=;
    my $end 		= qq=$brem\\s*[Cc][Ee][Nn][Dd]\\s*$eend=;
    if ($$template =~/$end/) {
    	$$template =~s|$start|<TMPL_CSTART>|g;
    	$$template =~s|$end|</TMPL_CSTART>|g;
    }
}



1;
