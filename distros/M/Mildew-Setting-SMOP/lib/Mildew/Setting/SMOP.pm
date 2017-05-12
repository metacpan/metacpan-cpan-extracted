#ABSTRACT: the setting for mildew compiled for SMOP
package Mildew::Setting::SMOP;
BEGIN {
  $Mildew::Setting::SMOP::VERSION = '0.03';
}
use File::ShareDir qw(dist_dir);
sub ld_library_path {
   dist_dir('Mildew-Setting-SMOP'); 
}
sub std_tmp_files_path {
   dist_dir('Mildew-Setting-SMOP'); 
}
sub standard_libs {
   dist_dir('Mildew-Setting-SMOP'); 
}
1;
