package HTML::Template::Extension::SLASH_VAR;

$VERSION 			= "0.24";
sub Version 		{ $VERSION; }

use Carp;
use strict;



my %fields_parent = (
			    	ecp_compatibility_mode => 0,
				);
     

my $re_var = q{
  ((<\s*                           # first <
  [Tt][Mm][Pp][Ll]_[Vv][Aa][Rr]   # interesting TMPL_VAR tag only
  (?:.*?)>)                       # this is H:T standard tag
  ((?:.*?)                        # delete alla after here
  <\s*\/                          # if there is the </TMPL_VAR> tag
  [Tt][Mm][Pp][Ll]_[Vv][Aa][Rr]
  \s*>))
};

sub init {
	my $self = shift;
	while (my ($key,$val) = each(%fields_parent)) {
		$self->{$key} = $self->{$key} || $val;
	}
}


sub push_filter {
	my $self = shift;
	push @{$self->{filter_internal}},@{&_get_filter($self)};
}

sub _get_filter {
	my $self = shift;
	my @ret ;
	# Sorry for this :->. I've an e-commerce project called ecp that
	# use a modified vanguard compatibility mode %%...%% 
	# This disable vanguard_compatibility_mode
	if ($self->{ecp_compatibility_mode}) {
		push @ret,\&_ecp_vanguard_syntax ;
		$self->{options}->{vanguard_compatibility_mode}=0;
	}
	push @ret,\&_slash_var;
	return \@ret;
}


# funzione filtro per aggiungere il tag </TMPL_VAR> 
# da tenere fintanto che la nostra patch non sia inserita nella 
# distribuzione standard del modulo
sub _slash_var {
    my $template = shift;
	while ($$template =~/(?=$re_var)/sgx) {
        my $two = $2;
        if ($3 !~/(?:$re_var)/sx) {
                $$template =~s{\Q$1}{$two}s;
        }
    }
    return $$template;
}

sub _ecp_vanguard_syntax {
	my $template 	= shift;
    if ($$template =~/%%([-\w\/\.+]+)%%/) {
    	$$template =~ s/%%([-\w\/\.+]+)%%/<TMPL_VAR NAME=$1>/g;
    }
}

1;
