package HTML::Template::Pro::Extension::IF_TERN;

$VERSION 			= "0.11";
sub Version 		{ $VERSION; }

use Carp;
use strict;

my %fields_parent   =
                (
                 );

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
	push @ret,\&_if_tern;
	return @ret;
}


sub _if_tern {
	my $template = shift;
	my $re_var		= q{\%(\S+?)\?(.*?)(\:(.*?))?\%};
	$$template =~ s{$re_var}{
		my $replace	= qq{<TMPL_IF NAME="$1">$2};
		if (defined $3) {
			$replace	.= qq{<TMPL_ELSE>$4</TMPL_IF>};
		} else {
			$replace	.= q{</TMPL_IF>};
		}
		$replace;
	}gse;
	return $$template;
		
}

1;
