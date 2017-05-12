package HTML::SiteTear::PageFilter;

use strict;
use warnings;
use File::Basename;
use Encode;
use Encode::Guess;
use URI;
#use Data::Dumper;

use HTML::Parser 3.40;
use HTML::HeadParser;
use base qw(HTML::Parser Class::Accessor);
__PACKAGE__->mk_accessors(qw(has_remote_base
                            page));

use HTML::Copy;

our $VERSION = '1.45';
our @htmlSuffix = qw(.html .htm .xhtml);

=head1 NAME

HTML::SiteTear::PageFilter - change link pathes in HTML files.

=head1 SYMPOSIS

 use HTML::SiteTear::PageFilter;

 # $page must be an instance of L<HTML::SiteTear::Page>.
 $filter = HTML::SiteTear::PageFilter->new($page);
 $fileter->parse_file();

=head1 DESCRIPTION

This module is to change link pathes in HTML files. It's a sub class of L<HTML::Parser>. Internal use only.

=head1 METHODS

=head2 new

    $filter = HTML::SiteTear::PageFilter->new($page);

Make an instance of this moduel. $parent must be an instance of HTML::SiteTear::Root or HTML::SiteTear::Page. This method is called from $parent.

=cut

sub new {
    my ($class, $page) = @_;
    my $parent = $class->SUPER::new();
    my $self = bless $parent, $class;
    $self->page($page);
    $self->{'allow_abs_link'} = $page->source_root->allow_abs_link;
    $self->{'use_abs_link'} = 0;
    $self->attr_encoded(1);
    $self->has_remote_base(0);
    return $self;
}

=head2 parse_file

    $filter->parse_file;

Parse the HTML file given by $page and change link pathes. The output data are retuned thru the method "write_data".

=cut

sub parse_file {
    my ($self) = @_;
    my $p = HTML::Copy->new($self->page->source_path);
    $self->page->set_binmode($p->io_layer);
    $self->SUPER::parse($p->source_html);
}

=head1 SEE ALOSO

L<HTML::SiteTear>, L<HTML::SiteTear::Item>,  L<HTML::SiteTear::Root>, L<HTML::SiteTear:Page>

=head1 AUTHOR

Tetsuro KURITA <tkurita@mac.com>

=cut

##== private methods
sub output {
  my ($self, $data) = @_;
  $self->page->write_data($data);
}

##== overriding methods of HTML::Parser

sub declaration { $_[0]->output("<!$_[1]>")     }
sub process     { $_[0]->output($_[2])          }
sub end         { $_[0]->output($_[2])          }
sub text        { $_[0]->output($_[1])          }

sub comment {
    my ($self, $comment) = @_;

    if ($self->{'allow_abs_link'}) {
        if ($comment =~ /^\s*begin abs_link/) {
            $self->{'use_abs_link'} = 1;
        
        } elsif($comment =~ /^\s*end abs_link/) {
            $self->{'use_abs_link'} = 0;
        }
    }

    $self->output("<!--$comment-->");
}

sub start {
    my ($self, $tag, $attr_dict, $attr_names, $tag_text) = @_; 
    my $page = $self->page;
    my $empty_tag_end = ($tag =~ /\/>$/) ? ' />' : '>';
    
    if ($self->has_remote_base) {
        return $self->output($tag_text);
    }
    
    my $process_link = sub {
        my ($target_attr, $folder_name, $kind) = @_;
        if (my $link = $attr_dict->{$target_attr}) {
            if ($self->{'use_abs_link'}) {
                $attr_dict->{$target_attr} = $page->build_abs_url($link);
            } else {
                unless ($kind) {$kind = $folder_name};
                $attr_dict->{$target_attr} 
                        = $page->change_path($link, $folder_name, $kind);
            }
            return HTML::Copy->build_attributes($attr_dict, $attr_names);
        }
        return ();
    };
    
    if ($tag eq 'base') {
        my $uri = URI->new($attr_dict->{'href'});
        if (!($uri->scheme) or ($uri->scheme eq 'file')) {
            $page->base_uri($uri->abs($page->base_uri));
            $tag_text  = '';
        } else {
            $self->has_remote_base(1);
        }
    #treat image files    
    } elsif ($tag eq 'img') {
        if (my $tag_attrs = &$process_link('src', $page->resource_folder_name)) {
            $tag_text = "<$tag $tag_attrs".$empty_tag_end;
        }

    } elsif ($tag eq 'body') { #background images
        if (my $tag_attrs = &$process_link('background', $page->resource_folder_name)) {
            $tag_text = "<$tag $tag_attrs>";
        }
    }
    #linked stylesheet
    elsif ($tag eq 'link') {
        my $folder_name = $page->resource_folder_name;
        my $kind = $folder_name;
        my $relation;
        if (defined( $relation = ($attr_dict ->{'rel'}) )){
            $relation = lc $relation;
            if ($relation eq 'stylesheet') {
                $kind = 'css';
            }
        }
        
        if (my $tag_attrs = &$process_link('href', $folder_name, $kind)) {
            $tag_text = "<$tag $tag_attrs".$empty_tag_end;
        }
    }
    #frame
    elsif ($tag eq 'frame') {
        if (my $tag_attrs = &$process_link('src', $page->page_folder_name, 'page')) {
            $tag_text = "<$tag $tag_attrs".$empty_tag_end;
        }    
    }
    #javascript
    elsif (($tag eq 'script') or ($tag eq 'embed')) {
        if (my $tag_attrs = &$process_link('src', $page->resource_folder_name)) {
            $tag_text = "<$tag $tag_attrs>";
        }
    }
    #link
    elsif ($tag eq 'a') {
        if ( exists($attr_dict->{'href'}) ) {
            my $href =  $attr_dict->{'href'};
            my $kind = 'page';
            my $folder_name = $page->page_folder_name;
            if ($href !~/(.+)#(.*)/) {
                my @matchedSuffix = grep {$href =~ /\Q$_\E$/} @htmlSuffix;
                unless (@matchedSuffix) {
                    $folder_name = $page->resource_folder_name;
                    $kind = $folder_name;
                }
            }
            if (my $tag_attrs = &$process_link('href', $folder_name, $kind)) {
                $tag_text = "<$tag $tag_attrs>";
            }
        }
    }
    elsif ($tag eq 'param') {
        if (my $tag_attrs = &$process_link('src', $page->resource_folder_name)) {
            $tag_text = "<$tag $tag_attrs".$empty_tag_end;
        }        
    }
    
    $self->output($tag_text);
}

1;
