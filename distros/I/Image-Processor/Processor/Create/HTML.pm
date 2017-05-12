package Image::Processor::Create::HTML;

use base ('Image::Processor::Base');

use Text::Template;

sub table_columns {
    my ($self,$set) = @_;
    $self->{'table_columns'} ||= '4';
    return $self->{'table_columns'} if !$set;
    $self->{'table_columns'} = $set;
}

sub create_thumbnails_html {
    my ($self,$vars) = @_;
       #thumb_suffix => $sm_suffix,
       #full_suffix  => $full_suffix,
    if (
        ($vars->{'thumb_suffix'} eq '' &&
        $vars->{'full_suffix'} eq '')
        && !$vars->{'is_custom'}) {
        
        $self->graceful_exit->(qq~
    I didn't get all the parameters
    I need for 'create_thumbnails_html'
    It requires the suffix for the thumbnails
    and the "full" picture.
~);
    }

    print "Creating HTML page for thumbnails\n";
    
    my $template = Text::Template->new(TYPE => 'STRING',  SOURCE => $self->thumbnail_template);

    $vars->{ 'image_list' } = $self->image_list();
    $vars->{ 'orderid'    } = $self->{'orderid'};
    $vars->{ 'columns'    } = $self->table_columns();

    my $result = $template->fill_in(HASH => $vars);
    
    open(FULL,">" . $self->output_directory() . "/thumbnail.html") or die "$!";
    print FULL $result;
    close FULL;
}

sub create_index_html {
    my ($self) = @_;
    my $number_of_photos = @{$self->image_list()};
    print "Creating HTML page for index\n";
    
    my $template = Text::Template->new(
         TYPE => 'STRING',
         SOURCE => $self->index_template
         );

    my %vars = (
       orderid          => $self->{'orderid'},
       number_of_photos => $number_of_photos,
       date             => $self->{'date'} || 'Unkown',
    );

    my $html = $template->fill_in(HASH => \%vars);  
    
    open(INDEX,">" . $self->output_directory() . "/index.html") or die "$!";
    print INDEX $html;
    close INDEX;

}

sub index_template {
    my ($self,$set) = @_;
    if ($set) {
        $self->{'index_template'} = $set;
        return;
    }
    
    return $self->{'index_template'} || <<"EOF";
    <html>
    <head>
    <title>Index for CD number {\$orderid}</title>
    </head>
    <body>
    This image archive has {\$number_of_photos} photos in it.<br>
    The source CD was created on {\$date}<br>
    <br>
<a href="thumbnail.html">Show all photos as thumbnails</a><br>
    </body>
</html>

EOF

}

sub thumbnail_template {
    my ($self,$set) = @_;
    if ($set) {
        $self->{'thumbnail_template'} = $set;
        return;
    }
    
    return $self->{'thumbnail_template'} || <<"EOF";
<html>
    <head>
    <title>Thumbnails of Images from {\$orderid}</title>
    </head>
    <body>
    <a href="../">Return to the Album List</a><br>
    <a href="">Return to Album opening page</a><br>
    
    <table align="center">
        <tr>
    { my \$count = 1;
      my \$html = '';
    foreach my \$file (\@image_list) {
        \$html .= qq~
            <td valign="center" align="center"><a href="\$full_suffix\$file"><img src="\$thumb_suffix\$file"></a><td>~;
        if (\$count % \$columns == 0) { \$html .= qq~
        </tr>
        <tr>~; }
        \$count ++;
    }
    \$html    
    }
        </tr>
    </table>
    </body>
</html>

EOF

}

1;