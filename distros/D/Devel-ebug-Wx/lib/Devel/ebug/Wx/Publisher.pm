package Devel::ebug::Wx::Publisher;

use strict;
use base qw(Class::Accessor::Fast Class::Publisher
            Devel::ebug::Wx::Service::Base);

use Devel::ebug::Wx::ServiceManager::Holder qw(:noautoload);

__PACKAGE__->mk_ro_accessors( qw(ebug argv script) );
__PACKAGE__->mk_accessors( qw(_line _sub _package _file _running) );

use Devel::ebug;

sub new {
    my( $class, $ebug ) = @_;
    $ebug ||= Devel::ebug->new;
    my $self = $class->SUPER::new( { ebug     => $ebug,
                                     _package => '',
                                     _line    => -1,
                                     _sub     => '',
                                     _file    => '',
                                     _running => 0,
                                     } );

    return $self;
}

sub service_name { 'ebug_publisher' }

sub DESTROY {
    my ( $self ) = @_;
    $self->delete_all_subscribers;
}

sub can {
    my( $self, $method ) = @_;
    return undef if $method eq 'id';
    my $can = $self->SUPER::can( $method );
    return $can if $can;
    return 1 if $self->ebug->can( $method ); # FIXME return coderef
}

# FIXME: does not scale when additional ebug plugins are loaded
#        maybe needs another level of plugins :-(
my %no_notify =
   map { $_ => 1 }
       qw(program line subroutine package filename codeline
          filenames break_points codelines pad finished
          is_running);

my %must_be_running =
   map { $_ => 1 }
       qw(step next run return);

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    ( my $sub = $AUTOLOAD ) =~ s/.*:://;
    return if $must_be_running{$sub} && !$self->is_running;
    if( wantarray ) {
        my @res = $self->ebug->$sub( @_ );

        $self->_notify_basic_changes unless $no_notify{$sub};
        return @res;
    } else {
        my $res = $self->ebug->$sub( @_ );

        $self->_notify_basic_changes unless $no_notify{$sub};
        return $res;
    }
}

sub is_running {
    my( $self ) = @_;

    return $self->argv && !$self->ebug->finished;
}

sub load_program {
    my( $self, $argv ) = @_;
    $self->{argv} = $argv || $self->{argv} || [];
    $self->{script} = $self->argv->[0];
    my $filename = join ' ', @{$self->argv};

    unless ($filename) {
        $filename = '-e "Interactive ebugging shell"';
    }

    $self->ebug->program( $filename );
    $self->ebug->load;
    $self->_running( 1 );

    $self->notify_subscribers( 'load_program',
                               argv      => $self->argv,
                               filename  => $filename,
                               );
    $self->_notify_basic_changes;
}

sub save_program_state {
    my( $self, $file ) = @_;
    my $state = $self->ebug->get_state;
    my $cfg = $self->get_service( 'configuration' )
                   ->get_config( 'ebug_publisher', $file );

    $cfg->set_serialized_value( 'state', $state );
}

sub load_program_state {
    my( $self, $file ) = @_;
    my $cfg = $self->get_service( 'configuration' )
                   ->get_config( 'ebug_publisher', $file );
    my $state = $cfg->get_serialized_value( 'state' );

    $self->set_state( $state ) if $state;
    $self->notify_subscribers( 'load_program_state' ); # FIXME bad name
}

sub reload_program {
    my( $self ) = @_;

    my $state = $self->ebug->get_state;
    $self->ebug->load;
    $self->_running( 1 );
    $self->ebug->set_state( $state );

    $self->notify_subscribers( 'load_program',
                               argv      => $self->argv,
                               filename  => $self->program,
                               );
    $self->notify_subscribers( 'load_program_state' );
    $self->_notify_basic_changes;
}

sub break_point {
    my( $self, $file, $line, $condition ) = @_;
    return unless $self->is_running;
    my $act_line = $self->ebug->break_point( $file, $line, $condition );

    return unless defined $act_line;
    $self->notify_subscribers( 'break_point',
                               file      => $file,
                               line      => $act_line,
                               condition => $condition,
                               );
}

sub break_point_delete {
    my( $self, $file, $line ) = @_;
    return unless $self->is_running;
    $self->ebug->break_point_delete( $file, $line );

    $self->notify_subscribers( 'break_point_delete',
                               file  => $file,
                               line  => $line,
                               );
}

sub _notify_basic_changes {
    my( $self ) = @_;
    my $ebug = $self->ebug;

    if( $ebug->finished && $self->_running ) {
        $self->_running( 0 );
        $self->notify_subscribers( 'finished' );
        return;
    }

    my $file_changed = $self->_file ne $ebug->filename;
    my $line_changed = $self->_line ne $ebug->line;
    my $sub_changed  = $self->_sub ne $ebug->subroutine;
    my $pack_changed = $self->_package ne $ebug->package;
    my $any_changed  = $file_changed || $line_changed ||
                       $sub_changed || $pack_changed;

    # must do it here or we risk infinite recursion
    $self->_file( $ebug->filename );
    $self->_line( $ebug->line );
    $self->_sub( $ebug->subroutine );
    $self->_package( $ebug->package );

    $self->notify_subscribers( 'file_changed',
                               old_file    => $self->_file,
                               )
      if $file_changed;
    $self->notify_subscribers( 'line_changed',
                               old_line    => $self->_line,
                               )
      if $line_changed;
    $self->notify_subscribers( 'sub_changed',
                               old_sub     => $self->_sub,
                               )
      if $sub_changed;
    $self->notify_subscribers( 'package_changed',
                               old_package => $self->_package,
                               )
      if $pack_changed;
    $self->notify_subscribers( 'state_changed',
                               old_file    => $self->_file,
                               old_line    => $self->_line,
                               old_sub     => $self->_sub,
                               old_package => $self->_package,
                               )
      if $any_changed;
}

1;
