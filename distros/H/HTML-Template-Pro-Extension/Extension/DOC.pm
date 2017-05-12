package HTML::Template::Pro::Extension::DOC;

$VERSION 		= "0.11";
sub Version 		{ $VERSION; }

use Carp;
use strict;

my %fields_parent 	=
			    (
			     );
     
my $re_var = q{
  <\s*                           	# first <
  [Tt][Mm][Pp][Ll]_[Dd][Oo][Cc]   	# interesting TMPL_DOC tag only
  \s*>                       		# this is H:T standard tag
  ((?:.*?)                        	# delete alla after here
<\s*\/[Tt][Mm][Pp][Ll]_[Dd][Oo][Cc]\s*>)};

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
	push @ret,\&_tmpl_doc;
	return @ret;
}


# funzione filtro per aggiungere il tag </TMPL_DOC> 
# da tenere fintanto che la nostra patch non sia inserita nella 
# distribuzione standard del modulo
sub _tmpl_doc {
        my $template = shift;
        # handle the </TMPL_DOC> tag
		$$template =~s{$re_var}{}xsg
}



1;

# vim: ts=2:
