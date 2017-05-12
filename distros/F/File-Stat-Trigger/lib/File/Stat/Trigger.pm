package File::Stat::Trigger;

use Moose;
use Moose::Util::TypeConstraints;

use File::Stat::OO;
use Class::Trigger;
use DateTime;
use DateTime::Format::DateParse;

our $VERSION = '0.05';

subtype 'FileStat'
    => as 'Object'
    => where { $_->isa('File::Stat::OO') };

coerce 'FileStat'
    => from 'Str',
    => via { File::Stat::OO->new({ file => $_  }) };

subtype 'DateTime'
    => as 'Object'
    => where { $_->isa('DateTime') };
      
coerce 'DateTime'
    => from 'Str'
    => via { DateTime::Format::DateParse->parse_datetime($_) };

has 'file_stat' => (is => 'rw', isa => 'FileStat', coerce  => 1);

has [ qw<check_atime check_mtime check_ctime> ] =>
    ( is  => 'rw', isa => 'ArrayRef', default => sub { ['!='] } );

has [ qw<_atime _mtime _ctime> ] =>
    ( is  => 'rw', isa => 'DateTime', coerce  => 1);

has 'check_size' => ( is  => 'rw', isa => 'ArrayRef', default => sub { ['!='] } );

has '_size' => ( is  => 'rw', isa => 'Int');

has 'auto_stat' => ( is  => 'rw', isa => 'Int', default => 0);

has 'file' => ( is  => 'rw', isa => 'Str');

sub BUILD {
    my ($self) = @_;
    $self->init_stat();
}

sub init_stat {
    my ( $self ) = @_;

    $self->file_stat(File::Stat::OO->new({ file => $self->file }));

    $self->file_stat->use_datetime(1);
    $self->file_stat->stat();

    $self->_atime( $self->file_stat->atime );
    $self->_mtime( $self->file_stat->mtime );
    $self->_ctime( $self->file_stat->ctime );
    $self->_size( $self->file_stat->size );

    $self->_atime( $self->check_atime->[1] )
      if $self->check_atime && $self->check_atime->[1];

    $self->_mtime( $self->check_mtime->[1] )
      if $self->check_mtime && $self->check_mtime->[1];

    $self->_ctime( $self->check_ctime->[1] )
      if $self->check_ctime && $self->check_ctime->[1];

    $self->_size( $self->check_size->[1] )
      if $self->check_size && $self->check_size->[1];

    return;
}

sub run {
    my ($self, $time ) = @_;
    $time ||= 5;
    while (1) {
        $self->scan();
        sleep($time);
    }
}

sub scan {
    my ($self) = @_;
    my $fs = $self->file_stat;

    my $result;

    # init 
    for ( qw( size_trigger atime_trigger mtime_trigger ctime_trigger ) ){ 
        $result->{$_} = 0;
    }

    $fs->use_datetime(1);
    $fs->stat($self->file);

    if ( $self->check_size && $self->_judge($fs->size, [$self->check_size->[0],$self->_size]) ) {
        $result->{size_trigger} = $self->call_trigger('size_trigger',$self);
        $self->_size($fs->size) if ( $self->auto_stat );
    }

    for my $st_time ( qw(atime mtime ctime) ) {
        my $method = 'check_'.$st_time;#  check_atime or check_mtime or check_ctime
        my $_time   = '_'.$st_time;# _atime or _mtime or _ctime

        if ( $self->$method &&
            $self->_judge($fs->$st_time->epoch, [$self->$method->[0], $self->$_time->epoch] ) ) {
            $result->{$st_time.'_trigger'} = $self->call_trigger($st_time.'_trigger',$self);

            $self->$_time($fs->$st_time) if ( $self->auto_stat );
        }
    }

    return $result;
}

sub size_trigger {
    my ($self, $code, $check_size) = @_;
    $self->check_size($check_size) if $check_size;
    $self->_trigger('size_trigger', $code);
}

sub atime_trigger {
    my ($self, $code, $_check_atime) = @_;
    if ( $_check_atime ) {
        $self->check_atime($_check_atime); 
        $self->_atime($_check_atime->[1]); 
    }
    $self->_trigger('atime_trigger', $code);
}

sub mtime_trigger {
    my ($self, $code, $_check_mtime) = @_;
    if ( $_check_mtime ) {
        $self->check_mtime($_check_mtime); 
        $self->_mtime($_check_mtime->[1]); 
    }
    $self->_trigger('mtime_trigger', $code);
}

sub ctime_trigger {
    my ($self, $code, $_check_ctime) = @_;
    if ( $_check_ctime ) {
        $self->check_atime($_check_ctime); 
        $self->_ctime($_check_ctime->[1]); 
    }
    $self->_trigger('ctime_trigger', $code);
}

sub _trigger {
    my ($self, $type, $code) = @_;
    $self->add_trigger($type,$code);
}

sub _judge {
    my ($self, $value, $op) = @_;

    return unless $op;

    my $code = "$value $op->[0] $op->[1]";

    if ( eval $code ) { 
        return 1;
    }

    return; 
}

1;
__END__

=head1 NAME

File::Stat::Trigger - The module to monitor the status of file.

=head1 SYNOPSIS

  use File::Stat::Trigger;

  my $file = 'sample.txt';
  my $fs = File::Stat::Trigger->new({
   file        => $file,
   check_atime => ['>=','2008/12/1 12:00:00'],
   check_ctime => ['>='],
   check_mtime => ['==', '2008/12/1 12:00:00'],
   check_size  => ['!=',1024],
   auto_stat   => 1,
  });
  
  $fs->size_trigger( sub {
          my $self = shift;
          my $i = $self->file_stat->size;    
      } );
  
  $fs->atime_trigger(\&sample);
  $fs->ctime_trigger(\&sample);
  # $fs->ctime_trigger(\&sample,['!=', '2008/12/1 12:00:00']);
  $fs->mtime_trigger(\&sample);
  # $fs->mtime_trigger(\&sample,['!=', '2008/12/1 12:00:00']);
  
  my $result = $fs->scan();
  
  $result->{size_trigger};# 1
  $result->{atime_trigger};# 1
  $result->{ctime_trigger};# 0
  $result->{mtime_trigger};# 0

  # This function execute 'scan()' in three interval. 
  $result = $fs->run(3);

=head1 DESCRIPTION

This module executes the registered function
 when the stat of file changed and matched parameter.

=head1 METHODS

=over 4

=item new({file=>'filename'...})

Set file name, file parameter.

=item size_trigger

Register size trigger. Set file parameter.

=item atime_trigger

Register atime trigger. Set file parameter.

=item ctime_trigger

Register ctime trigger. Set file parameter.

=item mtime_trigger

Register mtime trigger. Set file parameter.

=item scan

Scan file stat.

=item run(second)

This function execute 'scan()' in any interval. 

=back

=head1 AUTHOR

Akihito Takeda E<lt>takeda.akihito@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
