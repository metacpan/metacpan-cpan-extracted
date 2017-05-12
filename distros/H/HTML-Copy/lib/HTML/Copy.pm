package HTML::Copy;

use 5.008;
use strict;
use warnings;
use File::Spec;
use File::Basename;
use File::Path;
use utf8;
use Encode;
use Encode::Guess;
use Carp;

use HTML::Parser 3.40;
use HTML::HeadParser;
use URI::file;

use base qw(HTML::Parser Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(link_attributes
                            has_base));

#use Data::Dumper;

our @default_link_attributes = ('src', 'href', 'background', 'csref', 'livesrc', 'user');
# 'livesrc', 'user' and 'csref' are uesed in Adobe GoLive

=head1 NAME

HTML::Copy - copy a HTML file without breaking links.

=head1 VERSION

Version 1.31

=cut

our $VERSION = '1.31';

=head1 SYMPOSIS

  use HTML::Copy;

  HTML::Copy->htmlcopy($source_path, $destination_path);

  # or

  $p = HTML::Copy->new($source_path);
  $p->copy_to($destination_path);

  # or

  open my $in, "<", $source_path;
  $p = HTML::Copy->new($in)
  $p->source_path($source_path);    # can be omitted, 
                                    # when $source_path is in cwd.

  $p->destination_path($destination_path) # can be omitted, 
                                          # when $source_path is in cwd.
  open my $out, ">", $source_path;
  $p->copy_to($out);

=head1 DESCRIPTION

This module is to copy a HTML file without beaking links in the file. This module is a sub class of HTML::Parser.

=head1 REQUIRED MODULES

=over 2

=item L<HTML::Parser>

=back

=head1 CLASS METHODS

=head2 htmlcopy

    HTML::Copy->htmlcopy($source_path, $destination_path);

Parse contents of $source_path, change links and write into $destination_path.

=cut

sub htmlcopy($$$) {
    my ($class, $source_path, $destination_path) = @_;
    my $p = $class->new($source_path);
    return $p->copy_to($destination_path);
}

=head2 parse_file

    $html_text = HTML::Copy->parse_file($source_path, 
                                        $destination_path);

Parse contents of $source_path and change links to copy into $destination_path. But don't make $destination_path. Just return modified HTML. The encoding of strings is converted into utf8.

=cut

sub parse_file($$$) {
    my ($class, $source, $destination) = @_;
    my $p = $class->new($source);
    return $p->parse_to($destination);
}


=head1 CONSTRUCTOR METHODS

=head2 new

    $p = HTML::Copy->new($source);

Make an instance of this module with specifying a source of HTML.

The argument $source can be a file path or a file handle. When a file handle is passed, you may need to indicate a file path of the passed file handle by the method L<"source_path">. If calling L<"source_path"> is omitted, it is assumed that the location of the file handle is the current working directory.

=cut

sub new {
    my $class = shift @_;
    my $self = $class->SUPER::new();
    if (@_ > 1) {
        my %args = @_;
        my @keys = keys %args;
        @$self{@keys} = @args{@keys};
    } else {
        my $file = shift @_;
        my $ref = ref($file);
        if ($ref =~ /^Path::Class::File/) {
            $self->source_path($file);
        } elsif (! $ref && (ref(\$file) ne 'GLOB')) {
            $self->source_path($file);
        } else {
            $self->source_handle($file);
        }
    }
    
    $self->link_attributes(\@default_link_attributes);
    $self->has_base(0);
    $self->attr_encoded(1);
    return $self;
}


=head1 INSTANCE METHODS

=head2 copy_to

    $p->copy_to($destination)

Parse contents of $source given in new method, change links and write into $destination.

The argument $destination can be a file path or a file handle. When $destination is a file handle, you may need to indicate the location of the file handle by a method L<"destination_path">. L<"destination_path"> must be called before calling L<"copy_to">. When calling L<"destination_path"> is omitted, it is assumed that the locaiton of the file handle is the current working directory.

=cut

sub copy_to {
    my ($self, $destination) = @_;
    my $io_layer = $self->io_layer();
    my $fh;
    if (!ref($destination) && (ref(\$destination) ne "GLOB")) {
        $destination = $self->set_destination($destination);
        open $fh, ">$io_layer", $destination
                             or croak "can't open $destination.";
    } else {
        $fh = $destination;
        binmode($fh, $io_layer);
    }
    
    $self->{'output_handle'} = $fh;
    $self->SUPER::parse($self->{'source_html'});
    $self->eof;
    close $fh;
    $self->source_handle(undef);
    return $self->destination_path;
}

=head2 parse_to

    $p->parse_to($destination_path)

Parse contents of $source_path given in new method, change links and return HTML contents to wirte $destination_path. Unlike copy_to, $destination_path will not created and just return modified HTML. The encoding of strings is converted into utf8.

=cut

sub parse_to {
    my ($self, $destination_path) = @_;
    $destination_path = $self->destination_path($destination_path);
    
    my $output = '';
    open my $fh, ">", \$output;
    $self->copy_to($fh);
    return Encode::decode($self->encoding, $output);
}

=head1 ACCESSOR METHODS

=head2 source_path

    $p->source_path
    $p->source_path($path)

Get and set a source location. Usually source location is specified with the L<"new"> method. When a file handle is passed to L<"new"> and the location of the file handle is not the current working directory, you need to use this method.

=cut

sub source_path {
    my $self = shift @_;
    
    if (@_) {
        my $path = shift @_;
        $self->{'source_path'} = $path;
        $self->source_uri(URI::file->new_abs($path));
    }
    
    return $self->{'source_path'};
}


=head2 destination_path

    $p->destination_path
    $p->destination_path($path)

Get and set a destination location. Usually destination location is specified with the L<"copy_to">. When a file handle is passed to L<"copy_to"> and the location of the file handle is not the current working directory, you need to use this method before L<"copy_to">.

=cut

sub destination_path {
    my $self = shift @_;
    
    if (@_) {
        my $path = shift @_;
        $self->{'destination_path'} = $path;
        $self->destination_uri(URI::file->new_abs($path));
    } 
    
    return $self->{'destination_path'};
}

=head2 enchoding

    $p->encoding;

Get an encoding of a source HTML.

=cut

sub encoding {
    my ($self) = @_;
    if ($self->{'encoding'}) {
        return $self->{'encoding'};
    }
    my $in = $self->source_handle;
    my $data = do {local $/; <$in>;};
    my $p = HTML::HeadParser->new;
    $p->utf8_mode(1);
    $p->parse($data);
    my $content_type = $p->header('content-type');
    my $encoding = '';
    if ($content_type) {
        if ($content_type =~ /charset\s*=(.+)/) {
            $encoding = $1;
        }
    }
    
    unless ($encoding) {
        my $decoder;
        if (my @suspects = $self->encode_suspects) {
            $decoder = Encode::Guess->guess($data, @suspects);
        }
        else {
            $decoder = Encode::Guess->guess($data);
        }
        
        ref($decoder) or 
                    die("Can't guess encoding of ".$self->source_path);
                    
        $encoding = $decoder->name;
    }
    
    $self->{'source_html'} = Encode::decode($encoding, $data);
    $self->{'encoding'} = $encoding;
    return $encoding;
}

=head2 io_layer

    $p->io_layer;
    $p->io_layer(':utf8');

Get and set PerlIO layer to read the source path and to write the destination path. Usually it was automatically determined by $source_path's charset tag. If charset is not specified, Encode::Guess module will be used.

=cut

sub io_layer {
    my $self = shift @_;
    if (@_) {
        $self->{'io_layer'} = shift @_;
    }
    else {
        unless ($self->{'io_layer'}) {
            $self->{'io_layer'} = $self->check_io_layer();
        }
    }
    
    return $self->{'io_layer'};
}

=head2 encode_suspects

    @suspects = $p->encode_sustects;
    $p->encode_suspects(qw/shiftjis euc-jp/);

Add suspects of text encoding to guess the text encoding of the source HTML. If the source HTML have charset tag, it is not required to add suspects.

=cut

sub encode_suspects {
    my $self = shift @_;
    
    if (@_) {
        my @suspects = @_;
        $self->{'EncodeSuspects'} = \@suspects;
    }
    
    if (my $suspects_ref = $self->{'EncodeSuspects'}) {
        return @$suspects_ref;
    }
    else {
        return ();
    }
}

=head2 source_html

    $p->source_html;

Obtain source HTML's contents

=cut

sub source_html {
    my ($self) = @_;
    $self->io_layer;
    return $self->{'source_html'};
}

=head1 NOTE

Cleanuped pathes should be given to HTML::Copy and it's instances. For example, a verbose path like '/aa/bb/../cc' may cause converting links wrongly. This is a limitaion of the URI module's rel method. To cleanup pathes, Cwd::realpath is useful.


=head1 AUTHOR

Tetsuro KURITA <tkurita@mac.com>

=cut

##== overriding methods of HTML::Parser

sub declaration { $_[0]->output("<!$_[1]>")     }
sub process     { $_[0]->output($_[2])          }
sub end         { $_[0]->output($_[2])          }
sub text        { $_[0]->output($_[1])          }

sub comment     {
    my ($self, $comment) = @_;
    if ($comment =~ /InstanceBegin template="([^"]+)"/) {
        my $uri = URI->new($1);
        my $newlink = $self->change_link($uri);
        $comment = " InstanceBegin template=\"$newlink\" ";
    }
    
    $self->output("<!--$comment-->");
}

sub process_link {
    my ($self, $link_path)= @_;
    return undef if ($link_path =~ /^\$/);
    return undef if ($link_path =~ /^\[%.*%\]$/);
    my $uri = URI->new($link_path);
    return undef if ($uri->scheme);
    return $self->change_link($uri);
}

sub start {
    my ($self, $tag, $attr_dict, $attr_names, $tag_text) = @_; 
    
    unless ($self->has_base) {
        if ($tag eq 'base') {
            $self->has_base(1);
        }
        
        my $is_changed = 0;
        foreach my $an_attr (@{$self->link_attributes}) {
            if (exists($attr_dict->{$an_attr})){
                my $newlink = $self->process_link($attr_dict->{$an_attr});
                next unless ($newlink);
                $attr_dict->{$an_attr} = $newlink;
                $is_changed = 1;
            }
        }
        
        if ($tag eq 'param') {
            if ($attr_dict->{'name'} eq 'src') {
                my $newlink = $self->process_link($attr_dict->{'value'});
                if ($newlink) {
                    $attr_dict->{'value'} = $newlink;
                    $is_changed = 1;
                }
            }
        }
        
        if ($is_changed) {
            my $attrs_text = $self->build_attributes($attr_dict, $attr_names);
            $tag_text = "<$tag $attrs_text>";
        }
    }
    
    $self->output($tag_text);
}

##== private functions

sub complete_destination_path {
    my ($self, $dir) = @_;
    my $source_path = $self->source_path
        or croak "Can't resolve a file name of the destination, because a source path is not given.";
    my $filename = basename($source_path)
        or croak "Can't resolve a file name of the destination, because given source path is a directory.";
    return File::Spec->catfile($dir, $filename);
    
}
    
sub set_destination {
    my ($self, $destination_path) = @_;
    
    if (-d $destination_path) {
        $destination_path = $self->complete_destination_path($destination_path);
    } else {
        my ($name, $dir) = fileparse($destination_path);
        unless ($name) {
            $destination_path = $self->complete_destination_path($destination_path);
        }
        
        mkpath($dir);
    }

    return $self->destination_path($destination_path);
}

sub check_io_layer {
    my ($self) = @_;
    my $encoding = $self->encoding;
    return '' unless ($encoding);
    
    my $io_layer = '';
    if (grep {/$encoding/} ('utf8', 'utf-8', 'UTF-8') ) {
        $io_layer = ":utf8";
    }
    else {
        $io_layer = ":encoding($encoding)";
    }
    return $io_layer;
}

sub build_attributes {
    my ($self, $attr_dict, $attr_names) = @_;
    my @attrs = ();
    foreach my $attr_name (@{$attr_names}) {
        if ($attr_name eq '/') {
            push @attrs, '/';
        } else {
            my $attr_value = $attr_dict->{$attr_name};
            push @attrs, "$attr_name=\"$attr_value\"";
        }
    }
    return join(' ', @attrs);
}

sub change_link {
    my ($self, $uri) = @_;
    my $result_uri;
    my $abs_uri = $uri->abs( $self->source_uri );
    my $abs_path = $abs_uri->file;

    if (-e $abs_path) {
        $result_uri = $abs_uri->rel($self->destination_uri);
    } else {
        warn("$abs_path is not found.\nThe link to this path is not changed.\n");
        return "";
    }
    
    return $result_uri->as_string;
}

sub output {
    my ($self, $out_text) = @_;
    print {$self->{'output_handle'}} $out_text;
}

sub source_handle {
    my $self = shift @_;
    
    if (@_) {
        $self->{'source_handle'} = shift @_;
    } elsif (!$self->{'source_handle'}) {
        my $path = $self->source_path or croak "source_path is undefined.";
        open my $in, "<", $path or croak "Can't open $path.";
        $self->{'source_handle'} = $in;
    }
    
    return $self->{'source_handle'}
}

sub source_uri {
    my $self = shift @_;
    if (@_) {
        $self->{'source_uri'} = shift @_;
    } elsif (!$self->{'source_uri'}) {
        $self->{'source_uri'} = do {
            if (my $path = $self->source_path) {
                URI::file->new_abs($path);
            } else {
                URI::file->cwd;
            }
        }
    } 
    
    return $self->{'source_uri'}
}

sub destination_uri {
    my $self = shift @_;
    
    if (@_) {
        $self->{'destination_uri'} = shift @_;
    } elsif (!$self->{'destination_uri'}) {
        $self->{'destination_uri'} = do {
            if (my $path = $self->destination_path) {
                URI::file->new_abs($path);
            } else {
                URI::file->cwd;
            }
        }
    }
    
    return $self->{'destination_uri'};
}



1;
