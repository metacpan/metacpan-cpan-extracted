use strict;
use warnings;

=head1 NAME

Jifty::Plugin::Media::Action::ManageFile - upload file form

=cut

package Jifty::Plugin::Media::Action::ManageFile;

use base qw/Jifty::Plugin::Media::Action Jifty::Action/;

use Jifty::Param::Schema;
use Jifty::Action schema {
    param 'selected'; # =>
#        type is 'hidden';
    param 'create_dir' =>
        hints is _('ascii char, no white space'),
        label is _('Create dir');
    param file =>
        label is _('File'),
        render as 'Upload';
    param action =>
        is mandatory,
        valid_values are qw(upload delete view create_dir);
};

=head1 METHODS

=head2 take_action

=cut

sub take_action {
    my $self = shift;

    my ($plugin) = Jifty->find_plugin('Jifty::Plugin::Media');

    my $root = $plugin->real_root();

    my $action = $self->argument_value('action');

    my $selected = $self->argument_value('selected');
    my $selected_dir = 1 if (-d $root.'/'.$selected);

    my $current_dir = ($selected_dir) ? $selected : File::Basename::dirname($selected);
    $current_dir =~ s/^\///;
    $current_dir =~ s/\/$//;

    if ( $action eq 'delete' ) {
        my $delete = $self->argument_value('selected');
        if ( ! -e $root.'/'.$selected ) {
            $self->result->error(_('no more exist'));
        }
        else {
            if  (-f $root.'/'.$selected ) {
                my $res = unlink $root.'/'.$selected;
                $self->result->error(_('can not delete this file')) if !$res;
            };
            if  (-d $root.'/'.$selected ) {
                rmdir  $root.'/'.$selected;
                $self->result->error($!) if $!;
            };

        };
    };


    if ( $action eq ('create_dir') ) {
        my $dir = $self->argument_value('selected');
        my $create_dir = $self->argument_value('create_dir');
        $create_dir = Jifty::Plugin::Media->clean_dir_name($create_dir);
        my $destdir = $root.'/'.$dir;
        if ($create_dir) {
           my $newdir = $destdir.'/'.$create_dir;
           if ( ! -d $newdir) {
                eval { File::Path::mkpath($newdir, 0, 0775); };
                $self->result->error($@) if $@;
           };
        };
    };

    if( $action eq ('upload') ) {
        my $dir = $self->argument_value('selected');
        my $destdir = $root.'/'.$dir;
        $destdir .= '/' if $destdir !~ m/\/$/;

        my $fh = $self->argument_value('file');
        if ($fh) {
            my $filename = scalar($fh);
            $filename = Jifty::Plugin::Media->clean_file_name($filename);

            local $/;
            binmode $fh;
            if (open FILE, '>', $destdir.$filename) {
                print FILE <$fh>; close FILE ;
            }
            else {
                $self->result->error($!);
            };
        };
    };

    if ( $action eq 'view' ) {
        my $url = $self->argument_value('selected');
        my $redirect = '/static/'.$plugin->default_root().$url;
        $self->result->content( viewfile => $redirect )
            if  (-f $root.'/'.$selected );
        return 1;
    };
    

    $self->result->content( dir => $current_dir );


    $self->report_success if not $self->result->failure;

   return 1;
};

=head2 report_success

=cut

sub report_success {
    my $self = shift;
    # Your success message here
    $self->result->message(_('Success'));
};

1;


1;
