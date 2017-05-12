# -*- perl -*-
#

require 5.004;
use strict;

require Mail::IspMailGate::Filter;


package Mail::IspMailGate::Filter::Banner;

$Mail::IspMailGate::Filter::Banner::VERSION = "1.000";
@Mail::IspMailGate::Filter::Banner::ISA = qw(Mail::IspMailGate::Filter);


sub getSign { "X-ispMailGateFilter-Banner"; };


#####################################################################
#
#   Name:     setEncoding
#
#   Purpse:   set a reasonable encoding type, for the filtered mail
#
#   Inputs:   $self   - This class
#             $entity - The entity 
#
#   Returns:  error-message if any
#    
#####################################################################

sub setEncoding ($$$) {
    my ($self, $entity) = @_;
    my ($head) = $entity->head();
    
    '';
}


#####################################################################
#
#   Name:     hookFilter
#
#   Purpose:   a function which is called after the filtering process
#             
#   Inputs:   $self   - This class
#             $entity - the whole message
#                       
#
#   Returns:  errormessage if any
#    
#####################################################################

sub hookFilter ($$) {
    my($self, $entity) = @_;
    '';
}


#####################################################################
#
#   Name:     doFilter
#
#   Purpose:   does the filtering process
#
#   Inputs:   $self   - This class
#             $attr   - a hash ref to the attributes 
#                       Following things are needed !!!!
#                       1) 'entity': a ref to the Entity object
#                       2) 'parser': a ref to a Parser object
#
#   Returns:  error message, if any
#    
#####################################################################

sub BannerPLAIN ($$$) {
    my($self, $banner, $contents) = @_;
    "\r\n$banner\r\n$contents";
}

sub BannerHTML ($$$) {
    my($self, $banner, $contents) = @_;
    require HTML::Parser;

    if (!defined($banner)) {
	return $contents;
    }

    # First scan: Try to find a body tag and put the banner behind
    # the body tag.
    my $parser = Mail::IspMailGate::Filter::Banner::HTML_Parser->new();
    $parser->{_banner_body} = $banner;
    $parser->{_banner_output} = '';
    $parser->parse($contents);
    $parser->eof();
    if (!defined($parser->{_banner_body})) {
	return $parser->{_banner_output};
    }

    # No body tag found. Did we find a head tag? If so, restart and put
    # the banner behind the /head.
    if ($parser->{_banner_head_found}) {
	my $parser = Mail::IspMailGate::Filter::Banner::HTML_Parser->new();
	$parser->{_banner_head} = $banner;
	$parser->{_banner_output} = '';
	$parser->parse($contents);
	$parser->eof();
	return $parser->{_banner_output};
    }

    # No body tag and no head tag. Sigh. Put the banner right behind
    # the HTML tag.
    if ($parser->{_banner_html_found}) {
	my $parser = Mail::IspMailGate::Filter::Banner::HTML_Parser->new();
	$parser->{_banner_html} = $banner;
	$parser->{_banner_output} = '';
	$parser->parse($contents);
	$parser->eof();
	return $parser->{_banner_output};
    }

    # Give up...
    $contents;
}


sub doFilter ($$) {
    my($self, $attr) = @_;
    my ($entity) = $attr->{'entity'};

    my $parser = $attr->{'parser'};

    my $type = $entity->mime_type();

    if (!$type) {
	return '';
    }

    my ($mult) = $entity->is_multipart();
    if (!defined($mult)) {
	die "Could not determine if the Entity is multipart or not";
    }

    if ($mult) {
	my $part;
	my $globHead = exists($attr->{'globHead'}) ?
	    $attr->{'globHead'} : $entity->{'head'};
	my $main = $attr->{'main'};
	my $parser = $attr->{'parser'};
	my @parts;
	if ($type eq 'multipart/alternative') {
	    # Try any part
	    @parts = $entity->parts();
	} else {
	    # Try the first part only
	    push(@parts, $entity->parts(0));
	}
	foreach $part (@parts) {
	    if (!$part) {
		next;
	    }
	    $self->doFilter({'entity' => $part,
			     'parser' => $parser,
			     'globHead' => $globHead,
			     'main' => $main});
	}
    } else {
	if ($type =~ /^text\/(html|plain)$/) {
	    $type = $1;
	    my $file = $self->{$type};
	    if (defined($file)) {
		my $fh;
		my $banner;
		local $/ = undef;
		if (ref($file)) {
		    $fh = $file;   # For testing and debugging
		    $banner = $fh->getline();
		} else {
		    if (!-f $file) {
			return '';
		    }
		    require Symbol;
		    $fh = Symbol::gensym();
		    if (!open($fh, "<$file")) {
			return '';
		    }
		    $banner = <$fh>;
		}
		my $method = "Banner" . (uc $type);
		if (defined($banner)) {
		    my $contents;
		    my $io = Symbol::gensym();
		    my $path = $entity->bodyhandle()->path();
		    if ($path  &&
			(!open($io, "+<$path"))  ||
			!defined($contents = <$io>)  ||
			!seek($io,0,0)  ||
			!(print $io ($self->$method($banner, $contents)))  ||
			!close($io)) {
			die "Error while adding banner to $path: $!";
		    }
		}
	    }
	}
    }

    '';
}


package Mail::IspMailGate::Filter::Banner::HTML_Parser;

@Mail::IspMailGate::Filter::Banner::HTML_Parser::ISA = qw(HTML::Parser);


sub declaration ($$) {
    my($self, $decl) = @_;
    $self->{_banner_output} .= "<!$decl>";
}

sub start ($$) {
    my($self, $tag, $attr, $attrseq, $origtext) = @_;
    if ((lc $tag) eq 'body'  &&  defined($self->{_banner_body})) {
	$origtext .= "\r\n" . (delete $self->{_banner_body}) . "\r\n";
    } elsif ((lc $tag) eq 'html') {
	$self->{_banner_html_found} = 1;
	if (defined($self->{_banner_html})) {
	    $origtext .= "\r\n" . (delete $self->{_banner_html}) . "\r\n";
	}
    }
    $self->{_banner_output} .= $origtext;
}

sub end ($$) {
    my($self, $tag, $origtext) = @_;
    if ((lc $tag) eq 'head') {
	$self->{_banner_head_found} = 1;
	if (defined($self->{_banner_head})) {
	    $origtext .= "\r\n" . (delete $self->{_banner_head}) . "\r\n";
	}
    }
    $self->{_banner_output} .= $origtext;
}

sub text ($$) {
    my($self, $text) = @_;
    $self->{_banner_output} .= $text;
}

sub comment ($$) {
    my($self, $comment) = @_;
    $self->{_banner_output} .= "<!--${comment}-->";
}


1;


__END__

=pod

=head1 NAME

Mail::IspMailGate::Filter::Banner - Add a banner message to outgoing mails

=head1 SYNOPSIS

 # Create a filter
 my($filter) = Mail::IspMailGate::Filter::Banner->new({
     'plain' => '/etc/mail/banner.plain',
     'html' => '/etc/mail/banner.html'
 });

 # Call him for filtering a given mail (aka MIME::Entity)
 my ($attr) = {
     'entity' => $entity,    # a MIME::Entity object
     'parser' => $parser     # a MIME::Parser object
 };
 my($res) = $filter->doFilter($attr); 


=head1 DESCRIPTION

This class can be used for adding a banner message to the top of outgoing
E-Mails. It knows about MIME types and can deal with plain text or HTML
messages.

=head1 PUBLIC INTERFACE

=over 4

=item I<new $ATTR>

I<Class method.> Create a new filter instance; you may supply two
attributes: C<plain> is the name of a banner file to attach to plain
text mails and C<html> is similar for HTML mails. The difference is,
that the latter may contain HTML tags.


=cut
