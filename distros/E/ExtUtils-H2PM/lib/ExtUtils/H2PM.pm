#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2016 -- leonerd@leonerd.org.uk

package ExtUtils::H2PM;

use strict;
use warnings;

use Carp;

our $VERSION = '0.10';

use Exporter 'import';
our @EXPORT = qw(
   module
   include
   constant

   structure
      member_numeric
      member_strarray
      member_constant

   no_export use_export use_export_ok

   gen_output
   write_output

   include_path
   define
);

use ExtUtils::CBuilder;

use List::Util 1.29 qw( pairs );

=head1 NAME

C<ExtUtils::H2PM> - automatically generate perl modules to wrap C header files

=head1 DESCRIPTION

This module assists in generating wrappers around system functionallity, such
as C<socket()> types or C<ioctl()> calls, where the only interesting features
required are the values of some constants or layouts of structures normally
only known to the C header files. Rather than writing an entire XS module just
to contain some constants and pack/unpack functions, this module allows the
author to generate, at module build time, a pure perl module containing
constant declarations and structure utility functions. The module then
requires no XS module to be loaded at run time.

In comparison to F<h2ph>, C<C::Scan::Constants>, and so on, this module works
by generating a small C program containing C<printf()> lines to output the
values of the constants, compiling it, and running it. This allows it to
operate without needing tricky syntax parsing or guessing of the contents of
C header files.

It can also automatically build pack/unpack functions for simple structure
layouts, whose members are all simple integer or character array fields.
It is not intended as a full replacement of arbitrary code written in XS
modules. If structures should contain pointers, or require special custom
handling, then likely an XS module will need to be written.

=cut

my $output = "";

my @preamble;
my @fragments;

my $done_carp;

my @perlcode;
my @genblocks;

my $export_mode; use_export_ok();
my @exports; my @exports_ok;

=head1 FUNCTIONS

=cut

sub push_export
{
   my $name = shift;

   if( $export_mode eq "OK" ) {
      push @exports_ok, $name;
   }
   elsif( $export_mode ) {
      push @exports, $name;
   }
}

=head2 module $name

Sets the name of the perl module to generate. This will apply a C<package>
header.

=cut

my $modulename;
sub module
{
   $modulename = shift;

   $output .= gen_perl() if @fragments;

   $output .= "package $modulename;\n" .
              "# This module was generated automatically by ExtUtils::H2PM from $0\n" .
              "\n";

   undef $done_carp;
}

=head2 include $file

Adds a file to the list of headers which will be included by the C program, to
obtain the constants or structures from

=cut

sub include
{
   my ( $file, %params ) = @_;

   # undocumented but useful for testing
   if( $params{local} ) {
      push @preamble, qq[#include "$file"];
   }
   else {
      push @preamble, "#include <$file>";
   }
}

# undocumented so far
sub perlcode
{
   my ( $code ) = @_;
   push @perlcode, $code;
}

=head2 constant $name, %args

Adds a numerical constant.

The following additional named arguments are also recognised:

=over 8

=item * name => STRING

Use the given name for the generated constant function. If not specified, the
C name for the constant will be used.

=item * ifdef => STRING

If present, guard the constant with an C<#ifdef STRING> preprocessor macro. If
the given string is not defined, no constant will be generated.

=back

=cut

sub constant
{
   my $constname = shift;
   my %args = @_;

   my $name = $args{name} || $constname;

   push @fragments, qq{  printf("$constname=%ld\\n", (long)$constname);};

   if( my $symbol = $args{ifdef} ) {
      $fragments[-1] = "#ifdef $symbol\n$fragments[-1]\n#endif";
   }

   push @genblocks, [ $constname => sub {
      my ( $result ) = @_;
      return () unless defined $result;

      push_export $name;
      "use constant $name => $result;";
   } ];
}

=head2 structure $name, %args

Adds a structure definition. This requires a named argument, C<members>. This
should be an ARRAY ref containing an even number of name-definition pairs. The
first of each pair should be a member name. The second should be one of the
following structure member definitions.

The following additional named arguments are also recognised:

=over 8

=item * pack_func => STRING

=item * unpack_func => STRING

Use the given names for the generated pack or unpack functions.

=item * with_tail => BOOL

If true, the structure is a header with more data behind it. The pack function
takes an optional extra string value for the data tail, and the unpack
function will return an extra string value containing it.

=item * no_length_check => BOOL

If true, the generated unpack function will not first check the length of its
argument before attempting to unpack it. If the buffer is not long enough to
unpack all the required values, the remaining ones will not be returned. This
may be useful, for example, in cases where various versions of a structure
have been designed, later versions adding extra members, but where the exact
version found may not be easy to determine beforehand.

=item * arg_style => STRING

Defines the style in which the functions take arguments or return values.
Defaults to C<list>, which take or return a list of values in the given order.
The other allowed value is C<hashref>, where the pack function takes a HASH
reference and the unpack function returns one. Each will consist of keys named
after the structure members. If a data tail is included, it will use the hash
key of C<_tail>.

=item * ifdef => STRING

If present, guard the structure with an C<#ifdef STRING> preprocessor macro.
If the given string is not defined, no functions will be generated.

=back

=cut

sub structure
{
   my ( $name, %params ) = @_;

   ( my $basename = $name ) =~ s/^struct //;

   my $packfunc   = $params{pack_func}   || "pack_$basename";
   my $unpackfunc = $params{unpack_func} || "unpack_$basename";

   my $with_tail       = $params{with_tail};
   my $no_length_check = $params{no_length_check};

   my $arg_style = $params{arg_style} || "list";

   my @membernames;
   my @argnames;
   my @memberhandlers;

   my $argindex = 0;
   my @members = @{ $params{members} };
   foreach ( pairs @members ) {
      my $memname = $_->key;
      my $handler = $_->value;

      push @membernames, $memname;
      push @memberhandlers, $handler;

      $handler->{set_names}->( $basename, $memname );

      my $wasindex = $argindex;
      $handler->{set_arg}( $argindex );

      push @argnames, $memname if $argindex > $wasindex;
   }

   push @fragments, "#ifdef $params{ifdef}" if $params{ifdef};
   push @fragments,
      "  {",
      "    $name $basename;", 
    qq[    printf("$basename=%lu,", (unsigned long)sizeof($basename));],
      ( map { "    " . $_->{gen_c}->() } @memberhandlers ),
    qq[    printf("\\n");],
      "  }";
   push @fragments, "#endif" if $params{ifdef};

   push @genblocks, [ $basename => sub {
      my ( $result ) = @_;
      return () unless defined $result;

      my @result = split m/,/, $result;

      my $curpos = 0;

      my $format = "";

      my $sizeof = shift @result;

      my ( @postargs, @preret );

      foreach my $def ( @result ) {
         my $handler = shift @memberhandlers;

         $format .= $handler->{gen_format}( $def, $curpos, \@postargs, \@preret ) . " ";
      }

      if( $curpos < $sizeof ) {
         $format .= "x" . ( $sizeof - $curpos );
      }

      my $eq = "==";
      if( $with_tail ) {
         $format .= "a*";
         $eq = ">=";
      }

      unshift( @perlcode, "use Carp;" ), $done_carp++ unless $done_carp;

      my ( @argcode, @retcode );
      if( $arg_style eq "list" ) {
         my $members = join( ", ", @argnames, ( $with_tail ? "[tail]" : () ) );

         @argcode = (
            qq{   \@_ $eq $argindex or croak "usage: $packfunc($members)";},
            qq{   my \@v = \@_;} );
         @retcode = (
            qq{   \@v;} );
      }
      elsif( $arg_style eq "hashref" ) {
         my $qmembers = join( ", ", map { "'$_'" } @membernames, ( $with_tail ? "_tail" : () ) );

         @argcode = (
            qq{   ref(\$_[0]) eq "HASH" or croak "usage: $packfunc(\\%args)";},
            qq(   my \@v = \@{\$_[0]}{$qmembers};) );
         @retcode = (
            # Seems we can't easily do this without a temporary
            qq(   my %ret; \@ret{$qmembers} = \@v;),
            qq{   \\%ret;} );
      }
      else {
         carp "Unrecognised arg_style $arg_style";
      }

      push_export $packfunc;
      push_export $unpackfunc;

      join( "\n",
         "",
         "sub $packfunc",
         "{",
         @argcode,
         @postargs,
         qq{   pack "$format", \@v;},
         "}",
         "",
         "sub $unpackfunc",
         "{",
         ( $no_length_check ? '' :
            qq{   length \$_[0] $eq $sizeof or croak "$unpackfunc: expected $sizeof bytes, got " . length \$_[0];}
         ),
         qq{   my \@v = unpack "$format", \$_[0];},
         @preret,
         @retcode,
         "}"
      );
   } ];
}

=pod

The following structure member definitions are allowed:

=over 8

=cut

my %struct_formats = (
   map {
      my $bytes = length( pack "$_", 0 );
      "${bytes}u" => uc $_,
      "${bytes}s" => lc $_
   } qw( C S L )
);

if( eval { pack "Q", 0 } ) {
   my $bytes = length( pack "Q", 0 );
   $struct_formats{"${bytes}u"} = "Q";
   $struct_formats{"${bytes}s"} = "q";
}

=item * member_numeric

The field contains a single signed or unsigned number. Its size and signedness
will be automatically detected.

=cut

my $done_u64;

sub member_numeric
{
   my $varname;
   my $membername;
   my $argindex;

   return {
      set_names => sub { ( $varname, $membername ) = @_; },
      set_arg => sub { $argindex = $_[0]++; },

      gen_c => sub {
         qq{printf("$membername@%ld+%lu%c,", } . 
            "(long)((char*)&$varname.$membername-(char*)&$varname), " . # offset
            "(unsigned long)sizeof($varname.$membername), " .           # size
            "($varname.$membername=-1)>0?'u':'s'" .                     # signedness
            ");";
      },
      gen_format => sub {
         my ( $def, undef, $postarg, $preret ) = @_;
         #  ( undef, curpos ) = @_;

         my ( $member, $offs, $size, $sign ) = $def =~ m/^([\w.]+)@(\d+)\+(\d+)([us])$/
            or die "Could not parse member definition out of '$def'";

         $member eq $membername or die "Expected definition of $membername but found $member instead";

         my $format = "";
         if( $offs > $_[1] ) {
            my $pad = $offs - $_[1];

            $format .= "x" x $pad;
            $_[1] += $pad;
         }
         elsif( $offs < $_[1] ) {
            die "Err.. need to go backwards for structure $varname member $member";
         }

         if( exists $struct_formats{"$size$sign"} ) {
            $format .= $struct_formats{"$size$sign"};
         }
         elsif( $size == 8 and $sign eq "u" ) {
            # 64bit int on a 64bit-challenged perl. We'll have to improvise

            unless( $done_u64 ) {
               my $hilo = pack("S",0x0201) eq "\x02\x01" ? "\$hi, \$lo" : "\$lo, \$hi";

               perlcode join "\n",
                  "require Math::BigInt;",
                  "",
                  "sub __pack_u64 {",
                  "   my ( \$hi, \$lo ) = ( int(\$_[0] / 2**32), \$_[0] & 0xffffffff );",
                  "   pack( \"L L\", $hilo );",
                  "}",
                  "",
                  "sub __unpack_u64 {",
                  "   length \$_[0] == 8 or return undef;", # in case of no_length_check
                  "   my ( $hilo ) = unpack( \"L L\", \$_[0] );",
                  "   return \$lo if \$hi == 0;",
                  "   my \$n = Math::BigInt->new(\$hi); \$n <<= 32; \$n |= \$lo;",
                  "   return \$n;",
                  "}",
                  "";

               $done_u64++;
            }

            push @$postarg, "   \$v[$argindex] = __pack_u64( \$v[$argindex] );";
            push @$preret,  "   \$v[$argindex] = __unpack_u64( \$v[$argindex] );";
            

            $format .= "a8";
         }
         else {
            die "Cannot find a pack format for size $size sign $sign";
         }

         $_[1] += $size;
         return $format;
      },
   };
}

=item * member_strarray

The field contains a NULL-padded string of characters. Its size will be
automatically detected.

=cut

sub member_strarray
{
   my $varname;
   my $membername;
   my $argindex;

   return {
      set_names => sub { ( $varname, $membername ) = @_; },
      set_arg => sub { $argindex = $_[0]++; },

      gen_c => sub {
         qq{printf("$membername@%ld+%lu,", } .
            "(long)((char*)&$varname.$membername-(char*)&$varname), " . # offset
            "(unsigned long)sizeof($varname.$membername)" .             # size
            ");";
      },
      gen_format => sub {
         my ( $def ) = @_;

         my ( $member, $offs, $size ) = $def =~ m/^([\w.]+)@(\d+)\+(\d+)$/
            or die "Could not parse member definition out of '$def'";

         $member eq $membername or die "Expected definition of $membername but found $member instead";

         my $format = "";
         if( $offs > $_[1] ) {
            my $pad = $offs - $_[1];

            $format .= "x" x $pad;
            $_[1] += $pad;
         }
         elsif( $offs < $_[1] ) {
            die "Err.. need to go backwards for structure $varname member $member";
         }

         $format .= "Z$size";
         $_[1] += $size;

         return $format;
      },
   };
}

=item * member_constant($code)

The field contains a single number as for C<member_numeric>. Instead of 
consuming/returning a value in the arguments list, this member will be packed
from an expression, or asserted that it contains the given value. The string
C<$code> will be inserted into the generated pack and unpack functions, so it
can be used for constants generated by the C<constant> directive.

=cut

sub member_constant
{
   my $value = shift;

   my $constant = member_numeric;

   my $arg_index;
   $constant->{set_arg} = sub { $arg_index = $_[0] }; # no inc

   my $gen_format = delete $constant->{gen_format};
   $constant->{gen_format} = sub {
      my ( $def, undef, $postarg, $preret ) = @_;

      my ( $member ) = $def =~ m/^([\w.]+)@/
         or die "Could not parse member definition out of '$def'";

      push @$postarg, "   splice \@v, $arg_index, 0, $value;";

      my $format = $gen_format->( @_ );

      push @$preret,  "   splice( \@v, $arg_index, 1 ) == $value or croak \"expected $member == $value\";";

      return $format;
   };

   $constant;
}

=back

The structure definition results in two new functions being created,
C<pack_$name> and C<unpack_$name>, where C<$name> is the name of the structure
(with the leading C<struct> prefix stripped). These behave similarly to the
familiar functions such as C<pack_sockaddr_in>; the C<pack_> function will
take a list of fields and return a packed string, the C<unpack_> function will
take a string and return a list of fields.

=cut

=head2 no_export, use_export, use_export_ok

Controls the export behaviour of the generated symbols. C<no_export> creates
symbols that are not exported by their package, they must be used fully-
qualified. C<use_export> creates symbols that are exported by default.
C<use_export_ok> creates symbols that are exported if they are specifically
requested at C<use> time.

The mode can be changed at any time to affect only the symbols that follow
it. It defaults to C<use_export_ok>.

=cut

sub no_export     { $export_mode = 0 }
sub use_export    { $export_mode = 1 }
sub use_export_ok { $export_mode = "OK" }

my $cbuilder = ExtUtils::CBuilder->new( quiet => 1 );
my %compile_args;
my %link_args;

if( my $mb = eval { require Module::Build and Module::Build->current } ) {
   $compile_args{include_dirs}         = $mb->include_dirs;
   $compile_args{extra_compiler_flags} = $mb->extra_compiler_flags;

   $link_args{extra_linker_flags} = $mb->extra_linker_flags;
}

sub gen_perl
{
   return "" unless @fragments;

   my $c_file = join "\n",
      "#include <stdio.h>",
      @preamble,
      "",
      "int main(void) {",
      @fragments,
      "  return 0;",
      "}\n";

   undef @preamble;
   undef @fragments;

   die "Cannot generate a C file yet - no module name\n" unless defined $modulename;

   my $tempname = "gen-$modulename";

   my $sourcename = "$tempname.c";
   {
      open( my $source_fh, "> $sourcename" ) or die "Cannot write $sourcename - $!";
      print $source_fh $c_file;
   }

   my $objname = eval { $cbuilder->compile( source => $sourcename, %compile_args ) };

   unlink $sourcename;

   if( !defined $objname ) {
      die "Failed to compile source\n";
   }

   my $exename = eval { $cbuilder->link_executable( objects => $objname, %link_args ) };

   unlink $objname;

   if( !defined $exename ) {
      die "Failed to link executable\n";
   }

   my $output;
   {
      open( my $runh, "./$exename |" ) or die "Cannot pipeopen $exename - $!";

      local $/;
      $output = <$runh>;
   }

   unlink $exename;

   my %results = map { m/^(\w+)=(.*)$/ } split m/\n/, $output;

   my $perl = "";

   my @bodylines;

   # Evaluate these first, so they have a chance to push_export()
   foreach my $genblock ( @genblocks ) {
      my ( $key, $code ) = @$genblock;

      push @bodylines, $code->( $results{$key} );
   }

   if( @exports ) {
      $perl .= "push \@EXPORT, " . join( ", ", map { "'$_'" } @exports ) . ";\n";
      undef @exports;
   }

   if( @exports_ok ) {
      $perl .= "push \@EXPORT_OK, " . join( ", ", map { "'$_'" } @exports_ok ) . ";\n";
      undef @exports_ok;
   }

   $perl .= join "", map { "$_\n" } @bodylines;

   undef @genblocks;

   my @thisperlcode = @perlcode;
   undef @perlcode;

   return join "\n", @thisperlcode, $perl;
}

=head2 $perl = gen_output

Returns the generated perl code. This is used internally for testing purposes
but normally would not be necessary; see instead C<write_output>.

=cut

sub gen_output
{
   my $ret = $output . gen_perl . "\n1;\n";
   $output = "";

   return $ret;
}

=head2 write_output $filename

Write the generated perl code into the named file. This would normally be used
as the last function in the containing script, to generate the output file. In
the case of C<ExtUtils::MakeMaker> or C<Module::Build> invoking the script,
the path to the file to be generated should be given in C<$ARGV[0]>. Normally,
therefore, the script would end with

 write_output $ARGV[0];

=cut

sub write_output
{ 
   my ( $filename ) = @_;

   my $output = gen_output();

   open( my $outfile, ">", $filename ) or die "Cannot write '$filename' - $!";

   print $outfile $output;
}

=head2 include_path

Adds an include path to the list of paths used by the compiler

 include_path $path

=cut

sub include_path
{
   my ( $path ) = @_;

   push @{ $compile_args{include_dirs} }, $path;
}

=head2 define

Adds a symbol to be defined on the compiler's commandline, by using the C<-D>
option. This is sometimes required to turn on particular optional parts of the
included files. An optional value can also be specified.

 define $symbol
 define $symbol, $value;

=cut

sub define
{
   my ( $symbol, $value ) = @_;

   if( defined $value ) {
      push @{ $compile_args{extra_compiler_flags} }, "-D$symbol=$value";
   }
   else {
      push @{ $compile_args{extra_compiler_flags} }, "-D$symbol";
   }
}

=head1 EXAMPLES

Normally this module would be used by another module at build time, to
construct the relevant constants and structure functions from system headers.

For example, suppose your operating system defines a new type of socket, which
has its own packet and address families, and perhaps some new socket options
which are valid on this socket. We can build a module to contain the relevant
constants and structure functions by writing, for example:

 #!/usr/bin/perl

 use ExtUtils::H2PM;
 
 module "Socket::Moonlaser";

 include "moon/laser.h";

 constant "AF_MOONLASER";
 constant "PF_MOONLASER";

 constant "SOL_MOONLASER";

 constant "MOONLASER_POWER",      name => "POWER";
 constant "MOONLASER_WAVELENGTH", name => "WAVELENGTH";

 structure "struct laserwl",
    members => [
       lwl_nm_coarse => member_numeric,
       lwl_nm_fine   => member_numeric,
    ];

 write_output $ARGV[0];

If we save this script as, say, F<lib/Socket/Moonlaser.pm.PL>, then when the
distribution is built, the script will be used to generate the contents of the
file F<lib/Socket/Moonlaser.pm>. Once installed, any other code can simply

 use Socket::Moonlaser qw( AF_MOONLASER );

to import a constant.

The method described above doesn't allow us any room to actually include other
code in the module. Perhaps, as well as these simple constants, we'd like to
include functions, documentation, etc... To allow this, name the script
instead something like F<lib/Socket/Moonlaser_const.pm.PL>, so that this is
the name used for the generated output. The code can then be included in the
actual F<lib/Socket/Moonlaser.pm> (which will just be a normal perl module) by

 package Socket::Moonlaser;

 use Socket::Moonlaser_const;

 sub get_power
 {
    getsockopt( $_[0], SOL_MOONLASER, POWER );
 }

 sub set_power
 {
    setsockopt( $_[0], SOL_MOONLASER, POWER, $_[1] );
 }

 sub get_wavelength
 {
    my $wl = getsockopt( $_[0], SOL_MOONLASER, WAVELENGTH );
    defined $wl or return;
    unpack_laserwl( $wl );
 }

 sub set_wavelength
 {
    my $wl = pack_laserwl( $_[1], $_[2] );
    setsockopt( $_[0], SOL_MOONLASER, WAVELENGTH, $wl );
 }

 1;

Sometimes, the actual C structure layout may not exactly match the semantics
we wish to present to perl modules using this extension wrapper. Socket
address structures typically contain their address family as the first member,
whereas this detail isn't exposed by, for example, the C<sockaddr_in> and
C<sockaddr_un> functions. To cope with this case, the low-level structure
packing and unpacking functions can be generated with a different name, and
wrapped in higher-level functions in the main code. For example, in
F<Moonlaser_const.pm.PL>:

 no_export;

 structure "struct sockaddr_ml",
    pack_func   => "_pack_sockaddr_ml",
    unpack_func => "_unpack_sockaddr_ml",
    members => [
       ml_family    => member_numeric,
       ml_lat_deg   => member_numeric,
       ml_long_deg  => member_numeric,
       ml_lat_fine  => member_numeric,
       ml_long_fine => member_numeric,
    ];

This will generate a pack/unpack function pair taking or returning five
arguments; these functions will not be exported. In our main F<Moonlaser.pm>
file we can wrap these to actually expose a different API:

 sub pack_sockaddr_ml
 {
    @_ == 2 or croak "usage: pack_sockaddr_ml(lat, long)";
    my ( $lat, $long ) = @_;

    return _pack_sockaddr_ml( AF_MOONLASER, int $lat, int $long,
      ($lat - int $lat) * 1_000_000, ($long - int $long) * 1_000_000);
 }

 sub unpack_sockaddr_ml
 {
    my ( $family, $lat, $long, $lat_fine, $long_fine ) =
       _unpack_sockaddr_ml( $_[0] );

    $family == AF_MOONLASER or croak "expected family AF_MOONLASER";

    return ( $lat + $lat_fine/1_000_000, $long + $long_fine/1_000_000 );
 }

Sometimes, a structure will contain members which are themselves structures.
Suppose a different definition of the above address, which at the C layer is
defined as

 struct angle
 {
    short         deg;
    unsigned long fine;
 };

 struct sockaddr_ml
 {
    short        ml_family;
    struct angle ml_lat, ml_long;
 };

We can instead "flatten" this structure tree to obtain the five fields by
naming the sub-members of the outer structure:

 structure "struct sockaddr_ml",
    members => [
       "ml_family"    => member_numeric,
       "ml_lat.deg"   => member_numeric,
       "ml_lat.fine"  => member_numeric,
       "ml_long.deg"  => member_numeric,
       "ml_long.fine" => member_numeric,
    ];

=head1 TODO

=over 4

=item *

Consider more structure members. With strings comes the requirement to have
members that store a size. This requires cross-referential members. And while
we're at it it might be nice to have constant members; fill in constants
without consuming arguments when packing, assert the right value on unpacking.

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
