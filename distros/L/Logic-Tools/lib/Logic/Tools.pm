package Logic::Tools;

use strict;
use warnings;
use Config::IniFiles;
use Log::Any::Adapter; 
use Log::Any::Adapter::Syslog;

use POSIX;

=head1 NAME

Voiecng::Tools - The great new Logic::Tools!

=head1 VERSION

Version 0.5.7

=cut

my @ISA = qw(Logic);
our $VERSION = '0.5.7';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Logic::Tools;

    my $foo = Logic::Tools->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS
=cut

=head1 constructor
=cut


sub new
{
    my $invocant = shift; # первый параметр - ссылка на объект или имя класса
    my $class = ref($invocant) || $invocant; # получение имени класса        

    my $log;
    use Log::Any '$log';

    my $self = { @_ }; # ссылка на анонимный хеш - это и будет нашим новым объектом, инициализация объекта
    my $log_level;

    $self->{NAME}=$invocant;
    $self->{VERSION}=$VERSION;
    
    bless($self, $class); # освящаем ссылку в объект

    if(defined($self->{'logfile'}))
    {
        if($self->{'logfile'} eq "Stdout")
        {
            Log::Any::Adapter->set('Stdout');
        }
        elsif($self->{'logfile'} eq "Syslog")
        {

            Log::Any::Adapter->set('Syslog',
                                    name     => $self->{'syslog_name'});
        }
        else
        {
            Log::Any::Adapter->set('File', $self->{'logfile'});
        }       
    }
    

    return $self; # возвращаем объект
}

=head1 METHODS
=cut

sub read_config
{
    my $self = shift;

    my $config_file = $self->{'config_file'};
    my $section = shift || die "[FAILED] Не задана секция для чтения конфига";
    my $param = shift || die "[FAILED] Не задан параметр для чтения конфига";

    my $cfg=new Config::IniFiles( -file => $config_file ) or die "[FAILED]] Не найден конфигурационный файл $config_file";

    my $value = $cfg->val( $section, $param);

    die "[FAILED] Не найден параметр ".$param." в секции ".$section unless(defined($value));

    return $value;
}


sub check_proc
{
    my $self = shift;

    my $pid_f = $self->{'lock_file'};
    
    # Проверяем запущен ли уже процесс
    if( -e $pid_f ) 
    {

        open(my $pid_file,'<',$pid_f) || die "[FAILED] can't open $pid_f";
        my $pid=<$pid_file>;
        close $pid_file;
        chomp $pid;
        
        # Процесс запущен, но активного процесса с указанным PID нет
        unless( -e "/proc/$pid" )
        {
            #print STDERR "Файл блокировки уже существует, но демон с pid=$pid не существует\n";
            die "[FAILED] can't delete file $pid_f\n" if ( !unlink $pid_f );
            #print STDERR "Файл блокировки удален\n";
        }
        else
        {
            die "process alredy run pid=$pid\n";
        }
    }
    return 1;
} 


sub logprint
{
    my $self = shift;

    my $loglevel=shift;
    my $message=shift;

    $message=~s/\n/ /g;
    while($message=~/\s\s/)
    {
        $message=~s/\s\s/ /g;
    }

    
    my $logstring;
    if($self->{'logfile'} eq "Stdout")
    {
        my ($sec, $min, $hour, $day, $mon, $year) = ( localtime(time) )[0,1,2,3,4,5];
        $logstring=sprintf("%04d/%02d/%02d %02d:%02d:%02d [%d][%s]: %s",$year+1900,$mon+1,$day,$hour,$min,$sec,$$,$loglevel,$message);
    }
    elsif($self->{'logfile'} eq "Syslog")
    {
        $logstring=sprintf("[%d]: %s",$$,$message);
    }
    else
    {
        $logstring=sprintf("[%d][%s]: %s",$$,$loglevel,$message);
    }   
    

    if($loglevel eq "trace")
    {
        $log->trace("$logstring");
    }
    elsif($loglevel eq "debug")
    {
        $log->debug("$logstring");
    }
    elsif($loglevel eq "info")
    {
        $log->info("$logstring");
    }
    elsif($loglevel eq "notice")
    {
        $log->notice("$logstring");
    }
    elsif($loglevel eq "notice")
    {
        $log->notice("$logstring");
    }
    elsif($loglevel eq "warning")
    {
        $log->warning("$logstring");
    }
    elsif($loglevel eq "error")
    {
        $log->error("$logstring");
    }
    elsif($loglevel eq "critical")
    {
        $log->critical("$logstring");
    }
    elsif($loglevel eq "alert")
    {
        $log->alert("$logstring");
    }
    elsif($loglevel eq "emergency")
    {
        $log->emergency("$logstring");
    }

    return 1;
}

sub start_daemon
{
    $SIG{CHLD} = 'IGNORE';

    my $self = shift;

    my $runas_user=$self->{'runas_user'};
    my $lock_file=$self->{'lock_file'};

    my ($name, $passwd, $uid, $gid) = getpwnam($runas_user) or die "[FAILED] Невозможно запуститься под $runas_user";
    
    my $pid = fork();
    
    die "[FAILED] Не удается создать форк: $!" unless(defined($pid));
    
     
    if($pid)
    {
        # Запись файле блокировки
        open(my $pid_file, ">" ,$lock_file) || die "[FAILED] Не удалось создать файл блокировки $lock_file\n";
        print $pid_file "$pid";
        close $pid_file;
        chown $uid, $gid, $lock_file;
        exit;
    } 
    else
    {
        # daemon
        setpgrp();
        select(STDERR); $| = 1;
        select(STDOUT); $| = 1;
        #syslog(LOG_INFO, "---------------------------------------");
        #syslog(LOG_INFO, "Скрипт запущен");
    }

    # Сброс привилегий
    setuid($uid);
    $< = $uid;
    $> = $uid;

    return 1;
}


#старт демона супервизором
#первый порожденный пид
my $first_child_pid=0;
sub supervisor_start_daemon
{
    $SIG{INT} = \&close_prog;
    $SIG{QUIT} = \&close_prog;
    $SIG{TERM} = \&close_prog;

    $SIG{CHLD} = 'IGNORE';

    my $self = shift;

    my $runas_user=$self->{'runas_user'};
    my $lock_file=$self->{'lock_file'};

    my ($name, $passwd, $uid, $gid) = getpwnam($runas_user) or die "[FAILED] can't start under the $runas_user";
    
    $first_child_pid = fork();
    
    die "[FAILED] can't create fork: $!" unless(defined($first_child_pid));
    
     
    if($first_child_pid)
    {
        # Запись файле блокировки
        open(my $pid_file, ">" ,$lock_file) || die "[FAILED] can't create block file $lock_file\n";
        print $pid_file "$first_child_pid";
        close $pid_file;        
        chown $uid, $gid, $lock_file;
        while(1)
        {
            # Процесс запущен, но активного процесса с указанным PID нет

            unless( -e "/proc/$first_child_pid" )
            {
                die "child $first_child_pid dead, exit\n";
                exit;
            }
            sleep(1);
        }
    } 
    else
    {
        # daemon
        setpgrp();
        select(STDERR); $| = 1;
        select(STDOUT); $| = 1;
    }

    # Сброс привилегий
    setuid($uid);
    $< = $uid;
    $> = $uid;
}

sub close_prog 
{   
    #отправка сигнала завершения дочернему процессу
    kill("TERM",$first_child_pid);
    die "TERM signal recieved\n";
    exit;
}

=head1 AUTHOR

lagutas, C<< <lagutas at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-logic-tools at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Logic-Tools>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Logic::Tools


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Logic-Tools>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Logic-Tools>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Logic-Tools>

=item * Search CPAN

L<http://search.cpan.org/dist/Logic-Tools/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 lagutas.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Logic::Tools
