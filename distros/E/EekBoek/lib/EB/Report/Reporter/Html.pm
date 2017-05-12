#! perl

# Html.pm -- HTML backend for Reporters.
# Author          : Johan Vromans
# Created On      : Thu Dec 29 15:46:47 2005
# Last Modified By: Johan Vromans
# Last Modified On: Sat Jun 19 00:39:34 2010
# Update Count    : 70
# Status          : Unknown, Use with caution!

package main;

our $dbh;
our $cfg;

package EB::Report::Reporter::Html;

use strict;
use warnings;

use EB;
use EB::Format qw(datefmt_full);

use base qw(EB::Report::Reporter);

################ API ################

my $html;

sub start {
    my ($self, @args) = @_;
    eval {
	require HTML::Entities;
    };
    $html = $@ ? \&__html : \&_html;
    $self->SUPER::start(@args);
}

sub finish {
    my ($self) = @_;
    $self->SUPER::finish();
    print {$self->{fh}} ("</table>\n");

    my $now = $cfg->val(qw(internal now), iso8601date());
    # Treat empty value as no value.
    $now ||= iso8601date();
    my $ident = $EB::ident;
    $ident = (split(' ', $ident))[0] if $cfg->val(qw(internal now), 0);

    $self->{fh}->print("<p class=\"footer\">",
		       __x("Overzicht aangemaakt op {date} door <a href=\"{url}\">{ident}</a>",
			   ident => $ident, date => datefmt_full($now), url => $EB::url), "</p>\n");
    $self->{fh}->print("</body>\n",
		       "</html>\n");
    close($self->{fh});
}

sub add {
    my ($self, $data) = @_;

    my $style = delete($data->{_style});

    $self->SUPER::add($data);

    return unless %$data;

    $self->_checkhdr;

    print {$self->{fh}} ("<tr", $style ? " class=\"r_$style\"" : (), ">\n");

    my $colspan = 0;
    foreach my $col ( @{$self->{_fields}} ) {

	if ( $colspan > 1 ) {
	    $colspan--;
	    next;
	}

	my $fname = $col->{name};
	my $value = defined($data->{$fname}) ? $data->{$fname} : "";
	my $class = "c_$fname";

	# Examine style mods.
	if ( $style ) {
	    if ( my $t = $self->_getstyle($style, $fname) ) {
		if ( $t->{class} ) {
		    $class = $t->{class};
		}
		if ( $t->{colspan} ) {
		    $colspan = $t->{colspan};
		}
	    }
	}
	print {$self->{fh}} ("<td class=\"$class\"",
			     $colspan > 1 ? " colspan=\"$colspan\"" : "",
			     ">",
			     $value eq "" ? "&nbsp;" : $html->($value),
			     "</td>\n");
    }

    print {$self->{fh}} ("</tr>\n");
}

################ Pseudo-Internal (used by Base class) ################

sub header {
    my ($self) = @_;

    print {$self->{fh}}
      ("<html>\n",
       "<head>\n",
       "<title>", $html->($self->{_title0} || $self->{_title1}), "</title>\n");

    if ( my $style = $self->{_style} ) {
	if ( $style =~ /\W/ ) {
	    print {$self->{fh}}
	      ('<link rel="stylesheet" href="', $style, '">', "\n");
	}
	elsif ( defined $self->{_cssdir} ) {
	    print {$self->{fh}}
	      ('<link rel="stylesheet" href="', $self->{_cssdir},
	       $style, '.css">', "\n");
	}
	elsif ( my $css = findlib("css/".$style.".css") ) {
	    print {$self->{fh}} ('<style type="text/css">', "\n");
	    copy_style($self->{fh}, $css);
	    print {$self->{fh}} ('</style>', "\n");
	}
	else {
	    print {$self->{fh}} ("<!-- ",
				 __x("Geen stylesheet voor {style}",
				     style => $style), " -->\n");
	}
    }

    print {$self->{fh}}
      ("</head>\n",
       "<body>\n",
       "<p class=\"title\">", $html->($self->{_title1}), "</p>\n",
       "<p class=\"subtitle\">", $html->($self->{_title2}), "<br>\n", $html->($self->{_title3l}), "</p>\n",
       "<table class=\"main\">\n");

    if ( grep { $_->{title} =~ /\S/ } @{$self->{_fields}} ) {
	print {$self->{fh}} ("<tr class=\"head\">\n");
	foreach ( @{$self->{_fields}} ) {
	    print {$self->{fh}} ("<th class=\"h_", $_->{name}, "\">",
				 $_->{title} ? $html->($_->{title}) : "&nbsp'",
				 "</th>\n");
	}
	print {$self->{fh}} ("</tr>\n");
    }

}

################ Internal methods ################

sub html {
    my $self = shift;
    _html(@_);
}

sub _html {
    HTML::Entities::encode(shift);
}

sub __html {
    my ($t) = @_;
    $t =~ s/&/&amp;/g;
    $t =~ s/</&lt;/g;
    $t =~ s/>/&gt;/g;
    $t =~ s/\240/&nbsp;/g;
    $t =~ s/\x{eb}/&euml;/g;	# for IVP.
    $t;
}

sub copy_style {
    my ($out, $css) = @_;
    my $in;
    unless ( open($in, "<:encoding(utf-8)", $css) ) {
	print {$out} ("/**** stylesheet $css: $! ****/\n");
	return;
    }
    print {$out} ("/** begin stylesheet $css */\n");
    while ( <$in> ) {
	if ( /^\s*\@import\s*(["']?)(.*?)\1\s*;/ ) {
	    use File::Basename;
	    my $newcss = join("/", dirname($css), $2);
	    copy_style($out, $newcss);
	}
	else {
	    print {$out} $_;
	}
    }
    close($in);
    print {$out} ("/** end   stylesheet $css */\n");
}

1;
