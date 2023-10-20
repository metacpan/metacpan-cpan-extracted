use v5.12;
use warnings;

package Kephra::App::Window;
use base qw(Wx::Frame);

use Kephra::App::Dialog;
use Kephra::App::Editor;
use Kephra::App::SearchBar;
use Kephra::App::ReplaceBar;
use Kephra::App::Window::Menu;
use Kephra::IO::LocalFile;

sub new {
    my ($class, $parent) = @_;
    my $self = $class->SUPER::new( undef, -1, '', [-1,-1], [1200,1000] );
    $self->CreateStatusBar(3);
    $self->SetStatusWidths(100, 150, -1);
    $self->SetStatusBarPane(2);

    $self->{'app'} = $parent;
    $self->{'editor'} = Kephra::App::Editor->new($self, -1);
    $self->{'searchbar'} = Kephra::App::SearchBar->new($self, -1);
    $self->{'replacebar'} = Kephra::App::ReplaceBar->new($self, -1);
    Kephra::App::Window::Menu::mount( $self );

    my $sizer = Wx::BoxSizer->new( &Wx::wxVERTICAL );
    $sizer->Add( $self->{'editor'}, 1, &Wx::wxEXPAND, 0);
    $sizer->Add( $self->{'searchbar'}, 0, &Wx::wxGROW, 0);
    $sizer->Add( $self->{'replacebar'}, 0, &Wx::wxGROW, 0);

    $self->SetSizer($sizer);

    Wx::Window::SetFocus( $self->{'editor'} );
    Wx::Event::EVT_KEY_DOWN( $self, sub {
        my ($self, $event) = @_;
        my $code = $event->GetKeyCode ;
        if   ($code == &Wx::WXK_F11)        {  $self->ShowFullScreen( not $self->IsFullScreen ); say  "F11"  }
        else { $event->Skip }
    });
    Wx::Event::EVT_CLOSE( $self, sub {
        my ($self, $event) = @_;
        if ($self->{'editor'}->GetModify() and not exists $self->{'dontask'}){
            my $ret = Kephra::App::Dialog::yes_no_cancel( "\n".' save file ?  ');
            return                   if $ret ==  &Wx::wxCANCEL;
            $self->save_file if $ret ==  &Wx::wxYES;
        }
        $event->Skip(1);
    });
    Wx::Event::EVT_CLOSE( $self,       sub {
        $self->config->set_value( $self->{'file'}, 'file');
        $self->{'editor'}->save_config( $self->config );
        $self->{'searchbar'}->save_config( $self->config );
        $_[1]->Skip(1);
    });

    # recreate starting state
    $self->set_title();
    $self->{'searchbar'}->show(1);
    $self->{'replacebar'}->show(0);

    $self->read_file( $self->config->get_value('file') ); # open the last opened file
    $self->{'editor'}->apply_config( $self->config );
    $self->{'searchbar'}->apply_config( $self->config );

    return $self;
}

sub config {$_[0]{'app'}{'config'}}

sub new_file {
    my $self = shift;
    $self->{'file'} = '';
    $self->{'editor'}->new_text( '' );
    $self->{'encoding'} = 'utf-8';
    $self->set_title();
    $self->SetStatusText(  $self->{'encoding'}, 1);
}

sub open_file   {
    my ($self) = @_;
    my $dir = Kephra::IO::LocalFile::dir_from_path( $self->{'file'} );
    my $file = Kephra::App::Dialog::get_file_open( $dir );
    $self->read_file( $file ) if $file;
}

sub reopen_file { $_[0]->read_file( $_[0]->{'file'}, 1) }

sub read_file {
    my ($self, $file, $soft) = @_;
    return unless defined $file and -r $file;
    my ($content, $encoding) = Kephra::IO::LocalFile::read( $file );
    $self->{'encoding'} = $encoding;
    $self->{'editor'}->new_text( $content, $soft );
    $self->{'file'} = $file;
    $self->set_title();
    $self->SetStatusText(  $self->{'encoding'}, 1);
}

sub save_file {
    my $self = shift;
    unless (exists $self->{'file'} and -r $self->{'file'}){
        my $file = Kephra::App::Dialog::get_file_save( );
        return if $file eq &Wx::wxID_CANCEL;
        $self->{'file'} = $file;
    }
    Kephra::IO::LocalFile::write( $self->{'file'},  $self->{'encoding'}, $self->{'editor'}->GetText() );
    $self->{'editor'}->SetSavePoint;
}

sub save_as_file {
    my $self = shift;
    my $dir = Kephra::IO::LocalFile::dir_from_path( $self->{'file'} );
    my $file = Kephra::App::Dialog::get_file_save( $dir );
    return unless $file;
    $self->{'file'} = $file;
    $self->save_file;
}

sub save_under_file {
    my $self = shift;
    my $dir = Kephra::IO::LocalFile::dir_from_path( $self->{'file'} );
    my $file = Kephra::App::Dialog::get_file_save( $dir );
    Kephra::IO::LocalFile::write( $file,  $self->{'encoding'}, $self->{'editor'}->GetText() ) if $file;
}

sub set_title {
    my ($self) = @_;
    my $title .=  $self->{'file'} ? $self->{'file'} : '<unnamed>';
    $title .= " - Kephra";
    $title = '* '.$title if $self->{'editor'}->GetModify();
    $self->SetTitle( $title );
}

sub toggle_full_screen {
    my ($self) = @_;
    $self->ShowFullScreen( not $self->IsFullScreen );
    $self->GetMenuBar->Check(16410, $self->IsFullScreen);
}

1;
