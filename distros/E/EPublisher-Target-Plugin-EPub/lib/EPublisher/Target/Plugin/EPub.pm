package EPublisher::Target::Plugin::EPub;

# ABSTRACT: Use EPub as a target for EPublisher

use strict;
use warnings;
use Data::UUID;
use EBook::EPUB;
use File::Basename;
use File::Temp qw(tempfile);
use File::Path qw(remove_tree);
use Pod::Simple::XHTML;

use EPublisher;
use EPublisher::Target::Base;
our @ISA = qw(EPublisher::Target::Base);

our $VERSION = 0.6;

sub deploy {
    my ($self) = @_;
    
    my $pods = $self->_config->{source} || [];
    
    my $author         = $self->_config->{author}   || 'Perl Author';
    my $title          = $self->_config->{title}    || 'Pod Document';
    my $language       = $self->_config->{lang}     || 'en';
    my $out_filename   = $self->_config->{output}   || '';
    my $css_filename   = $self->_config->{css}      || '';
    my $cover_filename = $self->_config->{cover}    || '';
    my $encoding       = $self->_config->{encoding} || ':encoding(UTF-8)';
    my $version        = 0;
    
    # Create EPUB object
    my $epub = EBook::EPUB->new();

    # Set the ePub metadata.
    $epub->add_title( $title );
    $epub->add_author( $author );
    $epub->add_language( $language );

    # Add user defined cover image if it supplied.
    $self->add_cover( $epub, $cover_filename ) if $cover_filename;

    # Add the Dublin Core UUID.
    my $du = Data::UUID->new();
    my $uuid = $du->create_str;

    {

        # Ignore overridden UUID warning form EBook::EPUB.
        local $SIG{__WARN__} = sub { };
        $epub->add_identifier( "urn:uuid:$uuid" );
    }

    # Add some other metadata to the OPF file.
    $epub->add_meta_item( 'EPublisher version',  $EPublisher::VERSION );
    $epub->add_meta_item( 'EBook::EPUB version', $EBook::EPUB::VERSION );


    # Get the user supplied or default css file name.
    $css_filename = $self->get_css_file( $css_filename );


    # Add package content: stylesheet, font, xhtml
    $epub->copy_stylesheet( $css_filename, 'styles/style.css' );
    
    my $counter       = 1;
    my $image_counter = 1;
    
    for my $pod ( @{$pods} ) {    
        my $parser = Pod::Simple::XHTML->new;
        $parser->index(0);
        
        $parser->accept_directive_as_processed( 'image' );

        # we have to decrease all headings to the layer below
        $pod->{pod} =~ s/=[hH][eE][aA][dD]1[ ]/=head2 /g; 
        $pod->{pod} =~ s/=[hH][eE][aA][dD]2[ ]/=head3 /g; 
        $pod->{pod} =~ s/=[hH][eE][aA][dD]3[ ]/=head4 /g; 
        #TODO: need a fix for head4
        
        my ($in_fh_temp,$in_file_temp) = tempfile();
        binmode $in_fh_temp, $encoding;
        # adding a title, given from the meta-data
        print $in_fh_temp "=head1 $pod->{title}\n\n" || ''; 
        # adding the content
        print $in_fh_temp $pod->{pod} || '';
        close $in_fh_temp;
        
        my $in_fh;
        open $in_fh, "<$encoding", $in_file_temp;
    
        my ($xhtml_fh, $xhtml_filename) = tempfile();
        
        $parser->output_fh( $xhtml_fh );
        $parser->parse_file( $in_fh );

        close $xhtml_fh;
        close $in_fh;
        
        $epub->copy_xhtml( $xhtml_filename, "text/$counter.xhtml", linear => 'no' );
        
        # cleaning up...
        unlink $xhtml_filename;
        unlink $in_file_temp;
        
        $self->add_to_table_of_contents( $counter, $parser->{to_index} );

        # add images
        my @images = $parser->images_to_import();
        for my $image ( @images ) {
            my $path     = $image->{path};
            my $name     = $image->{name};
            my $image_id = $epub->copy_image( $path, "images/$name" );
            $epub->add_meta_item( "image$image_counter", $image_id );
        }
        
        $counter++;
    }

    # Add Pod headings to table of contents.
    $self->set_table_of_contents( $epub, $self->table_of_contents );

    # clean up...
    unlink $css_filename if !$self->user_css;

    # Generate the ePub eBook.
    my $success = $epub->pack_zip( $out_filename );
    if ( !$success ) {
        $self->publisher->debug( "402: can't create epub" );
        return '';
    }

    # delete tmp dir created by EBook::EPUB
    my $epub_tmp = $epub->tmpdir;
    remove_tree $epub_tmp if $epub_tmp and -d $epub_tmp;
    
    return $out_filename;
}

sub add_to_table_of_contents {
    my ($self,$page, $arrayref) = @_;
    
    push @{ $self->{__toc} }, +{ page => $page, headings => $arrayref };
    return 1;
}

sub table_of_contents {
    my ($self) = @_;
    
    return $self->{__toc};
}

sub _html_header {
    return
        qq{<?xml version="1.0" encoding="UTF-8"?>\n}
          . qq{<!DOCTYPE html\n}
          . qq{     PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"\n}
          . qq{    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">\n}
          . qq{\n}
          . qq{<html xmlns="http://www.w3.org/1999/xhtml">\n}
          . qq{<head>\n}
          . qq{<title></title>\n}
          . qq{<meta http-equiv="Content-Type" }
          . qq{content="text/html; charset=iso-8859-1"/>\n}
          . qq{<link rel="stylesheet" href="../styles/style.css" }
          . qq{type="text/css"/>\n}
          . qq{</head>\n}
          . qq{\n}
          . qq{<body>\n};
}

sub set_table_of_contents {
    my ($self,$epub,$pod_headings) = @_;

    my $play_order        = 1;
    my $max_heading_level = $self->_config->{max_heading_level} || 2;
    my @navpoints         = ($epub) x ($max_heading_level + 1);
        
    for my $content_part ( @{$pod_headings} ) {
        
        my $headings = $content_part->{headings};
        my $page     = $content_part->{page};

        for my $heading ( @{$headings} ) {

            my $heading_level = $heading->[0];
            my $section       = $heading->[1];
            my $label         = $heading->[2];
            my $content       = "text/$page.xhtml";

            # Only deal with head1 and head2 headings.
            next if $heading_level > $max_heading_level;

            # Add the pod section to the NCX data, Except for the root heading.
            $content .= '#' . $section;# if $play_order > 1;

            my %options = (
                content    => $content,
                id         => 'navPoint-' . $play_order,
                play_order => $play_order,
                label      => $label,
            );

            $play_order++;

            # Add the navpoints at the correct nested level.
            my $navpoint_obj = $navpoints[ $heading_level - 1 ];
            $navpoint_obj    = $navpoint_obj->add_navpoint( %options );
            
            $navpoints[ $heading_level ] = $navpoint_obj;
        }
    }
}

sub get_css_file {
    my ($self,$css_filename) = @_;
    
    my $css_fh;

    # If the user supplied the css filename check if it exists.
    if ( $css_filename ) {
        if ( -e $css_filename ) {
            $self->user_css(1);
            return $css_filename;
        }
        else {
            warn "CSS file $css_filename not found.\n";
        }
    }

    # If the css file doesn't exist or wasted supplied create a default.
    ( $css_fh, $css_filename ) = tempfile();

    print $css_fh "h1         { font-size: 110%; }\n";
    print $css_fh "h2, h3, h4 { font-size: 100%; }\n";
    print $css_fh ".code      { font-family: Courier; }\n";

    close $css_fh;

    return $css_filename;
}

sub user_css {
    my ($self,$value) = @_;
    
    return $self->{__user_css} if @_ != 2;
    $self->{__user_css} = $value;
}

sub add_cover {
    my ($self,$epub,$cover_filename) = @_;

    # Check if the cover image exists.
    if ( !-e $cover_filename ) {
        warn "Cover image $cover_filename not found.\n";
        return undef;
    }
    
    my $cover_basename = basename $cover_filename;

    # Add cover metadata for iBooks.
    my $cover_id = $epub->copy_image( $cover_filename, "images/$cover_basename" );
    $epub->add_meta_item( 'cover', $cover_id );

    # Add an additional cover page for other eBook readers.
    my $cover_xhtml =
        qq[<?xml version="1.0" encoding="UTF-8"?>\n]
      . qq[<!DOCTYPE html\n]
      . qq[     PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"\n]
      . qq[    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">\n\n]
      . qq[<html xmlns="http://www.w3.org/1999/xhtml">\n]
      . qq[<head>\n]
      . qq[<title></title>\n]
      . qq[<meta http-equiv="Content-Type" ]
      . qq[content="text/html; charset=iso-8859-1"/>\n]
      . qq[<style type="text/css"> img { max-width: 100%; }</style>\n]
      . qq[</head>\n]
      . qq[<body>\n]
      . qq[    <p><img alt="" src="../images/$cover_basename" /></p>\n]
      . qq[</body>\n]
      . qq[</html>\n\n];

    # Crete a temp file for the cover xhtml.
    my ( $tmp_fh, $tmp_filename ) = tempfile();

    print $tmp_fh $cover_xhtml;
    close $tmp_fh;

    # Add the cover page to the ePub doc.
    $epub->copy_xhtml( $tmp_filename, 'text/cover.xhtml', linear => 'no' );

    # Add the cover to the OPF guide.
    my $guide_options = {
        type  => 'cover',
        href  => 'text/cover.xhtml',
        title => 'Cover',
    };

    $epub->guide->add_reference( $guide_options );

    # Cleanup the temp file.
    unlink $cover_xhtml;

    return $cover_id;
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
    
    sub Pod::Simple::XHTML::images_to_import {
        my ($self) = @_;
        
        return @{ $self->{images_to_import} || [] };
    };
    
    sub Pod::Simple::XHTML::end_image {
        my ($self) = @_;
        
        my %regexe = (
            path_quoted => qr/"([^"]+)"(?:\s+(.*))?/s, # =image "C:\path with\whitespace.png" alt text
            path_plain  => qr/([^\s]+)(?:\s+(.*))?/s,  # =image C:\path\img.png alt text
        );
        
        my $text  = $self->{scratch};
        my $regex = $text =~ /^\s*"/ ? $regexe{path_quoted} : $regexe{path_plain};
        
        my ($path,$alt) = $text =~ $regex;
        $alt = '' if !defined $alt;
        
        return if !$path;
        
        if ( !-e $path ) {
            warn "Image $path does not exist!";
            return;
        }
        
        my $filename     = basename $path;
        
        # save complete path in $self->{images_to_import}
        push @{$self->{images_to_import}}, { path => $path, name => $filename };
        
        $self->{scratch} = qq~<p><img src="../images/$filename" alt="$alt" /></p>~;
        
        $self->emit;
    };

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

        my $xhtml_headers =
            qq{<?xml version="1.0" encoding="UTF-8"?>\n}
          . qq{<!DOCTYPE html\n}
          . qq{ PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"\n}
          . qq{ "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">\n} . qq{\n}
          . qq{<html xmlns="http://www.w3.org/1999/xhtml">\n}
          . qq{<head>\n}
          . qq{<title></title>\n}
          . qq{<meta http-equiv="Content-Type" }
          . qq{content="text/html; charset=utf-8"/>\n}
          . qq{<link rel="stylesheet" href="../styles/style.css" }
          . qq{type="text/css"/>\n}
          . qq{</head>\n} . qq{\n}
          . qq{<body>\n};


        $self->{'scratch'} .= $xhtml_headers;
        $self->emit('nowrap');
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

EPublisher::Target::Plugin::EPub - Use EPub as a target for EPublisher

=head1 VERSION

version 0.6

=head1 SYNOPSIS

  use EPublisher::Target;
  my $EPub = EPublisher::Target->new( { type => 'EPub' } );
  $EPub->deploy;

=head1 METHODS

=head2 deploy

creates the output.

  $EPub->deploy;

=head1 YAML SPEC

  EPubTest:
    source:
      #...
    target:
      type: EPub
      author: reneeb
      output: /path/to/test.epub
      title: The Books Title
      cover: /path/to/an/image/for/the/cover.jpg
      encoding: utf-8

=head1 TODO

=head2 document methods

=over

=item add_to_table_of_contents

=item table_of_contents

=item _html_header

=item set_table_of_contents

=item get_css_file

=item user_css

=item add_cover

=back

=head2 write more tests

Untile now the test just cover the basics. Tests of output should be added.

=head1 AUTHOR

Renee Bäcker <reneeb@cpan.org>, Boris Däppen <boris_daeppen@bluewin.ch>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Renee Bäcker, Boris Däppen.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
