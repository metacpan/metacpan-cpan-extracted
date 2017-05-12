#!perl
#
# Documentation, copyright and license is at the end of this file.
#
package File::Drawing;

use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE);
$VERSION = '0.01';
$DATE = '2004/05/04';
$FILE = __FILE__;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1; # dump hashes sorted
$Data::Dumper::Terse = 1; # avoid Varn Variables

#####
# Just in case Data::Dumper throws in some Varn
#
use vars qw($VAR1 $VAR2 $VAR3 $VAR4 $VAR5 $VAR6 $VAR7 $VAR8);

use File::Copy;
use File::Path;
use File::Spec;

use Data::Secs2 1.19;
use Data::SecsPack 0.04;
use Data::Startup 0.02;
use File::Where 0.04;
use File::Revision 1.04;
use File::SmartNL 1.14;

use vars qw(@ISA @EXPORT_OK);
require Exporter;
@ISA= qw(Exporter);
@EXPORT_OK = qw(
    dod_date dod_drawing_number number2pm pm2number obsolete 
    broken backup);

use vars qw($contents $white_tape $pod);
$contents = '';
$white_tape = '';

use vars qw($default_options);
$default_options =  File::Drawing->defaults();

#######
# Object used to set default, startup, options values.
#
sub defaults
{
   my $class = shift;
   $class = ref($class) if ref($class);
   my $self = $class->Data::Startup::new(   
      warn => 0,
      die => 0,
      default_repository => 'Etc::',

      drawing_block_regex => 
           '(\n#<--\s*BLK\s+ID\s*=\s*\"DRAWING\"\s*-->\s*\n' .
           '.*?' .
           '#\s*<--\s*/BLK\s*-->[ \t]*\n)',

      drawing_block_start => "#<-- BLK ID=\"DRAWING\" -->",
      drawing_block_end =>  "#<-- /BLK -->",
      original => 0,
      clobber => 0,
      inc_dir => '',

   );
   $self->{drawing_block_holder} = "\n" . $self->{drawing_block_start} . "\n" .
                                          $self->{drawing_block_end} . "\n";
   $self->Data::Startup::override(@_);

}


########
# Keep backup of obsolete files
#
sub backup
{
     my $self = __PACKAGE__;
     $self = shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);
     my ($number, $repository, $dir) = @_;
     my $pm;
     $pm = $self->number2pm($number, $repository);
     my ($file, $inc_path) = File::Where->where_pm( $pm );
     return undef unless $file;
     return undef unless -e $file;  

     my $backup_pm = $repository .  $dir . '::' . $number;
     my @dirs = split /::/,$backup_pm;
     my $backup_file   = (pop @dirs) . '.pm';
     my $backup_dirs = File::Spec->catdir($inc_path, @dirs);
     mkpath($backup_dirs) if $backup_dirs;
     if($dir eq 'Obsolete' && ref($self)) {

         if($self->[1]->{active_obsolete}) {
             my $delete_revision = $self->[1]->{revision} - $self->[1]->{active_obsolete};
             if(0 <= $delete_revision) {
                  my $delete_file;
                  if($delete_revision == 0) {
                      $delete_file = $backup_file;
                  } 
                  else {

                      ($delete_file) = File::Revision->revision_file($delete_revision, 
                                File::Revision->parse_options($backup_file))
                  }
                  unlink File::Spec->catfile($backup_dirs, $delete_file);
             }
         }
         ($backup_file) = File::Revision->new_revision($backup_file, revision => $self->[1]->{revision})
                unless $self->[1]->{revision} == 0;
         
     }
     else {
         ($backup_file) = File::Revision->new_revision($backup_file, revision => -1);
     }

     $backup_file = File::Spec->catfile($backup_dirs, $backup_file);
     ($file, $backup_file)
}

########
# Keep backup of broken files
#
sub broken
{
     my $self = __PACKAGE__;
     $self = shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);
     my ($number,$repository) = @_;
     my ($file,$backup_file);
     ($file,$backup_file) = $self->backup($number, $repository, 'Broken');
     return undef unless $file;
     rename($file,$backup_file );  
}


######
# Program module wide configuration
#
sub config
{
     $default_options = File::Drawing->defaults() unless $default_options;
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);
     $default_options->Data::Startup::config(@_);
}


######
# DOD-STD-100C, Drawing Practices, quotation: 
#
#     402.17. Origianal Date. The method for specifying the
#    date on a drawing shall be numerically - year, month, date (e.g. 
#    75-10-15 
#
# With automatically generating of drawings, activities that took
# days and weeks, now happen in milliseconds. Thus, time is also
# now very relevant.
#
sub dod_date
{
     my $self = __PACKAGE__;
     shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);
     my @d = @_;
     @d = @d[5,4,3,2,1,0];
     $d[0] += 1900;
     $d[1] += 1;
     sprintf( "%04d/%02d/%02d %02d:%02d:%02d", @d);
}


my $last_number = 0;
sub dod_drawing_number
{
     my $self = __PACKAGE__;
     $self = shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);
     my (@d);
     my $new_number;
     do {
         @d = gmtime();
         @d = (@d[5,4,3],((($d[2] * 60) + $d[1]) * 60) + $d[0]);
         $d[0] -= 100;
         $d[1] += 1;
         $new_number = sprintf( "%02d%02d%02d%05d", @d); # 11 digit number
     }
     while($new_number eq $last_number);
     $last_number = $new_number;
     $new_number;
}



#######
#
#
sub new
{
     my ($class, $contents, $white_tape, $pod, $file_contents, $drawing_number, $repository) = @_;
     $class = ref($class) if ref($class);
     $contents = {} unless $contents;
     $white_tape = {} unless $white_tape;
     $white_tape->{drawing_number} = $drawing_number if $drawing_number;
     $repository = $white_tape->{repository} unless $repository;

     $default_options = File::Drawing->default() unless $default_options;
     $repository = $default_options->{default_repository} unless (defined $repository);
     if ($repository) {
         $repository .= '::' unless substr($repository, -2, 2) eq '::';
     }
     $white_tape->{repository} = $repository;
     if($pod) {
         $pod = $1 if $pod =~ /^\s*(.*?)\s*$/s;
     }
     $pod = '# end of file' unless($pod);
     bless [$contents, $white_tape, $pod, $file_contents],$class
}

#######
# Convert a drawing number to its drawing program module
#
sub number2pm
{
     my $self = __PACKAGE__;
     $self = shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);
     my ($number, $repository) = @_; 
     unless( defined($repository) ) {
         $repository = $self->[1]->{repository} if ref($self);
         $default_options = File::Drawing->default() unless $default_options;
         $repository = $default_options->{default_repository} unless defined $repository;
     }
     return $number unless $repository;
     $repository .= '::' unless substr($repository, -2, 2) eq '::';
     $repository . $number; 
}


########
# Keep backup of obsolete files
#
sub obsolete
{
     my $self = __PACKAGE__;
     $self = shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);
     my ($number, $repository) = @_;
     my ($file,$backup_file);
     ($file,$backup_file) = $self->backup($number, $repository, 'Obsolete');
     return undef unless $file;
     my $result = copy($file, $backup_file);

}

######
# Obtain the drawing number from the drawing program module name. 
#
sub pm2number
{
     my $self = __PACKAGE__;
     $self = shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);
     my ($pm, $repository) = @_;
     unless( defined($repository) ) {
         $repository = $self->[1]->{repository} if ref($self);
         $default_options = File::Drawing->default() unless $default_options;
         $repository = $default_options->{default_repository} unless defined $repository;
     }
     return $pm unless $repository && $pm;
     $repository .= '::' unless substr($repository, -2, 2) eq '::';
     $pm =~ s/\Q$repository\E//;
     $pm;
}


######
# Load the drawing contents and white tape from a file, and bless it
# as an drawing object. 
#
# On error this function returns an error string; otherwise,
# it returns an object bless with a reference to an array
# where the first element is the drawing contents and the
# second element the drawing white tape.
#
sub retrieve
{
     my $event;
     my $self = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;

     my ($drawing_number, @options) = @_;

     ######
     # Validate the input varaibles and crunch into a known
     # canoncial form.
     #
     #
     unless($drawing_number) {
        $event = "No drawing number specified\n";
        gotto EVENT;
     }

     $default_options = File::Drawing->default() unless $default_options;
     my $options = $default_options->Data::Startup::override(@options);

     my $repository = $options->{repository};
     $repository = $options->{default_repository}  unless (defined $repository);
     if ($repository) {
         $repository .= '::' unless substr($repository, -2, 2) eq '::';
     }

     ##########
     # Determine the program module file and its include path
     # 
     my $pm = number2pm($drawing_number, $repository);
     my ($pm_file, $inc_path) = File::Where->where_pm( $pm );
     unless($pm_file) {
         $event = "# Locate error. Cannot find $pm in " . join( ' ', @INC) . "\n";
         goto EVENT;
     }
             
     ######
     # Read the contents of the program module file contents
     #
     my $file_contents = File::SmartNL->fin($pm_file);
     unless (defined $file_contents) {
         remove($drawing_number, $repository);
         $event = "# ($repository)$drawing_number read error. $!\n"; 
         goto EVENT;
     }

     #####
     # Force the package name to agree with program package file name
     #
     my $release = 0;
     if($file_contents !~ /^\s*package\s*$pm\s*;/m) {
         $file_contents =~ s/^\s*package.*;/package $pm;/m;
         $release = 1;  # Force update of revision and version
     }

     ####
     # Place to store data from the program module file
     #
     local ($contents, $white_tape, $pod) = ('',''); 

     #####

     # Pick up the values for the white_tape and the contents
     #

     if ($file_contents =~ /(.*)\n\s*__END__(.*)/s) {
         $file_contents = $1;
         $pod = $2;
     }
     if($pod) {
         $pod = $1 if $pod =~ /^\s*(.*?)\s*$/s;
     }
     $pod = '# end of file' unless($pod);

     #####
     # Locate and extract drawing block
     #
     my $drawing_block='';
     $file_contents = '' unless $file_contents;
     if($file_contents =~ s|$options->{drawing_block_regex}|$options->{drawing_block_holder}|s) {
         $drawing_block = $1;
     }
     if(!$drawing_block && $options->{retrieve_unblocked}) {
         if($file_contents =~ s|(\$white_tape =  # parts.*)|$options->{drawing_block_holder}|s) {
             $drawing_block = $1;
         }
     }
     unless($drawing_block) {
         $self->broken($drawing_number, $repository);
       	 $event = "# Drawing block error. Removing ($repository)$drawing_number.\n";
         goto EVENT;
     }
     $file_contents .= "\n\n1\n" unless $file_contents =~ /1\s*$/;  # 1 at end of program module

     ######
     # Take care of variables in the contents
     #
     $drawing_block = '' unless $drawing_block;
     $drawing_block =~ s/\Q__FILE__\E/\'$pm_file\'/g;

     ####
     # When running under test harness, get all kinds things coming out
     #
     eval($drawing_block);
     if($@) {
         $self->broken($drawing_number, $repository);
      	 $event = "# Contents eval error. Removing ($repository)$drawing_number.\n#\t$@";
         goto EVENT;
     }
 
     my $drawing = $self->File::Drawing::new($contents, $white_tape, $pod, $file_contents, $drawing_number, $repository);
     $drawing->release( clobber => 1 ) if $release;
     return $drawing;

EVENT:
    $event .= "\tFile::Drawing::retrieve $VERSION\n";
    if($options->{warnings} ) {
        warn($event);
    }
    elsif($options->{die}) {
        die($event);
    }
    $event;

}


######
# Release the docuemnt. 
#
sub release
{
     my ($self, @options) = @_;
     my $options = new Data::Startup(@options);
     $options->{original} = 1;
     $self->revise( $options );

}


######
# Revise the document by updating the drawing program module with
# the latest content for the drawing. If successful, returns '';
# otherwise a string describing the error.
#
sub revise
{
     my $event;
     my ($self, @options) = @_;
     my ($contents, $white_tape, $pod, $file_contents) = @$self;

     $default_options = File::Drawing->default() unless $default_options;
     my $options = $default_options->Data::Startup::override(@options);

     ##############
     # Determine the repository to deposit the released or revised drawing.
     #
     $white_tape->{repository} = $options->{revise_repository} if $options->{revise_repository};
     if ($white_tape->{repository}) {
         $white_tape->{repository} .= '::' unless substr($white_tape->{repository}, -2, 2) eq '::';
     }
     $white_tape->{drawing_number} = $options->{revise_drawing_number} if $options->{revise_drawing_number};
     my $repository = $white_tape->{repository};
     my $drawing_number = $white_tape->{drawing_number};
     my $pm = number2pm($drawing_number, $repository);
     if($file_contents && $file_contents !~ /^\s*package\s*$pm\s*;/m) {
         $file_contents =~ s/^\s*package.*;/package $pm;/m;
     }

     #######
     # Determine if compare release with current drawing
     # 
     my $current_drawing = '';
     unless($options->{original} || $options->{clobber}) {

         ######
         # Retrieve the last version of the drawing 
         $current_drawing = retrieve($drawing_number, repository => $white_tape->{repository});
         unless(ref($current_drawing)) {
             unless($current_drawing =~ /^# Locate error./ ) {
                $event = $current_drawing;
                goto EVENT
             }
         }

     }

     #######
     # Update the white tape data
     #
     $white_tape->{type} = lc($white_tape->{type});
     $white_tape->{type} = 'source_control' unless $white_tape->{type};
     $white_tape->{classification} = 'Public Domain' unless $white_tape->{classification};

     my ($type, $title, $description, $keywords, $drawing_title, 
         $classification, $revision_history, $authorization);
     foreach ( [\$title, 'title'], [\$description, 'description'],
               [\$keywords, 'keywords'], [\$type, 'type'], 
               [\$classification, 'classification'] ) {
         $white_tape->{$_->[1]} = '' unless $white_tape->{$_->[1]};
         ${$_->[0]} = Dumper($white_tape->{$_->[1]});      
         while( chomp ${$_->[0]}) {}; # drop trailing new lines
     }

     #############
     # Establish white tape properties
     #
     $white_tape->{properties} = {} unless ref($white_tape->{properties}) eq 'HASH';
     my $properties = Dumper( $white_tape->{properties} );
     while( chomp $properties) {}; # drop trailing new lines

     #############
     # Establish the revision history
     #
     $white_tape->{revision_history} = {} unless ref($white_tape->{revision_history}) eq 'HASH';
     $revision_history = Dumper( $white_tape->{revision_history} );
     while(chomp $revision_history) {}; # drop trailing new lines

     #############
     # Establish the authorization
     #
     $white_tape->{authorization} = {} unless ref($white_tape->{authorization}) eq 'HASH';
     $authorization = Dumper( $white_tape->{authorization} );
     while(chomp $authorization) {}; # drop trailing new lines

     #######
     # If the contents of the drawing did not change since the last version, do not
     # release a new version that is the same as the last version
     #
     if(ref($current_drawing)) {
         my($current_contents, $current_white_tape, $current_pod, $current_file_contents) = @$current_drawing;
         my $compare_contents = Data::Secs2->stringify($contents);
         my $compare_current_contents = Data::Secs2->stringify($current_contents);
         my $unchanged = 1;
         if ($compare_contents ne $compare_current_contents) {
             $unchanged = 0;
         }
         else {         
             my @fields = qw(type title description keywords classification);
             foreach (@fields) {
                 if ($white_tape->{$_} ne $current_white_tape->{$_}) {
                     $unchanged = 0;
                     last;
                 }
             }
             $unchanged = 0 if $current_pod ne $pod;
             $unchanged = 0 if $current_file_contents ne $file_contents;
         }
         return '' if $unchanged;

         $current_drawing->obsolete($drawing_number, $white_tape->{repository});

         #######
         # Make sure that the revision and version numbers do not go backwards.
         #
         if ($white_tape->{revision} < $current_white_tape->{revision}) {
             $white_tape->{revision} = $current_white_tape->{revision};
         }

         if ($white_tape->{version} < $current_white_tape->{version}) {
             $white_tape->{version} = $current_white_tape->{version};
         }
     }

     ######
     # Release an original drawing file or revised a current drawing file
     # 
     my ($file) = File::Where->where_pm( $pm );

     ######
     # If documentation file does not exist make
     # sure the directory exists.
     #
     unless($file) {

         my $inc_dir = $options->{inc_path};

         ######
         # Make a best guess at the include directory
         #
         (undef, $inc_dir) = File::Where->where_repository( $repository ) unless $inc_dir;
         my @dirs = split /::/, $pm;
         $file = (pop @dirs) . '.pm';
         my $dirs = File::Spec->catdir($inc_dir, @dirs);
         if ($dirs) {
              $dirs =~ s/\\/\\\\/g;  # Patch for the backslashes in Microsoft file spec
              eval( 'mkpath("' .  $dirs . '")' );
              if( $@ ) {
                   while(chomp($@)) {};
                   $event = "# Create directory error. Path: $dirs\n#\tDrawing: ($repository)$drawing_number\n#\t$@\n";
                   goto EVENT;
              }
         }
         $file = File::Spec->catfile($dirs, $file);
     }
     $white_tape->{file} = $file;

     #########
     # Establish contents
     #
     while( chomp $properties ) {}; # drop trailing new lines
     $contents = '' unless $contents;
     $contents = Dumper($contents);
     while( chomp $contents ) {}; # drop trailing new lines

     #######
     # Process white tape configuration management
     #
     my $version = 0.01;
     my $revision = 0;
     unless($options->{original}) {
         $version = $white_tape->{version} if $white_tape->{version}; 
         $revision = $white_tape->{revision} if $white_tape->{revision}; 
         $version += 0.01;
         $revision += 1;
     }
     my $date_loc = dod_date(localtime());
     my $date_gm = dod_date(gmtime());
     my $time_to_live = $white_tape->{time_to_live};
     $time_to_live = '' unless $time_to_live;
     my $active_obsolete = $white_tape->{active_obsolete};
     $active_obsolete = '' unless $active_obsolete;

     #####
     # Format the pod
     #
     if($pod) {
         $pod = $1 if $pod =~ /^\s*(.*?)\s*$/s;
     }
     $pod = '# end of file' unless($pod);

     #####
     # Build drawing block
     #
     my $drawing_block = <<"EOF";

$options->{drawing_block_start}

###
# Changing the data in this block may prohibit it from being automatically
# processed by File::Drawing and other modules. See File::Drawing POD before
# making any changes.
#

use vars qw(\$VERSION);
\$VERSION = '$version';

###
# Never know when Data::Dumper going to throw in a VARn
#
use vars qw(\$VAR1 \$VAR2 \$VAR3 \$VAR4 \$VAR5 \$VAR6 \$VAR7 \$VAR8);

use vars qw(\$contents \$white_tape);

\$white_tape =  # parts are marked with a pn and other data, many times with a white tape
   
     {
       #####
       # Configuration version control
       #
       version => '$version',
       revision => '$revision',
       date_loc => '$date_loc', 
       date_gm => '$date_gm', 
       time_to_live => '$time_to_live', 
       active_obsolete => '$active_obsolete',
 
       #####
       # Drawing identification data
       #
       repository => '$repository',
       drawing_number => '$drawing_number',
       type => $type,
       title => $title ,
       description => $description,
       keywords => $keywords,
       file => __FILE__,

       ######
       # Drawing classification, authorization, and
       # revision history
       #
       classification => $classification,
       revision_history => $revision_history,
       authorization => $authorization,

       ######
       # Detail drawing properties. These usually contain
       # information for hard copy or soft rendering of the
       # drawing such as HTML page.
       #
       properties => $properties,

     };

\$contents =
   $contents;

$options->{drawing_block_end}
EOF

     ######
     # Contruct the file_contents
     #
     if($file_contents) {
         $file_contents =~ s|$options->{drawing_block_regex}|$drawing_block|s;
     }

     else {

         $file_contents = <<"EOF";
#!/usr/bin/perl
#
#
package $pm;

use strict;
use warnings;
use warnings::register;

use vars qw(\$VERSION);
\$VERSION = '$version';

$drawing_block

1

EOF

     }

     #####
     # Write out the drawing file
     #
     unless (open (PM, ">$file")) {
         $event = "# Open Error. File: $file\n#\t$!";
         goto EVENT;
     }
     print PM <<"EOF";
$file_contents
__END__

$pod

EOF

    close PM;

    return '';

EVENT:
    $event .= "\tFile::Drawing::retrieve $VERSION\n";
    if($options->{warnings} ) {
        warn($event);
    }
    elsif($options->{die}) {
        die($event);
    }
    $event;
}



1

__END__

=head1 NAME

File::Drawing - release, revise and retrieve contents to/from a drawing program module

=head1 SYNOPSIS

 ##########
 # Subroutine interface
 #
 use File::Drawing qw(
     dod_date dod_drawing_number number2pm pm2number obsolete  
     broken backup);

 $date = dod_date($sec, $min, $hour, $day, $month, $year);
 $drawing_number = dod_drawing_number( );

 $pm = number2pm($drawing_number, $repository); 
 $drawing_number = pm2number($drawing_number, $repository);

 $old_value = config( $option );
 $old_value = config( $option => $new_value);
 (@all_options) = config( );

 obsolete($drawing_number, $repository);
 broken($drawing_number, $repository);
 ($file, $backup_file) = backup($drawing_number, $repository, $dir);

 ###### 
 # Class Interface 
 #
 use File::Drawing;

 $default_options = defaults(@options);

 $old_value = $default_options->config( $option );
 $old_value = $default_options->config( $option => $new_value);
 (@all_options) = $default_options->config( );

 $drawing = new File::Drawing($contents, $white_tape, $pod, $file_contents, $drawing_number, $repository);

 $drawing = File::Drawing->retrieve($drawing_number, @options);

 $error = $drawing->release(@options);

 $error = $drawing->revise(@options);

 $date = $drawing->dod_date($sec, $min, $hour, $day, $month, $year);
 $drawing_number = $$drawing->dod_drawing_number( );

 $pm = $drawing->number2pm($drawing_number, $repository); 
 $drawing_number = $drawing->pm2number($drawing_number, $repository); 

 $drawing->obsolete($drawing_number, $repository);
 $drawing->broken($drawing_number, $repository);
 ($file, $backup_file) = $drawing->backup($drawing_number, $repository, $dir);

Generally, if a subroutine will process a list of options, C<@options>,
that subroutine will also process an array reference, C<\@options>, C<[@options]>,
or hash reference, C<\%options>, C<{@options}>.
If a subroutine will process an array reference, C<\@options>, C<[@options]>,
that subroutine will also process a hash reference, C<\%options>, C<{@options}>.
See the description for a subroutine for details and exceptions.

=head1 DESCRIPTION

The C<File::Drawing> program module uses American National Standards
for drawings as a model for storing data.
Commercial, governement and casual orgainizations
have stored information over the centuries as drawings.
Drawings probably evolved from the census that the Roman's
rulers, started back when Rome was a little
frontier town.
In other words, the practices of the drafting displines
have evolved over time and have stood the test of time.
Any deviation must be a crystal clear advantage.
Many of the practices are in place to avoid common and
costly human mistakes that obviously a computerize
drafting system will not make.
A good approach is to make the computerized data structure
optimum for computers and have the computer render the
computerized data into a form that meets the
drafting standards.
The C<File::Drawing> program module, uses
the Perl program module name as a drawing repository,
drawing number combination. 
The contents of the drawing is contained in the
program module file.
The <File::Drawing> program module established methods
to retrieve contents from a program module drawing file,
create an Perl drawing object with the contents, and methods to
release and revise the contents in a program module
drawing file from a Perl drawing object.
Other popular methods for computerize date are the SQL and XML.
Perl has a wide range of program modules using these approach.

In this time in history, the Drawings are highly standardize
and even subject to Internationl standarization agreements.
The Drawing Sheet Size and Format conform to ANSI Y14.1-1975
or its successor.
The drawing has a box with zone numbers running right to left
alon the top and bottom, and zone letters running bottom to
top along the sides. There is a section inside the box,
lower right corner with the blocks for such things as the
title, drawing number, current revision, authoriztion, and
sheet number.
There is an expandable
four column table in the top right corner to record the revision
history.

The data in a drawing may be divided into two parts
as follows:

=over 4

=item contents

The contents proper is the text and graphics inside the
drawing boundaries, not including the lower right corner
blocked off area containing the title and the upper right
corner revision history.
The contents should conform to standards for contents
such as ANSI X3.5-1970, Flowchart Symbols and their
Usage in Information Processing.

=item white tape

The white tape is the drawing information that is not
the contents such as the drawing number, revision,
revision history. This is meta type data about
the contents. 

The term white tape is derived from a common practice of writing 
part numbers and drawing numbers on white tape and affixing the white
tape to parts and drawing media such as magnetic tape, disks, etc.
There are vendors that sell gadgets whereby you can punch in text
and it will generate tape with the text to affix to parts and drawings.

=back

The C<File::Drawing> program module provides a format for
very specific white tape data and 100% open, unspecified
contents.

The white tape data include information needed to
support rendering of the drawings for delivery to
other activities such as other commerical and
industry activities and government activities.

For example, for delivery to the US DOD, the 
drawing number must meet very specific requirements.
The drawing number must
comply to DOD-STD-100C, Drawing Practices following
requirements 

401.4. I<Drawing Number.> The drawing number consists of letters,
numbers or combination of letters and numbers, which may or may 
not be separated by dashes. The number is assigned to a particular
drawing for identification purposes by the design activity.

402.5 I<Drawing number.> The drawing number shall not exceed 15
characters. These characters may include numbers, letter, and dashes 
with the following limitations:

a. Letters "I", "O', "Q", "S", "X", and "Z" shall not be used;
however letters "S" and "Z" may be used only if they are a part of
the existing drawing numbering system. THey shall not be used in the
development of new drawing numbering systems. Letters shall be upper
case (capital letters).

b. Numbers shall be arabic numberals. Fractional, decimal and Roman 
numberals shall not be used.

c. Blank spaces are not permitted.

d. Symbols such as: parentheseis, asterisks, virgule, degree, plus, minus
shall not be used, except when referencing the Government or non-governemnt
standardization document whose identification contains such symbol

e. The FSCM number, drawing format size letter, and drawing revision 
letter (see paragraphs 503.2 and 602.3) are not considered part of
the drawing number

f. A system based on a significant numbering system or a sequentially
assigned non-significant numbering system designed to preclude 
duplication is acceptable.

Does the <File::Drawing> internal data format
have to comply to DOD drawing standards?
Of course not. Do they have ot comply to American National Standards?
Of course not.  In fact, just the index of American National Standards
may on A size paper (drafting talk for 8.5" by 11") may be more than
half as thick as the Bible. With these many rules it is nearly
impossible to comply to the standards 100%.
Some of DOD activities
still insist that programs be delivered on mylar "paper" tape,
logistic data delivered on punched cards.

Is the US DOD the only activity that makes such demands on their
contractors? Of course not. If you build semiconductor implanters
where the base model runs 2 million dollars, one of your 
customers if you have a going business is Intel.
An implanter will dope semiconductor wafers with different ions.
If takes time, many ten, twenty, forty minutes, depending on the
type of ion and enery levels, to take down an ion beam and setup
and tune a new beam for a different ion. Intel does not care about
the setup time. They will buy a different implanter for
each ion beam. Intel's setup time is the time to move a cassette
of wafers from one implanter to the next. 
In the semiconductor equipment business,
"what Intel wants, Intel gets." 
Maybe not exactly what they want but Intel does
carry a big stick to the negotiating table. 
Does this mean you cannot negotiate. Of course, not.
Chrome plated front panel; No problem; $100,000.
Solid gold front panel to match your other equipment.
No problem; $6,000,000. 
Things like this only happen in dreams.
The HP in the HP model number means High Performance, not High Price.

Should you comply with them? If you want their business. Yes. 
If your drawings are hard copy base, then your internal drafting
must be accordance with the standards. However, if it is computer
base, such as C<File::Drawing> program module,
the internal program module data format does not have to be in accordance with
the standards. 

The C<File::Drawing> program module white tape data has open
unspecificd properties key that may be used for
data needed to render the drawing object as
hard copies, soft display images that comply to the 
national, government, industry or company specific
standards.

The approach here is to design a C<File::Drawing> class
that has very specific hard coded C<$white_tape>
data formats. 
Perl has many program modules such as L<DBI|DBI>,
L<XML::Simple> that may be used to enter data
into C<File::Drawing> objects from many different sources.
The C<$white_tape> properties key provides a
home for information to render in formats
that complies to special delivery requirements
of outside activities.

Thus, the C<File::Drawing> methods only have to
deal with very, specific, hard coded data and
not every current or future curve ball that
the DOD, Intel, or the New Iraq Army throws.
Those things will be handle by vendor specific
methods that filter, massage and transfer the
US DOD, Intel or the New Iraq Army view of the world
into C<File::Drawing> source control or 
specification drawing objects or another
appropriate type of C<File::Drawing> drawing object
that has the C<File::Drawing> rose colored view
of the world.

=head2 C<File::Drawing> Class

The C<File::Drawing> program module establishes 
a C<File::Drawing> class with C<release> and
C<retrive> methods that reads and writes the
data for a C<File::Drawing> object to and
from a file.
A <File::Drawing> object underlying data
is a two member array, the first member the drawing
contents and the second member the drawing
white tape.

A C<File::Drawing> drawings object's data will be stored 
in a file separate from the <File::Drawing> class methods.
The format of the file is a Perl program
module with the data stored in 
a <$contents> variable and
a <$white_tape> hash between unique comments
that identify the drawing data.
Equivalent file formats such as a file containing
L<Data::Secs2|Data::Secs2> binary or
ascii image of the C<File::Drawing> data program
module are also acceptable.

The C<$contents> variable is undefined and assumes
whatever form is appropriate for the C<$contents>.
The C<$white_tape> hash is used to store information found and required
by National Standards on the drawing, such as the title block, revision
block, date block. The contents may be either a hash or an array and 
is the contents of the drawing.

The C<File::Drawing> class design is to try to internally to
utilize Perl features for the best performance while
supporting the introduction of outside data control by
source control and specification C<File::Drawing> objects
from as many sources as possible and supporting 
rendering the C<File::Drawing> object in as many output
forms as possible.

Thus, not matter where the source of the drawing data and
the sink of the drawing data, the drawing data for 
the C<File::Drawing> object is in a very well defined and
extremely filtered from outside influences.
After extemely, narrow well-defined data, rosed-colored 
view greatly simplies the C<File::Drawing> methods and
allows the design to concentrate and the best data
form to maximize the Perl C<File::Drawing> methods 
performance.

=head2 white tape keys

Preassigned keys for the White Tape hash are as
follows:

=over 4

=item version

Perl version of form \d+.\d+
starting with 0.01 

=item revision

The revision is an integer starting
with 0 for the initial release that
originates the C<File::Drawing> object.
The revision is incremented by one
each time the C<File::Drawing> object
is revised.
The L<num2revision|Data::Revision/num2revision>
subroutine will render a revision letter(s)
that complies to
drafting standards from the revision integer.

=item date_loc

The local date and time in US DOD format which is the same
as many countries such as Canada.
DOD-STD-100C, Drawing Practices,

402.17. I<Original Date.> The method for specifying the
date on a drawing shall be numerically - year, month, date (e.g. 
75-10-15 

With computer automation of drawings, activities that took
days and weeks, now happen in milliseconds. Thus, time is also
now very relevant.

=item date_gm

The gm time in US DOD format. 

=item time_to_live

The time in seconds from the date_gm that
the drawing data is valid. 
An empty or undef signifies there
is no time limit.

=item active_obsolete

The number of revisions that are maintained
before the older drawing revisions are 
permantenly removed.

=item repository

For drawing program modules the program
module identifier is divided into
two parts as follows

 $repository . '::' $drawing_number

The repository is the leading part of
the program module that determines the
location of a group of drawing program
modules.

For a file, the repository is the relative
path that correponds to the program module
respository.

Repositories local to a specific user may
add library absolute path to the beginning of
the PERL5LIB environmental variable so that
C<File::Drawing> look for drawings the
local repository first. 
This is best set when the user logs on.  
When the PERL5LIB environmental variable has been 
correctly set up, the repository absolute library root appears as
a member in the C<@INC> array.

=item drawing_number

The drawing number does not conform to
known drawing standards. 
It is based on the
site operating system that identifies
the drawing file from other files in
the operating system file system.

The drawing number is the trailing part of
the program module that determines the
an unique drawing program modules in
a repository group.

For a file, the drawing_number is the relative
path that correponds to the program module
drawing_number.

=item type

The type of drawing that should be one
of the American Nation Standards drawing
types with contents in accordance with
the Standard for that drawing type

=item description

A short description of the drawing that
should be natural language and may or may
not conform to a drawing standard.

=item title

A natural language title that may or
may not conform to drawing standards

=item keywords

These words should be the anticipated
words that a person would enter into
a web search engine to find the 
drawing.

=item file

The file key is the absolute file specification
for the site operating system for
the drawing program module.

=item classification

The classification key 
is security level, licenses or
references to this information.

=item  revision_history

The revision_history key is
at this type an unspecified 
revision history.

=item authorization

The authorization for the drawing.
This may be a legal digital key
authorization, plain text,
link or left blank.

=item properties

The properties key data is unspecified.
It may be used for whatever 
is necessary for rendering the drawing
in a form for delivery or use of another
activity.
One anticipate use is for information for
hard copy or soft rendering of the
drawing such as a HTML page
or a format suitable for delivery to
specific activities. 
For web page rendering this could
be keys for titles for list tables.
For DOD rendering
typical keys would be as follows:

=over 4

=item dod_fscm property

A US DOD number that identifies the
activity responsible for maintaining the
file. 
It goes without saying that
if activity does not have a dod
identifying number the dod_fscm
is blank or missing and is required for drawings
to be rendered for delivery to
the US government activities.

=item dod_title property

A title that conforms to drafing
standards of noun, adjective where
the nouns and adjectives are selected
from standardize lists.
This is empty or missing expect when
the drawing must be rendered as
a drawing conforming to American
National Standards or a similar
standard.

=item dod_drawing_number property

A drawing number that complies to
DOD standards. Most industry and
commerical activities reqirements
for drawing numbers are the same.

The C<dod_drawing_number> method
generates a number that complies
to these requirements.

This field is missing or empty
unless a rendering for delivery
requires this information.
Once assigned it should never
be revised or deleted.

=back 

=back

=head1 Methods

=head2 backup

 ($file, $backup_file) = $self->backup($drawing_number, $repository, $dir);

The C<backup> subroutine determines the absolute file for
C<$drawing_number> C<$repository>  and determines a backup file as follows:
The backup repository is C<$repository . '::' . $dir>. 

=head2 broken

 $self->broken($drawing_number, $repository);

The C<retreive> method calls the C<broken> subroutine when it cannot retreive
the drawing data from a drawing C<$repository> C<$drawing_number>
program module.The C<obsolete> subroutine determines the
C<$file,$backup_file> as follows:

 ($file,$backup_file) = $self->backup($number, $repository, 'Broken')

The C<$backup_file> repositiory is C<"$repository::Broken">.
The drawing number is C<$file> with an embedded revision number
inserted by C<File::Revision>.
The C<broken> subroutine renames the broken program module
file C<$file> to C<$backup_file>.

=head2 config

 $old_value = config( $option );
 $old_value = config( $option => $new_value);
 (@all_options) = config( );

When Perl loads 
the C<File::Drawing> program module,
Perl creates a
C<$File::Drawing::default_options> object
using the C<default> method.

Using the C<config> as a subroutine 

 config(@_) 

writes and reads
the C<$File::Drawing::default_options> object
directly using the L<Data::Startup::config|Data::Startup/config>
method.
Avoided the C<config> and in multi-threaded environments
where separate threads are using C<File::Drawing>.
All other subroutines are multi-thread safe.
They use C<override> to obtain a copy of the 
C<$File::Drawing::default_options> and apply any option
changes to the copy keeping the original intact.

Using the C<config> as a method,

 $options->config(@_)

writes and reads the C<$options> object
using the L<Data::Startup::config|Data::Startup/config>
method.
It goes without saying that that object
should have been created using one of
the following or equivalent:

 $default_options = $class->File::Drawing::defaults(@_);

The underlying object data for the C<File::Drawing>
class of objects is a hash. For object oriented
conservative purist, the C<config> subroutine is
the accessor function for the underlying object
hash.

Since the data are all options whose names and
usage is frozen as part of the C<File::Drawing>
interface, the more liberal minded, may avoid the
C<config> accessor function layer, and access the
object data directly.

=head2 defaults

The C<defaults> subroutine establish C<File::Drawing> class wide options
options as follows:

 option                  initial value
 --------------------------------------------
 default_repository      'Etc::'

 drawing_block_regex     '(\n#<--\s*BLK\s+ID\s*=\s*\"DRAWING\"\s*-->\s*\n' .
                         '.*?' .
                         #\s*<--\s*/BLK\s*-->[ \t]*\n)'

 drawing_block_start     "#<-- BLK ID=\"DRAWING\" -->"
 drawing_block_end       "#<-- /BLK -->"

 original                 0
 clobber                  0
 inc_dir                  ''

In general, whenever a subroutine or method, it will use C<default_repository> whenever
it has a C<$repository> input and none is found.

The C<release>, C<retreive> and C<revise> methods use C<drawing_block_regex> option to
locate the drawing contents and replaces the drawing contents with C<$drawing_block_holder>
option until revised contents are available.
These subroutines have option inputs that may be used to override these options
during the execution of that subroutine.

The C<revise> subroutine uses the C<original>, C<clobber>, and C<inc_dir>.
See L<revise|File::Drawings/revise>.

=head2 dod_date

 $date = $self->dod_date($sec, $min, $hour, $day, $month, $year);

The C<dod_date> method generates a date in the yyyy/mm/dd hh:mm::ss
numeric format. This is the format used by the US DOD and many
countries besides the United States.

=head2 dod_drawing_number

 $drawing_number = $self->dod_drawing_number( );

The C<dod_drawing_number> generates a drawing number that
complies to DOD-STD-100C, 401, 402.
The number should comply to most other industry and
commerical standards for drawing numbers.
The C<dod_drawing_number> subroutine cannot generate numbers faster
than one number per sec.
For large activities, place this on a server and every one must
obtain a number from the only copy running on the server. 
This number will have no relation or importance what so ever for the 
C<File::Drawing> objects
since they use a linguistic drawing numbers map one to one
to the file system. 

=head2 number2pm

 $pm = number2pm($drawing_number, $repository); 

The C<number2pm> combines a C<repository> and
C<$drawing_number> into a <$pm> name.

=head2 new

 $self = new File::Drawing($contents, $white_tape, $pod, $file_contents, $drawing_number, $repository);

The C<new> method is used internally by the C<revise> and C<release> methods to
create C<File::Drawing> objects.
If C<new> receivces blank inputs, the C<new>
method creates the C<File::Drawing> without
those inputs.
The C<$drawing_number> and C<$repository> are keys in the
C<$white_tape> hash and when present will override
the values for those keys in the C<$white_tape> hash.

The C<$contents> C<$white_tape> C<$pod> and C<$file_contents>
normally are orginally obtained by the C<retreive> method
from the C<File::Drawings> program module specified by
a C<$repository> C<$drawing_number>. 
The data typically will have processed as established by
the C<retrieve> and C<release> method and used to release
or revise a C<File::Drawing> program module file.

=head2 obsolete

 $self->obsolete($drawing_number, $repository);

The C<revise> method calls the C<obsolete> subroutine
whenever it is about to revise a drawing C<$repository> C<$drawing_number>
program module. The C<obsolete> subroutine determines the
C<$file,$backup_file> as follows:

 ($file,$backup_file) = $self->backup($number, $repository, 'Obsolete')

The C<$backup_file> repositiory is C<"$repository::Obsolete">.
The drawing number is C<$file> with an embedded revision number
inserted by C<File::Revision>.
The C<obsolete> subroutine copies the program module
C<$file> about to be revised C<$backup_file>.

=head2 pm2number

 $drawing_number = pm2number($pm, $repository); 

The C<pm2number> returns the C<$drawing_number>
for a C<$pm> C<$repository> pair. The
C<$drawing_number> is the trailing part of C<$pm>
after the leading C<$repository> part.

=head2 release

The C<release> method calls the C<revise> method
with the C<original => 1> option added to the
C<revise> method options.

=head2 retrieve

 $drawing = File::Drawing->retrieve($drawing_number);
 $drawing = File::Drawing->retrieve($drawing_number, @options);
 $drawing = File::Drawing->retrieve($drawing_number, \@options);
 $drawing = File::Drawing->retrieve($drawing_number, \%options);

The C<retrieve> method is the top constructor for a
C<File::Drawing> object.
The C<retrieve> method creates a C<File::Drawing> object
from the data in a drawing program module file specified
by C<$drawing_number> and C<$repository>
The method uses C<$File::Drawing::default_repository>
for $respository unless overriden by the
C<repository> option.
The program module file is located by <$repository> <$drawing_number>
in the C<@INC> path. 

The <retrieve> method breaks up the 
drawing program module file into four parts:

C<$white_tape $contents $file_contents $pod>

The method obtains $white_tape and $contents by C<eval> 
of the drawing block in the $file_contents by the
C<$File::Drawing::drawing_block_regex> regular expression
and replacing it with C<$File::Drawing::drawing_block_holder>.

If the C<eval> fails, the C<retrieve> method moves the drawing program
module to the C<Broken> directory under <$respository>.
If the drawing program package name does not match the
drawing file name, the C<retrieve> method changes the
package name to argee and calls the C<release> method
with C<clobber => 1> option automatically release the
revised C<File::Drawing> object.

One early design actually used C<require> to
load in the module.
However no was found for unloading the program module without
leaving a residue memory. 
When processing a large number of drawing program modules
the resulting memory leak brought the processing to a crawl.
Creating an Perl object from the data from the program file, 
taps Perl's fine tuned memory management for objects.
Performance is consistent so long as Perl drawing objects
do not accumulate. When the object is no longer in use,
Perl behind the scene memory management does an excellent
job of free memory with no noticeable memory leaks.

If the C<retrieve> subroutine encounters an event where it cannot
continue, it halts processing, and returns the 
event as a scalar string, with the subroutine name and version.
If the C<retrieve> subroutine return is a reference,
the return is a C<$drawing> object; otherwise it is a scalar text event
message.

The events are as follows:

 "No drawing number specified\n"
 "# Locate error. Cannot find $pm in " . join( ' ', @INC) . "\n"
 "# ($repository)$drawing_number read error. $!\n"
 "# Contents eval error. Removing ($repository)$drawing_number.\n#\t$@" 

=head2 revise

 $error = $self->revise();
 $error = $self->revise(@options);
 $error = $self->revise(\@options);
 $error = $self->revise(\%options);

The C<revise> method revises the program module file for
a C<File::Drawing> object created by the C<new> or
C<retrieve> method.

Unless the C<original> or C<clobber> options exists,
the C<revise> method  uses the C<retrieve> method
to obtain the current drawing and 
compares the current drawing  contents and the revised contents.
If the contents are the same, the method returns
an empty string.

If the compare was differenct or not made,
the C<revise> method cleans up the C<$white_tape>,
incrementing the C<revision> and C<version> keys
off the current drawing if that is needed to keep
the revision and version from going backwards,
copyies the current revision to the 
C<"$repository::Obsolete> respository and
overwrites the current drawing program module file
with the revised C<$contents> and C<$white_tape>

The C<revise> method processes the following options:

=over 4

=item revise_repository

Override the C<$white_tape> repository key.

=item revise_drawing_number

Override the C<$white_tape> drawing key.

=item original

Sets the C<$white_tape> (version, revision) to ('0.01', '0')

=item clobber

Releases the C<File::Drawing> object no matter what.
Releases the drawing object even if the
revised C<$contents> are the
same as the current C<$contents>.

=item inc_path

When a drawing program file cannot be found
used the C<inc_path> list of directories instead
of C<@INC> to try to locate a repository
with the drawing number. 

=back

If the C<revise> subroutine encounters an event where it cannot
continue, it halts processing, and returns the 
event as a scalar string, with the subroutine name and version.
If the C<revise> subroutine return does not exist, the C<revise>
was successful; otherwise it is an event
message.

The events are as follows:

 "# Create directory error. Path: $dirs\n" .
 "#\tDrawing: ($repository)$drawing_number\n .
 "#\t$@\n"

 "# Open Error. File: $file\n#\t$!"

In addition, to these events, the C<revise> subroutine passes along any events
from the L<retrieve subroutine|File::Drawing/retrieve>.


=head1 REQUIREMENTS

Someday.

=head1 DEMONSTRATION

 #########
 # perl Drawing.d
 ###

~~~~~~ Demonstration overview ~~~~~

The results from executing the Perl Code 
follow on the next lines as comments. For example,

 2 + 2
 # 4

~~~~~~ The demonstration follows ~~~~~

     use File::Package;
     use File::SmartNL;
     use File::Path;
     use File::Copy;
     my $fp = 'File::Package';
     my $uut = 'File::Drawing';
     my $loaded;
     my $artists1;

 ##################
 # Load UUT
 # 

 my $errors = $fp->load_package($uut)
 $errors

 # ''
 #

 ##################
 # pm2number
 # 

 $uut->pm2number('_Drawings_::Repository0::Artists_M::Madonna::Erotica','_Drawings_::Repository0')

 # 'Artists_M::Madonna::Erotica'
 #

 ##################
 # pm2number, empty repository
 # 

 $uut->pm2number('_Drawings_::Repository0::Artists_M::Madonna::Erotica','')

 # '_Drawings_::Repository0::Artists_M::Madonna::Erotica'
 #

 ##################
 # pm2number, no repository
 # 

 $uut->pm2number('Etc::Artists_M::Madonna::Erotica')

 # 'Artists_M::Madonna::Erotica'
 #

 ##################
 # number2pm
 # 

 $uut->number2pm('Artists_M::Madonna::Erotica','_Drawings_::Repository0')

 # '_Drawings_::Repository0::Artists_M::Madonna::Erotica'
 #

 ##################
 # number2pm, empty repository
 # 

 $uut->number2pm('Artists_M::Madonna::Erotica','')

 # 'Artists_M::Madonna::Erotica'
 #

 ##################
 # number2pm, no repository
 # 

 $uut->number2pm('Artists_M::Madonna::Erotica')

 # 'Etc::Artists_M::Madonna::Erotica'
 #

 ##################
 # dod_date
 # 

 $uut->dod_date(25, 34, 36, 5, 1, 104)

 # '2004/02/05 36:34:25'
 #

 ##################
 # dod_drawing_number
 # 

 length($uut->dod_drawing_number())

 # 11
 #

 ##################
 # Repository0 exists
 # 

    ####
    # Drawing must find the below directory in the @INC paths
    # in order to perform this test.
    #
 -d (File::Spec->catfile( qw(_Drawings_ Repository0)))

 # '1'
 #

 ##################
 # Created Repository1
 # 

    ####
    # Drawing must find the below directory in the @INC paths
    # in order to perform this test.
    #     
    rmtree (File::Spec->catdir( qw(_Drawings_ Repository1) ));
    mkpath (File::Spec->catdir( qw(_Drawings_ Repository1) ));
 -d (File::Spec->catfile( qw(_Drawings_ Repository1)))

 # '1'
 #

 ##################
 # Retrieve erotica source control drawing
 # 

 my $erotica2 = $uut->retrieve('Artists_M::Madonna::Erotica', repository => '_Drawings_::Repository0')
 ref($erotica2)

 # 'File::Drawing'
 #

 ##################
 # Release erotica to different repository
 # 

  my $error= $erotica2->release(revise_repository => '_Drawings_::Repository1::' )
 $error

 # ''
 #

 ##################
 # Retrieve erotica
 # 

 my $erotica1 = $uut->retrieve('Artists_M::Madonna::Erotica', repository => '_Drawings_::Repository1');
 ref($erotica1)

 # 'File::Drawing'
 #

 ##################
 # Erotica contents unchanged
 # 

  $erotica1->[0]

 # {
 #          'amazon' => {
 #                        'part_number' => 'B000002M32'
 #                      },
 #          'in_house' => {
 #                          'path' => [
 #                                      'Index',
 #                                      'Music::Index',
 #                                      'Artists::Index',
 #                                      'Artists_M::Index',
 #                                      'Artists_M::Madonna::Index',
 #                                      'Artists_M::Madonna::Erotica'
 #                                    ],
 #                          'release_date' => '05 November, 1992',
 #                          'product_name' => 'Erotica',
 #                          'artists' => [
 #                                         'Madonna'
 #                                       ],
 #                          'thumb_url' => 'thumbs/erotica.jpg',
 #                          'product_type' => 'Audio CD',
 #                          'UPC' => {
 #                                     'part_number' => '093624058526'
 #                                   },
 #                          'home' => [
 #                                      'Artists_M::Madonna::Index,music',
 #                                      'Pop_Music::Artists_M::Madonna',
 #                                      'Pop_Music::Adult_Contemporary_Singles'
 #                                    ],
 #                          'discs' => [
 #                                       [
 #                                         'Erotica (Album Edit)',
 #                                         'Erotica (Kenlou B-Boy Mix)',
 #                                         'Erotica (WO 12 Inch)',
 #                                         'Erotica (Underground Club Mix)',
 #                                         'Erotica (Masters At Work Dub)',
 #                                         'Erotica (Jeep Beats)',
 #                                         'Erotica (William Orbit 12")'
 #                                       ]
 #                                     ],
 #                          'manufacturer' => 'Warner Brothers',
 #                          'image_url' => 'images/erotica.jpg',
 #                          'part_number' => 'Artists_M::Madonna::Erotica',
 #                          'features' => [
 #                                          'CD-single'
 #                                        ]
 #                        }
 #        }
 #
  $erotica1->[1]

 # {
 #          'description' => 'Madonna's Erotica Audio CD - narcissistic, dark, brooding, hint of S&M',
 #          'title' => 'Erotica',
 #          'date_loc' => '2004/05/03 01:53:23',
 #          'revision' => '0',
 #          'active_obsolete' => '',
 #          'revision_history' => {},
 #          'drawing_number' => 'Artists_M::Madonna::Erotica',
 #          'repository' => '_Drawings_::Repository1::',
 #          'date_gm' => '2004/05/03 05:53:23',
 #          'properties' => {
 #                            'dod_title' => 'Madonna, Erotica',
 #                            'dod_fscm' => 'none-SoftDia',
 #                            'dod_drawing_number' => '04040364301'
 #                          },
 #          'keywords' => 'cd single,madonna,music,pop music,madonna,adult contemporary singles,erotica,audio cd,pop,adult,contemporary,erotica,narcissistic,dark,brooding,S&M',
 #          'classification' => 'Public Domain',
 #          'file' => 'E:\User\SoftwareDiamonds\installation\t\File\_Drawings_\Repository1\Artists_M\Madonna\Erotica.pm',
 #          'version' => '0.01',
 #          'type' => 'source_control',
 #          'authorization' => {},
 #          'time_to_live' => ''
 #        }
 #

 ##################
 # Revise erotica contents
 # 

     $erotica2->[0]->{in_house}->{num_media} =  1;
     $error = $erotica2->revise();
 $error

 # ''
 #
 -e File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists_M Madonna Erotica.pm))

 # '1'
 #

 ##################
 # Retrieve erotica, revision 1
 # 

 $erotica1 = $uut->retrieve('Artists_M::Madonna::Erotica', repository => '_Drawings_::Repository1');
 ref($erotica1)

 # 'File::Drawing'
 #

 ##################
 # Erotica Revision 1 contents revised
 # 

 $erotica1->[0]

 # {
 #          'amazon' => {
 #                        'part_number' => 'B000002M32'
 #                      },
 #          'in_house' => {
 #                          'path' => [
 #                                      'Index',
 #                                      'Music::Index',
 #                                      'Artists::Index',
 #                                      'Artists_M::Index',
 #                                      'Artists_M::Madonna::Index',
 #                                      'Artists_M::Madonna::Erotica'
 #                                    ],
 #                          'release_date' => '05 November, 1992',
 #                          'product_name' => 'Erotica',
 #                          'artists' => [
 #                                         'Madonna'
 #                                       ],
 #                          'thumb_url' => 'thumbs/erotica.jpg',
 #                          'product_type' => 'Audio CD',
 #                          'UPC' => {
 #                                     'part_number' => '093624058526'
 #                                   },
 #                          'home' => [
 #                                      'Artists_M::Madonna::Index,music',
 #                                      'Pop_Music::Artists_M::Madonna',
 #                                      'Pop_Music::Adult_Contemporary_Singles'
 #                                    ],
 #                          'discs' => [
 #                                       [
 #                                         'Erotica (Album Edit)',
 #                                         'Erotica (Kenlou B-Boy Mix)',
 #                                         'Erotica (WO 12 Inch)',
 #                                         'Erotica (Underground Club Mix)',
 #                                         'Erotica (Masters At Work Dub)',
 #                                         'Erotica (Jeep Beats)',
 #                                         'Erotica (William Orbit 12")'
 #                                       ]
 #                                     ],
 #                          'manufacturer' => 'Warner Brothers',
 #                          'image_url' => 'images/erotica.jpg',
 #                          'part_number' => 'Artists_M::Madonna::Erotica',
 #                          'num_media' => 1,
 #                          'features' => [
 #                                          'CD-single'
 #                                        ]
 #                        }
 #        }
 #
 $erotica1->[1]->{version}

 # '0.02'
 #
 $erotica1->[1]->{revision}

 # '1'
 #
 $erotica1->[1]->{date_gm}

 # '2004/05/03 05:53:23'
 #
 $erotica1->[1]->{date_loc}

 # '2004/05/03 01:53:23'
 #
     $erotica2->[1]->{classification} = 'Top Secret';
     $error = $erotica2->revise();
 $error

 # ''
 #
 -e File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists_M Madonna Erotica-01.pm))

 # undef
 #

 ##################
 # Retrieve erotica revision 2
 # 

 $erotica1 = $uut->retrieve('Artists_M::Madonna::Erotica', repository => '_Drawings_::Repository1');
 ref($erotica1)

 # 'File::Drawing'
 #
  $erotica1->[1]

 # {
 #          'description' => 'Madonna's Erotica Audio CD - narcissistic, dark, brooding, hint of S&M',
 #          'title' => 'Erotica',
 #          'date_loc' => '2004/05/03 01:53:24',
 #          'revision' => '2',
 #          'active_obsolete' => '',
 #          'revision_history' => {},
 #          'drawing_number' => 'Artists_M::Madonna::Erotica',
 #          'repository' => '_Drawings_::Repository1::',
 #          'date_gm' => '2004/05/03 05:53:24',
 #          'properties' => {
 #                            'dod_title' => 'Madonna, Erotica',
 #                            'dod_fscm' => 'none-SoftDia',
 #                            'dod_drawing_number' => '04040364301'
 #                          },
 #          'keywords' => 'cd single,madonna,music,pop music,madonna,adult contemporary singles,erotica,audio cd,pop,adult,contemporary,erotica,narcissistic,dark,brooding,S&M',
 #          'classification' => 'Top Secret',
 #          'file' => 'E:\User\SoftwareDiamonds\installation\t\File\_Drawings_\Repository1\Artists_M\Madonna\Erotica.pm',
 #          'version' => '0.03',
 #          'type' => 'source_control',
 #          'authorization' => {},
 #          'time_to_live' => ''
 #        }
 #

 ##################
 # Retrieve _Drawings_::Erotica
 # 

 $erotica2 = $uut->retrieve('_Drawings_::Erotica', repository => '');
 ref($erotica2)

 # 'File::Drawing'
 #

 ##################
 # Revise erotica revision 2
 # 

 $error = $erotica2->revise(revise_drawing_number=>'Artists_M::Madonna::Erotica', revise_repository=>'_Drawings_::Repository1');
 $error

 # ''
 #
 -e File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists_M Madonna Erotica-2.pm))

 # '1'
 #

 ##################
 # Retrieve erotica revision 3
 # 

 $erotica1 = $uut->retrieve('Artists_M::Madonna::Erotica', repository => '_Drawings_::Repository1');
 ref($erotica1)

 # 'File::Drawing'
 #
 $erotica1->[1]->{version}

 # '0.04'
 #
 $erotica1->[1]->{revision}

 # '3'
 #
 $erotica1->[1]->{date_gm}

 # '2004/05/03 05:53:24'
 #
 $erotica1->[1]->{date_loc}

 # '2004/05/03 01:53:24'
 #

 ##################
 # Erotica revision 3 file contents revised
 # 

  $erotica1->[3]

 # '#!/usr/bin/perl
 ##
 ##
 #package _Drawings_::Repository1::Artists_M::Madonna::Erotica;

 #use strict;
 #use warnings;
 #use warnings::register;

 ##<-- BLK ID="DRAWING" -->
 ##<-- /BLK -->

 ######
 ## This section may be used for Perl subroutines and expressions.
 ##
 #print "Hello world from _Drawings_::Erotica\n";

 #1
 #'
 #

 ##################
 # Retrieve Sandbox erotica
 # 

    unshift @INC,'_Sandbox_';
    $erotica2 = $uut->retrieve('Artists_M::Madonna::Erotica', repository => '_Drawings_::Repository1');
 ref($erotica2)

 # 'File::Drawing'
 #

 ##################
 # Revise erotica revision 3
 # 

     shift @INC;
     $error = $erotica2->revise( );
 $error

 # ''
 #
 -e File::Spec->catfile(qw(_Drawings_ Repository1 Obsolete Artists_M Madonna Erotica-3.pm))

 # '1'
 #

 ##################
 # Retrieve erotica revision 4
 # 

 $erotica1 = $uut->retrieve('Artists_M::Madonna::Erotica', repository => '_Drawings_::Repository1')
 ref($erotica1)

 # 'File::Drawing'
 #
 $erotica1->[1]->{version}

 # '0.05'
 #
 $erotica1->[1]->{revision}

 # '4'
 #
 $erotica1->[1]->{date_gm}

 # '2004/05/03 05:53:24'
 #
 $erotica1->[1]->{date_loc}

 # '2004/05/03 01:53:24'
 #

 ##################
 # Erotica Revision 4 file contents revised
 # 

  $erotica1->[3]

 # '#!/usr/bin/perl
 ##
 ##
 #package _Drawings_::Repository1::Artists_M::Madonna::Erotica;

 #use strict;
 #use warnings;
 #use warnings::register;

 ##<-- BLK ID="DRAWING" -->
 ##<-- /BLK -->

 ######
 ## This section may be used for Perl subroutines and expressions.
 ##
 #print "Hello world from Sandbox\n";

 #1
 #'
 #
 rmtree (File::Spec->catdir( qw(_Drawings_ Repository1) ));

=head1 QUALITY ASSURANCE

Running the test script C<Drawing.t> verifies
the requirements for this module.
The C<tmake.pl> cover script for L<Test::STDmaker|Test::STDmaker>
automatically generated the
C<Drawing.t> test script, C<Drawing.d> demo script,
and C<t::File::Drawing> STD program module POD,
from the C<t::File::Drawing> program module contents.
The C<tmake.pl> cover script automatically ran the
C<Drawing.d> demo script and inserted the results
into the 'DEMONSTRATION' section above.
The  C<t::File::Drawing> program module
is in the distribution file
F<File-Drawing-$VERSION.tar.gz>.

=head1 NOTES

=head2 Author

The holder of the copyright and maintainer is

E<lt>support@SoftwareDiamonds.comE<gt>

=head2 COPYRIGHT NOTICE

Copyrighted (c) 2002 Software Diamonds

All Rights Reserved

=head2 Binding Requirements Notice

Binding requirements are indexed with the
pharse 'shall[dd]' where dd is an unique number
for each header section.
This conforms to standard federal
government practices, L<STD490A 3.2.3.6|Docs::US_DOD::STD490A/3.2.3.6>.
In accordance with the License, Software Diamonds
is not liable for any requirement, binding or otherwise.

=head2 License

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

=over 4

=item 1

Redistributions of source code must retain
the above copyright notice, this list of
conditions and the following disclaimer. 

=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

=back

SOFTWARE DIAMONDS, http://www.softwarediamonds.com,
PROVIDES THIS SOFTWARE 
'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
SHALL SOFTWARE DIAMONDS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL,EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE,DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING USE OF THIS SOFTWARE, EVEN IF
ADVISED OF NEGLIGENCE OR OTHERWISE) ARISING IN
ANY WAY OUT OF THE POSSIBILITY OF SUCH DAMAGE. 

=head1 SEE ALSO

=over 4

=item L<Data::Dumper|Data::Dumper>

=item L<Data::Secs2|Data::Secs2>

=item L<Data::SecsPack|Data::SecsPack>

=item L<Data::Startup|Data::Startup>

=item L<File::Revision|File::Revision>

=item L<File::Where|File::Where>

=item L<Docs::Site_SVD::File_Drawing|Docs::Site_SVD::File_Drawing>

=item L<Test::STDmaker|Test::STDmaker>

=item L<Test::Tech|Test::Tech>

=item L<ExtUtils::SVDmaker|ExtUtils::SVDmaker> 

=back

=cut

### end of file ###