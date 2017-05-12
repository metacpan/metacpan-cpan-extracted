
###################################################################################
#
#   Embperl - Copyright (c) 1997-2008 Gerald Richter / ecos gmbh  www.ecos.de
#   Embperl - Copyright (c) 2008-2014 Gerald Richter
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#   $Id: Object.pm 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################


package Embperl::Object ;

require Cwd ;
require File::Basename ;

require Exporter;
require DynaLoader;

use Embperl ;
use Embperl::Constant ;

use constant OK => 0  ;
use constant NOT_FOUND => 404 ; 
use constant FORBIDDEN => 403 ; 
use constant DECLINED  => $ENV{MOD_PERL}?-1:403 ; 


use File::Spec ;
use File::Basename ;

use strict ;
use vars qw(
    @ISA
    $VERSION
    $volume
    $fsignorecase
    %packages
    ) ;


@ISA = qw(Exporter DynaLoader);


$VERSION = '2.4.0';


$volume = (File::Spec -> splitpath ($Embperl::cwd))[0] ;
$fsignorecase = File::Spec->case_tolerant ;

1 ;

#############################################################################
#
# Normalize path into filesystem
#
#   in	$path	path to normalize
#   ret		normalized path
#


sub norm_path

    {
    my $path = shift ;
    return '' if (!$path) ;

    # remove spaces
    $path = $1 if ($path =~ /^\s*(.*?)\s*$/) ;
    
    if (File::Spec->file_name_is_absolute ($path))
        {
        $path = File::Spec -> canonpath ($path) ;
        if (!$_[0])
            {
            my ($volume, $dir, $file) = File::Spec -> splitpath ($path) ;
            $_[0] = File::Spec -> catdir ($volume, $dir) ;
            }
        }
    else
        {            
        $_[0] ||= Cwd::fastcwd ;
        # make absolute path
        $path = File::Spec -> rel2abs ($path, $_[0]) ;
        }
    # Use always forward slashes
    $path =~ s/\\/\//g ;
    # Add volume (i.e. drive on Windows) if not exists
    $path = $volume . $path if ($path =~ /^\//) ;
    # Make lower case if filesystem doesn't cares about case 
    $path = lc ($path) if ($fsignorecase) ;

    return $path ;
    }


#############################################################################

sub handler_dmalloc
    {
    my %req ;

    $req{'req_rec'} = $_[0] ;
    
    my $n = Embperl::dmalloc_mark () ;
    my $rc = Execute (\%req) ;
    Embperl::dmalloc_check ($n, "Embperl::Object") ;
    return $rc ;
    }
        
#############################################################################

sub handler
    {
    my %req ;

    $req{'req_rec'} = $_[0] ;
    
    Execute (\%req) ;
    }
        
    
    
#############################################################################

sub run
    {
    $_[0] -> run ;
    }

#############################################################################

sub Execute

    {
    my $req = shift ;
    
    local $SIG{__WARN__} = \&Embperl::Warn ;

    $Embperl::req_rec = $req -> {req_rec} ;
    my ($rc, $r) = Embperl::Req::InitRequest ($req -> {req_rec}, $req) ;
    my $debug     = $r && ($r -> config -> debug & Embperl::Constant::dbgObjectSearch) ;
    
    if ($rc) 
        {
        print Embperl::LOG "[$$]Embperl::Object InitRequest returns $rc\n"  if ($debug);
        return $rc ;
        }


    if (exists $req -> {fdat} && ref ($req -> {fdat}) eq 'HASH')
        {
        %Embperl::fdat = %{$req -> {fdat}} ;
        if (ref $req -> {ffld} eq 'ARRAY')
            {
            @Embperl::ffld = @%{$req -> {ffld}};
            }
        else
            {
            @Embperl::ffld = keys %Embperl::fdat ;
            }
        delete $req -> {fdat};
        delete $req -> {ffld} ;
        }


    my $app    = $r -> app ;
    my $appcfg = $app -> config;

    my $cwd ;
    my $filename = norm_path ($r -> param -> filename, $cwd) ;
    my $apr        ;
    $apr = $req -> {req_rec} if ($req -> {req_rec}) ;

    my $basename  = $appcfg -> object_base || '_base.epl' ;
    ##$basename     =~ s/%modifier%/$req->{object_base_modifier}/ ;
    my $addpath   = $appcfg -> object_addpath ;
    my $reqpath   = $appcfg -> object_reqpath ;
    my $directory ;
    my $rootdir   = $apr?norm_path ($apr -> document_root, $cwd):"$volume/" ;
    my $stopdir   = norm_path ($appcfg -> object_stopdir, $cwd) ;
    
    if (-d $filename)
        {
        $directory = $filename ;
        }
    else
        {
        $directory = dirname ($filename) ;
        }
    
    my @searchpath  ;
    	 
    print Embperl::LOG "[$$]Embperl::Object Request Filename: $filename\n" if ($debug);
    print Embperl::LOG "[$$]Embperl::Object basename: $basename\n"  if ($debug);
    
    my $fn ;
    my $ap ;
    my $ldir  = '' ;
    my $found = 0 ;
    my $fallback = 0 ;
    	
    do
        {
        $fn = "$directory/$basename" ;
        push @searchpath, $directory ; 
        print Embperl::LOG "[$$]Embperl::Object Check for base: $fn\n"  if ($debug);
        if (-e $fn)
            {
            $apr -> filename ($fn) if ($apr) ;
            $found = 1 ;
            }
        else
            {
	    $ldir      = $directory ;
            $directory = dirname ($directory) ;
            }
        }
    while (!$found && $ldir ne $rootdir && $ldir ne $stopdir && $directory ne '/' && $directory ne '.' && $directory ne $ldir) ;

    while ($found && $stopdir && $stopdir ne $directory && $directory ne '/' && $directory ne '.' && $directory ne $ldir) 
        {
	$ldir      = $directory ;
        $directory = dirname ($directory) ;
        push @searchpath, $directory ; 
        }

    push @searchpath, @$addpath if ($addpath) ; 
    if (!$found)
        {
        foreach $ap (@$addpath)
            {
            next if (!$ap) ;
            $fn = "$ap/$basename" ;
            print Embperl::LOG "[$$]Embperl::Object Check for base: $fn\n"  if ($debug);
            if (-e $fn)
                {
                $apr -> filename ($fn) if ($apr) ;
                $found = 1 ;
                last ;
                }

            }
        }


    if ($found)
        {
        print Embperl::LOG "[$$]Embperl::Object Found Base: $fn\n"  if ($debug);
        print Embperl::LOG "[$$]Embperl::Object path: @searchpath\n"  if ($debug);

        
        my $basepackage = $packages{$fn} ;
        my $package     = $packages{$filename} ;

        if (!$basepackage)
            {
            print Embperl::LOG "[$$]Embperl::Object import new Base: $fn\n"  if ($debug);
            my $cparam = {%$req, inputfile => $fn, import => 0 } ;
            my $c = $r -> setup_component ($cparam) ;
            run($c) ;
            $basepackage = $packages{$fn} = $c -> curr_package if (!$r -> error) ;
            $c -> cleanup ;
            print Embperl::LOG "[$$]Embperl::Object import base ", ($r -> error?'with ERRORS ':'') . "finished: $fn, " . ($basepackage?"package = $basepackage \n":"\n")  if ($debug);

            if (!$r -> error)
                {
                local $^W = 0 ;
        no strict ;
                my $isa   = \@{"$package\:\:ISA"} ;
                my $class = $appcfg -> object_handler_class || 'Embperl::Req' ;
                if (!grep /^\Q$class\E$/, @$isa)
                    {
                    push @{"$basepackage\:\:ISA"}, $class ;
                    }
                }
        use strict ;
            }

        $r -> config -> path (\@searchpath) ;

        if ($appcfg -> object_app && !$r -> error)
            {
            my $appfn = $appcfg -> object_app ;

            print Embperl::LOG "[$$]Embperl::Object import new Application: $appfn\n"  if ($debug);
            
            my $cparam = {object => $appfn, syntax => 'Perl', debug => $req -> {debug}} ;
            my $c = $r -> setup_component ($cparam) ;
            my $app = run($c) ;
            my $package = $c -> curr_package  if (!$r -> error) ;
            $c -> cleanup ;
            print Embperl::LOG "[$$]Embperl::Object import new Application ", ($r -> error?'with ERRORS ':'') . "finished: $appfn, " . ($package?"package = $package\n":"\n")  if ($debug);

            if (!$r -> error)
                {
                no strict ;
                my $isa = \@{"$package\:\:ISA"} ;
                if (!grep /^Embperl::App$/, @$isa)
                    {
                    push @{"$package\:\:ISA"}, 'Embperl::App'  ;
                    }
                use strict ;
            
                $app = $r -> app ;
                bless $app, $package ;

                my $status = eval { $app -> init ($r) ; } ;
                if ($@)
                    {
                    $r -> logerror (Embperl::Constant::rcEvalErr, $@, $apr) ;
                    }
                elsif ($status) 
                    {
                    $r -> send_http_header ;
                    $r -> cleanup ;
                    print Embperl::LOG "[$$]Embperl::Object Application -> init had returned $status\n"  if ($debug);
                    return $status ;
                    }
                $filename = norm_path ($r -> param -> filename, $cwd) ;
                }
            }



        my $file_not_found = 0 ;
        if (!-f $filename)
            {
            $file_not_found = 1 ;
            if ($reqpath)
                {
                my $file = basename ($filename) ;
                foreach my $path (@$reqpath)
                    {
                    my $testfn = "$path/$file" ;
                    print Embperl::LOG "[$$]Embperl::Object Search for request file $file in $path\n"  if ($debug);
                    if (-f $testfn)
                        {
                        $filename = $testfn ;
                        $file_not_found = 0 ;
                        last ;
                        }
                    }
                }
            }

        if ($file_not_found)
            {
            if ($appcfg -> object_fallback)
                {
                $fallback = 1 ;
                $filename = $appcfg -> object_fallback ;
                print Embperl::LOG "[$$]Embperl::Object use fallback: $filename\n"  if ($debug);
                }
            else
                {
                print Embperl::LOG "[$$]Embperl::Object $filename not found, no fallback\n"  if ($debug);
                return NOT_FOUND ;
                }
            }
    
        if ($fn eq $filename) 
            {
            $r -> logerror (Embperl::Constant::rcForbidden, $filename, $apr) ;
            $r -> cleanup ;
            return FORBIDDEN ;
            }


        if ((!$package || $fallback) && !$r -> error)
            {
            print Embperl::LOG "[$$]Embperl::Object import new file: $filename\n"  if ($debug && !$fallback);
            
            my $cparam = {%$req, inputfile => $filename, import => 0 } ;
            my $c = $r -> setup_component ($cparam) ;
            run($c) ;
            $package = $packages{$filename} = $c -> curr_package if (!$r -> error);
            $c -> cleanup ;
            print Embperl::LOG "[$$]Embperl::Object import file ", ($r -> error?'with ERRORS ':'') , "finished: $filename, package = $package\n"  if ($debug);

            if (!$r -> error && $package ne $basepackage)
                {
        no strict ;
                my $isa   = \@{"$package\:\:ISA"} ;
                if (!grep /^\Q$basepackage\E$/, @$isa)
                    {
                    push @{"$package\:\:ISA"}, $basepackage ;
                    }
                }
        use strict ;

            }

        if (!$r -> error)
            {
            $r -> param -> filename ($filename) if ($filename ne $fn) ;
            bless $r, $package ;
            }

        my $cparam = {%$req, inputfile => $fn } ;
        my $c = $r -> setup_component ($cparam) ;

        $rc = run($r) ;

        $r -> cleanup ;

        return $rc ;
        }

   
    $r -> logerror (Embperl::Constant::rcNotFound, $basename, $apr) ;
    $apr -> log_error ("Embperl::Object base $basename not found. Searched '@searchpath'" . ($addpath?" and '@$addpath' ":''))  if ($apr) ;
    $r -> cleanup ;

    return &NOT_FOUND ;
    }


__END__


=head1 NAME

Embperl::Object - Extents Embperl for building whole website with reusable components and objects


=head1 SYNOPSIS


    <Location /foo>
        EMBPERL_APPNAME     unique-name
        EMBPERL_OBJECT_BASE base.htm
        EMBPERL_URIMATCH "\.htm.?|\.epl$"
        SetHandler perl-script
        PerlHandler Embperl::Object 
        Options ExecCGI
    </Location>


=head1 DESCRIPTION

I<Embperl::Object> allows you to build object-oriented (OO) websites using
HTML components which implement inheritance via subdirectories. This
enables elegant architectures and encourages code reuse. The use of
inheritance also enables a website-wide "look and feel" to be specified
in a single HTML file, which is then used as a template for every other
page on the site. This template can include other modules which can be
overridden in subdirectories; even the template itself can be
overridden. In a nutshell, I<Embperl::Object> makes
the design of large websites much more intuitive, allowing
object-oriented concepts to be utilised to the fullest while staying
within the "rapid application development" model of Perl and HTML.


I<Embperl::Object> is basicly a I<mod_perl> handler or could be invoked
offline and helps you to
build a whole page out of smaller parts. Basicly it does the following:

When a request comes in, a page, which name is specified by L<EMBPERL_OBJECT_BASE>, is
searched in the same directory as the requested page. If the pages isn't found, 
I<Embperl::Object> walking up the directory tree until it finds the page, or it
reaches C<DocumentRoot> or the directory specified by L<EMBPERL_OBJECT_STOPDIR>.

This page is then called as frame for building the real page. Addtionaly I<Embperl::Object>
sets the search path to contain all directories it had to walk before finding that page.
If L<EMBPERL_OBJECT_STOPDIR> is set the path contains all directories up to the
in EMBPERL_OBJECT_STOPDIR specified one.

This frame page can now include other pages, using the C<Embperl::Execute> method.
Because the search path is set by I<Embperl::Object> the included files are searched in
the directories starting at the directory of the original request walking up thru the directory
which contains the base page. This means that you can have common files, like header, footer etc.
in the base directory and override them as necessary in the subdirectory.

To include the original requested file, you need to call C<Execute> with a C<'*'> as filename.
To call the the same file, but in an upper directory you can use the
special shortcut C<../*>.

Additionally I<Embperl::Object> sets up a inherence hierachie for you: The requested page
inherit from the base page and the base page inherit from a class which could be
specified by C<EMBPERL_OBJECT_HANDLER_CLASS>, or if C<EMBPERL_OBJECT_HANDLER_CLASS> is
not set, from C<Embperl::Req>. That allows you to define methods in base page and
overwrite them as necessary in the original requested files. For this purpose a request
object, which is blessed into the package of the requested page, is given as first 
parameter to each page (in C<$_[0]>). Because this request object is a hashref, you can
also use it to store additional data, which should be available in all components. 
I<Embperl> does not use this hash itself, so you are free to store whatever you want.
Methods can be ordinary Perl sub's (defined with [! sub foo { ... } !] ) or Embperl sub's
(defined with [$sub foo $] .... [$endsub $]) .

=head1 Runtime configuration

The runtime configuration is done by setting environment variables,
in your web
server's configuration file. Basicly the configuration is the same as
for normal Embperl. All Embperl configuration directives also applies
to Embperl::Object. There are a few addtional configuration directives
listed below. Addtionaly you have to set the C<PerlHandler> to
C<Embperl::Object> when running under mod_perl or use C<epocgi.pl>
instead of C<embpcgi.pl> when running as CGI Script.


=head2 EMBPERL_DECLINE

Perl regex which files should be ignored by I<Embperl::Object>

=head2 EMBPERL_FILESMATCH

Perl regex which files should be processed by I<Embperl::Object>

=head2 EMBPERL_OBJECT_BASE

Name of the base page to search for

=head2 EMBPERL_OBJECT_STOPDIR

Directory where to stop searching for the base page

=head2 EMBPERL_OBJECT_ADDPATH

Additional directories where to search for pages. Directories are
separated by C<;> (on Unix C<:> works also). This path is
B<always> appended to the searchpath.

=head2 EMBPERL_OBJECT_FALLBACK

If the requested file is not found the file given by C<EMBPERL_OBJECT_FALLBACK>
is displayed instead. If C<EMBPERL_OBJECT_FALLBACK> isn't set a
staus 404, NOT_FOUND is returned as usual. If the fileame given in 
C<EMBPERL_OBJECT_FALLBACK> doesn't contain a path, it is searched thru the same
directories as C<EMBPERL_OBJECT_BASE>.

=head2 EMBPERL_OBJECT_HANDLER_CLASS

If you specify this call the template base and the requested page inherit all
methods from this class. This class must contain C<Embperl::Req> in his
@ISA array.

=head2 EMBPERL_OBJECT_APP

Filename of the application object. The file should contain the Perl code for 
the application object. The must be no package name given (as the package is set
by Embperl::Object), but the @ISA should point to Embperl::App.
If set this file is searched through the same search path as any content file.
After a successfull load the init method is called with the Embperl request object
as parameter. The init method can change the parameters inside the request object
to influence the current request.

The init method should return zero or a valid HTTP status code (e.g. return 302
and set the location header in %http_headers_out)

=head1 Execute

You can use I<Embperl::Object> also offline. You can do this by calling the function
C<Embperl::Object::Execute>. C<Execute> takes a hashref as argument, which can
contains the same parameters as the C<Embperl::Execute> function. Additionally
you may specify the following parameters:

=over 4

=item object_base

same as $ENV{EMBPERL_OBJECT_BASE} 

=item object_addpath

same as $ENV{EMBPERL_OBJECT_ADDPATH} 

=item object_stopdir

same as $ENV{EMBPERL_OBJECT_STOPDIR} 

=item object_fallback

same as $ENV{EMBPERL_OBJECT_FALLBACK} 

=item object_handler_class

same as $ENV{EMBPERL_OBJECT_HANDLER_CLASS}

=back

See also the C<object> and C<isa> parameters in Embperl's Execute function, on how
to setup additional inherence and how to create Perl objects out of Embperl pages.

=head1 Basic Example


With the following setup:


 <Location /foo>
    PerlSetEnv EMBPERL_OBJECT_BASE base.htm
    PerlSetEnv EMBPERL_FILESMATCH "\.htm.?|\.epl$"
    SetHandler perl-script
    PerlHandler Embperl::Object 
    Options ExecCGI
 </Location>


B<Directory Layout:>

 /foo/base.htm
 /foo/head.htm
 /foo/foot.htm
 /foo/page1.htm
 /foo/sub/head.htm
 /foo/sub/page2.htm

B</foo/base.htm:>

 <html>
 <head>
 <title>Example</title>
 </head>
 <body>
 [- Execute ('head.htm') -]
 [- Execute ('*') -]
 [- Execute ('foot.htm') -]
 </body>
 </html>

B</foo/head.htm:>

 <h1>head from foo</h1>

B</foo/sub/head.htm:>

 <h1>another head from sub</h1>

B</foo/foot.htm:>

 <hr> Footer <hr>


B</foo/page1.htm:>

 PAGE 1

B</foo/sub/page2.htm:>

 PAGE 2

B</foo/sub/index.htm:>

 Index of /foo/sub



If you now request B<http://host/foo/page1.htm> you will get the following page

  
 <html>
 <head>
 <title>Example</title>
 </head>
 <body>
 <h1>head from foo</h1>
 PAGE 1
 <hr> Footer <hr>
 </body>
 </html>


If you now request B<http://host/foo/sub/page2.htm> you will get the following page

  
 <html>
 <head>
 <title>Example</title>
 </head>
 <body>
 <h1>another head from sub</h1>
 PAGE 2
 <hr> Footer <hr>
 </body>
 </html>


If you now request B<http://host/foo/sub/> you will get the following page

  
 <html>
 <head>
 <title>Example</title>
 </head>
 <body>
 <h1>another head from sub</h1>
 Index of /foo/sub
 <hr> Footer <hr>
 </body>
 </html>

 

=head1 Example for using method calls

(Everything not given here is the same as in the example above)


B</foo/base.htm:>

 [!

 sub new
    {
    my $self = shift ; 

    # here we attach some data to the request object
    $self -> {fontsize} = 3 ;
    }

 # Here we give a default title
 sub title { 'Title not given' } ;

 !]

 [-
  
 # get the request object of the current request
 $req = shift ;

 # here we call the method new
 $req -> new ;

 -]

 <html>
 <head>
 <title>[+ $req -> title +]</title>
 </head>
 <body>
 [- Execute ('head.htm') -]
 [- Execute ('*') -]
 [- Execute ('foot.htm') -]
 </body>
 </html>


B</foo/head.htm:>


 [# 
    here we use the fontsize
    Note that 
      $foo = $_[0] 
    is the same as writing 
      $foo = shift  
 #]

 <font size=[+ $_[0] -> {fontsize} +]>header</font>

B</foo/sub/page2.htm:>

 [!

 sub new
    {
    my $self = shift ; 

    # here we overwrite the new method form base.htm
    $self -> {fontsize} = 5 ;
    }

 # Here we overwrite the default title
 sub title { 'Title form page 2' } ;

 !]

 PAGE 2


  

=head1 Author

G. Richter (richter at embperl dot org)

=head1 See Also

perl(1), Embperl, mod_perl, Apache httpd
