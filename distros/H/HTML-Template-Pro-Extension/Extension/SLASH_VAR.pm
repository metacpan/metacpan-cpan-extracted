package HTML::Template::Pro::Extension::SLASH_VAR;

$VERSION 			= "0.11";
sub Version 		{ $VERSION; }

use Carp;
use strict;

my %fields_parent   =
                (
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


sub get_filter {
	my $self = shift;
	return &_get_filter($self);
}

sub _get_filter {
	my $self = shift;
	my @ret ;
	push @ret,\&_slash_var;
	push @ret,\&_vanguard_syntax;
	return @ret;
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

sub _vanguard_syntax {
	my $template 	= shift;
	# sintassi accettata %%....%% o %....% con .... che possono essere
	# numeri, lettere , il punto. Tutto pero deve iniziare con una lettera
 	$$template =~ s/%%([_A-Za-z][-\w\/\.]+)%%/<TMPL_VAR NAME=$1>/g;
 	$$template =~ s/%([_A-Za-z][-\w\/\.]+)%/<TMPL_VAR NAME=$1>/g;
}

1;
