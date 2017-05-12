package Jifty::Plugin::Media::View;

#use utf8;
use strict;
use warnings;
use Jifty::View::Declare -base;

=head1 NAME

Jifty::Plugin::Media::View - TD views for media plugin

=cut

template 'media_browse' => sub {
    my $dir = get('dir') || '';

    my $read = Jifty::Plugin::Media->read_dir($dir);
    return if ! $read;
    my @folders = @{$read->{Folders}};
    my @files = @{$read->{Files}};

    return if scalar @folders + scalar @files == 0;

    outs_raw "<ul class=\"jqueryFileTree\" style=\"display: none;\">";

    # print Folders
    foreach my $file (sort @folders) {
        outs_raw '<li class="directory collapsed"><a href="#" rel="' . 
              &HTML::Entities::encode($dir . $file) . '/">' . 
              &HTML::Entities::encode($file) . '</a></li>';
    };

    # print Files
    foreach my $file (sort @files) {
        $file =~ /\.(.+)$/;
        next if $file =~ /^\./; #don't show hidden files
        my $ext = $1 || '';
        outs_raw '<li class="file ext_' . $ext . '"><a href="#" rel="' . 
            &HTML::Entities::encode($dir . $file) . '">' .
            &HTML::Entities::encode($file) . '</a></li>';

    };

   outs_raw "</ul>\n";
};

template 'media_manage_page' => page {
    render_region ( name => 'media_manage', path => 'media_manage');
};


template 'media_manage_dir' => sub {
    my $self = shift;
    
    my $dir = get('mediadir') || '';
    my $rootdir = get('rootdir') || '/';

    $dir =~ s/\.\.//g; $dir =~ s/^\.//;
    $dir .= '/' if $dir !~ m/\/$/;
    $dir = '/'.$dir if $dir !~ m/^\//;

    $rootdir =~ s/\.\.//g; $rootdir =~ s/^\.//;
    $rootdir .= '/' if $rootdir !~ m/\/$/;
    $rootdir = '/'.$rootdir if $rootdir !~ m/^\//;


outs_raw <<"EOF";
<div id="folder"></div>

<script language="javascript">
jQuery(document).ready( function() {
    jQuery('#folder').fileTree ({ 
        root: '$rootdir',
        open: '$dir',
        script: '/media_browse',
        expandSpeed: 300,
        collapseSpeed: 300,
        dirAndFiles: true,
        multiFolder: false
        }, function(file) {
            jQuery('#static-selected-id').val(file);
        });
});
</script>
EOF

};

template 'media_manage' => sub {
    my $self = shift;

    my $dir = get('mediadir') || '';
    # don't allow relative path
    $dir =~ s/\.\.//g;
    # don't allow cached path
    $dir =~ s/^\.//;
    $dir .= '/' if $dir !~ m/\/$/;
    $dir = '/'.$dir if $dir !~ m/^\//;

    my $rootdir = get('rootdir') || '/';
    $rootdir =~ s/\.\.//g; $rootdir =~ s/^\.//;
    $rootdir .= '/' if $rootdir !~ m/\/$/;
    $rootdir = '/'.$rootdir if $rootdir !~ m/^\//;

    $dir = $rootdir if($dir eq '/' && $rootdir);

  my ($plugin) = Jifty->find_plugin('Jifty::Plugin::Media');

  div { class is 'media-manage';
    h2 { _('Manage media') };
    
    render_region( name => 'fmediadir', path => 'media_manage_dir');

  div { class is 'menu';
    form {
        my $upload = new_action('Jifty::Plugin::Media::Action::ManageFile', moniker => 'upload');
        my $selected_name = $upload->form_field('selected')->id() ;
        div { attr { class => "form_field argument-selected"};
            label { attr { class => "label text argument-selected", for => "static-selected-id" };
                outs '/static/'.$plugin->default_root;
            };
        outs_raw('<input name="'.$selected_name.'" id="static-selected-id" value="'.$dir.'" class="widget argument-selected" READONLY>');
        span { attr { class => "hints text argument-selected"}; outs _('Current selected url'); };
        foreach my $i ( qw(error warning canonicalization_note) ) {
            outs_raw('<span style ="display: none;"; class = "'.$i.' text argument-selected" id = "'.$i.'-'.$selected_name.'"></span>');
            #span { attr { style =>"display: none;"; class => "$i text argument-selected"; id => $i.'-'.$selected_name}; outs ' ';};
        };
        };
        div { class is 'submit_button';
        $upload->button (label => _('View'), class => 'view',
            onclick => [
            { submit => { action => $upload, arguments => { action => 'view' } } },
            { refresh => 'fmediadir', }, 
            { args => { viewfile => { result_of => $upload, name => 'viewfile' } } },
            ]);
        $upload->button (label => _('Delete'), class => 'delete',
            onclick => [
            {  confirm => _('Really delete?'),  submit => { action => $upload, arguments => { action => 'delete' } } },
            { refresh => 'fmediadir', }, 
            { args => { mediadir => { result_of => $upload, name => 'dir' }, rootdir => $rootdir } },
            ]);
        };
        my $view = get('viewfile') || '';
        if ($view) {
            return if $view !~ /^\//;
            $view =~ /\.(\w+)$/;
            my $ext = $1 || '';
            div { class is 'preview';
                my ($sname,$size,$date) = Jifty::Plugin::Media->file_info($view);
                outs( _(' preview for ') ); outs $view;
                br {};
                if ( $ext eq 'png' || $ext eq 'gif' || $ext eq 'jpg' ) {
                    img { attr { src => $view }; };
                }
                else {
                    hyperlink( label => _('Download file'), class => 'preview', url => $view);
                };
                div { class is 'info';
                    br {};
                    outs $sname.' : '.$size;
                    br {}; outs $date;
                    br {}; br {};
                };
            };
        };

        render_param($upload,'create_dir');
        div { class is 'submit_button';
        $upload->button (label => _('Create dir'), class => 'add-folder',
            onclick => [
            { submit => { action => $upload, arguments => { action => 'create_dir' } } },
            { args => { mediadir => { result_of => $upload, name => 'dir' }, rootdir => $rootdir } },
            { refresh => 'fmediadir', }
            ]);
        };

        render_param($upload,'file');
        div { class is 'submit_button';
        hyperlink (label => _('Upload'), class => 'upload',
            onclick => [
            { submit => { action => $upload, arguments => { action => 'upload' } } },
            { refresh => 'fmediadir', }, 
            { args => { mediadir => { result_of => $upload, name => 'dir' }, rootdir => $rootdir } },
            ]);
        };
    };
  };

  };
};


1;
