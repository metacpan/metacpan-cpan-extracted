package HTTP::DownloadLimit;

our $VERSION = '0.1.0';

use strict;
use warnings;

use Fcntl qw/:DEFAULT :flock/;
use CGI::Carp qw/fatalsToBrowser/;

$| = 1;

#--------------------------------------------------#
# Конструктор
sub new
{
    my( $class, %opt ) = @_;
    my $self =
    {
	REMOVE_FILE => $opt{'REMOVE_FILE'} || 1,
	TYPE_ALLOW => $opt{'TYPE_ALLOW'} || ['avi','mov','mpeg','mkv','mp4','mpg','vob'],
	FILE_NAME => $opt{'FILE_NAME'},
	BUFFER => $opt{'BUFFER'} || 262144,
	DEBUG => $opt{'DEBUG'} || 1, # *Options*
	MULTI => $opt{'MULTI'} || 0, # *Options*
	PATH => $opt{'PATH'} || '.',
	LOG => $opt{'LOG'} || '/var/log/HTTP::DownloadLimit.log', # *Options* if DEBUG=true
		
	FILE_SIZE => 0,
	HTTP_RANGE => 0,
    };

    # обработать имя файла если он содержит /
    my @tmp = split( /\//, $$self{'FILE_NAME'} );
    $$self{'FILE_NAME'} = $tmp[$#tmp];
    $$self{'PATH'} .= "/" . join '/', @tmp[0..$#tmp-1];

    bless $self, $class;
	
    return $self;
}
#--------------------------------------------------#
# Скачка файла с всевозможными проверками
sub Download
{
    my $self = shift;
	
    ## проверить наличие запрашиваемого файла
    if( -f "$$self{'PATH'}/$$self{'FILE_NAME'}" )
    {
	## получить размер запрашиваемого файла
	$$self{'FILE_SIZE'} = -s "$$self{'PATH'}/$$self{'FILE_NAME'}";
	
	## Логирование *Options
	$self->_logwrite("Connected") if $$self{'DEBUG'};
	
	# определить доступ к файлу для однаго или нескольких клиентов ( *Option )
	if( $self->_check_pid && ! $$self{'MULTI'} )
	{
	    print $self->_http_status_403;
	    
	    $self->_logwrite("403 file is busy $$self{'FILE_NAME'}") if $$self{'DEBUG'};
	}
	else
	{
	    ## проверить соотвецтвие запрашиваемого файла допустимым форматам
	    unless( $self->_permission )
	    {
		print $self->_http_status_403;
		
		$self->_logwrite("403 type file $$self{'FILE_NAME'}") if $$self{'DEBUG'};
	    }
	    else
	    {
		$self->_logwrite("GET $$self{'FILE_NAME'}") if $$self{'DEBUG'};
	    
		# открыть файл на чтение
		open( FH, '<', "$$self{'PATH'}/$$self{'FILE_NAME'}" )
		    or die $self->_logwrite("Permission denied $$self{'FILE_NAME'}") if $$self{'DEBUG'};
		## делает ли клиент докачку?
		if( exists $ENV{'HTTP_RANGE'} )
		{
		    $$self{'HTTP_RANGE'} = ( $ENV{'HTTP_RANGE'} =~ /bytes=(\d*)-/ )[0];
		    ## установить указатель дескриптора файла для продолжения скачки
		    seek FH, $$self{'HTTP_RANGE'}, 0;
		    # вывести зоголовок соотвецтвующий для продолжения скачки файла
		    print $self->_http_status_206;
		}
		else
		{
		    # вывести заголовок для скачки файла с 0-ля
		    print $self->_http_status_200;
		}
		
		# установить бинарный режим для обеих дискрипторов
		binmode FH; binmode STDOUT;
		
		## читать из дискриптора данные в бинарном виде и выдовать их клиенту	
		while( read FH, my $buf, $$self{'BUFFER'} )
		{
		    print $buf;
		    last if tell( FH ) == $$self{'FILE_SIZE'};
		}
				
		close FH && $self->_logwrite("Download $$self{'FILE_NAME'} complit") if $$self{'DEBUG'};
		
		## удалить файл и PID файла после полной скачки
		## удалить директорию где лежали файлы названные выше
		if( $$self{'REMOVE_FILE'} )
		{
		    if( unlink("$$self{'PATH'}/$$self{'FILE_NAME'}") && unlink("$$self{'PATH'}/$$self{'FILE_NAME'}.pid") )
		    {
		        $self->_logwrite("delete $$self{'PATH'}/$$self{'FILE_NAME'} and $$self{'PATH'}/$$self{'FILE_NAME'}.pid") if $$self{'DEBUG'};
		    }
		    else
		    {
			$self->_logwrite("not delete $$self{'PATH'}/$$self{'FILE_NAME'} and $$self{'PATH'}/$$self{'FILE_NAME'}.pid") if $$self{'DEBUG'};
		    }

		    if( rmdir("$$self{'PATH'}") )
		    {
			$self->_logwrite("delete $$self{'PATH'}") if $$self{'DEBUG'};
		    }
		    else
		    {
			$$self->_logwrite("not delete $$self{'PATH'}") if $$self{'DEBUG'};
		    }
		}
	    }
	}
    }
    else
    {
	print $self->_http_status_404;
	
	$self->_logwrite("404 $$self{'FILE_NAME'}") if $$self{'DEBUG'};
    }
}
#--------------------------------------------------#
# Логировние событий
sub _logwrite
{
    my ($self,$data) = @_;
    
    open( LOG, '>>', $$self{'LOG'} ) or die $!;
    flock( LOG, LOCK_EX );
    syswrite LOG, "[$$] $ENV{'REMOTE_ADDR'} " . localtime() .": $data\n";
    close LOG;
}
#--------------------------------------------------#
# Проверка занятости файла другим клиентом
sub _check_pid 
{
    my $self = shift;
    my $status = 0;
	
    if( -f "$$self{'PATH'}/$$self{'FILE_NAME'}.pid" )
    {
	open( PID_R, '<', "$$self{'PATH'}/$$self{'FILE_NAME'}.pid" ) or die $!; # LOG
	chomp( my $p = <PID_R> );
	close PID_R;
		
	if( kill 0, $p )
	{
	    $status = 1;
	}
	else
	{
	    open( PID_W, '>', "$$self{'PATH'}/$$self{'FILE_NAME'}.pid" ) or die $!; # LOG
	    syswrite PID_W, $$;
	    close PID_R;
	}
    }
    else
    {
	open( PID_W, '>', "$$self{'PATH'}/$$self{'FILE_NAME'}.pid" ) or die $!; # LOG
	syswrite PID_W, $$;
	close PID_W;
    }
    
    return $status;
}
#--------------------------------------------------#
# Определить доступность запрашиваемого файла клиенту
sub _permission
{
    my $self = shift;
    my $allow = 0;
	
    foreach my $t ( @{$$self{'TYPE_ALLOW'}} )
    {
	$allow = 1 if $$self{'FILE_NAME'} =~ /\.$t$/i;
    }
	
    return $allow;
}

#--------------------------------------------------#
# HTTP заголовки
sub _http_status_200
{
    my $self = shift;
	
    return "Status: 200 OK\n".
	    "Accept-Ranges: bytes\n".
	    "Content-Disposition: attachment; filename=\"$$self{'FILE_NAME'}\"\n".
	    "Content-Type: application/octet-stream\n".
	    "Content-Transfer-Encoding: binary\n".
	    "Content-Length: $$self{'FILE_SIZE'}\n\n";
}
#
sub _http_status_206
{
    my $self = shift;
	
    return "Status: 206 Partial Content\n".
	    "Accept-Ranges: bytes\n".
	    "Content-Disposition: attachment; filename=\"$$self{'FILE_NAME'}\"\n".
	    "Content-Type: application/octet-stream\n".
	    "Content-Transfer-Encoding: binary\n".
	    "Content-Range: bytes $$self{'HTTP_RANGE'}-" .( $$self{'FILE_SIZE'} - 1 ). "/$$self{'FILE_SIZE'}\n".
	    "Content-Length: " .( $$self{'FILE_SIZE'} - $$self{'HTTP_RANGE'} ) . "\n\n";
}
# 
sub _http_status_403
{
    return "Status: 403 Forbidden\n".
	    "Content-Type: text/html\n".
	    "Connection: close\n\n".
	    "403 Forbidden";
}
#
sub _http_status_404
{
    return "Status: 404 Not Found\n".
	    "Content-Type: text/html\n".
	    "Connection: close\n\n".
	    "404 Not Found";
}

__END__

=head1 NAME

   HTTP::DownloadLimit - module to set restrictions for files downloading from your webserver

=head1 VERSION

   This document describes HTTP::DownloadLimit version 0.1.0

=head1 SYSNOPSYS

   use HTTP::DownloadLimit;

   my $obj = HTTP::DownloadLimit->new
   (
       REMOVE_FILE => 1,
       TYPE_ALLOW => [qw/mp3 avi jpg/],
       FILE_NAME => $ENV{'PATH_INFO'},
       DEBUG => 1
   );

   $obj->Download;

=head1 DESCRIPTION

   This module allows you to log all downloads, restrict downloadable files extensions and
   concurrent downloads of the same file.

=head1 METHODS

   Note: there are a bunch of private module which are not discribed here.

   Constructor

       new(ARGS)

   Creates a new instance. Takes arguments as key => value pairs.

   Required arguments are:

       FILE_NAME - default value is taken from $ENV{'PATH_INFO'}. Download link will look like this:
       http://host/cgi-bin/HttpDownloadsControl.pl/Films/fileName.avi

   Optional arguments are:

       REMOVE_FILE - Delete file's parent directory after processing finished. Default: 1
       TYPE_ALLOW  - Downloadable file extensions. Default: avi, mov, mpeg, mkv, mp4, mpg, vob
       BUFFER      - read()'s function buffer size in bytes. Default: 262144
       DEBUG       - Enable logging. Default: 1
       MULTI       - Allow concurrent download of the file. Default: 0
       PATH        - Path to files storage dir. Default: '.'
       LOG         - Path to log file. Default: /var/log/HTTP::DownloadLimit.log

   Main methods:

       Download - No arguments needed. Return http status code or requested file content.

=head1 BUGS

   If you find the bug, please report it.

=head1 AUTHOR

   n4n0bit <n4n[dot]lab[at]gmail[dot]com>

=head1 COPYRIGHTS

   (c) 2008 by n4n0bit <n4n[dot]lab[at]gmail[dot]com>
   This program is free software, you can redistribute it and/or modify it under the same terms as Perl itself

