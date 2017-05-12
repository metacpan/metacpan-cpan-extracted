package File::FindByRegex::Base;

use File::Find;
use File::Spec::Functions qw( catfile canonpath tmpdir rel2abs abs2rel );
use File::Path; 

use File::Basename;
fileparse_set_fstype($^O);

# use File::Spec; 
# This loads File::Spec::Unix or File::Spec::Win32 or File::Spec::VMS, ... 
# depending on wich is the actual operating system.
# Methods of File::Spec are overriden by theese platform specific modules.
# There are more methods apart of catfile. See the documentation of 
# File::Spec::Unix, wich has the documentation of all methods available.

use strict;
use vars qw( $VERSION );

( $VERSION ) = '$Revision: 1.2 $ ' =~ /\$Revision:\s+([^\s]+)/;

# FindByRegex object internals:
#
# $object = 
# {
#     -srcdir    => [],  # Source directories.
#     -ignore    => [],  # Regex,es matching files to be ignored.
#     -excepts   => [],  # Regex,es exceptions to '-ignore'.
#     -callbacks => {},  # Pairs regex,es - functions
#     -tardir    => '',  # Target directory.
#     -find      => {},  # Arguments for File::Find.
#
#     -explain   => number  # Why -abspathn was or wasn't ignored. Values: 0, 1, 3, 4 or 7.
#
#     -absdir   => string,  # Absolute directory being processed.
#     -reldir   => string,  # Relative directory being processed.
#     -abspathn => string,  # Absolute pathname (file) being procesed
#     -name     => string,  # File name w/o extension being processed.
#     -ext      => string,  # File extension being procesed.
#
#     -newdir   => string,  # Directory created in last call to check_newdir
#                  (i.e. File::Spec->catdir($this->{-tardir},$this->{-reldir}); )
# }

sub new
{
    my $class = shift;
    my %config;

    SWITCH:
    {        
        ref($_[0]) eq 'HASH' && do
        {
            # Argument is a hash ref.
            %config = %{$_[0]}; 
            last SWITCH;
        };

        @_ > 1 && do
        {
            # Must be a hash.
            %config = @_;
            last SWITCH;
        };  

        die "Wrong arguments: $!\n";
    }

    die __PACKAGE__,"::new : -srcdir and -tardir are mandatory\n"
    if( !exists($config{-srcdir}) || @{$config{-srcdir}}==0 || 
        !exists($config{-tardir}) || $config{-tardir} eq '' );

    # Set canonical paths.
    my @srcdirs = ();
    foreach my $path ( @{$config{-srcdir}} )
    {
        push @srcdirs, File::Spec->canonpath($path);
    }
    $config{-srcdir} = \@srcdirs;
    $config{-tardir} = File::Spec->canonpath($config{-tardir});

    # Other initilializations.
    $config{-newdir} = '';

    return bless \%config, $class  ;
}

sub travel_tree
{
    my $this = shift;

    $this->{-find}->{wanted} = \&wanted_
        if( ! exists $this->{-find}->{wanted} );

    $this->{-find}->{-this} = $this;
    find( $this->{-find}, @{ $this->{-srcdir} } );
}

sub newdir
{
    my $this = shift;

    return File::Spec->catdir($this->{-tardir},$this->{-reldir});
}

sub newfile
{
    my $this = shift;

    return File::Spec->catfile($this->newdir,$this->{-name}.$this->{-ext});
}

sub check_newdir
{ 
    my $this = shift;

    my $newdir = $this->newdir;

    # Check if target dir exist.
    if( !( -e $newdir ) )
    {
        # Debug.
        # print LOG 'mkpath ',$newdir,"\n";
 
        mkpath $newdir || die $!;            

        $this->{-newdir} = $newdir;
    }
}

# Action done for something.
sub post_match
{
    my $this = shift;

    # Do nothing. A hook to be overriden.
    # 
    # Check like this:
    #    if ( $this->{-explain} == 0 )
    #    { nothing matched ... }
    #
    #    if ( $this->{-explain} == 1 )  # 1 == 0 + 1
    #    { any in -ignore was matched ... }
    #
    #    if ( $this->{-explain} == 3 )  # 3 == 1 + 2
    #    { any in -ignore and in -excepts were matched ... }
    #
    #    if ( $this->{-explain} == 4 )   # 4 == 0 + 4
    #    { any in -callbacks was matched (and action executed) but nothing was matched in -ignore nor -excepts ... }
    #
    #    if ( $this->{-explain} == 7 )   # 7 == 3 + 4
    #    { any in -ignore, -excepts and -callbacks were matched (and action executed) ... }
    #
    # Funtion in -callbacks was executed if 4 or 7.

    # Debug:
    # print "FindByRegex.pm . \$this->{-explain}=",$this->{-explain},"\n";

    if( $this->{-explain} > 3 )
    {
        my $srcpathn = File::Spec->catfile( $this->{-reldir}, $this->{-name} . $this->{-ext} );
        $srcpathn = File::Spec->catdir( '...',$srcpathn);
        
        my $tarpathn = File::Spec->catdir('...',$this->{-name} . $this->{-ext}) ;
        
        print "$srcpathn -> $tarpathn\n";
    }
}

# Default wanted function for File::Find::find
sub wanted_
{
    # !! Note !!
    # This is the default function to be called by File::Find::find. When this
    # function (or other like this specified in new) is called, Perl passes 3 
    # arguments, not documented (in this order):
    # 1.- Hash reference with wich find is called. If 1st argument is a function 
    #     ref then it's included in a hash ref.
    # 2.- Directory root where find begun.
    # 3.- ... unknown ...

    # !! A bit of hacking !!
    # The FindByRegex object was passed as a member of the hash argument
    # to this function. See previous note.
    my $this = $_[0]->{-this};

    # Debug:
    # print "wanted_(...): ",join(',',@_),"\n";
    # print "wanted_(...). this: $this\n";

    my ($n,$absdir,$ext) = fileparse($File::Find::name, '\.[^.]*$' );
    $absdir = File::Spec->canonpath($File::Find::dir);

    my $reldir = File::Spec->abs2rel($absdir, $_[1] );
    $reldir =~ s/^[a-zA-Z]:// if $^O eq 'MSWin32';
    # !! Importante !!:
    # En ActivePerl (MSWin32) hay un error en funcion abs2rel que hace que 
    # directorio relativo resultante empiece por C:, D: ... Asi por ejemplo
    # salen cosas como C:bin en lugar de bin.
    # Para evitarlo es por lo que hacemos esta sustitucion.

    my $abspathn = File::Spec->catfile($absdir,$n.$ext);
    # This may be a directory, and in this case $absdir is its parent dir,
    # $n is the directory name without path and $ext is ''.
 
    $this->{-absdir} = $absdir;
    $this->{-reldir} = $reldir;
    $this->{-abspathn} = $abspathn;
    $this->{-name} = $n;
    $this->{-ext} = $ext;

    # Local variable's explanation:
    #
    # $fn
    # Filename (name and extension) without path.
    #
    # $abspathn
    # Absolute pathname of file.
    # Better than $File::Find::name, because this don't put all slashes on same
    # direction, at less on Win32. Makes thins like C:\Perl/bin/lib/abbrev.pl  
    #
    # $absdir
    # Absolute directory path.
    #
    # $reldir
    # Relative directory path.
    #
    # $n
    # Name of file without extension.
    #
    # $ext
    # Filename extension (including period).

    # Debug:
    # print "want_(...):1: fn: $n$ext absdir:$absdir abspathn: $abspathn\n";

    # If $abspathn isn't a directory nor is a file or subdirectory of $tardir.
    unless( $this->recursive_( $abspathn,$this->{-tardir})      )
    {
        # Debug.
        # print  "wanted_(...):2: abspathn: $abspathn absdir: $absdir reldir: $reldir name: $n ext: $ext\n";
       
        # -explain is intialized for each file/dir.
        $this->{-explain} = 0;

        # Check if must be ignored. 
        $this->{-explain} += $this->check_if_must_ignore_;  # Adds nothing, 1, or 1 and 2 (3).

        if(  $this->{-explain} != 1 )
        {
            # Do action.
            $this->{-explain} += $this->do_action_;   # Adds 4 or nothing to $this->{-explain}
        }       

        # At this point $this->{-explain} may be 0, 1, 3, 4 or 7.
        $this->post_match;
    }
}

# Check if the pathname being processed includes the target directory.
# Use:
#    Sample 1: recursive_( $abspathn, $tardir ) 
#              Checks if $abspathn includes $tardir. 
#
#    Sample 2: recursive_( 'c:\Perl\htmltoc\Perl\bin', 'c:\Perl\htmltoc' )
#              Return true because $abspathname is a subdirectoruy of $tardir.
#              
# Returns: true if it is, false otherwise.
#
sub recursive_
{
    my $this = shift;
    my ($abspathn, $tardir) = @_;

    $tardir = quotemeta( $this->{-tardir} );

    # Debug:
    # print LOG "Recursive(...):1: abspathn: $abspathn tardir: $tardir\n";

    return $abspathn =~ /^$tardir/;
}

# Check if file or dir must be ignored:
#     initializes $rc = 0
#     adds 1 ($rc += 1) if -ignore is matched
#     if -ignore is matched, adds 2 ($rc += 2) if also -excepts is matched.
#
# Returns 0, 1 or 3 (-excepts is checked only if -ignore is matched):
#
# 0 : -callbacks must be checked: no regex in -ignore is matched (not ignored
#     at the moment).
#
# 1 : don't check -callbacks and ignore: matched a regex in -ignore and none
#     in -excepts.
#
# 3 : -callbacks must be checked: matched a regex in -ignore and another regex
#     in -excepts (not ignored at the moment).
# 
# Use:
#   if( $this->check_if_must_ignore_ == 1 ) { ignore .... }
#
sub check_if_must_ignore_
{
    my $this = shift;

    my $re;
    my $f = $this->{-abspathn};

    my $rc = 0;  # Return code.

    foreach $re ( @{ $this->{-ignore}} )
    {
        if( $f =~ $re )
        {
            $rc += 1;

            # If 'ignore' match, but it is in 'excepts', don't ignore.
            foreach $re ( @{ $this->{-excepts} } )
            {
                if( $f =~ $re )
                {
                    # Don't ignore.
                 
                    $rc += 2;
   
                    # Debug:
                    # print "MustBeIgnored(...):1: $f not ignored.\n";
 
                    return $rc;   # Returns 3
                }
            }
 
            # Ignore if this point has been reached.
 
            return $rc; # Returns 1
        }
    }

    return $rc;  # Returns 0. 
}

# Check absolute pathname of file/dir against each regex of -callbacks.
# If any is matched, action value is executed and 4 is returned, else
# 0 is returned.
#
sub do_action_
{
    my $this = shift;

    my $f = $this->{-abspathn};

    # Debug
    # print 'do_action_ .',join(',',keys %{ $this->{-callbacks} } ),"\n"; die;

    my $rc = 0;

    foreach my $re ( keys %{ $this->{-callbacks} } )
    {
        if( $f =~ $re ) 
        {
            my $action = $this->{-callbacks}->{$re};

            # Debug:
            # print "DoAction(...):1: re: $re action: $action f: $f\n";

            $rc += 4;
             
            if( ref($action) eq 'CODE' )
            {     
                &$action( $this );           
            }
            else
            {     
                eval "&$action( \$this )";
                die $@ if $@; 
            }

            last;
        }
    }

    return $rc;
}

package File::FindByRegex;

use File::Spec;

use strict;
use vars qw( @ISA );

@ISA = qw( File::FindByRegex::Base );

# Package for override File::FindByRegex::Base functions 

1;

__END__

=head1 NAME

File::FindByRegex - Wrapper for File::Find that finds a directory tree and runs
some action for each file whose name matchs a regex.

=head1 SYNOPSYS

   use File::FindByRegex;

   $find = File::FindByRegex->new( {

            -srcdir => ['C:\tmp\teradata-sql'], 
            -tardir => 'C:\tmp\teradata-sql\doc', 
            -find => {no_chdir => 1}, 

            -callbacks => 
            { 
                qr/\.p(l|m|od|t)$/oi,             => \&treat_pod,
                qr/\\sql\\.+?\.sql$/oi,           => 'treat_pod',
                qr/\.html?$/oi,                   => \&treat_html,
                qr/\.txt$/oi                      => \&treat_txt,
                qr/\.(jpg|gif|png|bmp|tiff)$/     => sub { &treat_graphic(@_) }
            },

            -ignore => 
            [
               qr/eg\\.+\.sql$/oi,  # *.sql in directory eg
               qr/java\\/oi,        # All files in java directory.
            ],
  
            -excepts   => 
            [ 
               qr/java\\.*?\.html?$/oi   # don't ignore *.html in java/
            ]          
   });

   sub File::FindByRegex::treat_pod
   {
       my $this = shift;  
       ...
   }

   sub File::FindByRegex::treat_html
   {
       my $this = shift;  
       ...
   }

   sub File::FindByRegex::treat_txt
   {
       my $this = shift;  
       ...
   }

   sub File::FindByRegex::treat_graphic
   {
       my $this = shift;  
       ...
   }

   $find->travel_tree;

=head1 DESCRIPTION

This is an OO module wrapper for File::Find that adds the functionality of
executing some action if absolute pathname of visited file matchs a regex.

Functions:

=head2 C<$find_obj = File::FindByRegex-E<gt>new( ... )>

Returns a File::FindByRegex object (a bessed hash reference).
Accepts a hash or a hash reference as argument. If argument is a hash ref., it
must be the only argument.

In both cases, keys of hash argument must be:

=over 4

=item C<-srcdir =E<gt> [...]>

Mandatory.
List of absolute paths to directories.
Finds each directory specified in array.

=item C<-tardir =E<gt> 'target_directory'>

Mandatory.
Target directory for actions. Specified with absolute path.

=item C<-find =E<gt> {...}>

Optional.
Arguments for C<File::Find>. See documentation of C<File::Find>.

=item C<-callbacks =E<gt> {...}>

Optional.
Regular expressions (keys) and actions to be executed (values).
Each key is a regular expression whose value is a function reference or a 
function name (string).

All functions specified as values must accept a C<File::FindByRegex> object as
first (and only) argument (they must be class methods).

=item C<-ignore =E<gt> [...]>

Optional.
List of regular expressions matching files to be ignored.

=item C<-excepts =E<gt> [...]>

Optional.
List of regular expressions that are exceptions to C<-ignore> list.

=back

Each absolute pathname of each file or dir is tested against each regular
expression of C<-ignore> list. If any is matched, its absolute pathname is
tested against each regex of C<-excepts>. If absolute pathname does not match
any in C<-ignore> or matchs any in C<-ignore> but other regex is matched in 
C<-excepts>, then the C<-callbacks> list of regex is tested. If any is matched
here, the associated action is executed.

Files and directory paths must be specified in the filesystem language
provided by O.S. This means that for Win32, \ of dir separator must be pecified
as \\.

In C<-ignore> and C<-excepts> list, regexes are tested in same order specified
by array.

=head2 C<$find_obj-E<gt>travel_tree>

Finds beginning with each directory specified in C<-srcdir>. Each file or
directory full pathname is macthed against regular expressions.

Functions specified in C<-callbacks> are executed when:

=over 4

=item *

None is matched in C<-ignore>, and the full pathname of file or dir. matches a
key in C<-callbacks>.

=item *

Full pathname of file or dir. matchs a regex in
C<-ignore>, but another is matched in C<-excepts>, and a key is matched in 
C<-callbacks>.

=back

Otherwise, no action is called for the file or dir.

=head1 ACTIONS SPECIFIED BY C<-callbacks> KEY.

Actions specified by C<-callbacks> key are called in the namespace of
C<File::FindByRegex>. Suppose this code:

    package AnyPackage;

    use File::FindByRegex;

    my $f = File::FindByRegex->new( 
                   ..., 
                   -callbacks => {
                        qr/\\doc\\.+?\.pod/oi => \&any_function
                    },
                   ...
            );
    
    sub any_function { my $this = shift; ... }

When any file matchs the key in C<-callbacks>, the C<File::FindByRegex> does
something like this:

    package File::FindByRegex;
    ...

    my $action = $this->{-callbacks}->{$re};
    
    if( ref($action) eq 'CODE' )
    {     
        &$action( $this );           
    }
    else
    {     
        eval "&$action( \$this )";
        die $@ if $@; 
    }

This produces an error because any_function isn't defined in C<File::FindByRegex>
package.

To avoid errors of this kind you have two posibilities:

=over 4

=item *

Specify C<any_function> in C<File::FindByRegex> package:

    package AnyPackage;

    use File::FindByRegex;

    my $f = File::FindByRegex->new( 
                   ..., 
                   -callbacks => {
                        qr/\\doc\\.+?\.pod/oi => \&any_function
                    },
                   ...
            );
    
    sub File::FindByRegex::any_function { my $this = shift; ... }

=item *

Specify the package in C<-callbacks>:

    package AnyPackage;

    use File::FindByRegex;

    my $f = File::FindByRegex->new( 
                   ..., 
                   -callbacks => {
                        qr/\\doc\\.+?\.pod/oi => \&AnyPackage::any_function
                    },
                   ...
            );
    
    sub any_function { my $this = shift; ... }

But in this case remember that C<$this> is a C<File::FindByRegex> blessed
reference.

=back

=head1 OVERRIDABLE FUNCTION.

A function named C<post_match>, of this module exists with the only purpose of
being overriden. It is called unconditionally for each visited file or dir.

Its default implementation is empty, so if not overriden, nothing is done.
Use it as a hook or callback in addition to C<-callbacks> functions.

Inside C<post_match>, one can investigate what occurred by the value of
C<$this-E<gt>{-explain}>:

=over 4

=item *

It's initialized to 0 for each visited file/dir.

=item *

If a regex in C<-ignore> is matched, 1 is added.

=item *

If a regex in C<-excepts> is matched, then 2 is added.

Remember that C<-excepts> is checked only if C<-ignore> is matched.

=item *

If a regex in C<-callbacks> is matched, 4 is added.

Remember that C<-callbacks> is checked only if none C<-ignore> nor C<-excepts>
are matched or if both are matched.

=back

So, posible values of C<$this-E<gt>{-explain}> are 0, 1, 3, 4, or 7:

   sub File::FindByRegex::post_match
   {
       my $this = shift;

     SWITCH:
     {
         $this->{-explain}==0 && do
         {
             ... nothing matched ...
             last;
         };

         $this->{-explain}==1 && do
         {
             ... matched -ignore only ...
             last;
         };

         $this->{-explain}==3 && do
         {
             ... matched -ignore and -excepts only ...
             last;
         };

         $this->{-explain}==4 && do
         {
             ... matched only -callbacks and function called ...
             last;
         };

         $this->{-explain}==7 && do
         {
             ... matched -ignore, -excepts and -callbacks, so
                 function was called ...
             last;
         };
     }
   }

Inside C<post_match>, one can ask for C<$this-E<gt>{-explain}> to know if an action
of callbacks was executed.

Sample:

    package Pkg;
    ...
    @ISA = qw( File::FindByRegex );
    ...

    sub post_match
    {
        my $this = shift;

        my $action_done = $this->{-explain} == 4 || $this->{-explain} == 7 ? 
                          1 : 0;

        if( $action_done )
        {
            # An action in -callbacks was called.
            ...
        }
        else
        {
            # No action done:  no regular expression matched.
            ...
        }
        ...
    }    

Must accept a C<File::FindByRegex> object as first and only argument.
Must be in C<File::FindByRegex> or a derived package because is
called in the context of C<File::FindByRegex> namespace.

=head1 OBJECTS INTERNALS.

Keys and values of C<$this> blessed hash reference are:

=over 4

=item *

Each key/value pairs of hash passed as argument to C<new>, are members of C<$this>.

=item *

C<-explain> with the meaning yet explained.

=item *

And attributes of file/dir being processed:

    -absdir   => string,  # Absolute directory being processed.
    -reldir   => string,  # Relative directory being processed.
    -abspathn => string,  # Absolute pathname (file) being procesed
    -name     => string,  # File name w/o extension being processed.
    -ext      => string,  # File extension being procesed.

=back

=head1 SEE ALSO

C<File::Find>.

=head1 AUTHOR AND COPYRIGHT

Enrique Castilla Contreras (ecastilla@wanadoo.es).

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

