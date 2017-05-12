package EPublisher::Target::Plugin::OTRSDoc;

# ABSTRACT: Create HTML version of OTRS documentation

use strict;
use warnings;
use File::Basename;
use File::Path qw(make_path);
use HTML::Template::Compiled;
use Pod::Simple::XHTML;

use EPublisher;
use EPublisher::Target::Base;
our @ISA = qw(EPublisher::Target::Base);

our $VERSION = 0.4;

sub deploy {
    my ($self) = @_;
    
    my $pods = $self->_config->{source} || [];
    
    my $encoding       = $self->_config->{encoding} || ':encoding(UTF-8)';
    my $base_url       = $self->_config->{base_url} || '';
    my $version        = 0;
    
    my @TOC = map{
        (my $name = $_->{title}) =~ s/::/_/g; 
        { target => join( '/', $base_url, lc( $name ) . '.html'), name => $_->{title} };
    } @{$pods};
    
    my $output = $self->_config->{output};
    make_path $output if $output && !-d $output;
    
    for my $pod ( @{$pods} ) {    
        my $parser = Pod::Simple::XHTML->new;
        $parser->index(0);
        
        (my $name = $pod->{title}) =~ s/::/_/g; 
                
        $parser->output_string( \my $xhtml );
        $parser->parse_string_document( $pod->{pod} );
        
        my $tmpl = HTML::Template::Compiled->new(
            filename => $self->_config->{template},
        );
        
        $xhtml =~ s{</body>}{};
        $xhtml =~ s{</html>}{};
        
        $tmpl->param(
            TOC  => \@TOC,
            Body => $xhtml,
        );
        
        if ( open my $fh, '>', File::Spec->catfile( $output, lc $name . '.html' ) ) {
            print $fh $tmpl->output;
            close $fh;
        }
    }
}

## -------------------------------------------------------------------------- ##
## Change behavour of Pod::Simple::XHTML
## -------------------------------------------------------------------------- ##

{
    no warnings 'redefine';
    
    sub Pod::Simple::XHTML::idify {
        my ($self, $t, $not_unique) = @_;
        for ($t) {
            s/<[^>]+>//g;            # Strip HTML.
            s/&[^;]+;//g;            # Strip entities.
            s/^([^a-zA-Z]+)$/pod$1/; # Prepend "pod" if no valid chars.
            s/^[^a-zA-Z]+//;         # First char must be a letter.
            s/[^-a-zA-Z0-9_]+/-/g; # All other chars must be valid.
        }
        return $t if $not_unique;
        my $i = '';
        $i++ while $self->{ids}{"$t$i"}++;
        return "$t$i";
    }
    
    sub Pod::Simple::XHTML::start_Verbatim {}
    
    sub Pod::Simple::XHTML::end_Verbatim {
        my ($self) = @_;
        
        $self->{scratch} =~ s{  }{ &nbsp;}g;
        $self->{scratch} =~ s{\n}{<br />}g;
        #$self->{scratch} =  '<div class="code">' . $self->{scratch} . '</div>';
        $self->{scratch} =  '<p><code class="code">' . $self->{scratch} . '</code></p>';
        
        $self->emit;
    }

    *Pod::Simple::XHTML::start_L  = sub {

        # The main code is taken from Pod::Simple::XHTML.
        my ( $self, $flags ) = @_;
        my ( $type, $to, $section ) = @{$flags}{ 'type', 'to', 'section' };
        my $url =
            $type eq 'url' ? $to
          : $type eq 'pod' ? $self->resolve_pod_page_link( $to, $section )
          : $type eq 'man' ? $self->resolve_man_page_link( $to, $section )
          :                  undef;

        # This is the new/overridden section.
        if ( defined $url ) {
            $url = $self->encode_entities( $url );
        }

        # If it's an unknown type, use an attribute-less <a> like HTML.pm.
        $self->{'scratch'} .= '<a' . ( $url ? ' href="' . $url . '">' : '>' );
    };
    
    *Pod::Simple::XHTML::start_Document = sub {
        my ($self) = @_;

        #my $xhtml_headers =
        #    qq{<?xml version="1.0" encoding="UTF-8"?>\n}
        #  . qq{<!DOCTYPE html\n}
        #  . qq{ PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"\n}
        #  . qq{ "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">\n} . qq{\n}
        #  . qq{<html xmlns="http://www.w3.org/1999/xhtml">\n}
        #  . qq{<head>\n}
        #  . qq{<title></title>\n}
        #  . qq{<meta http-equiv="Content-Type" }
        #  . qq{content="text/html; charset=utf-8"/>\n}
        #  . qq{<link rel="stylesheet" href="../styles/style.css" }
        #  . qq{type="text/css"/>\n}
        #  . qq{</head>\n} . qq{\n}
        #  . qq{<body>\n};


        #$self->{'scratch'} .= $xhtml_headers;
        $self->emit('nowrap');
    }
}

1;



=pod

=head1 NAME

EPublisher::Target::Plugin::OTRSDoc - Create HTML version of OTRS documentation

=head1 VERSION

version 0.4

=head1 SYNOPSIS

  use EPublisher::Target;
  my $EPub = EPublisher::Target->new( { type => 'OTRSDoc' } );
  $EPub->deploy;

=encoding utf8

=head1 METHODS

=head2 deploy

creates the output.

  $EPub->deploy;

=head1 YAML SPEC

  EPubTest:
    source:
      #...
    target:
      type: ÓTRSDoc

=head1 TODO

=head2 document methods

=head1 AUTHOR

Renee Bäcker <module@renee-baecker.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Renee Bäcker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


__END__

