package HTML::Template::Pro::Extension::TAG_ATTRIBUTE_NORMALIZER;

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
	push @ret,\&_tag_attribute_normalizer;
	return @ret;
}


sub _tag_attribute_normalizer {
       my $template = shift;
       $$template =~ s/(<
                    (?:!--\s*)?
                    (?:
                      [Tt][Mm][Pp][Ll]_
                      (?:
                         (?:[Vv][Aa][Rr])
                         |
                         (?:[Ll][Oo][Oo][Pp])
                         |
                         (?:[Ii][Ff])
                         |
                         (?:[Ee][Ll][Ss][Ee])
                         |
                         (?:[Uu][Nn][Ll][Ee][Ss][Ss])
                         |
                         (?:[Ii][Nn][Cc][Ll][Uu][Dd][Ee])
                      )
                    )
										)(.*?)
										[Cc][Ll][Aa][Ss][Ss]\s*=\s*(?:.*?)"
										\s*
                    ((?:--)?>)/$1$2$3$4/sxg;
			#open(DEBUG,'>/tmp/debug.txt');
			#print DEBUG $$template;
			#close(DEBUG);
			return $$template;
}

1;

# vim: set ts=2:
