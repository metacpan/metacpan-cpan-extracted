package Dir::ListFilesRecursive; ## Static functions to find files in directories.


use strict;

use vars qw(@ISA @EXPORT %EXPORT_TAGS $VERSION);
use Exporter; 

our $VERSION='0.05';


@ISA = qw(Exporter);

%EXPORT_TAGS = ( all => [qw(
                      list_files_flat
                      list_files_recursive
                      list_files_no_path
                )] ); 

Exporter::export_ok_tags('all'); 


# This class provides static functions which can be imported to the namespace of 
# the current class. The functions lists the content of directories.
#
# With options you can filter the files for specific criteria, like no hidden files, etc.
#
# SYNOPSIS
# ========
# 
#  # imports all functions
#  use Dir::ListFilesRecursive ':all';
#
#  # imports only one function
#  use Dir::ListFilesRecursive qw( list_files_recursive );
#
#  use Data::Dumper;
#  print Dumper( list_files_recursive('/etc') );
#
#  use Data::Dumper;
#  print Dumper( list_files_recursive('/etc', only_folders => 1) );
#  # shows only subfolders of /etc
#
# 
# Options
# =======
#
# For some functions, you can set options like the only_folders in the SYNOPSIS's example.
# You can use the following options:
# As options you can set these flags:
#
#  only_folders    => 1,
#  only_files      => 1,
#  no_directories  => 1,
#  no_folders      => 1,
#  no_hidden_files => 1,
#  extension       => 'string',
#  no_path         => 1,
#
# You can also use various aliases:
#
# only_folders:
# only_folder, only_dir, only_dirs, only_directories, no_files
#
# no_directories:
# no_dir, no_dirs, no_folder, no_folders
#
# no_hidden_files:
# no_hidden
#
# extension:
# ext
#
# Not implemented so far: regular expression match, file age and other attributes.
# 
#
#
# LICENSE
# =======   
# You can redistribute it and/or modify it under the conditions of LGPL.
# 
# AUTHOR
# ======
# Andreas Hernitscheck  ahernit(AT)cpan.org






# List the files of a directory with full path.
#
#  print list_files_flat('/etc');
#  # may return files like:
#  # /etc/hosts
#  # /etc/passwd
#
# It does not return directory names. (that means 'flat'),
# only the files of given directory.
#
# You can set key value pairs to use further options.
# Please see chapter 'options'.
#
# It returns an array or arrayref, depending on context.
#
sub list_files_flat{ # array|arrayref ($path,%options)
  my $path=shift;
  my %para=@_;
  my @files;



  @files=list_files_no_path($path);
  _add_path_to_array($path,\@files);
  _filter_file_array(\@files,%para);

  @files=sort @files;


  return wantarray ? @files : \@files;
}










# List the files of a directory and subdirctories 
# with full path.
#
#  print list_files_recursive('/etc');
#  # may return files like:
#  # /etc/hosts
#  # /etc/passwd
#  # /etc/apache/httpd.conf
#
# You can set key value pairs to use further options.
# Please see chapter 'options'.
#
# It returns an array or arrayref, depending on context.
#
sub list_files_recursive{ # array|arrayref ($path,%options)
  my $path=shift;
  my %para=@_;
  my @files;

  @files=_list_files_recursive_all($path);
  _filter_file_array(\@files,%para,path=>$path);
  @files=sort @files;

  return wantarray ? @files : \@files;
}




# that is the real recursive function to get all files.
sub _list_files_recursive_all{
  my $path=shift;
  my %para=@_;
  my @files;
  my @filesm;


  @files=list_files_no_path($path);

  _filter_file_array(\@files,%para);
  _add_path_to_array($path,\@files);

  foreach my $d (@files){
    if (-d $d){
      push @filesm,_list_files_recursive_all($d);
    }
  }
  push @files,@filesm;

  
  
  return @files;
}




# List the files of a directory without the path.
#
#  print list_files_no_path('/etc');
#  # may return files like:
#  # hosts
#  # passwd
#
# It does not return directory names.
#
# You can set key value pairs to use further options.
# Please see chapter 'options'.
#
# It returns an array or arrayref, depending on context.
sub list_files_no_path{ # array|arrayref ($path,%options)
  my $path=shift;
  my %para=@_;
  my @files;
  my @nf;

  opendir(FDIR,$path);
    @files=readdir FDIR;
  closedir(FDIR);

  _filter_file_array(\@files,%para);

  foreach my $d (@files){
    if ($d!~ m/^\.\.?/){push @nf,$d};
  }

  return wantarray ? @nf : \@nf;
}



# helper method to filter for options.
# is filtering the given array with options.
sub _filter_file_array{
  my $dir_ref=shift;
  my %para=@_;
  my @nf;
  my $path=$para{path};

  no warnings;

  if ($para{only_folder} ne ''){$para{no_files}=1};
  if ($para{only_folders} ne ''){$para{no_files}=1};
  if ($para{only_dir} ne ''){$para{no_files}=1};
  if ($para{only_dirs} ne ''){$para{no_files}=1};
  if ($para{only_directories} ne ''){$para{no_files}=1};

  if ($para{only_files} ne ''){$para{no_dir}=1};
  
  
  foreach my $i (@$dir_ref){
    my $ok=1;
    if ($i=~ m/^\.\.?$/){$ok=0};
        
    if (($para{no_files} ne '') && (!-d $i)){$ok=0};
    if (($para{no_dir} ne '') && (-d $i)){$ok=0};
    if (($para{no_dirs} ne '') && (-d $i)){$ok=0};
    if (($para{no_directories} ne '') && (-d $i)){$ok=0};
    if (($para{no_folder} ne '') && (-d $i)){$ok=0};
    if (($para{no_folders} ne '') && (-d $i)){$ok=0};
    if (($para{no_hidden_files} ne '') && ($i=~ m/^\./)){$ok=0};
    if (($para{no_hidden} ne '') && ($i=~ m/^\./)){$ok=0};

    my $ext=lc($para{ext}) || lc($para{extension});
    if (exists $para{ext}){
      if ($i=~ m/\.$ext$/i){$ok=1}else{$ok=0};
    };

    if ($ok == 1){push @nf,$i};
  }
  @$dir_ref=@nf;
  undef @nf;

  if ($para{no_path} ne ''){
    _sub_path_from_array($path,$dir_ref);
  }

}





# helper method to add the path to the found files.
sub _add_path_to_array{
  my $path=shift;
  my $dir_ref=shift;

    foreach my $z (@$dir_ref){
      $z=$path.'/'.$z;
    }
}


# helper method to remove path from found files
sub _sub_path_from_array{
  my $path=shift;
  my $dir_ref=shift;

    foreach my $z (@$dir_ref){
      $z=~ s/^$path\/?//;
    }
}




1;
#################### pod generated by Pod::Autopod - keep this line to make pod updates possible ####################

=head1 NAME

Dir::ListFilesRecursive - Static functions to find files in directories.


=head1 SYNOPSIS


 # imports all functions
 use Dir::ListFilesRecursive ':all';

 # imports only one function
 use Dir::ListFilesRecursive qw( list_files_recursive );

 use Data::Dumper;
 print Dumper( list_files_recursive('/etc') );

 use Data::Dumper;
 print Dumper( list_files_recursive('/etc', only_folders => 1) );
 # shows only subfolders of /etc




=head1 DESCRIPTION

This class provides static functions which can be imported to the namespace of 
the current class. The functions lists the content of directories.

With options you can filter the files for specific criteria, like no hidden files, etc.



=head1 REQUIRES

L<Exporter> 


=head1 METHODS

=head2 list_files_flat

 my @array | \@arrayref = list_files_flat($path, %options);

List the files of a directory with full path.

 print list_files_flat('/etc');
 # may return files like:
 # /etc/hosts
 # /etc/passwd

It does not return directory names. (that means 'flat'),
only the files of given directory.

You can set key value pairs to use further options.
Please see chapter 'options'.

It returns an array or arrayref, depending on context.



=head2 list_files_no_path

 my @array | \@arrayref = list_files_no_path($path, %options);

List the files of a directory without the path.

 print list_files_no_path('/etc');
 # may return files like:
 # hosts
 # passwd

It does not return directory names.

You can set key value pairs to use further options.
Please see chapter 'options'.

It returns an array or arrayref, depending on context.


=head2 list_files_recursive

 my @array | \@arrayref = list_files_recursive($path, %options);

List the files of a directory and subdirctories
with full path.

 print list_files_recursive('/etc');
 # may return files like:
 # /etc/hosts
 # /etc/passwd
 # /etc/apache/httpd.conf

You can set key value pairs to use further options.
Please see chapter 'options'.

It returns an array or arrayref, depending on context.




=head1 Options


For some functions, you can set options like the only_folders in the SYNOPSIS's example.
You can use the following options:
As options you can set these flags:

 only_folders    => 1,
 only_files      => 1,
 no_directories  => 1,
 no_folders      => 1,
 no_hidden_files => 1,
 extension       => 'string',
 no_path         => 1,

You can also use various aliases:

only_folders:
only_folder, only_dir, only_dirs, only_directories, no_files

no_directories:
no_dir, no_dirs, no_folder, no_folders

no_hidden_files:
no_hidden

extension:
ext

Not implemented so far: regular expression match, file age and other attributes.





=head1 AUTHOR

Andreas Hernitscheck  ahernit(AT)cpan.org


=head1 LICENSE

You can redistribute it and/or modify it under the conditions of LGPL.



=cut

