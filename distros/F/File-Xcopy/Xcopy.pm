package File::Xcopy;

use 5.005_64;
use strict;
use vars qw($AUTOLOAD);
use Carp;
our(@ISA, @EXPORT, @EXPORT_OK, $VERSION, %EXPORT_TAGS);
$VERSION = '0.12';


# require Exporter;
# @ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(xcp xmv xcopy xmove find_files list_files output
    fmtTime format_number get_stat file_stat execute syscopy
);
%EXPORT_TAGS = ( 
  all => [@EXPORT_OK] 
);

use File::Find; 
use IO::File;
use File::Basename;

# use Fax::DataFax::Subs qw(:echo_msg disp_param);

sub xcopy;
sub xmove;
sub xcp;
sub xmv;
sub syscopy;

=head1 NAME

File::Xcopy - copy files after comparing them.

=head1 SYNOPSIS

    use File::Xcopy;
    my $fx = new File::Xcopy; 
    $fx->from_dir("/from/dir");
    $fx->to_dir("/to/dir");
    $fx->fn_pat('(\.pl|\.txt)$');  # files with pl & txt extensions
    $fx->param('s',1);             # search recursively to sub dirs
    $fx->param('verbose',1);       # search recursively to sub dirs
    $fx->param('log_file','/my/log/file.log');
    my ($sr, $rr) = $fx->get_stat; 
    $fx->xcopy;                    # or
    $fx->execute('copy'); 

    # the same with short name
    $fx->xcp("from_dir", "to_dir", "file_name_pattern");

=head1 DESCRIPTION

The File::Xcopy module provides two basic functions, C<xcopy> and
C<xmove>, which are useful for coping and/or moving a file or
files in a directory from one place to another. It mimics some of 
behaviours of C<xcopy> in DOS but with more functions and options. 


The differences between C<xcopy> and C<copy> are

=over 4

=item *

C<xcopy> searches files based on file name pattern if the 
pattern is specified.

=item *

C<xcopy> compares the timestamp and size of a file before it copies.

=item *

C<xcopy> takes different actions if you tell it to.

=back

=cut

{  # Encapsulated class data
    my %_attr_data =                        # default accessibility
    (
      _from_dir   =>['$','read/write',''],  # directory 1
      _to_dir     =>['$','read/write',''],  # directory 2 
      _fn_pat     =>['$','read/write',''],  # file name pattern
      _action     =>['$','read/write',''],  # action 
      _param      =>['%','read/write',{}],  # dynamic parameters
    );
    sub _accessible {
        my ($self, $attr, $mode) = @_;
        if (exists $_attr_data{$attr}) {
            return $_attr_data{$attr}[1] =~ /$mode/;
        } 
    }
    # classwide default value for a specified object attributes
    sub _default_for {
        my ($self, $attr) = @_;
        if (exists $_attr_data{$attr}) {
            return $_attr_data{$attr}[2];
        } 
    }
    # list of names of all specified object attributes

    sub _standard_keys {
        my $self = shift;
        # ($self->SUPER::_standard_keys, keys %_attr_data);
        (keys %_attr_data);
    }
    sub _accs_type {
        my ($self, $attr) = @_;
        if (exists $_attr_data{$attr}) {
            return $_attr_data{$attr}[0];
        } 
    }
}

=head2 The Constructor new(%arg)

Without any input, i.e., new(), the constructor generates an empty
object with default values for its parameters.

If any argument is provided, the constructor expects them in
the name and value pairs, i.e., in a hash array.

=cut

sub new {
    my $caller        = shift;
    my $caller_is_obj = ref($caller);
    my $class         = $caller_is_obj || $caller;
    my $self          = bless {}, $class;
    my %arg           = @_;   # convert rest of inputs into hash array
    # print join "|", $caller,  $caller_is_obj, $class, $self, "\n";
    foreach my $attrname ( $self->_standard_keys() ) {
        my ($argname) = ($attrname =~ /^_(.*)/);
        # print "attrname = $attrname: argname = $argname\n";
        if (exists $arg{$argname}) {
            $self->{$attrname} = $arg{$argname};
        } elsif ($caller_is_obj) {
            $self->{$attrname} = $caller->{$attrname};
        } else {
            $self->{$attrname} = $self->_default_for($attrname);
        }
        # print $attrname, " = ", $self->{$attrname}, "\n";
    }
    # $self->debug(5);
    return $self;
}


# implement other get_... and set_... method (create as neccessary)
sub AUTOLOAD {
    no strict "refs";
    my ($self, $v1, $v2) = @_;
    (my $sub = $AUTOLOAD) =~ s/.*:://;
    my $m = $sub;
    (my $attr = $sub) =~ s/(get_|set_)//;
        $attr = "_$attr";
    # print join "|", $self, $v1, $v2, $sub, $attr,"\n";
    my $type = $self->_accs_type($attr);
    croak "ERR: No such method: $AUTOLOAD.\n" if !$type;
    my  $v = "";
    my $msg = "WARN: no permission to change";
    if ($type eq '$') {           # scalar method
        $v  = "\n";
        $v .= "    my \$s = shift;\n";
        $v .= "    croak \"ERR: Too many args to $m.\" if \@_ > 1;\n";
        if ($self->_accessible($attr, 'write')) {
            $v .= "    \@_ ? (\$s->{$attr}=shift) : ";
            $v .= "return \$s->{$attr};\n";
        } else {
            $v .= "    \@_ ? (carp \"$msg $m.\n\") : ";
            $v .= "return \$s->{$attr};\n";
        }
    } elsif ($type eq '@') {      # array method
        $v  = "\n";
        $v .= "    my \$s = shift;\n";
        $v .= "    my \$a = \$s->{$attr}; # get array ref\n";
        $v .= "    if (\@_ && (ref(\$_[0]) eq 'ARRAY' ";
        $v .= "|| \$_[0] =~ /.*=ARRAY/)) {\n";
        $v .= "        \$s->{$attr} = shift; return;\n    }\n";
        $v .= "    my \$i;     # array index\n";
        $v .= "    \@_ ? (\$i=shift) : return \$a;\n";
        $v .= "    croak \"ERR: Too many args to $m.\" if \@_ > 1;\n";
        if ($self->_accessible($attr, 'write')) {
            $v .= "    \@_ ? (\${\$a}[\$i]=shift) : ";
            $v .= "return \${\$a}[\$i];\n";
        } else {
            $v .= "    \@_ ? (carp \"$msg $m.\n\") : ";
            $v .= "return \${\$a}[\$i];\n";
        }
    } else {                      # assume hash method: type = '%'
        $v  = "\n";
        $v .= "    my \$s = shift;\n";
        $v .= "    my \$a = \$s->{$attr}; # get hash array ref\n";
        $v .= "    if (\@_ && (ref(\$_[0]) eq 'HASH' ";
        $v .= " || \$_[0] =~ /.*=HASH/)) {\n";
        $v .= "        \$s->{$attr} = shift; return;\n    }\n";
        $v .= "    my \$k;     # hash array key\n";
        $v .= "    \@_ ? (\$k=shift) : return \$a;\n";
        $v .= "    croak \"ERR: Too many args to $m.\" if \@_ > 1;\n";
        if ($self->_accessible($attr, 'write')) {
            $v .= "    \@_ ? (\${\$a}{\$k}=shift) : ";
            $v .= "return \${\$a}{\$k};\n";
        } else {
            $v .= "    \@_ ? (carp \"$msg $m.\n\") : ";
            $v .= "return \${\$a}{\$k};\n";
        }
    }
    # $self->echoMSG("sub $m {$v}\n",100);
    *{$sub} = eval "sub {$v}";
    goto &$sub;
}

sub DESTROY {
    my ($self) = @_;
    # clean up base classes
    return if !@ISA;
    foreach my $parent (@ISA) {
        next if $self::DESTROY{$parent}++;
        my $destructor = $parent->can("DESTROY");
        $self->$destructor() if $destructor;
    }
}


=head3 xcopy($from, $to, $pat, $par)

Input variables:

  $from - a source file or directory 
  $to   - a target directory or file name 
  $pat - file name match pattern, default to {.+}
  $par - parameter array
    log_file - log file name with full path
    

Variables used or routines called: 

  get_stat - get file stats
  output   - output the stats
  execute  - execute a action

How to use:

  use File::Xcopy;
  my $obj = File::Xcopy->new;
  # copy all the files with .txt extension if they exists in /tgt/dir
  $obj->xcopy('/src/files', '/tgt/dir', '\.txt$'); 

  use File:Xcopy qw(xcopy); 
  xcopy('/src/files', '/tgt/dir', '\.txt$'); 

Return: ($n, $m). 

  $n - number of files copied or moved. 
  $m - total number of files matched

=cut

sub xcopy {
    my $self = shift;
    my $class = ref($self)||$self;
    my($from,$to, $pat, $par) = @_;
    $self->action('copy');
    my ($sr, $rr) = $self->get_stat(@_); 
    return $self->execute; 
}

=head3 syscopy($from, $to)

Input variables:

  $from - a source file or directory 
  $to   - a target directory or file name 

Variables used or routines called: 


How to use:

  use File::Xcopy;
  syscopy('/src/file_a', '/tgt/dir/file_b');  # copy to a file
  syscopy('/src/file_a', '/tgt/dir');         # copy to a dir
  syscopy('/src/dir_a', '/tgt/dir_b');        # copy a dir to a dir

Return: none 

=cut

sub syscopy {
    my $self = shift;
    my $class = ref($self)||$self;
    my ($from, $to) = @_;
    
    my @arg = ();
    $arg[0] = '/bin/cp';
    if ($^O eq 'VMS') {
        return &rmscopy(@_);
    } elsif ($^O eq 'MacOS') {
        return &maccopy(@_);
    } elsif ($^O eq 'MSWin32') {
        $arg[0] = 'copy';
        $from =~ s{/}{\\}g;
        $to   =~ s{/}{\\}g;
        push @arg, "\"$from\"", "\"$to\"";
    } else {
        push @arg, '-p', '-f', $from, $to;
    } 
    # print "ARG: @arg\n";
    my $rcode = system(@arg);
    # MSWin32 returns 256: $rcode>>8 = 1
    # Unix returns 0: 
    my $r = "";
    if ($^O eq 'MSWin32') {
        $r = $rcode>>8;
    } else {
        $r = ($rcode==0)?1:0;
    }
    return $r;
}

sub maccopy {
    require Mac::MoreFiles;
    my($from, $to) = @_;
    my($dir, $toname);
    return 0 unless -e $from;
    if ($to =~ /(.*:)([^:]+):?$/) {
        ($dir, $toname) = ($1, $2);
    } else {
        ($dir, $toname) = (":", $to);
    }
    unlink($to);
    return Mac::MoreFiles::FSpFileCopy($from, $dir, $toname, 1);
}

=head3 xmove($from, $to, $pat, $par)

Input variables:

  $from - a source file or directory 
  $to   - a target directory or file name 
  $pat - file name match pattern, default to {.+}
  $par - parameter array
    log_file - log file name with full path
    

Variables used or routines called: 

  get_stat - get file stats
  output   - output the stats
  execute  - execute a action

How to use:

  use File::Xcopy;
  my $obj = File::Xcopy->new;
  # move the files with .txt extension if they exists in /tgt/dir
  $obj->xmove('/src/files', '/tgt/dir', '\.txt$'); 

Return: ($n, $m). 

  $n - number of files copied or moved. 
  $m - total number of files matched

=cut

sub xmove {
    my $self = shift;
    my $class = ref($self)||$self;
    my($from,$to, $pat, $par) = @_;
    $self->action('move');
    my ($sr, $rr) = $self->get_stat(@_); 
    return $self->execute; 
};

*xcp = \&xcopy;
*xmv = \&xmove;

=head3 execute ($act)

Input variables:

  $act  - action: 
       report|test - test run
       copy|CP - copy files from source to target only if
                 1) the files do not exist or 
                 2) newer than the existing ones
                 This is default.
  overwrite|OW - copy files from source to target only if
                 1) the files exist and 
                 2) no matter is older or newer 
       move|MV - same as in copy except it removes from source the  
                 following files: 
                 1) files are exactly the same (size and time stamp)
                 2) files are copied successfully
     update|UD - copy files only if
                 1) the file exists in the target and
                 2) newer in time stamp 

Variables used or routines called: None

How to use:

  use File::Xcopy;
  my $obj = File::Xcopy->new;
  # update all the files with .txt extension if they exists in /tgt/dir
  $obj->get_stat('/src/files', '/tgt/dir', '\.txt$'); 
  my ($n, $m) = $obj->execute('overwrite'); 

Return: ($n, $m). 

  $n - number of files copied or moved. 
  $m - total number of files matched

=cut

sub execute {
    my $self = shift;
    my ($act) = @_; 
    $act = $self->action  if ! $act;
    $act = 'test'         if ! $act; 
    my $sr = $self->param('stat_ar');
    my $rr = $self->param('file_ar');
    croak "ERR: please run get_stat first.\n" if ! $rr; 
    $self->action($act);
    my $par = $self->param; 
    my $vbm = ${$par}{verbose}; 
    my $fdir = $self->from_dir;
    my $tdir = $self->to_dir;
    my ($n, $m, $tp, $f1, $f2) = (0,0,"","","");
    my $tm_bit = 1;
    foreach my $f (sort keys %{$rr}) {
        ++$m; 
        $tp = ${$rr}{$f}{type};
        # skip if the file only exists in to_dir
        next if ($tp =~ /^OLD/); 
        my $f3 = $f; $f3 =~ s{^\.\/}{};
        $f1 = join '/', $fdir, $f3; 
        $f2 = join '/', $tdir, $f3; 
        next if -d $f1;       # skip the sub-dirs
        if (! -f $f1) {
           carp "WARN: 1 - could not find $f1\n";
           next;
        }
        my $td2 = dirname($f2);
        if (!-d $td2) {
            # we need to get original mask and imply here
            mkdir $td2;
        }
        if ($act =~ /^c/i) {            # copy
            if ($tp =~ /^(NEW|EX1|EX2)/) { 
                if ($self->syscopy($f1, $f2)) {
                    ++$n; 
                    print "$f1 copied to $f2\n" if $vbm; 
                } else { 
                  carp "ERR: could not copy $f1: $!\n"; 
                }
            } else {
                print "copying $f1 to $f2: skipped.\n" if $vbm; 
            }
        } elsif ($act =~ /^m/i) {       # move
            if ($tp =~ /^(NEW|EX1|EX2)/) { 
                if ($self->syscopy($f1, $f2)) {
                    ++$n; 
                    unlink $f1; 
                    print "$f1 moved to $f2\n" if $vbm; 
                } else {
                  carp "ERR: could not move $f1: $!\n"; 
                }
            } else { 
                print "moving $f1 to $f2: skipped.\n" if $vbm; 
            }
        } elsif ($act =~ /^u/i) {       # update
            if ($tp =~ /^(EX1|EX2)/) { 
                if ($self->syscopy($f1, $f2)) {
                    ++$n; 
                    print "$f1 updated to $f2\n" if $vbm; 
                } else {
                  carp "ERR: could not update $f2: $!\n"; 
                }
            } else {
                print "updating $f1 to $f2: skipped.\n" if $vbm; 
            }
        } elsif ($act =~ /^o/i) {       # overwirte
            if ($tp =~ /^(EX0|EX1|EX2)/) { 
                if ($self->syscopy($f1, $f2)) {
                    ++$n; 
                    print "$f1 overwritten $f2\n" if $vbm; 
                } else {
                  carp "ERR: could not overwrite $f2: $!\n"; 
                }
            } else {
                print "overwriting $f1 to $f2: skipped.\n" if $vbm; 
            }
        } else {
            carp "WARN: $f - do not know what to do.\n";
        } 
    }
    $self->output($sr,$rr,"",$par); 
    return ($n ,$m);
}


=head3 get_stat($from, $to, $pat, $par)

Input variables:

  $from - a source file or directory 
  $to   - a target directory or file name 
  $pat - file name match pattern, default to {.+}
  $par - parameter array
    log_file - log file name with full path
    

I currently only implemented /S paramter. Here is an example on how to
use the module:

  package main;
  my $self = bless {}, "main";

  use File::Xcopy;
  use Debug::EchoMessage;

  my $xcp = File::Xcopy->new;
  my $fm  = '/opt/from/dir';
  my $to  = '/opt/to/dir';
  my %p = (s=>1);   # or $xcp->param('s',1);
  my ($a, $b) = $xcp->get_stat($fm, $to, '\.sql$', \%p);
  # $self->disp_param($a);
  # $self->disp_param($b);
  $xcp->output($a,$b);

  $xcp->param('verbose',1);
  my ($n, $m) = $xcp->execute('cp');
  # $self->disp_param($xcp->param());

  print "Total number of files matched: $m\n";
  print "Number of files copied: $n\n";

I will implement the following parameters gradually:

  source       Specifies the file(s) to copy.
  destination  Specifies the location and/or name of new files.
  /A           Copies only files with the archive attribute set,
               doesn't change the attribute.
  /M           Copies only files with the archive attribute set,
               turns off the archive attribute.
  /D:m-d-y     Copies files changed on or after the specified date.
               If no date is given, copies only those files whose
               source time is newer than the destination time.
  /EXCLUDE:file1[+file2][+file3]...
               Specifies a list of files containing strings.  
               When any of the strings match any part of the absolute 
               path of the file to be copied, that file will be 
               excluded from being copied.  For example, specifying a 
               string like \obj\ or .obj will exclude all files 
               underneath the directory obj or all files with the
               .obj extension respectively.
  /P           Prompts you before creating each destination file.
  /S           Copies directories and subdirectories except empty ones.
  /E           Copies directories and subdirectories, including empty 
               ones.  Same as /S /E. May be used to modify /T.
  /V           Verifies each new file.
  /W           Prompts you to press a key before copying.
  /C           Continues copying even if errors occur.
  /I           If destination does not exist and copying more than one 
               file,
               assumes that destination must be a directory.
  /Q           Does not display file names while copying.
  /F           Displays full source and destination file names while 
               copying.
  /L           Displays files that would be copied.
  /H           Copies hidden and system files also.
  /R           Overwrites read-only files.
  /T           Creates directory structure, but does not copy files. 
               Does not include empty directories or subdirectories. 
               /T /E includes empty directories and subdirectories.
  /U           Copies only files that already exist in destination.
  /K           Copies attributes. Normal Xcopy will reset read-only 
               attributes.
  /N           Copies using the generated short names.
  /O           Copies file ownership and ACL information.
  /X           Copies file audit settings (implies /O).
  /Y           Suppresses prompting to confirm you want to overwrite an
               existing destination file.
  /-Y          Causes prompting to confirm you want to overwrite an
               existing destination file.
  /Z           Copies networked files in restartable mode.

Variables used or routines called: 

  from_dir   - get from_dir
  to_dir     - get to_dir
  fn_pat     - get file name pattern
  param      - get parameters
  find_files - get a list of files from a dir and its sub dirs
  list_files - get a list of files from a dir
  file_stat  - get file stats
  fmtTime    - format time


How to use:

  use File::Xcopy;
  my $obj = File::Xcopy->new;
  # get stat for all the files with .txt extension 
  # if they exists in /tgt/dir
  $obj->get_stat('/src/files', '/tgt/dir', '\.txt$'); 

  use File:Xcopy qw(xcopy); 
  xcopy('/src/files', '/tgt/dir', 'OW', '\.txt$'); 

Return: ($sr, $rr). 

  $sr - statistic hash array ref with the following keys: 
      OK    - the files are the same in size and time stamp
        txt - "The Same size and time"
        cnt - count of files
        szt - total bytes of all files in the category
      NO    - the files are different either in size or time
        txt - "Different size or time"
        cnt - count of files
        szt - total bytes of all files in the category
      OLD{txt|cnt|szt} - "File does not exist in FROM folder"
      NEW{txt|cnt|szt} - "File does not exist in TO folder"
      EX0{txt|cnt|szt} - "File is older or the same"
      EX1{txt|cnt|szt} - "File is newer and its size bigger"
      EX2{txt|cnt|szt} - "File is newer and its size smaller"
      STAT
        max_size - largest  file in all the selected files
        min_size - smallest file in all the selected files.
        max_time - time stamp of the most recent file
        min_time - time stamp of the oldest file 

The sum of {OK} and {NO} is equal to the sum of {EX0}, {EX1} and
{EX2}. 

  $rr - result hash array ref with the following keys {$f}{$itm}:
      {$f} - file name relative to from_dir or to_dir
         file - file name without dir parts
         pdir - parent directory
         prop - file stat array
         rdir - relative file name to the $dir
         path - full path of the file
         type - file status: NEW, OLD, EX1, or EX2
         f_pdir - parent dir for from_dir
         f_size - file size in bytes from from_dir
         f_time - file time stamp    from from_dir
         t_pdir - parent dir for to_dir
         t_size - file size in bytes from to_dir 
         t_time - file time stamp    from to_dir 
         tmdiff - time difference in seconds between the file 
                  in from_dir and to_dir
         szdiff - size difference in bytes between the file 
                  in from_dir and to_dir
         action - suggested action: CP, OW, SK

The method also sets the two parameters: stat_ar, file_ar and you can 
get it using this method: 

    my $sr = $self->param('stat_ar');
    my $rr = $self->param('file_ar');

=cut

sub get_stat {
    my $self = shift;
    my $class = ref($self)||$self;
    my($from,$to, $pat, $par) = @_;
    $from = $self->from_dir if ! $from; 
    $to   = $self->to_dir   if ! $to; 
    $pat  = $self->fn_pat   if ! $pat; 
    $par  = $self->param    if ! $par; 
    croak "ERR: source dir or file not specified.\n" if ! $from; 
    croak "ERR: target dir not specified.\n"         if ! $to; 
    croak "ERR: could not find src dir - $from.\n"   if ! -d $from;
    croak "ERR: could not find tgt dir - $to.\n"     if ! -d $to  ;
    $self->from_dir($from);
    $self->to_dir($to);
    $self->fn_pat($pat);
    my ($re, $n, $m, $t);
    if ($pat) { $re = qr {$pat}; } else { $re = qr {.+}; } 
    # $$re = qr {^lib_df51t5.*(\.pl|\.txt)$};
    my $far = bless [], $class;      # from array ref 
    my $tar = bless [], $class;      # to   array ref
    # get file name list
    if ($par && exists ${$par}{s}) {  # search sub-dir as well 
        $far = $self->find_files($from, $re); 
        $tar = $self->find_files($to,   $re); 
    } else {                          # only files in $from
        $far = $self->list_files($from, $re);
        $tar = $self->list_files($to,   $re); 
    }
    # convert array into hash 
    my $fhr = $self->file_stat($from, $far);
    my $thr = $self->file_stat($to,   $tar); 
    my %r = ();
    my %s = ( OK=>{txt=>"The Same size and time"},
              NO=>{txt=>"Different size or time"},
              OLD=>{txt=>"File does not exist in FROM folder"},
              NEW=>{txt=>"File does not exist in TO folder"},
              EX0=>{txt=>"File is older or the same"},
              EX1=>{txt=>"File is newer and its size bigger"},
              EX2=>{txt=>"File is newer and its size smaller"},
              STAT=>{max_size=>0, min_size=>99999999999, 
                     max_time=>0, min_time=>99999999999},
    );
    foreach my $f (keys %{$fhr}) {
        $s{STAT}{max_size} = ($s{STAT}{max_size}<${$fhr}{$f}{size}) ?
            ${$fhr}{$f}{size} : $s{STAT}{max_size}; 
        $s{STAT}{min_size} = ($s{STAT}{min_size}>${$fhr}{$f}{size}) ?
            ${$fhr}{$f}{size} : $s{STAT}{min_size}; 
        $s{STAT}{max_time} = ($s{STAT}{max_time}<${$fhr}{$f}{time}) ?
            ${$fhr}{$f}{time} : $s{STAT}{max_time}; 
        $s{STAT}{min_time} = ($s{STAT}{min_time}>${$fhr}{$f}{time}) ?
            ${$fhr}{$f}{time} : $s{STAT}{min_time}; 
        $r{$f} = {file=>${$fhr}{$f}{file},  f_pdir=>${$fhr}{$f}{pdir}, 
            f_size=>${$fhr}{$f}{size},
            f_time=>$self->fmtTime(${$fhr}{$f}{time})}; 
        if (! exists ${$thr}{$f}) {
            ++$s{NEW}{cnt};
            $s{NEW}{szt} += ${$fhr}{$f}{size}; 
            $r{$f}{t_pdir}=$to; $r{$f}{t_size}="";      
            $r{$f}{t_time}=""; $r{$f}{tmdiff}="";
            $r{$f}{szdiff}=""; 
            $r{$f}{action}="CP";
            $r{$f}{type}  = 'NEW'; 
            next; 
        }
        $r{$f}{t_pdir}=${$thr}{$f}{pdir}; 
        $r{$f}{t_size}=${$thr}{$f}{size}; 
        $r{$f}{t_time}=$self->fmtTime(${$thr}{$f}{time});
        $r{$f}{tmdiff}=${$thr}{$f}{time}-${$fhr}{$f}{time};
        $r{$f}{szdiff}=${$thr}{$f}{size}-${$fhr}{$f}{size};
        if (${$fhr}{$f}{size} == ${$thr}{$f}{size} && 
            ${$fhr}{$f}{time} == ${$thr}{$f}{time} ) {
            ++$s{OK}{cnt};
            $s{OK}{szt} += ${$fhr}{$f}{size}; 
            $r{$f}{action}="no action";
            $r{$f}{type}  = 'OK'; 
            next;
        }
        $s{NO}{szt}  += ${$fhr}{$f}{size}; 
        $r{$f}{type}  = 'NO'; 
        ++$s{NO}{cnt};
        if (${$fhr}{$f}{time}>${$thr}{$f}{time}) {
            if (${$fhr}{$f}{time}>${$thr}{$f}{time}) {
                ++$s{EX1}{cnt};
                $s{EX1}{szt} += ${$fhr}{$f}{size}; 
                $r{$f}{type}  = 'EX1'; 
            } else {
                ++$s{EX2}{cnt};
                $s{EX2}{szt} += ${$fhr}{$f}{size}; 
                $r{$f}{type}  = 'EX2'; 
            }
            $r{$f}{action}="OW";
        } else {
            $r{$f}{action}="SK";
            ++$s{EX0}{cnt};
            $s{EX0}{szt} += ${$fhr}{$f}{size}; 
            $r{$f}{type}  = 'EX0'; 
        }
    }
    foreach my $f (keys %{$thr}) {
        $s{STAT}{max_size} = ($s{STAT}{max_size}<${$thr}{$f}{size}) ?
            ${$thr}{$f}{size} : $s{STAT}{max_size}; 
        $s{STAT}{min_size} = ($s{STAT}{min_size}>${$thr}{$f}{size}) ?
            ${$thr}{$f}{size} : $s{STAT}{min_size}; 
        $s{STAT}{max_time} = ($s{STAT}{max_time}<${$thr}{$f}{time}) ?
            ${$thr}{$f}{time} : $s{STAT}{max_time}; 
        $s{STAT}{min_time} = ($s{STAT}{min_time}>${$thr}{$f}{time}) ?
            ${$thr}{$f}{time} : $s{STAT}{min_time}; 
        next if (exists ${$fhr}{$f}); 
        ++$s{OLD}{cnt};
        $s{OLD}{szt} += ${$thr}{$f}{size}; 
        $r{$f} = {file=>${$thr}{$f}{file}, 
            f_pdir=>"", f_size=>"", f_time=>"", 
            t_pdir=>${$thr}{$f}{pdir},
            t_size=>${$thr}{$f}{size},
            t_time=>$self->fmtTime(${$thr}{$f}{time}),
            tmdiff=>"", szdiff=>"", 
            action=>"NA", type  =>'OLD' 
        };
    }
    $s{STAT}{tmdiff}=$s{STAT}{max_time}-$s{STAT}{min_time};
    $s{STAT}{szdiff}=$s{STAT}{max_size}-$s{STAT}{min_size};
    $s{STAT}{max_time}=$self->fmtTime($s{STAT}{max_time});
    $s{STAT}{min_time}=$self->fmtTime($s{STAT}{min_time});

    $self->param('stat_ar', \%s);
    $self->param('file_ar', \%r);

    # $self->disp_param(\%s); 

    return (\%s, \%r); 
}

=head2 output($sr,$rr, $out, $par)

Input variables:

  $sr  - statistic hash array ref from xcopy 
  $rr  - result hash array ref containing all the files and their
         properties.
  $out - output file name. If specified, the log_file will not be used.
  $par - array ref containing parameters such as 
         log_file - log file name

Variables used or routines called: 

  from_dir   - get from_dir
  to_dir     - get to_dir
  fn_pat     - get file name pattern
  param      - get parameters
  action     - get action name 
  format_number - format time or size numbers

How to use:

  use File::Xcopy;
  my $fc = File::Xcopy->new;
  my ($s, $r) = $fc->get_stat($fdir, $tdir, 'pdf$') 
  $fc->output($s, $r); 

Return: None. 


If $out or log_file parameter is provided, then the result will be 
outputed to it.  

=cut

sub output {
    my $self = shift;
    my ($sr, $rr, $out, $par) = @_;
    my $fh = ""; 
    if ($out) {
        $fh = new IO::File "$out", O_WRONLY|O_APPEND;
    }
    $fh = *STDOUT if (!$fh && (!$par || ! exists ${$par}{log_file})); 
    if (!$fh && -f ${$par}{log_file}) {
        $fh = new IO::File "${$par}{log_file}", O_WRONLY|O_APPEND;
    } 
    my $fdir = $self->from_dir;
    my $tdir = $self->to_dir;
    my $fpat = $self->fn_pat;
    my $act  = $self->action;
    my $fmt  = "# %35s: %9s:%6.2f\%:%10s\n"; 
    my $ft1  = "# %15s: max %15s min %15s diff %10s\n"; 
    my $t = "";
    if (exists ${$par}{log_file}) {
        $t .= "# Xcopy Log File: ${$par}{log_file}\n" 
    } else {
        $t .= "# Xcopy Log Output\n" 
    }
    $t .= "# Date: " . localtime(time) . "\n";
    $t .= "# Input parameters: \n";
    $t .= "#   From dir: $fdir\n#    To  dir: $tdir\n";
    $t .= "#   File Pat: $fpat\n#    Action : $act\n";
    $t .= "# File statistics:           category: ";
    $t .= "    count:    pct: total size\n";
    my $n = ${$sr}{NEW}{cnt}+${$sr}{EX0}{cnt}+${$sr}{EX1}{cnt}
            +${$sr}{EX2}{cnt} +${$sr}{OLD}{cnt}; 
       $n = ($n)?$n:1;
    my $m = ${$sr}{NEW}{szt}+${$sr}{EX0}{szt}+${$sr}{EX1}{szt}
            +${$sr}{EX2}{szt} +${$sr}{OLD}{szt}; 
    $t .= sprintf $fmt, ${$sr}{OK}{txt}, ${$sr}{OK}{cnt},
          100*${$sr}{OK}{cnt}/$n, 
          $self->format_number(${$sr}{OK}{szt}); 
    $t .= sprintf $fmt, ${$sr}{NO}{txt}, ${$sr}{NO}{cnt},
          100*${$sr}{NO}{cnt}/$n, 
          $self->format_number(${$sr}{NO}{szt}); 
    $t .= sprintf $fmt, ${$sr}{NEW}{txt}, ${$sr}{NEW}{cnt},
          100*${$sr}{NEW}{cnt}/$n,
          $self->format_number(${$sr}{NEW}{szt}); 
    $t .= sprintf $fmt, ${$sr}{EX0}{txt}, ${$sr}{EX0}{cnt},
          100*${$sr}{EX0}{cnt}/$n,
          $self->format_number(${$sr}{EX1}{szt}); 
    $t .= sprintf $fmt, ${$sr}{EX1}{txt}, ${$sr}{EX1}{cnt},
          100*${$sr}{EX1}{cnt}/$n,
          $self->format_number(${$sr}{EX1}{szt}); 
    $t .= sprintf $fmt, ${$sr}{EX2}{txt}, ${$sr}{EX2}{cnt},
          100*${$sr}{EX2}{cnt}/$n,
          $self->format_number(${$sr}{EX2}{szt}); 
    $t .= sprintf $fmt, ${$sr}{OLD}{txt}, ${$sr}{OLD}{cnt},
          100*${$sr}{OLD}{cnt}/$n,
          $self->format_number(${$sr}{OLD}{szt}); 
    $t .= "# " . ("-"x35) . ": ---------:-------:----------\n";
    $t .= sprintf $fmt, "Totals", $n, 100, $self->format_number($m);
    $t .= "#\n";
    $t .= sprintf $ft1, "File size", ${$sr}{STAT}{max_size}, 
          ${$sr}{STAT}{min_size}, 
          $self->format_number(${$sr}{STAT}{szdiff},'time'); 
    $t .= sprintf $ft1, "File time", ${$sr}{STAT}{max_time}, 
          ${$sr}{STAT}{min_time}, 
          $self->format_number(${$sr}{STAT}{tmdiff},'time'); 
    print $fh $t; 
    $t = "#\n";  
    # action:f_time:t_time:tmdiff:f_size:t_size:szdiff:file_name
    $t .= "#action| from_time|        to_time|    tmdiff|";
    $t .= " from_size|   to_size|    szdiff|file_name";
    print $fh "$t\n";
    my $ft2 = "%2s|%15s|%15s|%10s|%10s|%10s|%10s|%-30s\n";
    foreach my $f (sort keys %{$rr}) {
        $t = sprintf $ft2, ${$rr}{$f}{action}, 
            ${$rr}{$f}{f_time}, ${$rr}{$f}{t_time}, 
            $self->format_number(${$rr}{$f}{tmdiff},'time'),
            $self->format_number(${$rr}{$f}{f_size}), 
            $self->format_number(${$rr}{$f}{t_size}), 
            $self->format_number(${$rr}{$f}{szdiff}),
            $f; 
        print $fh $t;
    }
    undef $fh;
}

=head2 format_number($n,$t)

Input variables:

  $n   - a numeric number 
  $t   - number type: 
         size - in bytes or 
         time - in seconds 

Variables used or routines called: None.

How to use:

  use File::Xcopy;
  my $fc = File::Xcopy->new;
  # convert bytes to KB, MB or GB 
  my $n1 = $self->format_number(10000000);       # $n1 = 9.537MB
  # convert seconds to DDD:HH:MM:SS
  my $n2 = $self->format_number(1000000,'time'); # $n2 = 11D13:46:40

Return: formated time difference in DDDHH:MM:SS or size in GB, MB or
KB.

=cut

sub format_number {
    my $self = shift;
    my ($n, $t) = @_;
    # $n - number
    # $t - type: size or time
    #
    return "" if $n =~ /^$/; 
    $t = 'size' if ! $t;
    my ($r,$s) = ("",0); 
    my $kb = 1024;
    my $mb = 1024*$kb;
    my $gb = 1024*$mb; 
    my $mi = 60;
    my $hh = 60*$mi;
    my $dd = 24*$hh; 
    if ($t =~ /^s/i) {
        return (sprintf "%5.3fGB", $n/$gb) if $n>$gb; 
        return (sprintf "%5.3fMB", $n/$mb) if $n>$mb; 
        return (sprintf "%5.3fKB", $n/$kb) if $n>$kb; 
        return "$n Bytes"; 
    } else {
        $s = abs($n);
        if ($s>$dd) { 
            $r = sprintf "%5dD", $s/$dd; 
            $s = $s%$dd;
        }
        if ($s>$hh) {
            $r .= sprintf "%02d:", $s/$hh; 
            $s = $s%$hh;
        } 
        if ($s>$mi) {
            $r .= sprintf "%02d:", $s/$mi; 
            $s = $s%$mi;
        } 
        $r .= sprintf "%02d", $s; 
        $r  = "-$r" if ($n<0); 
    }
    return $r;
}

=head2 find_files($dir,$re)

Input variables:

  $dir - directory name in which files and sub-dirs will be searched
  $re  - file name pattern to be matched. 

Variables used or routines called: None.

How to use:

  use File::Xcopy;
  my $fc = File::Xcopu->new;
  # find all the pdf files and stored in the array ref $ar
  my $ar = $fc->find_files('/my/src/dir', '\.pdf$'); 

Return: $ar - array ref and can be accessed as ${$ar}[$i]{$itm}, 
where $i is sequence number, and $itm are

  file - file name without dir 
  pdir - parent dir for the file
  path - full path for the file

This method resursively finds all the matched files in the directory 
and its sub-directories. It uses C<finddepth> method from 
File::Find(1) module. 

=cut

sub find_files {
    my $self = shift;
    my $cls  = ref($self)||$self; 
    my ($dir, $re) = @_;
    my $ar = bless [], $cls; 
    my $sub = sub { 
        (/$re/)
        && (push @{$ar}, {file=>$_, pdir=>$File::Find::dir,
           path=>$File::Find::name});
    };
    finddepth($sub, $dir);
    return $ar; 
}

=head2 list_files($dir,$re)

Input variables:

  $dir - directory name in which files will be searched
  $re  - file name pattern to be matched. 

Variables used or routines called: None.

How to use:

  use File::Xcopy;
  my $fc = File::Xcopu->new;
  # find all the pdf files and stored in the array ref $ar
  my $ar = $fc->list_files('/my/src/dir', '\.pdf$'); 

Return: $ar - array ref and can be accessed as ${$ar}[$i]{$itm}, 
where $i is sequence number, and $itm are

  file - file name without dir 
  pdir - parent dir for the file
  path - full path for the file

This method only finds the matched files in the directory and will not
search sub directories. It uses C<readdir> to get file names.  

=cut

sub list_files {
    my $self = shift;
    my $cls  = ref($self)||$self; 
    my $ar = bless [], $cls; 
    my ($dir, $re) = @_;
    opendir DD, $dir or croak "ERR: open dir - $dir: $!\n";
    my @a = grep $re , readdir DD; 
    closedir DD; 
    foreach my $f (@a) { 
        push @{$ar}, {file=>$f, pdir=>$dir, rdir=>$f,  
            path=>"$dir/$f"};
    }
    return $ar; 
}

=head2 file_stat($dir,$ar)

Input variables:

  $dir - directory name in which files will be searched
  $ar  - array ref returned from C<find_files> or C<list_files>
         method. 

Variables used or routines called: None.

How to use:

  use File::Xcopy;
  my $fc = File::Xcopu->new;
  # find all the pdf files and stored in the array ref $ar
  my $ar = $fc->find_files('/my/src/dir', '\.pdf$'); 
  my $br = $fc->file_stat('/my/src/dir', $ar); 

Return: $br - hash array ref and can be accessed as ${$ar}{$k}{$itm}, 
where $k is C<rdir> and the $itm are 

  size - file size in bytes
  time - modification time in Perl time
  file - file name
  pdir - parent directory


This method also adds the following elements additional to 'file',
'pdir', and 'path' in the $ar array:

  prop - file stat array
  rdir - relative file name to the $dir
  
The following lists the elements in the stat array: 

  file stat array - ${$far}[$i]{prop}: 
   0 dev      device number of filesystem
   1 ino      inode number
   2 mode     file mode  (type and permissions)
   3 nlink    number of (hard) links to the file
   4 uid      numeric user ID of file's owner
   5 gid      numeric group ID of file's owner
   6 rdev     the device identifier (special files only)
   7 size     total size of file, in bytes
   8 atime    last access time in seconds since the epoch
   9 mtime    last modify time in seconds since the epoch
  10 ctime    inode change time (NOT creation time!) in seconds 
              sinc e the epoch
  11 blksize  preferred block size for file system I/O
  12 blocks   actual number of blocks allocated

This method converts the array into a hash array and add additional 
elements to the input array as well.

=cut

sub file_stat {
    my $s = shift;
    my $c = ref($s)||$s; 
    my ($dir, $ar) = @_; 

    my $br = bless {}, $c; 
    my ($k, $fsz, $mtm); 
    for my $i (0..$#{$ar}) {
        $k = ${$ar}[$i]{path}; 
        ${$ar}[$i]{prop} = [stat $k];
        $k =~ s{$dir}{\.};
        ${$ar}[$i]{rdir} = $k; 
        $fsz = ${$ar}[$i]{prop}[7]; 
        $mtm = ${$ar}[$i]{prop}[9]; 
        ${$br}{$k} = {file=>${$ar}[$i]{file}, size=>$fsz, time=>$mtm,
            pdir=>${$ar}[$i]{pdir}};
    }
    return $br; 
}


=head3  fmtTime($ptm, $otp)

Input variables:

  $ptm - Perl time
  $otp - output type: default - YYYYMMDD.hhmmss
                       1 - YYYY/MM/DD hh:mm:ss
                       5 - MM/DD/YYYY hh:mm:ss
                      11 - Wed Mar 31 08:59:27 1999

Variables used or routines called: None

How to use:

  # return current time in YYYYMMDD.hhmmss
  my $t1 = $self->fmtTime;
  # return current time in YYYY/MM/DD hh:mm:ss
  my $t2 = $self->fmtTime(time,1);

Return: date and time in the format specified.

=cut

sub fmtTime {
    my $self = shift;
    my ($ptm,$otp) = @_;
    my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst,$r);
    #
    # Input variables:
    #   $ptm - Perl time
    #   $otp - output type: default - YYYYMMDD.hhmmss
    #                       1 - YYYY/MM/DD hh:mm:ss
    #                       5 - MM/DD/YYYY hh:mm:ss
    #                       11 - Wed Mar 31 08:59:27 1999
    # Local variables:
    #   $sec  - seconds (0~59)
    #   $min  - minutes (0~59)
    #   $hour - hours (0~23)
    #   $mday - day in month (1~31)
    #   $mon  - months (0~11)
    #   $year - year in YY
    #   $wday - day in a week (0~6: S M T W T F S)
    #   $yday - day in a year (1~366)
    #   $isdst -
    # Global variables used: None
    # Global variables modified: None
    # Calls-To:
    #   &cvtYY2YYYY($year)
    # Return: a formated time.
    # Purpose: format perl time to readable time.
    #
    if (!$ptm) { $ptm = time }
    if (!$otp) { $otp = 0 }
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
        localtime($ptm);
    $year = ($year<31) ? $year+2000 : $year+1900;
    if ($otp==1) {      # output format: YYYY/MM/DD hh:mm:ss
        $r = sprintf "%04d/%02d/%02d %02d:%02d:%02d", $year, $mon+1,
            $mday, $hour, $min, $sec;
    } elsif ($otp==2) { # output format: YYYYMMDD_hhmmss
        $r = sprintf "%04d%02d%02d_%02d%02d%02d", $year, $mon+1,
            $mday, $hour, $min, $sec;
    } elsif ($otp==5) { # output format: MM/DD/YYYY hh:mm:ss
        $r = sprintf "%02d/%02d/%04d %02d:%02d:%02d", $mon+1,
            $mday, $year, $hour, $min, $sec;
    } elsif ($otp==11) {
        $r = scalar localtime($ptm);
    } else {            # output format: YYYYMMDD.hhmmss
        $r = sprintf "%04d%02d%02d.%02d%02d%02d", $year, $mon+1,
            $mday, $hour, $min, $sec;
    }
    return $r;
}


1;

__END__

=head1 CODING HISTORY 

=over 4

=item * Version 0.01

04/15/2004 (htu) - Initial coding

=item * Version 0.02

04/16/2004 (htu) - laid out the coding frame

=item * Version 0.06

06/19/2004 (htu) - added the inline document

=item * Version 0.10

06/25/2004 (htu) - finished the core coding and passed first testing.

=item * Version 0.11

06/28/2004 (htu) - fixed the mistakes in documentation and populated
internal variables.

=item * Version 0.12

12/15/2004 (htu) - fixed a bug in the execute method. 

12/26/2004 (htu) - added syscopy method to replace methods in 
File::Copy module. The copy method in File::Copy does not reserve the 
attributes of a file.

12/29/2004 (htu) - tested on Solaris and Win32 operating systems

=back

=head1 FUTURE IMPLEMENTATION

=over 4

=item * add directory structure checking

Check whether the from_dir and to_dir have the same directory tree.

=item * add advanced parameters 

Ssearch file by a certain date, etc.

=item * add syncronize action 

Make sure the files in from_dir and to_dir the same by copying new 
files from from_dir to to_dir, update exisitng files in to_dir, and
move files that do not exist in from_dir out of to_dir to a 
temp directory. 

=back

=head1 AUTHOR

Copyright (c) 2004 Hanming Tu.  All rights reserved.

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut

