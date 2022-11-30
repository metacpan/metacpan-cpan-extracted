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
    my $self = $class->SUPER::new( undef, -1, '', [-1,-1], [1000,800] );
    $self->CreateStatusBar(3);
    $self->SetStatusWidths(100, 50, -1);
    $self->SetStatusBarPane(2);

    $self->{'ed'} = Kephra::App::Editor->new($self, -1);
    $self->{'sb'} = Kephra::App::SearchBar->new($self, -1);
    $self->{'rb'} = Kephra::App::ReplaceBar->new($self, -1);

    my $sizer = Wx::BoxSizer->new( &Wx::wxVERTICAL );
    $sizer->Add( $self->{'ed'}, 1, &Wx::wxEXPAND, 0);
    $sizer->Add( $self->{'sb'}, 0, &Wx::wxGROW, 0);
    $sizer->Add( $self->{'rb'}, 0, &Wx::wxGROW, 0);

    $self->SetSizer($sizer);

    Wx::Window::SetFocus( $self->{'ed'} );
    Wx::Event::EVT_KEY_DOWN( $self, sub {
        my ($self, $event) = @_;
        my $code = $event->GetKeyCode ;
        if   ($code == &Wx::WXK_F11)        {  $self->ShowFullScreen( not $self->IsFullScreen ); say  "F11"  }
        else { $event->Skip }
    });
    Wx::Event::EVT_CLOSE( $self, sub {
        my ($self, $event) = @_;
        if ($self->{'ed'}->GetModify() and not exists $self->{'dontask'}){
            my $ret = Kephra::App::Dialog::yes_no_cancel( "\n".' save file ?  ');
            return                   if $ret ==  &Wx::wxCANCEL;
            $self->{'ed'}->save_file if $ret ==  &Wx::wxYES;
        }
        $event->Skip(1);
    });
    Wx::Event::EVT_CLOSE( $self,       sub { $_[1]->Skip(1) });

    Kephra::App::Window::Menu::mount( $self );
    $self->set_title();
    $self->{'rb'}->show(0);
    
    $self->read_file( __FILE__);

    return $self;
}

sub new_file { 
    my $self = shift;
    $self->{'file'} = '';
    $self->{'ed'}->new_text( '' );
    $self->{'encoding'} = 'utf-8';
    $self->set_title();
    $self->SetStatusText(  $self->{'encoding'}, 1);
}

sub open_file   { $_[0]->read_file( Kephra::App::Dialog::get_file_open() ) }

sub reopen_file { $_[0]->read_file( $_[0]->{'file'}, 1) }

sub read_file {
    my ($self, $file, $soft) = @_;
    return unless defined $file and -r $file;
    my ($content, $encoding) = Kephra::IO::LocalFile::read( $file );
    $self->{'encoding'} = $encoding;
    $self->{'ed'}->new_text( $content, $soft );
    $self->{'file'} = $file;
    $self->set_title();
    $self->SetStatusText(  $self->{'encoding'}, 1);
}

sub save_file {
    my $self = shift;
    $self->{'file'} = Kephra::App::Dialog::get_file_save() unless $self->{'file'};
    Kephra::IO::LocalFile::write( $self->{'file'},  $self->{'encoding'}, $self->{'ed'}->GetText() );
    $self->{'ed'}->SetSavePoint;
}

sub save_as_file {
    my $self = shift;
    $self->{'file'} = Kephra::App::Dialog::get_file_save();
    $self->save_file;
}


sub set_title {
    my ($self) = @_;
    my $title .=  $self->{'file'} ? $self->{'file'} : '<unnamed>';
    $title .= "  - Kephra";
    $title = '* '.$title if $self->{'ed'}->GetModify();
    $self->SetTitle( $title );
}

1;
