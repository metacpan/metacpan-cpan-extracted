#line 1
# $Id: /local/ExtUtils-MakeMaker/lib/ExtUtils/MakeMaker.pm 54639 2008-02-29T00:06:55.056100Z schwern  $
package ExtUtils::MakeMaker;

use strict;

BEGIN {require 5.006;}

require Exporter;
use ExtUtils::MakeMaker::Config;
use Carp ();
use File::Path;

our $Verbose = 0;       # exported
our @Parent;            # needs to be localized
our @Get_from_Config;   # referenced by MM_Unix
my @MM_Sections;
my @Overridable;
my @Prepend_parent;
my %Recognized_Att_Keys;

our $VERSION = '6.44';
our ($Revision) = q$Revision: 54639 $ =~ /Revision:\s+(\S+)/;
our $Filename = __FILE__;   # referenced outside MakeMaker

our @ISA = qw(Exporter);
our @EXPORT    = qw(&WriteMakefile &writeMakefile $Verbose &prompt);
our @EXPORT_OK = qw($VERSION &neatvalue &mkbootstrap &mksymlists
                    &WriteEmptyMakefile);

# These will go away once the last of the Win32 & VMS specific code is 
# purged.
my $Is_VMS     = $^O eq 'VMS';
my $Is_Win32   = $^O eq 'MSWin32';

full_setup();

require ExtUtils::MM;  # Things like CPAN assume loading ExtUtils::MakeMaker
                       # will give them MM.

require ExtUtils::MY;  # XXX pre-5.8 versions of ExtUtils::Embed expect
                       # loading ExtUtils::MakeMaker will give them MY.
                       # This will go when Embed is it's own CPAN module.


sub WriteMakefile {
    Carp::croak "WriteMakefile: Need even number of args" if @_ % 2;

    require ExtUtils::MY;
    my %att = @_;

    _verify_att(\%att);

    my $mm = MM->new(\%att);
    $mm->flush;

    return $mm;
}


# Basic signatures of the attributes WriteMakefile takes.  Each is the
# reference type.  Empty value indicate it takes a non-reference
# scalar.
my %Att_Sigs;
my %Special_Sigs = (
 C                  => 'ARRAY',
 CONFIG             => 'ARRAY',
 CONFIGURE          => 'CODE',
 DIR                => 'ARRAY',
 DL_FUNCS           => 'HASH',
 DL_VARS            => 'ARRAY',
 EXCLUDE_EXT        => 'ARRAY',
 EXE_FILES          => 'ARRAY',
 FUNCLIST           => 'ARRAY',
 H                  => 'ARRAY',
 IMPORTS            => 'HASH',
 INCLUDE_EXT        => 'ARRAY',
 LIBS               => ['ARRAY',''],
 MAN1PODS           => 'HASH',
 MAN3PODS           => 'HASH',
 PL_FILES           => 'HASH',
 PM                 => 'HASH',
 PMLIBDIRS          => 'ARRAY',
 PMLIBPARENTDIRS    => 'ARRAY',
 PREREQ_PM          => 'HASH',
 SKIP               => 'ARRAY',
 TYPEMAPS           => 'ARRAY',
 XS                 => 'HASH',
 VERSION            => ['version',''],
 _KEEP_AFTER_FLUSH  => '',

 clean      => 'HASH',
 depend     => 'HASH',
 dist       => 'HASH',
 dynamic_lib=> 'HASH',
 linkext    => 'HASH',
 macro      => 'HASH',
 postamble  => 'HASH',
 realclean  => 'HASH',
 test       => 'HASH',
 tool_autosplit => 'HASH',
);

@Att_Sigs{keys %Recognized_Att_Keys} = ('') x keys %Recognized_Att_Keys;
@Att_Sigs{keys %Special_Sigs} = values %Special_Sigs;


sub _verify_att {
    my($att) = @_;

    while( my($key, $val) = each %$att ) {
        my $sig = $Att_Sigs{$key};
        unless( defined $sig ) {
            warn "WARNING: $key is not a known parameter.\n";
            next;
        }

        my @sigs   = ref $sig ? @$sig : $sig;
        my $given  = ref $val;
        unless( grep { $given eq $_ || ($_ && eval{$val->isa($_)}) } @sigs ) {
            my $takes = join " or ", map { _format_att($_) } @sigs;

            my $has = _format_att($given);
            warn "WARNING: $key takes a $takes not a $has.\n".
                 "         Please inform the author.\n";
        }
    }
}


sub _format_att {
    my $given = shift;
    
    return $given eq ''        ? "string/number"
         : uc $given eq $given ? "$given reference"
         :                       "$given object"
         ;
}


sub prompt ($;$) {  ## no critic
    my($mess, $def) = @_;
    Carp::confess("prompt function called without an argument") 
        unless defined $mess;

    my $isa_tty = -t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT)) ;

    my $dispdef = defined $def ? "[$def] " : " ";
    $def = defined $def ? $def : "";

    local $|=1;
    local $\;
    print "$mess $dispdef";

    my $ans;
    if ($ENV{PERL_MM_USE_DEFAULT} || (!$isa_tty && eof STDIN)) {
        print "$def\n";
    }
    else {
        $ans = <STDIN>;
        if( defined $ans ) {
            chomp $ans;
        }
        else { # user hit ctrl-D
            print "\n";
        }
    }

    return (!defined $ans || $ans eq '') ? $def : $ans;
}

sub eval_in_subdirs {
    my($self) = @_;
    use Cwd qw(cwd abs_path);
    my $pwd = cwd() || die "Can't figure out your cwd!";

    local @INC = map eval {abs_path($_) if -e} || $_, @INC;
    push @INC, '.';     # '.' has to always be at the end of @INC

    foreach my $dir (@{$self->{DIR}}){
        my($abs) = $self->catdir($pwd,$dir);
        eval { $self->eval_in_x($abs); };
        last if $@;
    }
    chdir $pwd;
    die $@ if $@;
}

sub eval_in_x {
    my($self,$dir) = @_;
    chdir $dir or Carp::carp("Couldn't change to directory $dir: $!");

    {
        package main;
        do './Makefile.PL';
    };
    if ($@) {
#         if ($@ =~ /prerequisites/) {
#             die "MakeMaker WARNING: $@";
#         } else {
#             warn "WARNING from evaluation of $dir/Makefile.PL: $@";
#         }
        die "ERROR from evaluation of $dir/Makefile.PL: $@";
    }
}


# package name for the classes into which the first object will be blessed
my $PACKNAME = 'PACK000';

sub full_setup {
    $Verbose ||= 0;

    my @attrib_help = qw/

    AUTHOR ABSTRACT ABSTRACT_FROM BINARY_LOCATION
    C CAPI CCFLAGS CONFIG CONFIGURE DEFINE DIR DISTNAME DL_FUNCS DL_VARS
    EXCLUDE_EXT EXE_FILES EXTRA_META FIRST_MAKEFILE
    FULLPERL FULLPERLRUN FULLPERLRUNINST
    FUNCLIST H IMPORTS

    INST_ARCHLIB INST_SCRIPT INST_BIN INST_LIB INST_MAN1DIR INST_MAN3DIR
    INSTALLDIRS
    DESTDIR PREFIX INSTALL_BASE
    PERLPREFIX      SITEPREFIX      VENDORPREFIX
    INSTALLPRIVLIB  INSTALLSITELIB  INSTALLVENDORLIB
    INSTALLARCHLIB  INSTALLSITEARCH INSTALLVENDORARCH
    INSTALLBIN      INSTALLSITEBIN  INSTALLVENDORBIN
    INSTALLMAN1DIR          INSTALLMAN3DIR
    INSTALLSITEMAN1DIR      INSTALLSITEMAN3DIR
    INSTALLVENDORMAN1DIR    INSTALLVENDORMAN3DIR
    INSTALLSCRIPT   INSTALLSITESCRIPT  INSTALLVENDORSCRIPT
    PERL_LIB        PERL_ARCHLIB 
    SITELIBEXP      SITEARCHEXP 

    INC INCLUDE_EXT LDFROM LIB LIBPERL_A LIBS LICENSE
    LINKTYPE MAKE MAKEAPERL MAKEFILE MAKEFILE_OLD MAN1PODS MAN3PODS MAP_TARGET 
    MYEXTLIB NAME NEEDS_LINKING NOECHO NO_META NORECURS NO_VC OBJECT OPTIMIZE 
    PERL_MALLOC_OK PERL PERLMAINCC PERLRUN PERLRUNINST PERL_CORE
    PERL_SRC PERM_RW PERM_RWX
    PL_FILES PM PM_FILTER PMLIBDIRS PMLIBPARENTDIRS POLLUTE PPM_INSTALL_EXEC
    PPM_INSTALL_SCRIPT PREREQ_FATAL PREREQ_PM PREREQ_PRINT PRINT_PREREQ
    SIGN SKIP TYPEMAPS VERSION VERSION_FROM XS XSOPT XSPROTOARG
    XS_VERSION clean depend dist dynamic_lib linkext macro realclean
    tool_autosplit

    MACPERL_SRC MACPERL_LIB MACLIBS_68K MACLIBS_PPC MACLIBS_SC MACLIBS_MRC
    MACLIBS_ALL_68K MACLIBS_ALL_PPC MACLIBS_SHARED
        /;

    # IMPORTS is used under OS/2 and Win32

    # @Overridable is close to @MM_Sections but not identical.  The
    # order is important. Many subroutines declare macros. These
    # depend on each other. Let's try to collect the macros up front,
    # then pasthru, then the rules.

    # MM_Sections are the sections we have to call explicitly
    # in Overridable we have subroutines that are used indirectly


    @MM_Sections = 
        qw(

 post_initialize const_config constants platform_constants 
 tool_autosplit tool_xsubpp tools_other 

 makemakerdflt

 dist macro depend cflags const_loadlibs const_cccmd
 post_constants

 pasthru

 special_targets
 c_o xs_c xs_o
 top_targets blibdirs linkext dlsyms dynamic dynamic_bs
 dynamic_lib static static_lib manifypods processPL
 installbin subdirs
 clean_subdirs clean realclean_subdirs realclean 
 metafile signature
 dist_basics dist_core distdir dist_test dist_ci distmeta distsignature
 install force perldepend makefile staticmake test ppd

          ); # loses section ordering

    @Overridable = @MM_Sections;
    push @Overridable, qw[

 libscan makeaperl needs_linking perm_rw perm_rwx
 subdir_x test_via_harness test_via_script 

 init_VERSION init_dist init_INST init_INSTALL init_DEST init_dirscan
 init_PM init_MANPODS init_xs init_PERL init_DIRFILESEP init_linker
                         ];

    push @MM_Sections, qw[

 pm_to_blib selfdocument

                         ];

    # Postamble needs to be the last that was always the case
    push @MM_Sections, "postamble";
    push @Overridable, "postamble";

    # All sections are valid keys.
    @Recognized_Att_Keys{@MM_Sections} = (1) x @MM_Sections;

    # we will use all these variables in the Makefile
    @Get_from_Config = 
        qw(
           ar cc cccdlflags ccdlflags dlext dlsrc exe_ext full_ar ld 
           lddlflags ldflags libc lib_ext obj_ext osname osvers ranlib 
           sitelibexp sitearchexp so
          );

    # 5.5.3 doesn't have any concept of vendor libs
    push @Get_from_Config, qw( vendorarchexp vendorlibexp ) if $] >= 5.006;

    foreach my $item (@attrib_help){
        $Recognized_Att_Keys{$item} = 1;
    }
    foreach my $item (@Get_from_Config) {
        $Recognized_Att_Keys{uc $item} = $Config{$item};
        print "Attribute '\U$item\E' => '$Config{$item}'\n"
            if ($Verbose >= 2);
    }

    #
    # When we eval a Makefile.PL in a subdirectory, that one will ask
    # us (the parent) for the values and will prepend "..", so that
    # all files to be installed end up below OUR ./blib
    #
    @Prepend_parent = qw(
           INST_BIN INST_LIB INST_ARCHLIB INST_SCRIPT
           MAP_TARGET INST_MAN1DIR INST_MAN3DIR PERL_SRC
           PERL FULLPERL
    );
}

sub writeMakefile {
    die <<END;

The extension you are trying to build apparently is rather old and
most probably outdated. We detect that from the fact, that a
subroutine "writeMakefile" is called, and this subroutine is not
supported anymore since about October 1994.

Please contact the author or look into CPAN (details about CPAN can be
found in the FAQ and at http:/www.perl.com) for a more recent version
of the extension. If you're really desperate, you can try to change
the subroutine name from writeMakefile to WriteMakefile and rerun
'perl Makefile.PL', but you're most probably left alone, when you do
so.

The MakeMaker team

END
}

sub new {
    my($class,$self) = @_;
    my($key);

    # Store the original args passed to WriteMakefile()
    foreach my $k (keys %$self) {
        $self->{ARGS}{$k} = $self->{$k};
    }

    if ("@ARGV" =~ /\bPREREQ_PRINT\b/) {
        require Data::Dumper;
        print Data::Dumper->Dump([$self->{PREREQ_PM}], [qw(PREREQ_PM)]);
        exit 0;
    }

    # PRINT_PREREQ is RedHatism.
    if ("@ARGV" =~ /\bPRINT_PREREQ\b/) {
        print join(" ", map { "perl($_)>=$self->{PREREQ_PM}->{$_} " } 
                        sort keys %{$self->{PREREQ_PM}}), "\n";
        exit 0;
   }

    print STDOUT "MakeMaker (v$VERSION)\n" if $Verbose;
    if (-f "MANIFEST" && ! -f "Makefile"){
        check_manifest();
    }

    $self = {} unless (defined $self);

    check_hints($self);

    my %configure_att;         # record &{$self->{CONFIGURE}} attributes
    my(%initial_att) = %$self; # record initial attributes

    my(%unsatisfied) = ();
    foreach my $prereq (sort keys %{$self->{PREREQ_PM}}) {
        # 5.8.0 has a bug with require Foo::Bar alone in an eval, so an
        # extra statement is a workaround.
        my $file = "$prereq.pm";
        $file =~ s{::}{/}g;
        eval { require $file };

        my $pr_version = $prereq->VERSION || 0;

        # convert X.Y_Z alpha version #s to X.YZ for easier comparisons
        $pr_version =~ s/(\d+)\.(\d+)_(\d+)/$1.$2$3/;

        if ($@) {
            warn sprintf "Warning: prerequisite %s %s not found.\n", 
              $prereq, $self->{PREREQ_PM}{$prereq} 
                   unless $self->{PREREQ_FATAL};
            $unsatisfied{$prereq} = 'not installed';
        } elsif ($pr_version < $self->{PREREQ_PM}->{$prereq} ){
            warn sprintf "Warning: prerequisite %s %s not found. We have %s.\n",
              $prereq, $self->{PREREQ_PM}{$prereq}, 
                ($pr_version || 'unknown version') 
                  unless $self->{PREREQ_FATAL};
            $unsatisfied{$prereq} = $self->{PREREQ_PM}->{$prereq} ? 
              $self->{PREREQ_PM}->{$prereq} : 'unknown version' ;
        }
    }
    
     if (%unsatisfied && $self->{PREREQ_FATAL}){
        my $failedprereqs = join "\n", map {"    $_ $unsatisfied{$_}"} 
                            sort { $a cmp $b } keys %unsatisfied;
        die <<"END";
MakeMaker FATAL: prerequisites not found.
$failedprereqs

Please install these modules first and rerun 'perl Makefile.PL'.
END
    }
    
    if (defined $self->{CONFIGURE}) {
        if (ref $self->{CONFIGURE} eq 'CODE') {
            %configure_att = %{&{$self->{CONFIGURE}}};
            $self = { %$self, %configure_att };
        } else {
            Carp::croak "Attribute 'CONFIGURE' to WriteMakefile() not a code reference\n";
        }
    }

    # This is for old Makefiles written pre 5.00, will go away
    if ( Carp::longmess("") =~ /runsubdirpl/s ){
        Carp::carp("WARNING: Please rerun 'perl Makefile.PL' to regenerate your Makefiles\n");
    }

    my $newclass = ++$PACKNAME;
    local @Parent = @Parent;    # Protect against non-local exits
    {
        print "Blessing Object into class [$newclass]\n" if $Verbose>=2;
        mv_all_methods("MY",$newclass);
        bless $self, $newclass;
        push @Parent, $self;
        require ExtUtils::MY;

        no strict 'refs';   ## no critic;
        @{"$newclass\:\:ISA"} = 'MM';
    }

    if (defined $Parent[-2]){
        $self->{PARENT} = $Parent[-2];
        for my $key (@Prepend_parent) {
            next unless defined $self->{PARENT}{$key};

            # Don't stomp on WriteMakefile() args.
            next if defined $self->{ARGS}{$key} and
                    $self->{ARGS}{$key} eq $self->{$key};

            $self->{$key} = $self->{PARENT}{$key};

            unless ($Is_VMS && $key =~ /PERL$/) {
                $self->{$key} = $self->catdir("..",$self->{$key})
                  unless $self->file_name_is_absolute($self->{$key});
            } else {
                # PERL or FULLPERL will be a command verb or even a
                # command with an argument instead of a full file
                # specification under VMS.  So, don't turn the command
                # into a filespec, but do add a level to the path of
                # the argument if not already absolute.
                my @cmd = split /\s+/, $self->{$key};
                $cmd[1] = $self->catfile('[-]',$cmd[1])
                  unless (@cmd < 2) || $self->file_name_is_absolute($cmd[1]);
                $self->{$key} = join(' ', @cmd);
            }
        }
        if ($self->{PARENT}) {
            $self->{PARENT}->{CHILDREN}->{$newclass} = $self;
            foreach my $opt (qw(POLLUTE PERL_CORE LINKTYPE)) {
                if (exists $self->{PARENT}->{$opt}
                    and not exists $self->{$opt})
                    {
                        # inherit, but only if already unspecified
                        $self->{$opt} = $self->{PARENT}->{$opt};
                    }
            }
        }
        my @fm = grep /^FIRST_MAKEFILE=/, @ARGV;
        parse_args($self,@fm) if @fm;
    } else {
        parse_args($self,split(' ', $ENV{PERL_MM_OPT} || ''),@ARGV);
    }


    $self->{NAME} ||= $self->guess_name;

    ($self->{NAME_SYM} = $self->{NAME}) =~ s/\W+/_/g;

    $self->init_MAKE;
    $self->init_main;
    $self->init_VERSION;
    $self->init_dist;
    $self->init_INST;
    $self->init_INSTALL;
    $self->init_DEST;
    $self->init_dirscan;
    $self->init_PM;
    $self->init_MANPODS;
    $self->init_xs;
    $self->init_PERL;
    $self->init_DIRFILESEP;
    $self->init_linker;
    $self->init_ABSTRACT;

    if (! $self->{PERL_SRC} ) {
        require VMS::Filespec if $Is_VMS;
        my($pthinks) = $self->canonpath($INC{'Config.pm'});
        my($cthinks) = $self->catfile($Config{'archlibexp'},'Config.pm');
        $pthinks = VMS::Filespec::vmsify($pthinks) if $Is_VMS;
        if ($pthinks ne $cthinks &&
            !($Is_Win32 and lc($pthinks) eq lc($cthinks))) {
            print "Have $pthinks expected $cthinks\n";
            if ($Is_Win32) {
                $pthinks =~ s![/\\]Config\.pm$!!i; $pthinks =~ s!.*[/\\]!!;
            }
            else {
                $pthinks =~ s!/Config\.pm$!!; $pthinks =~ s!.*/!!;
            }
            print STDOUT <<END unless $self->{UNINSTALLED_PERL};
Your perl and your Config.pm seem to have different ideas about the 
architecture they are running on.
Perl thinks: [$pthinks]
Config says: [$Config{archname}]
This may or may not cause problems. Please check your installation of perl 
if you have problems building this extension.
END
        }
    }

    $self->init_others();
    $self->init_platform();
    $self->init_PERM();
    my($argv) = neatvalue(\@ARGV);
    $argv =~ s/^\[/(/;
    $argv =~ s/\]$/)/;

    push @{$self->{RESULT}}, <<END;
# This Makefile is for the $self->{NAME} extension to perl.
#
# It was generated automatically by MakeMaker version
# $VERSION (Revision: $Revision) from the contents of
# Makefile.PL. Don't edit this file, edit Makefile.PL instead.
#
#       ANY CHANGES MADE HERE WILL BE LOST!
#
#   MakeMaker ARGV: $argv
#
#   MakeMaker Parameters:
END

    foreach my $key (sort keys %initial_att){
        next if $key eq 'ARGS';

        my($v) = neatvalue($initial_att{$key});
        $v =~ s/(CODE|HASH|ARRAY|SCALAR)\([\dxa-f]+\)/$1\(...\)/;
        $v =~ tr/\n/ /s;
        push @{$self->{RESULT}}, "#     $key => $v";
    }
    undef %initial_att;        # free memory

    if (defined $self->{CONFIGURE}) {
       push @{$self->{RESULT}}, <<END;

#   MakeMaker 'CONFIGURE' Parameters:
END
        if (scalar(keys %configure_att) > 0) {
            foreach my $key (sort keys %configure_att){
               next if $key eq 'ARGS';
               my($v) = neatvalue($configure_att{$key});
               $v =~ s/(CODE|HASH|ARRAY|SCALAR)\([\dxa-f]+\)/$1\(...\)/;
               $v =~ tr/\n/ /s;
               push @{$self->{RESULT}}, "#     $key => $v";
            }
        }
        else
        {
           push @{$self->{RESULT}}, "# no values returned";
        }
        undef %configure_att;  # free memory
    }

    # turn the SKIP array into a SKIPHASH hash
    for my $skip (@{$self->{SKIP} || []}) {
        $self->{SKIPHASH}{$skip} = 1;
    }
    delete $self->{SKIP}; # free memory

    if ($self->{PARENT}) {
        for (qw/install dist dist_basics dist_core distdir dist_test dist_ci/) {
            $self->{SKIPHASH}{$_} = 1;
        }
    }

    # We run all the subdirectories now. They don't have much to query
    # from the parent, but the parent has to query them: if they need linking!
    unless ($self->{NORECURS}) {
        $self->eval_in_subdirs if @{$self->{DIR}};
    }

    foreach my $section ( @MM_Sections ){
        # Support for new foo_target() methods.
        my $method = $section;
        $method .= '_target' unless $self->can($method);

        print "Processing Makefile '$section' section\n" if ($Verbose >= 2);
        my($skipit) = $self->skipcheck($section);
        if ($skipit){
            push @{$self->{RESULT}}, "\n# --- MakeMaker $section section $skipit.";
        } else {
            my(%a) = %{$self->{$section} || {}};
            push @{$self->{RESULT}}, "\n# --- MakeMaker $section section:";
            push @{$self->{RESULT}}, "# " . join ", ", %a if $Verbose && %a;
            push @{$self->{RESULT}}, $self->maketext_filter(
                $self->$method( %a )
            );
        }
    }

    push @{$self->{RESULT}}, "\n# End.";

    $self;
}

sub WriteEmptyMakefile {
    Carp::croak "WriteEmptyMakefile: Need an even number of args" if @_ % 2;

    my %att = @_;
    my $self = MM->new(\%att);
    
    my $new = $self->{MAKEFILE};
    my $old = $self->{MAKEFILE_OLD};
    if (-f $old) {
        _unlink($old) or warn "unlink $old: $!";
    }
    if ( -f $new ) {
        _rename($new, $old) or warn "rename $new => $old: $!"
    }
    open my $mfh, '>', $new or die "open $new for write: $!";
    print $mfh <<'EOP';
all :

clean :

install :

makemakerdflt :

test :

EOP
    close $mfh or die "close $new for write: $!";
}

sub check_manifest {
    print STDOUT "Checking if your kit is complete...\n";
    require ExtUtils::Manifest;
    # avoid warning
    $ExtUtils::Manifest::Quiet = $ExtUtils::Manifest::Quiet = 1;
    my(@missed) = ExtUtils::Manifest::manicheck();
    if (@missed) {
        print STDOUT "Warning: the following files are missing in your kit:\n";
        print "\t", join "\n\t", @missed;
        print STDOUT "\n";
        print STDOUT "Please inform the author.\n";
    } else {
        print STDOUT "Looks good\n";
    }
}

sub parse_args{
    my($self, @args) = @_;
    foreach (@args) {
        unless (m/(.*?)=(.*)/) {
            ++$Verbose if m/^verb/;
            next;
        }
        my($name, $value) = ($1, $2);
        if ($value =~ m/^~(\w+)?/) { # tilde with optional username
            $value =~ s [^~(\w*)]
                [$1 ?
                 ((getpwnam($1))[7] || "~$1") :
                 (getpwuid($>))[7]
                 ]ex;
        }

        # Remember the original args passed it.  It will be useful later.
        $self->{ARGS}{uc $name} = $self->{uc $name} = $value;
    }

    # catch old-style 'potential_libs' and inform user how to 'upgrade'
    if (defined $self->{potential_libs}){
        my($msg)="'potential_libs' => '$self->{potential_libs}' should be";
        if ($self->{potential_libs}){
            print STDOUT "$msg changed to:\n\t'LIBS' => ['$self->{potential_libs}']\n";
        } else {
            print STDOUT "$msg deleted.\n";
        }
        $self->{LIBS} = [$self->{potential_libs}];
        delete $self->{potential_libs};
    }
    # catch old-style 'ARMAYBE' and inform user how to 'upgrade'
    if (defined $self->{ARMAYBE}){
        my($armaybe) = $self->{ARMAYBE};
        print STDOUT "ARMAYBE => '$armaybe' should be changed to:\n",
                        "\t'dynamic_lib' => {ARMAYBE => '$armaybe'}\n";
        my(%dl) = %{$self->{dynamic_lib} || {}};
        $self->{dynamic_lib} = { %dl, ARMAYBE => $armaybe};
        delete $self->{ARMAYBE};
    }
    if (defined $self->{LDTARGET}){
        print STDOUT "LDTARGET should be changed to LDFROM\n";
        $self->{LDFROM} = $self->{LDTARGET};
        delete $self->{LDTARGET};
    }
    # Turn a DIR argument on the command line into an array
    if (defined $self->{DIR} && ref \$self->{DIR} eq 'SCALAR') {
        # So they can choose from the command line, which extensions they want
        # the grep enables them to have some colons too much in case they
        # have to build a list with the shell
        $self->{DIR} = [grep $_, split ":", $self->{DIR}];
    }
    # Turn a INCLUDE_EXT argument on the command line into an array
    if (defined $self->{INCLUDE_EXT} && ref \$self->{INCLUDE_EXT} eq 'SCALAR') {
        $self->{INCLUDE_EXT} = [grep $_, split '\s+', $self->{INCLUDE_EXT}];
    }
    # Turn a EXCLUDE_EXT argument on the command line into an array
    if (defined $self->{EXCLUDE_EXT} && ref \$self->{EXCLUDE_EXT} eq 'SCALAR') {
        $self->{EXCLUDE_EXT} = [grep $_, split '\s+', $self->{EXCLUDE_EXT}];
    }

    foreach my $mmkey (sort keys %$self){
        next if $mmkey eq 'ARGS';
        print STDOUT "  $mmkey => ", neatvalue($self->{$mmkey}), "\n" if $Verbose;
        print STDOUT "'$mmkey' is not a known MakeMaker parameter name.\n"
            unless exists $Recognized_Att_Keys{$mmkey};
    }
    $| = 1 if $Verbose;
}

sub check_hints {
    my($self) = @_;
    # We allow extension-specific hints files.

    require File::Spec;
    my $curdir = File::Spec->curdir;

    my $hint_dir = File::Spec->catdir($curdir, "hints");
    return unless -d $hint_dir;

    # First we look for the best hintsfile we have
    my($hint)="${^O}_$Config{osvers}";
    $hint =~ s/\./_/g;
    $hint =~ s/_$//;
    return unless $hint;

    # Also try without trailing minor version numbers.
    while (1) {
        last if -f File::Spec->catfile($hint_dir, "$hint.pl");  # found
    } continue {
        last unless $hint =~ s/_[^_]*$//; # nothing to cut off
    }
    my $hint_file = File::Spec->catfile($hint_dir, "$hint.pl");

    return unless -f $hint_file;    # really there

    _run_hintfile($self, $hint_file);
}

sub _run_hintfile {
    our $self;
    local($self) = shift;       # make $self available to the hint file.
    my($hint_file) = shift;

    local($@, $!);
    print STDERR "Processing hints file $hint_file\n";

    # Just in case the ./ isn't on the hint file, which File::Spec can
    # often strip off, we bung the curdir into @INC
    local @INC = (File::Spec->curdir, @INC);
    my $ret = do $hint_file;
    if( !defined $ret ) {
        my $error = $@ || $!;
        print STDERR $error;
    }
}

sub mv_all_methods {
    my($from,$to) = @_;

    # Here you see the *current* list of methods that are overridable
    # from Makefile.PL via MY:: subroutines. As of VERSION 5.07 I'm
    # still trying to reduce the list to some reasonable minimum --
    # because I want to make it easier for the user. A.K.

    local $SIG{__WARN__} = sub { 
        # can't use 'no warnings redefined', 5.6 only
        warn @_ unless $_[0] =~ /^Subroutine .* redefined/ 
    };
    foreach my $method (@Overridable) {

        # We cannot say "next" here. Nick might call MY->makeaperl
        # which isn't defined right now

        # Above statement was written at 4.23 time when Tk-b8 was
        # around. As Tk-b9 only builds with 5.002something and MM 5 is
        # standard, we try to enable the next line again. It was
        # commented out until MM 5.23

        next unless defined &{"${from}::$method"};

        {
            no strict 'refs';   ## no critic
            *{"${to}::$method"} = \&{"${from}::$method"};

            # If we delete a method, then it will be undefined and cannot
            # be called.  But as long as we have Makefile.PLs that rely on
            # %MY:: being intact, we have to fill the hole with an
            # inheriting method:

            {
                package MY;
                my $super = "SUPER::".$method;
                *{$method} = sub {
                    shift->$super(@_);
                };
            }
        }
    }

    # We have to clean out %INC also, because the current directory is
    # changed frequently and Graham Barr prefers to get his version
    # out of a History.pl file which is "required" so woudn't get
    # loaded again in another extension requiring a History.pl

    # With perl5.002_01 the deletion of entries in %INC caused Tk-b11
    # to core dump in the middle of a require statement. The required
    # file was Tk/MMutil.pm.  The consequence is, we have to be
    # extremely careful when we try to give perl a reason to reload a
    # library with same name.  The workaround prefers to drop nothing
    # from %INC and teach the writers not to use such libraries.

#    my $inc;
#    foreach $inc (keys %INC) {
#       #warn "***$inc*** deleted";
#       delete $INC{$inc};
#    }
}

sub skipcheck {
    my($self) = shift;
    my($section) = @_;
    if ($section eq 'dynamic') {
        print STDOUT "Warning (non-fatal): Target 'dynamic' depends on targets ",
        "in skipped section 'dynamic_bs'\n"
            if $self->{SKIPHASH}{dynamic_bs} && $Verbose;
        print STDOUT "Warning (non-fatal): Target 'dynamic' depends on targets ",
        "in skipped section 'dynamic_lib'\n"
            if $self->{SKIPHASH}{dynamic_lib} && $Verbose;
    }
    if ($section eq 'dynamic_lib') {
        print STDOUT "Warning (non-fatal): Target '\$(INST_DYNAMIC)' depends on ",
        "targets in skipped section 'dynamic_bs'\n"
            if $self->{SKIPHASH}{dynamic_bs} && $Verbose;
    }
    if ($section eq 'static') {
        print STDOUT "Warning (non-fatal): Target 'static' depends on targets ",
        "in skipped section 'static_lib'\n"
            if $self->{SKIPHASH}{static_lib} && $Verbose;
    }
    return 'skipped' if $self->{SKIPHASH}{$section};
    return '';
}

sub flush {
    my $self = shift;

    my $finalname = $self->{MAKEFILE};
    print STDOUT "Writing $finalname for $self->{NAME}\n";

    unlink($finalname, "MakeMaker.tmp", $Is_VMS ? 'Descrip.MMS' : ());
    open(my $fh,">", "MakeMaker.tmp")
        or die "Unable to open MakeMaker.tmp: $!";

    for my $chunk (@{$self->{RESULT}}) {
        print $fh "$chunk\n";
    }

    close $fh;
    _rename("MakeMaker.tmp", $finalname) or
      warn "rename MakeMaker.tmp => $finalname: $!";
    chmod 0644, $finalname unless $Is_VMS;

    my %keep = map { ($_ => 1) } qw(NEEDS_LINKING HAS_LINK_CODE);

    if ($self->{PARENT} && !$self->{_KEEP_AFTER_FLUSH}) {
        foreach (keys %$self) { # safe memory
            delete $self->{$_} unless $keep{$_};
        }
    }

    system("$Config::Config{eunicefix} $finalname") unless $Config::Config{eunicefix} eq ":";
}


# This is a rename for OS's where the target must be unlinked first.
sub _rename {
    my($src, $dest) = @_;
    chmod 0666, $dest;
    unlink $dest;
    return rename $src, $dest;
}

# This is an unlink for OS's where the target must be writable first.
sub _unlink {
    my @files = @_;
    chmod 0666, @files;
    return unlink @files;
}


# The following mkbootstrap() is only for installations that are calling
# the pre-4.1 mkbootstrap() from their old Makefiles. This MakeMaker
# writes Makefiles, that use ExtUtils::Mkbootstrap directly.
sub mkbootstrap {
    die <<END;
!!! Your Makefile has been built such a long time ago, !!!
!!! that is unlikely to work with current MakeMaker.   !!!
!!! Please rebuild your Makefile                       !!!
END
}

# Ditto for mksymlists() as of MakeMaker 5.17
sub mksymlists {
    die <<END;
!!! Your Makefile has been built such a long time ago, !!!
!!! that is unlikely to work with current MakeMaker.   !!!
!!! Please rebuild your Makefile                       !!!
END
}

sub neatvalue {
    my($v) = @_;
    return "undef" unless defined $v;
    my($t) = ref $v;
    return "q[$v]" unless $t;
    if ($t eq 'ARRAY') {
        my(@m, @neat);
        push @m, "[";
        foreach my $elem (@$v) {
            push @neat, "q[$elem]";
        }
        push @m, join ", ", @neat;
        push @m, "]";
        return join "", @m;
    }
    return "$v" unless $t eq 'HASH';
    my(@m, $key, $val);
    while (($key,$val) = each %$v){
        last unless defined $key; # cautious programming in case (undef,undef) is true
        push(@m,"$key=>".neatvalue($val)) ;
    }
    return "{ ".join(', ',@m)." }";
}

sub selfdocument {
    my($self) = @_;
    my(@m);
    if ($Verbose){
        push @m, "\n# Full list of MakeMaker attribute values:";
        foreach my $key (sort keys %$self){
            next if $key eq 'RESULT' || $key =~ /^[A-Z][a-z]/;
            my($v) = neatvalue($self->{$key});
            $v =~ s/(CODE|HASH|ARRAY|SCALAR)\([\dxa-f]+\)/$1\(...\)/;
            $v =~ tr/\n/ /s;
            push @m, "# $key => $v";
        }
    }
    join "\n", @m;
}

1;

__END__

#line 2637
