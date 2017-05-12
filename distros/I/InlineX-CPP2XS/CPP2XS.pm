package InlineX::CPP2XS;
use warnings;
use strict;
use Config;

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(cpp2xs);

our $VERSION = '0.25';
#$VERSION = eval $VERSION;

my $config_options;

our @allowable_config_keys = ('AUTOWRAP', 'AUTO_INCLUDE', 'CODE', 'DIST', 'TYPEMAPS', 'LIBS', 'INC',
        'WRITE_MAKEFILE_PL', 'BUILD_NOISY', 'BOOT', 'BOOT_F', 'EXPORT_ALL', 'EXPORT_OK_ALL',
        'EXPORT_TAGS_ALL', 'MAKE', 'PREFIX', 'PREREQ_PM', 'CCFLAGS', 'CCFLAGSEX', 'LD', 'LDDLFLAGS',
        'MYEXTLIB', 'OPTIMIZE', 'PRE_HEAD', 'CC', 'SRC_LOCATION', 'T', '_TESTING', 'USE', 'USING',
        'WRITE_PM', 'VERSION', 'MANIF');

##=========================##

sub cpp2xs {
    ## This is basically just a copy'n'paste of the InlineX::C2XS::c2xs() function,
    ## with all occurrences of "C" changed to "CPP" ... clever, eh ??
    eval {require "Inline/CPP.pm"};
    if($@ || $Inline::CPP::VERSION < 0.39) {die "Need a functioning Inline::CPP (version 0.39 or later). $@"}
    my $module = shift;
    my $pkg = shift;

    # Set the default for $build_dir.
    # (This will be overwritten by the build_dir argument in @_, if supplied.)
    my $build_dir = '.';


    if(@_) {
      if(ref($_[0]) eq "HASH") {
        $config_options = shift;
        if(@_) {die "Incorrect usage - there should be no arguments to cpp2xs() after the hash reference"}
        # Check for invalid config options - and die if one is found
        for(keys(%$config_options)) { die "$_ is an invalid config option" if !_check_config_keys($_)}
      }
      else {$build_dir = shift}
    }

    if(@_) {
      if(ref($_[0]) ne "HASH") {die "Fourth arg to cpp2xs() needs to be a hash containing config options ... but it's not !!\n"}
      $config_options = shift;
      # Check for invalid config options - and die if one is found
      for(keys(%$config_options)) { die "$_ is an invalid config option" if !_check_config_keys($_)}
    }

    unless(-d $build_dir) {
       die "$build_dir is not a valid directory";
    }
    my $modfname = (split /::/, $module)[-1];
    my $need_inline_h = $config_options->{AUTOWRAP} ? 1 : 0;
    my $code = '';
    my $o;

    if(exists($config_options->{CODE}) && exists($config_options->{SRC_LOCATION})) {
      die "You can provide either CODE *or* SRC_LOCATION arguments ... but not *both*";
    }

    if(exists($config_options->{BOOT}) && exists($config_options->{BOOT_F})) {
      die "You can provide either BOOT *or* BOOT_F arguments ... but not *both*";
    }

    if(exists($config_options->{CODE})) {
      $code = $config_options->{CODE};
      if($code =~ /inline_stack_vars/i) {$need_inline_h = 1 }
    }
    elsif(exists($config_options->{SRC_LOCATION})) {
      open(RD, "<", $config_options->{SRC_LOCATION}) or die "Can't open ", $config_options->{SRC_LOCATION}, " for reading: $!";
      while(<RD>) {
           $code .= $_;
           if($_ =~ /inline_stack_vars/i) {$need_inline_h = 1}
      }
      close(RD) or die "Can't close ", $config_options->{SRC_LOCATION}, " after reading: $!";
    }
    else {
      open(RD, "<", "src/$modfname.cpp") or die "Can't open src/${modfname}.cpp for reading: $!";
      while(<RD>) {
           $code .= $_;
           if($_ =~ /inline_stack_vars/i) {$need_inline_h = 1}
      }
      close(RD) or die "Can't close src/$modfname.cpp after reading: $!";
    }

    ## Initialise $o.
    ## Many of these keys may not be needed for the purpose of this
    ## specific exercise - but they shouldn't do any harm, so I'll
    ## leave them in, just in case they're ever needed.
    $o->{CONFIG}{BUILD_TIMERS} = 0;
    $o->{CONFIG}{PRINT_INFO} = 0;
    $o->{CONFIG}{USING} = [];
    $o->{CONFIG}{WARNINGS} = 1;
    $o->{CONFIG}{PRINT_VERSION} = 0;
    $o->{CONFIG}{CLEAN_BUILD_AREA} = 0;
    $o->{CONFIG}{GLOBAL_LOAD} = 0;
    $o->{CONFIG}{DIRECTORY} = '';
    $o->{CONFIG}{SAFEMODE} = -1;
    $o->{CONFIG}{CLEAN_AFTER_BUILD} = 1;
    $o->{CONFIG}{FORCE_BUILD} = 0;
    $o->{CONFIG}{NAME} = '';
    $o->{CONFIG}{_INSTALL_} = 0;
    $o->{CONFIG}{WITH} = [];
    $o->{CONFIG}{AUTONAME} = 1;
    $o->{CONFIG}{REPORTBUG} = 0;
    $o->{CONFIG}{UNTAINT} = 0;
    $o->{CONFIG}{VERSION} = '';
    $o->{CONFIG}{BUILD_NOISY} = 1;
    $o->{INLINE}{ILSM_suffix} = $Config::Config{dlext};
    $o->{INLINE}{ILSM_module} = 'Inline::CPP';
    $o->{INLINE}{version} = $Inline::VERSION;
    $o->{INLINE}{ILSM_type} = 'compiled';
    $o->{INLINE}{DIRECTORY} = 'irrelevant_0';
    $o->{INLINE}{object_ready} = 0;
    $o->{INLINE}{md5} = 'irrelevant_1';
    $o->{API}{modfname} = $modfname;
    $o->{API}{script} = 'irrelevant_2';
    $o->{API}{location} = 'irrelevant_3';
    $o->{API}{language} = 'CPP';
    $o->{API}{modpname} = 'irrelevant_4';
    $o->{API}{directory} = 'irrelevant_5';
    $o->{API}{install_lib} = 'irrelevant_6';
    $o->{API}{build_dir} = $build_dir;
    $o->{API}{language_id} = 'CPP';
    $o->{API}{pkg} = $pkg;
    $o->{API}{suffix} = $Config::Config{dlext};
    $o->{API}{cleanup} = 1;
    $o->{API}{module} = $module;
    $o->{API}{code} = $code;

    if(exists($config_options->{BUILD_NOISY})) {$o->{CONFIG}{BUILD_NOISY} = $config_options->{BUILD_NOISY}}

    if($config_options->{DIST}) {
      $config_options->{WRITE_MAKEFILE_PL} = 'P';
      $config_options->{WRITE_PM} = 1;
      $config_options->{MANIF} = 1;
      $config_options->{T} = 1;
    }

    if($config_options->{AUTOWRAP}) {$o->{ILSM}{AUTOWRAP} = 1}

    if($config_options->{BOOT}) {$o->{ILSM}{XS}{BOOT} = $config_options->{BOOT}}

    if($config_options->{BOOT_F}) {
      my $code;
      open(RD, "<", $config_options->{BOOT_F}) or die "Can't open ", $config_options->{BOOT_F}, " for reading: $!";
      while(<RD>) {
           $code .= $_;
           if($_ =~ /inline_stack_vars/i) {$need_inline_h = 1}
      }
      close(RD) or die "Can't close ", $config_options->{BOOT_F}, " after reading: $!";
      $o->{ILSM}{XS}{BOOT} = $code;
    }

    # This is what Inline::C does with the MAKE parameter ... so we'll do the same.
    # Not sure that this achieves anything in the context of InlineX::CPP2XS.
    if($config_options->{MAKE}) {$o->{ILSM}{MAKE} = $config_options->{MAKE}}

    if(exists($config_options->{TYPEMAPS})) {
      if(ref($config_options->{TYPEMAPS}) eq 'ARRAY') {
        for(@{$config_options->{TYPEMAPS}}) {
           die "Couldn't locate the typemap $_" unless -f $_;
        }
        $o->{ILSM}{MAKEFILE}{TYPEMAPS} = $config_options->{TYPEMAPS};
      }
      else {
        my @vals = split /\s+/, $config_options->{TYPEMAPS};
        for(@vals) {
           die "Couldn't locate the typemap $_" unless -f $_;
        }
        $o->{ILSM}{MAKEFILE}{TYPEMAPS} = \@vals;
      }
    }
    else {
      $o->{ILSM}{MAKEFILE}{TYPEMAPS} = [];
    }

    my @uncorrupted_typemaps = @{$o->{ILSM}{MAKEFILE}{TYPEMAPS}};
    push @uncorrupted_typemaps, 'CPP.map';

    if($config_options->{PREFIX}) {$o->{ILSM}{XS}{PREFIX} = $config_options->{PREFIX}}

    bless($o, 'Inline::CPP');

    Inline::CPP::validate($o);

    if($config_options->{LIBS}) {
      my @init;
      my $init;
      if(ref($o->{ILSM}{MAKEFILE}{LIBS}) eq 'ARRAY') {
        @init = @{$o->{ILSM}{MAKEFILE}{LIBS}};
        $init = join ' ', @init;
      }
      else {$init = $o->{ILSM}{MAKEFILE}{LIBS};}

      my @add;
      my $add;
      if(ref($config_options->{LIBS}) eq 'ARRAY') {
        @add = @{$config_options->{LIBS}};
        $add = join ' ', @add;
      }
      else {$add = $config_options->{LIBS};}
      $o->{ILSM}{MAKEFILE}{LIBS} = $init . ' ' . $add;
    }
    #else { $o->{ILSM}{MAKEFILE}{LIBS} = []} # We don't want this with Inline::CPP
                                             # as it clobbers any setting that was
                                             # made by Inline::CPP::validate()

    if($config_options->{PRE_HEAD}) {
      my $v = $config_options->{PRE_HEAD};
      #{ # open scope
      #  no warnings 'newline';
        unless( -f $v) {
          $o->{ILSM}{AUTO_INCLUDE} = $v . "\n" . $o->{ILSM}{AUTO_INCLUDE};
        }
        else {
          my $insert;
          open RD, '<', $v or die "Couldn't open $v for reading: $!";
          while(<RD>) {$insert .= $_}
          close RD or die "Couldn't close $v after reading: $!";
          $o->{ILSM}{AUTO_INCLUDE} = $insert . "\n" . $o->{ILSM}{AUTO_INCLUDE};
        }
      #} # close scope
    }

    if($config_options->{AUTO_INCLUDE}) {$o->{ILSM}{AUTO_INCLUDE} .= $config_options->{AUTO_INCLUDE} . "\n"}

    if($config_options->{CC}) {$o->{ILSM}{MAKEFILE}{CC} = $config_options->{CC}}

    if($config_options->{CCFLAGS}) {$o->{ILSM}{MAKEFILE}{CCFLAGS} = " " . $config_options->{CCFLAGS}}

    if($config_options->{CCFLAGSEX}) {$o->{ILSM}{MAKEFILE}{CCFLAGS} = $Config{ccflags} . " "
                                                                      . $config_options->{CCFLAGSEX}}

    if(exists($config_options->{INC})) {
      if(ref($config_options->{INC}) eq 'ARRAY') {$o->{ILSM}{MAKEFILE}{INC} = join ' ', @{$config_options->{INC}};}
      else {$o->{ILSM}{MAKEFILE}{INC} = $config_options->{INC};}
    }
    else {$o->{ILSM}{MAKEFILE}{INC} = ''}

    my $uncorrupted_inc = $o->{ILSM}{MAKEFILE}{INC};

    if($config_options->{LD}) {$o->{ILSM}{MAKEFILE}{LD} = " " . $config_options->{LD}}

    if($config_options->{PREREQ_PM}) {$o->{ILSM}{MAKEFILE}{PREREQ_PM} = $config_options->{PREREQ_PM}}

    if($config_options->{LDDLFLAGS}) {$o->{ILSM}{MAKEFILE}{LDDLFLAGS} = " " . $config_options->{LDDLFLAGS}}

    # Here, we'll add the MAKE parameter to $o->{ILSM}{MAKEFILE}{MAKE} ... which
    # could be useful (given that recent versions of Extutils::MakeMaker now recognise it):
    if($config_options->{MAKE}) {$o->{ILSM}{MAKEFILE}{MAKE} = $config_options->{MAKE}}

    if($config_options->{MYEXTLIB}) {$o->{ILSM}{MAKEFILE}{MYEXTLIB} = " " . $config_options->{MYEXTLIB}}

    if($config_options->{OPTIMIZE}) {$o->{ILSM}{MAKEFILE}{OPTIMIZE} = " " . $config_options->{OPTIMIZE}}

    if($config_options->{USING}) {
      my $val = $config_options->{USING};
      if(ref($val) eq 'ARRAY') {
        $o->{CONFIG}{USING} = $val;
      }
      else {
        $o->{CONFIG}{USING} = [$val];
      }
      Inline::push_overrides($o);
    }

    if(!$need_inline_h) {$o->{ILSM}{AUTO_INCLUDE} =~ s/#include "INLINE\.h"//i}

    my $portable;
    {
    no warnings 'uninitialized';
    $portable = uc($config_options->{WRITE_MAKEFILE_PL}) eq 'P' ? 1 : 0;
    }

    _build($o, $need_inline_h, $portable);

    if($config_options->{WRITE_MAKEFILE_PL}) {
     $o->{ILSM}{MAKEFILE}{INC}= $uncorrupted_inc; # Otherwise cwd is automatically added.
      $o->{ILSM}{MAKEFILE}{TYPEMAPS}= \@uncorrupted_typemaps; # Otherwise standard perl typemap is added.
      if($config_options->{VERSION}) {$o->{API}{version} = $config_options->{VERSION}}
      else {warn "'VERSION' being set to '0.00' in the Makefile.PL. Did you supply a correct version number to cpp2xs() ?"}
      print "Writing Makefile.PL in the ", $o->{API}{build_dir}, " directory\n";
      $o->call('write_Makefile_PL', 'Build Glue 3');
      if(uc($config_options->{WRITE_MAKEFILE_PL}) eq 'P') { # Need to rewrite the genrated Makefile.PL
        rewrite_makefile_pl($build_dir);
      }
    }

    if($config_options->{WRITE_PM}) {
      if($config_options->{VERSION}) {$o->{API}{version} = $config_options->{VERSION}}
      else {
        warn "'\$VERSION' being set to '0.00' in ", $o->{API}{modfname}, ".pm. Did you supply a correct version number to cpp2xs() ?";
        $o->{API}{version} = '0.00';
      }
    _write_pm($o);
    }

    if($config_options->{MANIF}) {
      _write_manifest($modfname, $build_dir, $config_options, $need_inline_h);
    }

    if($config_options->{T}) {
      _write_test_script($module, $build_dir);
    }
}

##=========================##

sub _build {
    my $o = shift;
    my $need_inline_headers = shift;
    my $portable = shift;
    my $save;

    $o->call('preprocess', 'Build Preprocess');
    $o->call('parse', 'Build Parse');

    my $modfname = $o->{API}{modfname};
    my $build_dir = $o->{API}{build_dir};

    print "Writing ${modfname}.xs in the $build_dir directory\n";
    if($portable) {
      $save = $o->{ILSM}{AUTO_INCLUDE};
      my @s = split /\n/, $save;
      open WRA, '>', "$build_dir/auto_include.in" or die "Couldn't open $build_dir/auto_include.in for writing: $!";
      for my $l(@s) {
        $l = '' if($l =~ /__INLINE_CPP_STANDARD_HEADERS/ || $l =~ /__INLINE_CPP_NAMESPACE_STD/);
        print WRA $l, "\n";
      }
      close WRA or die "Couldn't close $build_dir/auto_include.in after writing: $!";
      $o->{ILSM}{AUTO_INCLUDE} = "\n#include \"icppdefines.h\"\n";;
    }

    $Inline::CPP::Config::cpp_flavor_defs = ''; # Otherwise we find one more occurrence of
                                                # $Inline::CPP::Config::cpp_flavor_defs in the generated XS
                                                # file than we want.
    $o->call('write_XS', 'Build Glue 1');
    $o->{ILSM}{AUTO_INCLUDE} = $save if $portable;

    if($need_inline_headers) {
      print "Writing INLINE.h in the ", $o->{API}{build_dir}, " directory\n";
      $o->call('write_Inline_headers', 'Build Glue 2');
    }

}

##=========================##

sub _check_config_keys {
    for(@allowable_config_keys) {
      return 1 if $_ eq $_[0]; # it's a valid config option
    }
    return 0;                  # it's an invalid config option
}

##=========================##

sub _write_pm {
    my $o = shift;
    my $offset = 4;
    my $max = 100;
    my $length = $offset;
    my @use;

    if($config_options->{USE}) {
      die "Value supplied to config option USE must be an array reference"
        if ref($config_options->{USE}) ne 'ARRAY';
      @use = @{$config_options->{USE}};
    }

    open(WR, '>', $o->{API}{build_dir} . '/' . $o->{API}{modfname} . ".pm")
        or die "Couldn't create the .pm file: $!";
    print "Writing ", $o->{API}{modfname}, ".pm in the ", $o->{API}{build_dir}, " directory\n";
    print WR "## This file generated by InlineX::CPP2XS (version ",
             $InlineX::CPP2XS::VERSION, ") using Inline::CPP (version ", $Inline::CPP::VERSION, ")\n";
    print WR "package ", $o->{API}{module}, ";\n";
    for(@use) {
      print WR "use ${_};\n";
    }
    print WR "\n";
    print WR "require Exporter;\n*import = \\&Exporter::import;\nrequire DynaLoader;\n\n";
    print WR "our \$VERSION = '", $o->{API}{version}, "';\n";
    print WR "\$VERSION = eval \$VERSION;\n";
    print WR "DynaLoader::bootstrap ", $o->{API}{module}, " \$VERSION;\n\n";

    unless($config_options->{EXPORT_ALL}) {
      print WR "\@", $o->{API}{module}, "::EXPORT = ();\n";
    }
    else {
      print WR "\@", $o->{API}{module}, "::EXPORT = qw(\n";
      for(@{$o->{ILSM}{parser}{data}{functions}}) {
        # exclude function names that begin with a single underscore
        if ($_ =~ /^_/  && $_ !~ /^__/)  {next}
        my $l = length($_);
        if($length + $l > $max) {
          print WR "\n", " " x $offset, "$_ ";
          $length = $offset + $l + 1;
        }
        if($length == $offset) {print WR " " x $offset, "$_ "}
        else {print WR "$_ " }
        $length += $l + 1;
      }
      print WR "\n", " " x $offset, ");\n\n";
      $length = $offset;
    }

    unless($config_options->{EXPORT_OK_ALL} || $config_options->{EXPORT_TAGS_ALL}) {
      print WR "\@", $o->{API}{module}, "::EXPORT_OK = ();\n\n";
    }
    else {
      print WR "\@", $o->{API}{module}, "::EXPORT_OK = qw(\n";
      for(@{$o->{ILSM}{parser}{data}{functions}}) {
        # exclude function names that begin with a single underscore
        if ($_ =~ /^_/ && $_ !~ /^__/)   {next}
        my $l = length($_);
        if($length + $l > $max) {
          print WR "\n", " " x $offset, "$_ ";
          $length = $offset + $l + 1;
        }
        if($length == $offset) {print WR " " x $offset, "$_ "}
        else {print WR "$_ " }
        $length += $l + 1;
      }
      print WR "\n", " " x $offset, ");\n\n";
      $length = $offset;
    }

    if($config_options->{EXPORT_TAGS_ALL}){
      print WR "\%", $o->{API}{module}, "::EXPORT_TAGS = (", $config_options->{EXPORT_TAGS_ALL}, " => [qw(\n";
      for(@{$o->{ILSM}{parser}{data}{functions}}) {
        # exclude function names that begin with a single underscore
        if ($_ =~ /^_/ && $_ !~ /^__/)   {next}
        my $l = length($_);
        if($length + $l > $max) {
          print WR "\n", " " x $offset, "$_ ";
          $length = $offset + $l + 1;
        }
        if($length == $offset) {print WR " " x $offset, "$_ "}
        else {print WR "$_ " }
        $length += $l + 1;
      }
      print WR "\n", " " x $offset, ")]);\n\n";
      $length = $offset;
    }

    print WR "sub dl_load_flags {0} # Prevent DynaLoader from complaining and croaking\n\n";
    print WR "1;\n";
    close(WR) or die "Couldn't close the .pm file after writing to it: $!";
}

##=========================##

sub rewrite_makefile_pl {
    # This sub will get called if we want to write a portable Makefile.PL - ie iff
    # WRITE_MAKEFILE_PL is set to 'p' or 'P'.
    # Lines starting with '>>' are heredoc entries. (All occurrences of '>>' are
    # removed before the heredoc gets written to file.)
    my $bd = shift; # build directory

    die "Couldn't rename $bd/Makefile.PL"
      unless rename "$bd/Makefile.PL", "$bd/Makefile.PL_first";

    # Use the cpp test script from Inline::CPP
    my $test_cpp = <<'    TEST_CPP';
>>#include <iostream>
>>int main(){
>>    return 0;
>>}
>>
    TEST_CPP

    $test_cpp =~ s/>>//g;

    open WRT, '>', "$bd/ilcpptest.cpp" or die "Couldn't open $bd/ilcpptest.cpp for writing: $!";
    print WRT $test_cpp;
    close WRT or die "Couldn't close $bd/ilcpptest.cpp: $!";


    open RD, '<', "$bd/Makefile.PL_first" or die "Couldn't open $bd/Makefile.PL_first for reading: $!";
    open WR, '>', "$bd/Makefile.PL" or die "Couldn't open Makefile.PL for writing: $!";

    my @make = <RD>;

    my $insert = <<'    IN';
>>
>>    my ($cc_guess, $libs_guess) = _guess();
>>
>>    my $iostream = which_iostream($cc_guess);
>>
>>    my $standard;
>>    if($iostream eq '<iostream>' ) {
>>      $standard = <<'STD';
>>
>>#define __INLINE_CPP_STANDARD_HEADERS 1
>>#define __INLINE_CPP_NAMESPACE_STD 1
>>
>>STD
>>    }
>>    else {$standard = ''}
>>
>>write_icppdefines_h($standard);
>>
>>sub _guess {
>>
>>    my $cc_guess;
>>    my $libs_guess;
>>
>>    if($Config{osname} eq 'darwin'){
>>      my $stdlib_query =
>>        'find /usr/lib/gcc -name "libstdc++*" | grep $( uname -p )';
>>      my $stdcpp =
>>        `$stdlib_query`; + $stdcpp =~ s/^(.*)\/[^\/]+$/$1/;
>>      $cc_guess   = 'g++';
>>      $libs_guess = "-L$stdcpp -lstdc++";
>>    }
>>    elsif (
>>      $Config{osname} ne 'darwin' and
>>      $Config{gccversion} and
>>      $Config{cc} =~ m#\bgcc\b[^/]*$# ) {
>>      ($cc_guess  = $Config{cc}) =~ s[\bgcc\b([^/]*)$(?:)][g\+\+$1];
>>      $libs_guess = '-lstdc++';
>>    }
>>    elsif ($Config{osname} =~ m/^MSWin/) {
>>      $cc_guess   = 'cl -TP -EHsc';
>>      $libs_guess = 'MSVCIRT.LIB';
>>    }
>>    elsif ($Config{osname} eq 'linux') {
>>      $cc_guess   = 'g++';
>>      $libs_guess = '-lstdc++';
>>    }
>>    # Dragonfly patch is just a hunch...
>>    elsif( $Config{osname} eq 'netbsd' || $Config{osname} eq 'dragonfly' ) {
>>      $cc_guess   = 'g++';
>>      $libs_guess = '-lstdc++ -lgcc_s';
>>    }
>>    elsif ($Config{osname} eq 'cygwin') {
>>      $cc_guess   = 'g++';
>>      $libs_guess = '-lstdc++';
>>    }
>>    elsif ($Config{osname} eq 'solaris' or $Config{osname} eq 'SunOS') {
>>      if(
>>        $Config{cc} eq 'gcc' ||( exists( $Config{gccversion} ) && $Config{gccversion} > 0)) {
>>        $cc_guess   = 'g++';
>>        $libs_guess = '-lstdc++';
>>      }
>>      else {
>>        $cc_guess   = 'CC';
>>        $libs_guess ='-lCrun';
>>      }
>>    }
>>    elsif ($Config{osname} eq 'mirbsd') {
>>      my $stdlib_query =
>>        'find /usr/lib/gcc -name "libstdc++*" | grep $( uname -p ) | head -1';
>>      my $stdcpp =
>>        `$stdlib_query`; + $stdcpp =~ s/^(.*)\/[^\/]+$/$1/;
>>      $cc_guess   = 'g++';
>>      $libs_guess = "-L$stdcpp -lstdc++ -lc -lgcc_s";
>>    }
>>    # Sane defaults for other (probably unix-like) operating systems
>>    else {
>>      $cc_guess   = 'g++';
>>      $libs_guess = '-lstdc++';
>>    }
>>
>>    return ($cc_guess, $libs_guess);
>>}
>>
>>sub which_iostream {
>>
>>    my $cpp_compiler = shift;
>>
>>    my $result;
>>    if( $cpp_compiler =~ m/^cl/ ) {
>>      $result = system(
>>        qq{$cpp_compiler -Fe:ilcpptest.exe } .
>>        qq{ilcpptest.cpp}
>>      );
>>    }
>>    else {
>>      $result = system(
>>        qq{$cpp_compiler -o ilcpptest.exe } .
>>        qq{ilcpptest.cpp}
>>      );
>>    }
>>
>>    if( $result != 0 ) {
>>      # Compiling with <iostream> failed, so we'll assume .h headers.
>>      $result = '<iostream.h>';
>>    }
>>    else {
>>      # Compiling with <iostream> succeeded.
>>      $result = '<iostream>';
>>      unlink "ilcpptest.exe" or warn $!; # Unlink the executable.
>>    }
>>    return $result;
>>}
>>
>>sub write_icppdefines_h {
>>
>>    my $standard = shift;
>>
>>    open RDA, '<', 'auto_include.in' or die "Couldn't open auto_include.in for reading: $!";
>>    my @auto = <RDA>;
>>    close RDA or die "Couldn't close auto_include.in after reading: $!";
>>
>>    my $auto = join '', @auto;
>>
>>    if($standard) {$auto =~ s/<iostream.h>/<iostream>/g}
>>    else {$auto =~ s/<iostream>/<iostream.h>/g}
>>
>>    open WRXS, '>', "icppdefines.h" or die "Couldn't open icppdefines.h for writing: $!";
>>
>>    print WRXS "\n/* This file generated by the Makefile.PL */\n\n";
>>    print WRXS $standard;
>>    print WRXS $auto;
>>
>>    close WRXS or die "Couldn't close icppdefines.h: $!";
>>
>>}
>>
    IN

    $insert =~ s/>>//g;

    $make[0] .= $insert;
    for(@make) {
      if($_ =~ /'LIBS' => '/) {
        my @t = split /'LIBS' => /;
        $t[1] =~ s/'/"/g;
        $t[1] =~ s/"/\$libs_guess /;
        $_ = join "'LIBS' => \"", @t;
      }
      if($_ =~ /'CC' =>/) {$_ = '  \'CC\' => "$cc_guess",' . "\n"}
    }

    for(@make) {print WR $_}
    close RD or die "Couldn't close $bd/Makefile.PL_first: $!";
    close WR or die "Couldn't close $bd/Makefile.PL: $!";
    unlink "$bd/Makefile.PL_first" or die "Couldn't unlink $bd/Makefile.PL_first: $!";
}

##=========================##

sub _write_manifest {
    my $m = shift;  # name of pm and xs files
    my $bd = shift; # build directory
    my $c = shift;  # config options
    my $ih = shift; # INLINE.h required ?

    print "Writing the MANIFEST file in the $bd directory\n";

    open WRM, '>', "$bd/MANIFEST" or die "Can't open MANIFEST for writing: $!";
    print WRM "MANIFEST\n";
    if($c->{WRITE_PM}) {print WRM "$m.pm\n"}
    if($ih) {print WRM "INLINE.h\n"}
    print WRM "$m.xs\nCPP.map\n";
    if($c->{WRITE_MAKEFILE_PL}) {
      print WRM "Makefile.PL\n";
      if(uc($c->{WRITE_MAKEFILE_PL}) eq 'P') {
        print WRM "auto_include.in\nilcpptest.cpp\n";
      }
    }
    close WRM;
}

##=========================##

sub _write_test_script {
  use File::Path;
  my $mod = $_[0];
  my $path = "$_[1]/t";
  unless(-d $path) {
    if(!File::Path::make_path($path, {verbose => 1})) {die "Failed to create $path directory"};
  }

  print "Writing 00load.t in the $path directory\n";
  open WRT, '>', "$path/00load.t" or die "Couldn't open $path/00load.t for writing: $!";
  print WRT "## This file auto-generated by InlineX-CPP2XS-" . $InlineX::CPP2XS::VERSION . "\n\n";
  print WRT "use strict;\nuse warnings;\n\n";
  print WRT "print \"1..1\\n\";\n\n";
  print WRT "eval{require $mod;};\n";
  print WRT "if(\$\@) {\n  warn \"\\\$\\\@: \$\@\";\n  print \"not ok 1\\n\";\n}\n";
  print WRT "else {print \"ok 1\\n\"}\n";
  close WRT or die "Couldn't close $path/00load.t after writing: $!";
}

##=========================##

##=========================##

##=========================##

1;

__END__

=head1 NAME

InlineX::CPP2XS - Convert from Inline C++ code to XS.

=head1 SYNOPSIS

 #USAGE:
 #cpp2xs($module_name, $package_name [, $build_dir] [, $config_opts])
  use InlineX::CPP2XS qw(cpp2xs);

  my $module_name = 'MY::XS_MOD';
  my $package_name = 'MY::XS_MOD';

  # $build_dir is an optional third arg.
  # If omitted it defaults to '.' (the cwd).
  my $build_dir = '/some/where/else';

  # $config_opts is an optional fourth arg (hash reference)
  my $config_opts = {'WRITE_PM' => 1,
                     #'WRITE_MAKEFILE_PL' => 1, # non portable files
                     'WRITE_MAKEFILE_PL' => 'p', # portable files
                     'VERSION' => 0.42,
                    };

  # Create /some/where/else/XS_MOD.xs from ./src/XS_MOD.cpp
  # Will also create the typemap file /some/where/else/CPP.map
  # if that file is going to be needed to build the module:
  cpp2xs($module_name, $package_name, $build_dir);

  # Alternatively create XS_MOD.xs (and CPP.map, if needed) in
  # the cwd:
  cpp2xs($module_name, $package_name);

  # Or Create /some/where/else/XS_MOD.xs from $code
  $code = 'void foo() {printf("Hello World\n");}' . "\n\n";
  cpp2xs($module_name, $package_name, $build_dir, {CODE => $code});

  # Or Create /some/where/else/XS_MOD.xs from the C code that's in
  # ./otherplace/otherfile.ext
  $loc = './otherplace/otherfile.ext';
  cpp2xs($module_name, $package_name, $build_dir, {SRC_LOCATION => $loc});

  The optional fourth arg (a reference to a hash) is to enable the
  passing of additional information and configuration options that
  Inline may need - and also to enable the creation of the
  Makefile.PL and .pm file(if desired).
  See the "Recognised Hash Keys" section below.

  # Create XS_MOD.xs in the cwd, and generate the Makefile.PL
  # and XS_MOD.pm :
  cpp2xs($module_name, $package_name, $config_opts);

  NOTE: If you wish to supply the $config_opts argument, but not the
  $build_dir argument then you simply omit the $build_dir argument.
  That is, the following are equivalent:
   cpp2xs($module_name, $package_name, '.', $config_opts);
   cpp2xs($module_name, $package_name, $config_opts);
  If a third argument is given, it's deemed to be the build directory
  unless it's a hash reference (in which case it's deemed to be the
  hash reference containing the additional config options).

  As of version 0.19, a cpp2xs utility is also provided. It's just an
  Inline::CPP2XS wrapper - see 'cpp2xs --help'.
  See also the cpp2xs demos in demos/cpp2xs_utility/README (in the
  InlineX::CPP2XS source distro).

=head1 DESCRIPTION

 Don't feed an actual Inline::CPP script to this module - it won't
 be able to parse it. It is capable of parsing correctly only
 that CPP code that is suitable for inclusion in an Inline::CPP
 script.

 For example, here is a simple Inline::CPP script:

  use warnings;
  use Inline CPP => Config =>
      BUILD_NOISY => 1,
      CLEAN_AFTER_BUILD => 0;
  use Inline CPP => <<'EOC';
  #include <stdio.h>

  void greet() {
      printf("Hello world\n");
  }
  EOC

  greet();
  __END__

 The CPP file that InlineX::CPP2XS needs to find would contain only that code
 that's between the opening 'EOC' and the closing 'EOC' - namely:

  #include <stdio.h>

  void greet() {
      printf("Hello world\n");
  }

 If the CPP code is not provided by either the CODE or SRC_LOCATION keys,
 InlineX::CPP2XS looks for the source file in ./src directory - expecting
 that the filename will be the same as what appears after the final '::'
 in the module name (with a '.cpp' extension). ie if your module is
 called My::Next::Mod the cpp2xs() function looks for a file ./src/Mod.cpp,
 and creates a file named Mod.xs.  Also created (by the cpp2xs function,
 is the file 'INLINE.h' - but only if that file is needed. The generated
 xs file (and INLINE.h) will be written to the cwd unless a third argument
 (specifying a valid directory) is provided to the cpp2xs function.

 The created XS file, when packaged with the '.pm' file, an
 appropriate 'Makefile.PL' (which can also be auto-generated by setting
 the WRITE_MAKEFILE_PL hash key), and 'INLINE.h' (if it's needed), can be
 used to build the module in the usual way - without any dependence
 upon the Inline::CPP module. The cpp2xs() function may also produce
 a typemap file ('CPP.map'). That file, if produced, is also needed for a
 successful build. See the demos/cpp folder in the InlineX::CPP2XS source
 for an example of what's required.

=head1 Recognised Hash Keys

 As regards the optional fourth argument to cpp2xs(), the following hash
 keys/values are recognised:

  AUTO_INCLUDE
   The value specified is automatically inserted into the generated XS
   file. (Also, the specified include will be parsed and used iff
   AUTOWRAP is set to a true value.) eg:

    AUTO_INCLUDE => '#include <my_header.h>',
  ----

  AUTOWRAP
   Set this to a true value to enable Inline::CPP's AUTOWRAP capability.
   eg:

    AUTOWRAP => 1,
  ----

 BOOT
   Specifies C/CPP code to be executed in the XS BOOT section. Corresponds
   to the XS parameter. eg:

    BOOT => 'printf("Hello .. from bootstrap\n");',
  ----

 BOOT_F
   Specifies a file containing C/CPP code to be executed in the XS BOOT
   section.
   eg:

    BOOT_F => '/home/me/boot_code.ext',
  ----

  BUILD_NOISY
   Is set to a true value, by default. Setting to a false value will
   mean that progress messages generated by Inline::CPP are suppressed. eg:

    BUILD_NOISY => 0,
  ----

  CC
   Specify the compiler you want to use. It makes sense to assign this
   key only when WRITE_MAKEFILE_PL is set to a true value. eg:

    CC => 'g++',
  ----

  CCFLAGS
   Specify which compiler flags to use. (Existing value gets clobbered, so
   you'll probably want to re-specify it.) It makes sense to assign this
   key only when WRITE_MAKEFILE_PL is set to a true value. eg:

    CCFLAGS => $Config{ccflags} . ' -DMY_DEFINE',
  ----

  DIST
   If set, sets WRITE_MAKEFILE_PL => 'p', WRITE_PM => 1, MANIF => 1. eg:

    DIST => 1,
  ----

  CCFLAGSEX
   Add compiler flags to existing flags.
   It makes sense to assign this key only when WRITE_MAKEFILE_PL is set to
   a true value. eg:

    CCFLAGSEX => '-DMY_DEFINE',
  ----

  CODE
   A string containing the CPP code. eg:

    CODE => 'void foo() {printf("Hello World\n");}' . "\n\n",
  ----

  EXPORT_ALL
   Makes no sense to use this unless WRITE_PM has been set.
   Places all XSubs except those beginning with a *single* underscore (but not
   multiple underscores) in @EXPORT in the generated .pm file. eg:

    EXPORT_ALL => 1,
  ----

  EXPORT_OK_ALL
   Makes no sense to use this unless WRITE_PM has been set.
   Places all XSubs except those beginning with a *single* underscore (but not
   multiple underscores) in @EXPORT_OK in the generated .pm file. eg:

    EXPORT_OK_ALL => 1,
  ----

  EXPORT_TAGS_ALL
   Makes no sense to use this unless WRITE_PM has been set.
   In the generated .pm file, creates an EXPORT_TAGS tag named 'name'
   (where 'name' is whatever you have specified), and places all XSubs except
   those beginning with a *single* underscore (but not multiple underscores)
   in 'name'. Also places same subs in @EXPORT_OK.
   eg, the following creates and fills a tag named 'all':

    EXPORT_TAGS_ALL => 'all',
  ----

  INC
   The value specified is added to the includes search path. It makes
   sense to assign this key only when AUTOWRAP and/or WRITE_MAKEFILE_PL
   are set to a true value. eg:

    INC => '-I/my/includes/dir -I/other/includes/dir',
    INC => ['-I/my/includes/dir', '-I/other/includes/dir'],
  ----

  LD
   Specify the linker you want to use.It makes sense to assign this
   key only when WRITE_MAKEFILE_PL is set to a true value. eg:

    LD => 'g++',
  ----

  LDDLFLAGS
   Specify which linker flags to use. (Existing value gets clobbered, so
   you'll probably want to re-specify it.) It makes sense to assign this
   key only when WRITE_MAKEFILE_PL is set to a true value. eg:

    LDDLFLAGS => "$my_ldopts " . $Config{lddlflags},
  ----

  LIBS
   The value(s) specified become the LIBS search path. It makes sense
   to assign this key only if WRITE_MAKEFILE_PL is set to a true value.
   eg:

    LIBS => '-L/somewhere -lsomelib -L/elsewhere -lotherlib',
    LIBS => ['-L/somewhere -lsomelib', '-L/elsewhere -lotherlib'],
  ----

  MAKE
   Specify the make utility you want to use. It makes sense to assign this
   key only when WRITE_MAKEFILE_PL is set to a true value. eg:

    MAKE => 'pmake', # I have no idea whether that will work :-)
  ----

  MANIF
   If true, the MANIFEST file will be written. (It will include all created
   files.) eg:

   MANIF => 1,

  ----

  MYEXTLIB
   Specifies a user compiled object that should be linked in.
   Corresponds to the MakeMaker parameter. It makes sense to assign this
   key only when WRITE_MAKEFILE_PL is set to a true value. eg:

    MYEXTLIB => '/your/path/yourmodule.so',
  ----

  OPTIMIZE
   This controls the MakeMaker OPTIMIZE setting.It makes sense to assign
   this key only when WRITE_MAKEFILE_PL is set to a true value. eg:

    OPTIMIZE => '-g',
  ----

  PREFIX
   Specifies a prefix that will be automatically stripped from C
   functions when they are bound to Perl. eg:

    PREFIX => 'FOO_',
  ----

  PRE_HEAD

   Specifies code that will precede the inclusion of all files specified
   in AUTO_INCLUDE (ie EXTERN.h, perl.h, XSUB.h, INLINE.h and anything
   else that might have been added to AUTO_INCLUDE by the user). If the
   specified value identifies a file, the contents of that file will be
   inserted, otherwise the specified value is inserted.
   If the specified value is a string of code, then since that string
   ends in "\n" (as all code *should* terminate with at least one "\n"),
   you will get a warning about an "Unsuccessful stat on filename
   containing newline" when the test for the existence of a file that
   matches the PRE_HEAD value is conducted.

    PRE_HEAD => $code_or_filename;
  ----

  PREREQ_PM
   Makes sense to specify this only if WRITE_MAKEFILE_PL is set to true.
   The string to which PREREQ_PM is set will be reproduced as is in the
   generated Makefile.PL. That is, if you specify:

   PREREQ_PM => "{'Some::Mod' => '1.23', 'Nother::Mod' => '3.21'}",

   then the WriteMakefile hash in the generated Makefile.PL will
   contain:

   PREREQ_PM => {'Some::Mod' => '1.23', 'Nother::Mod' => '3.21'},
  ----

  SRC_LOCATION
   Specifies a C file that contains the CPP source code. eg:

    SRC_LOCATION => '/home/me/source.ext',
  ----

  T
   Is false by default but, When set to true will write a basic
   t/00load.t test script in the build directory.
   eg:

    T => 1,
  ----

  TYPEMAPS
   The value(s) specified are added to the list of typemaps.
   eg:

    TYPEMAPS =>['my_typemap', 'my_other_typemap'],
    TYPEMAPS =>'my_typemap my_other_typemap',
  ----

  USE
   Must be an array reference, listing the modules that the autogenerated
   pm file needs to load (use). Makes no sense to assign this key if
   WRITE_PM is not set to a true value. eg:

    USE => ['Digest::MD5', 'LWP::Simple'];
  ----

  USING
    With Inline::C, enables use of an alternative parser. But with
    Inline::CPP, there is currently no alternative parser available.

    USING => ['ParseRegExp'], # fails on Inline::CPP & InlineX::CPP2XS.
    or
    USING => 'ParseRegExp', # fails on Inline::CPP & InlineX::CPP2XS.
  ----

  VERSION
   Set this to the version number of the module. It makes sense to assign
   this key only if WRITE_MAKEFILE_PL and/or WRITE_PM is set to a true
   value. eg:

    VERSION => 0.42,
  ----

  WRITE_MAKEFILE_PL
   Set this to to a true value if you want the Makefile.PL to be
   generated. (You should also assign the 'VERSION' key to the
   correct value when WRITE_MAKEFILE_PL is set.) eg:

    WRITE_MAKEFILE_PL => 1,   # Makefile.PL and xs file may not work on
                              # a different machine.
    WRITE_MAKEFILE_PL => 'p', # Makefile.PL and xs file should be portable
  ----

  WRITE_PM
   Set this to a true value if you want a .pm file to be generated.
   You'll also need to assign the 'VERSION' key appropriately.
   Note that it's a fairly simplistic .pm file - no POD, no perl
   subroutines, no exported subs (unless EXPORT_ALL or EXPORT_OK_ALL
   has been set), no warnings - but it will allow the utilisation of all of
   the XSubs in the XS file. eg:

    WRITE_PM => 1,
  ----

=head1 BUGS

   None known - patches/rewrites/enhancements welcome.
   Send to sisyphus at cpan dot org

=head1 LICENSE

   This program is free software; you may redistribute it and/or
   modify it under the same terms as Perl itself.
   Copyright 2006-2009, 2010-12, Sisyphus

=head1 AUTHOR

   Sisyphus <sisyphus at(@) cpan dot (.) org>

=cut

