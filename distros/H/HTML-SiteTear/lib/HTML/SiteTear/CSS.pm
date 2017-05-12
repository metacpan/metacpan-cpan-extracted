package HTML::SiteTear::CSS;

use strict;
use warnings;
use File::Spec;
use File::Basename;
use File::Path;

use base qw(HTML::SiteTear::Item);
our $VERSION = '1.45';

=head1 NAME

HTML::SiteTear::CSS - treat cascading style sheet files.

=head1 SYMPOSIS

  use HTML::SiteTear::CSS;
  
  $item = HTML::SiteTear::CSS->new($parent,$source_path,$kind);
  $item->linkpath($path); # usually called from the mothod "change_path"
                          # of the parent object.
  $item->copy_to_linkpath();
  $item->copy_linked_files();

=head1 DESCRIPTION

This module is to treat cascading style sheet files liked from web pages. It's also a sub class of the L<HTML::SiteTear::Item>. Internal use only.

=head1 METHODS

=head2 new

    $css = HTML::SiteTear::CSS->new('parent' => $parent, 
                                    'source_path' => $source_path);

Make an instance of this moduel. The parent object "$parent" must be an instance of HTML::SiteTear::Page. This method is called from $parent.

=cut

sub new {
    my $class = shift @_;
    my $self = $class->SUPER::new(@_);
    unless ($self->kind ) { $self->kind('css') };
    $self->{'linkedFiles'} = [];
    return $self;
}

=head2 css_copy

    $css->css_copy($source_path, $target_path);

Copy a cascading style sheet file "$source_path" into $target_path dealing with internal links. This method is called form the method "copy_to_linkpath".

=cut

sub css_copy {
    my ($self, $target_path) = @_;
    my $source_path = $self->source_path;
    open(my $CSSIN, "< $source_path");
    open(my $CSSOUT, "> $target_path");
    while (my $a_line = <$CSSIN>) {
        if ($a_line =~ /url\(([^()]+)\)/) {
            my $new_link = $self->change_path($1, $self->resource_folder_name, 'css');
            $a_line =~ s/url\([^()]+\)/url\($new_link\)/;
        }
        print $CSSOUT $a_line;
    }
    close($CSSIN);
    close($CSSOUT);
}

=head2 copy_to_linkpath

    $item->copy_to_linkpath;

Copy $source_path into new linked path from $parent.

=cut

sub copy_to_linkpath {
    my ($self) = @_;
    my $source_path = $self->source_path;
    unless ($self->exists_in_copied_files($source_path)) {
        unless (-e $source_path) {
            die("The file \"$source_path\" does not exists.\n");
            return;
        }
        
        my $target_path = do {
            if (my $target_uri = $self->item_in_filemap($source_path)) {
                $target_uri->file;
            } else {
                $self->link_uri->file;
            }};

        print "Copying asset...\n";
        print "from : $source_path\n";
        print "to : $target_path\n\n";
        ($source_path eq $target_path) and die "source and target is same file.\n";
        mkpath(dirname($target_path));
        $self->target_path($target_path); #temporary set for css_copy
        $self->css_copy($target_path);
        $self->add_to_copyied_files($source_path);
        $self->copy_linked_files;
    }
}

=head1 SEE ALSO

L<HTML::SiteTear>, L<HTML::SiteTear::Page>, L<HTML::SiteTear::CSS>, L<HTML::SiteTear::Root>

=head1 AUTHOR

Tetsuro KURITA <tkurita@mac.com>

=cut

1;
