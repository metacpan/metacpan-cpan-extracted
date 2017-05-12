package File::Operator;

use strict;
use vars qw($VERSION);
use Fcntl qw(:flock);

$VERSION = '1.00';

sub new {
my $class=shift;
my %arg=@_;
# по умолчанию работаем с текущим каталогом скрипта
$arg{'-path'}="." unless(exists($arg{'-path'}));
die "Incorrect file name" unless(defined($arg{'-file'}));
# если файл не существует, то создаем новый файл
unless(-e "$arg{'-path'}/$arg{'-file'}") {
	open(NEW,">","$arg{'-path'}/$arg{'-file'}") || die "Can't create file: $!";
	close(NEW);
	}
my $fh;
# блокируем через семафор (шароварная)
_block($arg{'-path'},LOCK_SH);
# оживляем дескриптор $fh
open($fh,"<","$arg{'-path'}/$arg{'-file'}") || die "Can't open file: $!"; 
my $self={
          file  => $fh, # дескриптор файла
          fpath => $arg{'-path'}, # путь к файлу
          nfile => $arg{'-file'},# имя файла
          };
bless($self,$class);
return $self;
}

sub renew {# обновление дескриптора после закрытия
my $class=shift;
my $package=__PACKAGE__;
die "Bad file name" unless(-e "$class->{'fpath'}/$class->{'nfile'}");
my $fh;
# блокируем через семафор
_block($class->{'fpath'},LOCK_SH);
# оживляем дескриптор $fh
open($fh,"<","$class->{'fpath'}/$class->{'nfile'}") || die "Can't open file: $!"; 
my $self={
          file  => $fh, # дескриптор файла
          fpath => $class->{'fpath'}, # путь к файлу
          nfile => $class->{'nfile'},# имя файла
          };
bless($self,$package);
return $self;
}

sub FetchFileToHash {# без аргументов
my $obj=shift;
my $fh=$obj->{'file'};# сохраняем дескриптор файла в переменной
my %hash=();
# считываем файл
seek($fh,0,0);# перемещаемся к началу файла
while(defined(my $line=<$fh>)) {
        chomp($line);
	my($id,@REC)=split(/\|/,$line);
	$hash{$id}=\@REC;
}
return %hash;
}

sub FetchRecord {# аргумент -id
my $obj=shift;
my $fh=$obj->{'file'};# сохраняем дескриптор файла в переменной
my %param=@_;# принимаем аргументы в хэш
# считываем файл в поисках нужного id
seek($fh,0,0);
while(defined(my $line=<$fh>)) {
        chomp($line);
	my($id,@REC)=split(/\|/,$line);
	return \@REC if($id eq $param{'-id'});	
}
my @ERR=();
push(@ERR,"record by id $param{'-id'} not found");
return \@ERR;
}

sub FetchLastRecords {# аргументы -num  (необязательный -raw)
my $obj=shift;
my $fh=$obj->{'file'};# сохраняем дескриптор файла в переменной
my %param=@_;# принимаем аргументы в хэш
$param{'-num'}=1 unless(exists($param{'-num'}));# по умолчанию 1 запись
seek($fh,0,0);
# считываем файл в поисках нужного id
my @LIST=<$fh>;# считываем файл в массив
# проверяем не превышает ли запрос кол-во элементов в массиве
$param{'-num'}=$param{'-num'}>@LIST ? @LIST : $param{'-num'};
@LIST=splice(@LIST,-$param{'-num'});# удаляем N последних элементов и присваиваем их массиву @LIST
return \@LIST if exists($param{'-raw'});# выходим здесь - если нужен не форматированный вывод
# отсекаем перевод строк и разделитель |
my @LIST_CUT=();
foreach (@LIST) {
	chomp;# удаляем перевод строки
	s/\|/ /g;# заменяем разделитель | на пробел
	push(@LIST_CUT,$_);
	}
return \@LIST_CUT;
}

sub WriteRecord { # аргументы -id =>(необязательный) -record =>сыслка на массив
my $obj=shift;
my $fh=$obj->{'file'};# сохраняем дескриптор файла в переменной
#$obj->{'fpath'};# путь до файла
#$obj->{'nfile'}; # имя файла
my $File="$obj->{'fpath'}/$obj->{'nfile'}";# для удобства сохраняем данные в переменной
my %param=@_;# принимаем аргументы в хэш
$param{'-id'}=time() unless(exists($param{'-id'}));# если -id не передан, сами генерим его 
my %hash=();
my $random=time();
my $name=int(rand($random));
$name=$random . $name .".tmp";
# открываем временный файл
open(TMP,">","$obj->{'fpath'}/$name") || die "can't create temp file: $!";
# записываем весь файл $fh во временный
seek($fh,0,0);
while(defined(my $line=<$fh>)) {
        print TMP $line;
}
# дописываем в конец новую запись
$param{'-id'}=~s/\|//g;# удяляем символы |
print TMP "$param{'-id'}|";
foreach (@{$param{'-record'}}) {
                s/\|/ /g;# заменяем все символы | на пробелы
		print TMP "$_|";
		}
	print TMP "\n";
close(TMP);
close($fh);
my $test=rename($File,"$File.orig");
$test=rename("$obj->{'fpath'}/$name",$File);   
return $param{'-id'} if $test==1;
return 0;
}

sub EditRecord { # аргументы -id -record =>сыслка на массив
my $obj=shift;
my $fh=$obj->{'file'};# сохраняем дескриптор файла в переменной
my $File="$obj->{'fpath'}/$obj->{'nfile'}";# для удобства сохраняем данные в переменной
my %param=@_;# принимаем аргументы в хэш
my %hash=();
my $random=time();
my $name=int(rand($random));
$name=$random . $name .".tmp";
# открываем временный файл
open(TMP,">","$obj->{'fpath'}/$name") || die "can't create temp file: $!";
# считываем файл
seek($fh,0,0);
while(defined(my $line=<$fh>)) {
	my($id,@REC)=split(/\|/,$line);
        print TMP $line  if($id ne $param{'-id'});
        if($id eq $param{'-id'}) {
        print TMP "$param{'-id'}|";
        	foreach (@{$param{'-record'}}) {
        	s/\|/ /g;# заменяем все символы | на пробелы
		print TMP "$_|";
		}
	print TMP "\n";
        } 
}
close(TMP);
close($fh);
my $test=rename($File,"$File.orig");
$test=rename("$obj->{'fpath'}/$name",$File);   
return $test;
}

sub DeleteRecord { # аргументы -id
my $obj=shift;
my $fh=$obj->{'file'};# сохраняем дескриптор файла в переменной
my $File="$obj->{'fpath'}/$obj->{'nfile'}";# для удобства сохраняем данные в переменной
my %param=@_;# принимаем аргументы в хэш
my %hash=();
my $random=time();
my $name=int(rand($random));
$name=$random . $name .".tmp";
# открываем временный файл
open(TMP,">","$obj->{'fpath'}/$name") || die "can't create temp file: $!";
# считываем файл
seek($fh,0,0);
while(defined(my $line=<$fh>)) {
	my($id,@REC)=split(/\|/,$line);
	next if($id eq $param{'-id'});# пропускаем при копировании запись к удалению
        print TMP $line;
}
close(TMP);
close($fh);
my $test=rename($File,"$File.orig");
$test=rename("$obj->{'fpath'}/$name",$File);   
return $test;
}

sub DESTROY {
my $self=shift;
close($self->{'file'});
_unblock();
}

## private methods ########
sub _block {
my($path,$type)=@_;
open(SEM,">","$path/.keep_me") || die "Can't create lock file";
my $lock=flock(SEM,$type);
return $lock;
}

sub _unblock {
close(SEM)
}

1;

__END__


=head1 NAME

File::Operator - Perl Object Oriented module for operation with text files

=head1 SYNOPSIS

  use File::Operator;
  my $fio=File::Operator->new(
                              -path => "/usr/home",
                              -file => "filename");
 # read methods
        %hash=$fio->FetchFileToHash();	    
        $array=$fio->FetchRecord(-id => 123456789);
        $array2=$fio->FetchLastRecords(-num =>10,
                                        -raw =>1);
 # write/edit methods
        $write=$fio->WriteRecord(-id => 12346577,
                                 -record =>\@ARRAY);
        $fio=$fio->renew();
        $write=$fio->EditRecord(-id => 12346577,
                                -record =>\@ARRAY);
        $fio=$fio->renew();
        $write=$fio->DeleteRecord(-id => 12346577);
        $fio=$fio->renew();


=head1 DESCRIPTION

The module is intended for work with the simplified text database where data are stored in text files in the form of lines divided by a symbol |. The first field of record is called as an index which is unique key in a current file, and can be initialized by any value. The field of an index can be not transferred in methods, and to generate means of the module.
The module allows to write, read, edit and delete records using their index, not caring about blocking files.

=head1 METHODS

 new        Method create File::Operator object and passing as arguments 
            the path to the file and filename to read/write/edit (or create).
	    
	    Usage:
	          my $fio=File::Operator->new(
		                              -path => "/home/foo",
					      -file => "database.txt"
					      );
	    -path => Default value is current directory (e.q ".")
	    
 renew      Method reopen filehandle after write/edit/delete operations and it need to
            call after write/edit methods.

=head2 READ METHODS

B<FetchFileToHash>   
method returns a hash, containing all records in a file. 
Hash values is references on arrays. Hash keys is INDEXes.
(the method is not recommended to be used with greater files).

Usage:
      %hash=$fio->FetchFileToHash();
      
      foreach my $gid(keys %hash) { 
      print "index: $gid $hash{$gid}->[0],$hash{$gid}->[1] ...\n"; }

B<FetchRecord>
method as parameter accepts INDEX. Returns the reference to a array corresponding transferred INDEX.

Usage:
        $array=$fio->FetchRecord(-id => INDEX);
        print "$array->[0] $array->[1]\n";

B<FetchLastRecords>  
method returns the reference to a array. 
as parameter accepts quantity of the demanded records, (-num => NUMBER),
and also unessential parameter -raw for return of not formatted data 
(with translation of lines and divided by a symbol |).
The method is not recommended to be used with greater files.

Usage:
       # unformated output (raw output with | and \n symbols)
       $records=$fio->FetchLastRecords(-num =>10,
                                       -raw =>1);
       print "$records->[0]";
       # formated output
       $records=$fio->FetchLastRecords(-num =>10);
                  
       print "$records->[0]\n";	

B<WriteRecord>
as parameters accepts -id => [unessential] and -record => \@ARRAYREF.
In case of absence of a field-id - generates id by a call of function time ().
In case of successful operation - returns an index of new record.         

Usage:
       my @DATA=qw(Header 11/05/2005 Good! This_is_just_example);
                 
       my $index=$fio->WriteRecord( -record=>\@DATA,
                                   #-id => $index);
       #rebuid object or renew filehandler or ...just do it :)  
       $fio=$fio->renew(); 
     
B<EditRecord>
as parameters accepts -id => INDEX [required here] and -record => \@ARRAYREF.
In case of successful operation - returns 1 (e.q $result==1 in example).

Usage:
        my @DATA=qw(Edit 11/05/2005 Good! This_is_just_edit_example);
                 
        my $result=$fio->EditRecord( -record=>\@DATA,
                                     -id => INDEX
                                       );
        $fio=$fio->renew();# just do it ;-)

B<DeleteRecord> 
as parameters accepts -id => INDEX [required here] and returns 1 if successfull.

Usage:
        my $result=$fio->DeleteRecord( -id => INDEX);
	
        $fio=$fio->renew();         

=head1 AUTHOR

P. A. Kuptsov, ya@poizon.net.ru

=head1 SEE ALSO

File::LineEdit on CPAN

=cut
