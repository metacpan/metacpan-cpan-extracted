###############################################################################
#
# Inline::Octave - 
#
# $Id: Octave.pm 7780 2011-02-13 20:16:12Z adler $

package Inline::Octave;

$VERSION = '0.31';
require Inline;
@ISA = qw(Inline);
use Carp;
use IO::Select;
use POSIX 'WNOHANG';
use vars qw( $octave_object );

# set values which should change to this,
# if it doesn't change, we have an error.
# This value is not special, it's a random value thats
# unlikely to be really used
my $retcode_string= "[-101101.101101,-918273.6455,-178.9245867]";
my $retcode_value=   eval $retcode_string;

sub register {
#  print "REGISTERING\n";
   return {
           language    => 'Octave',
           aliases     => ['octave'],
           type        => 'interpreted',
           suffix      => 'm',
          };
}


sub build {
   my $o = shift;
   $o->_build (@_ );
}

sub _build {
#  print "BUILDING\n";
   my $o = shift;
   my $code = $o->{API}{code};

   # we don't really need to validate the code here
   # since that gets done in load anyway
   #
   # Also, stopping the interpreter will make any
   # functions defined in a previous section disappear
   if (0) {
      $o->start_interpreter();
      print $o->interpret($code);
      my @def_funcs= $o->get_defined_functions();
      $o->stop_interpreter();
   }

   croak "Octave build failed:\n$@" if $@;
   my $path = "$o->{API}{install_lib}/auto/$o->{API}{modpname}";
   my $obj = $o->{API}{location};
   $o->mkpath($path) unless -d $path;
   open PERL_OBJ, "> $obj" or croak "Can't open $obj for output\n$!";
   print PERL_OBJ $code;
   close \*PERL_OBJ;
}



sub load {
#  print "LOADING\n";
   my $o = shift;
   $o->_validate();
   
   my $obj = $o->{API}{location};
   open OCTAVE_OBJ, "< $obj" or croak "Can't open $obj for output\n$!";
   
   my $code;
   my %nargouts;
   while (<OCTAVE_OBJ>) {
      if(/\bfunction\s+(.*?=\s*\w*|\w*)\b/) {
         my $pat =$1;
         my $fnam= $1 if $pat =~ /(\w*)$/;
         #TODO make this better - ie loop
         my $nargout=0;
            $nargout= 1 if $pat =~ /^\w+\s*=/;

         if ($pat =~ /^\[([\s\w,]+)\]\s*=/ ) {
            my @fnpat = split /,/, $1;
            foreach (@fnpat) {
               $nargout++ if /^\s*\w+\s*$/;
            }
         }

         $nargouts{$fnam}=$nargout;
      }
      if (/^\s*##\s*Inline::Octave::(\w+)\s*\(nargout=(\d+)\)\s*=>\s*(\w*)/) {
          $o->bind_octave_function( $3, $1, $2 );
      }
      $code.=$_;
   }
   close OCTAVE_OBJ;
#  use Data::Dumper; print Dumper(\%nargouts);
   
   $o->start_interpreter();

   print $o->interpret($code);
   my @def_funcs= $o->get_defined_functions();
   foreach my $funname (@def_funcs) {
      next if defined $octave_object->{FUNCS}->{$funname};
      $o->bind_octave_function( $funname, $funname, $nargouts{$funname} );
   }

   return;
}


sub validate
{
# print "VALIDATING\n";
  my $o = shift;
  $o->_validate( @_ );
}

sub _validate
{
  my $o = shift;

  my $switches= "-qfH";
  my $octave_interpreter_bin;

  $octave_interpreter_bin= 'octave' # _EDITLINE_MARKER_
     unless $octave_object->{INTERP};

  $octave_interpreter_bin = $ENV{PERL_INLINE_OCTAVE_BIN}
     if $ENV{PERL_INLINE_OCTAVE_BIN};

  $octave_object->{INTERP} = "$octave_interpreter_bin $switches " 
     unless $octave_object->{INTERP};

  while (@_) {
     my ($key, $value) = (shift, shift) ;
     if ($key eq 'OCTAVE_BIN'){
        $octave_object->{INTERP} = "$value $switches ";
     } 
#    print "$key--->$value\n";
  }


# choose a random value that's unlikely to appear normally
# This is 50 characters long: 8^50 = 1.43e45 
  $octave_object->{MARKER} = '-9w#wastaal!|j"Ahv8~;/+ua;78<<hs+[uhBa8l_8Onq,zU9-'
     unless exists $octave_object->{MARKER};
}   

sub info
{
#  print "INFO\n";
   my $o = shift;
}


# here we write code to bind to an octave function and eval this
# into the callers namespace
#
# $o->bind_octave_function( octave_funcname, perl_funcname, nargout )
# 
# we need to specify the nargout, because we can't infer
# it from perl (other than scalar or list context)
#
# now, when perl6 comes out ...
#
sub bind_octave_function
{
   my $o= shift;
   my $oct_funname = shift;
   my $perl_funname = shift;
   my $nargout = shift;
   my $pkg= $o->{API}->{pkg};
   my $code = <<CODE;
package $pkg;
sub $perl_funname {
   # we need to prevent IOM variables from going out of scope
   # in the loop, but rather at the end of the function
   
   #input variables
   my \$inargs=" ";
   my \@vin;
   for (my \$i=0; \$i < \@_; \$i++) {
      \$vin[\$i]= Inline::Octave->new( \$_[\$i] );
      \$inargs.= \$vin[\$i]->name.",";
   }
   chop(\$inargs); #remove last ,

   #output variables
   my \$outargs=" ";
   my \@vout;
   for (my \$i=0; \$i < $nargout; \$i++) {
      \$vout[\$i]= Inline::Octave->new( $retcode_string );
      \$outargs.= \$vout[\$i]->name.",";
   }
   chop(\$outargs); #remove last ,
   \$outargs= "[".\$outargs."]=";
   \$outargs= "" if $nargout==0;

   my \$call= "\$outargs $oct_funname(\$inargs);";
#  print "--\$call--\\n";
   my \$retval= Inline::Octave::interpret(0, \$call );
#  print "--\$retval--\\n";

   # Get the correct size for each new variable
   foreach (\@vout) { \$_->store_size(); }

   return \@vout if wantarray();
   return \$vout[0];
}
CODE
  #print "--$code--\n";
   eval $code;
   croak "Problem binding $oct_funname to $perl_funname: $@" if $@;

   $octave_object->{FUNCS}->{$oct_funname}= $perl_funname;
   return;
}   

sub start_interpreter
{
   my $o = shift;

   # check if interpreter already alive
   return if $octave_object->{OCTIN} and $octave_object->{OCTOUT};

   use IPC::Open3;
   use IO::File;
   my $Oin = new IO::File;
   my $Oout= new IO::File;
   my $Oerr= new IO::File;
   my $pid;
   eval {
      $pid= open3( $Oin , $Oout, $Oerr, $octave_object->{INTERP} );
      # set our priority lower than the kid, so that we don't read each
      # character. Experimentally, I've found 3 to be optimum on Linux 2.4.21
      setpriority 0,0, (getpriority 0,0)+10;
   };
   # ignore errors from setpriority if it's not available
   croak "Can't locate octave interpreter: $@\n" if $@ =~ /Open3/i;

   my $select= IO::Select->new($Oout, $Oerr);

# New idea - start octave with 
# use IPC::Run qw(start);
#  my ($Oin, $Oout, $Oerr);
#  my $pid;
#  eval {
#    $pid= start $octave_object->{INTERP}, \$Oin, \$Oout, \$Oerr
#  };
#  croak "Error starting octave interpreter: $@\n" if $@;

   $octave_object->{octave_pid} = $pid;
   $octave_object->{OCTIN} = $Oin;
   $octave_object->{OCTOUT} = $Oout;
   $octave_object->{OCTERR} = $Oerr;
   $octave_object->{SELECT} = $select;

   # some of this is necessary, some are the defaults
   # but it never hurts to be cautious
   my $startup_code= <<STARTUP_CODE;
crash_dumps_octave_core(0);
page_screen_output(0);
silent_functions(1);
page_screen_output(0);
page_output_immediately(1);
warning( "off", "Octave:fortran-indexing" );
warning( "off", "Octave:empty-list-elements" ); 
more off;
suppress_verbose_help_message(1);
STARTUP_CODE

   $o->interpret( $startup_code ); # check return value?

   return;
}

# we get here from a SIG{CHLD} or a SIG{PIPE}.
# if it's the octave process, then we want to deal
# with it, if it isn't, then we want to pass it to
# the calling processes handler. But how can we
# do that reliably?
#
# instead we just reap any dead processes

sub reap_interpreter
{
#  print "REAP_INTERPRETER\n";
   my $o= $octave_object;
   my $pid= $octave_object->{octave_pid};
   return unless $pid;

   if ( waitpid($pid, WNOHANG) > 0 ) {
       $octave_object->{OCTIN} = "";
       $octave_object->{OCTOUT} = "";
       $octave_object->{octave_pid} = "";
   }

   while (
      ( my $reaped = waitpid (-1, WNOHANG) ) > 0
         ) { };

   return;
}   

sub stop_interpreter
{
   my $o = shift;

   my $Oin= $octave_object->{OCTIN};
   my $Oout= $octave_object->{OCTOUT};

   return unless $Oin and $Oout;

   print $Oin "\n\nexit\n";
   #<$Oin>; #clean up input - is this required?
   close $Oin;
   close $Oout;
   $octave_object->{OCTIN} = "";
   $octave_object->{OCTOUT} = "";
   $octave_object->{octave_pid} = "";
   return;
}   

# send a string to octave and get the result
sub interpret
{
   my $o = shift;
   my $cmd= shift;
   my $marker= $octave_object->{MARKER};

   my $Oin=    $octave_object->{OCTIN};
   my $Oerr=   $octave_object->{OCTERR};
   my $select= $octave_object->{SELECT};
   my $pid   = $octave_object->{octave_pid};

   croak "octave interpreter not alive"  unless $Oin and $Oerr;

#  set SIGnals here, and they will be reset to what the
#  user set them to outside
   local $SIG{CHLD}= \&reap_interpreter;
   local $SIG{PIPE}= \&reap_interpreter;

#  print STDERR "INTERP: $cmd\n";
#  $Oin = "\n\n$cmd\ndisp('$marker');fflush(stdout);\n";
#  $pid->pump() while length $Oin;
   print $Oin "\n\n$cmd\ndisp('$marker');fflush(stdout);\n";

   my $input= '';
   my $marker_len= length( $marker )+1;
   while ( 1 ) {
      for my $fh ( $select->can_read() ) {
          if ($fh eq $Oerr) {
              process_errors();
          } else {

              sysread $fh, (my $line), 16386;
              $input.= $line;
              # delay if we're reading nothing, not sure why select doesn't block
              select undef, undef, undef, 0.5 unless $line;
          }
      }
      last if $input && substr( $input, -$marker_len, -1) eq $marker;

#     $pid->pump();

      process_errors() if $Oerr;
#     select undef, undef, undef, 0.5 unless $line;
#     last if substr( $Oout, -$marker_len, -1) eq $marker;
   }   

   # we need to leave octave blocked doing something,
   # otherwise it can't handle a CTRL-C
   print $Oin "\n\nfread(stdin,1);\n";
   return substr($input,0,-$marker_len);
}

# process any input of stderr
# we assume that we will get a line with
# error: or warning:
sub process_errors
{
   my $Oerr=   $octave_object->{OCTERR};
   my $select= IO::Select->new( $Oerr );

   my $input= "\n";
   # to get full error buffer, wait until we have 100ms with
   # not stderr input
   while ( my @fh = $select->can_read(0.1) ) {
      sysread $fh[0], (my $line), 1024;
      last unless $line;
      $input.= $line;
   }

   #parse input, looking for warning and error patterns
#  print STDERR "#########$input########\n";
   my ($error, $warning);
   while ($input =~ /\n (warning:|error:)  \s+
                     (.*?)
                   (?=
                     ( \nwarning: \s+ | \nerror: \s+ | $) ) /gsx) {
       my $type=    $1;
       my $message= $2;
          $message=~ s/[\012\015]+/ /gs; # turn newlines into spaces
       if ($type eq "error:") {
           $error.=   $message."; " if $message;
       } else {
           $warning.= $message."; " if $message;
       }
   }
   carp  "Warning: $warning (in octave code)" if $warning;
   croak "Error: $error (in octave code)"   if $error;
}


# usage:
# with return values:
#   run_math_code ( $code, $val1, $val2 ... )
# without return values:
#   run_math_code ( $code )
#    
# dies on error, no return
sub run_math_code
{
   my $code= shift;
   my @v   = @_;

   if (@v) {
      my $vname= $v[0]->name;
      $code.= "; disp (size($vname)==[3,1] && ".
                " all($vname==$retcode_string') );\n";
   } else {
      $code.= "; disp (0);\n";
   }

   my $retval= Inline::Octave::interpret(0, $code );

   if ($retval == 0) {
      foreach my $v (@v) {
         $v->store_size();
      }
   } else {
      croak "Error performing operation $code";
   }
}

sub get_defined_functions
{
   my $o = shift;
   my $data= $o->interpret("__dump_symtab_info__('functions')");
   my @funclist;
   $compiled_fns_marker= 0;
   while ( $data =~ /(.+)/g )
   {
      my $line= $1;
      if ( $line =~ /^\s+(.+) \[c\]/ ) {
        push @funclist, $1;
      }
   }
   return @funclist;

}       

END {
#  print "ENDING\n";
   Inline::Octave::stop_interpreter() if $octave_object;
}

# define a generic Inline::Octave->new
# which will figure out which class best suits the
# new object
# This is not OO. It directly calls the other packages,
# but the idea is to put all the non OO stuff here.

sub fix_octave_type
{
    my $m = shift;
    if    ($m->{"complex"}) {
        return Inline::Octave::ComplexMatrix->new($m);
    }
    elsif ($m->{"string"}) {
        return Inline::Octave::String->new($m);
    }
    else {
        return Inline::Octave::Matrix->new($m);
    }
}

# an Inline::Octave object is created here.
# We try to switch to the correct underlying object
sub new
{
   my $class = shift;
   my ($m, $rows, $cols) = @_;

   if ( ref($m) =~ /^Inline::Octave::/ ) {
      return fix_octave_type($m);
   }
   elsif ((ref $m eq "ARRAY") ||
          (ref $m eq "Math::Complex" ) ||
          (ref $m eq "" ) ) {
          # here we have data or numbers, we write it
          # to a complex matrix just in case
          # the fix_octave_type will set it correctly afterwards
      return fix_octave_type( Inline::Octave::ComplexMatrix->new($m) );
   } else {
      croak "Can't construct Inline::Octave from Perl var of type:".ref($m);
   }
} #new - no return required at end

#
# Inline::Octave::String contains the code
# to handle octave String objects
#
# called as
# new IOS( "string" )
# new IOS( ["1","2","3"] ) -> Strings as Matrix Rows
package Inline::Octave::String;
@ISA= qw( Inline::Octave::Variable);
use Carp;

$varcounter= 30000001;

sub new
{
   my $class = shift;
   my ($m, $rows, $cols) = @_;
   my $self = {};
   bless ($self, $class);

   my $varname= "sname_".$varcounter++;
   $self->{varname}= $varname;

   my $code;
   my @vals;

   if    (ref $m      eq "Inline::Octave::String") {
      my $prev_varname= $m->{varname};
      $code= "$varname= $prev_varname;";
   }
   elsif (ref $m eq "ARRAY" ) {
      # 1 dimentional array;
      $rows= @$m unless defined $rows;
      $cols= 1 unless defined $cols;
      @vals= @{$m};
   }
   elsif (ref $m eq "" ) {
      $rows= 1 unless defined $rows;
      $cols= 1 unless defined $cols;
      @vals = ($m);
   } else {
      croak "Can't construct String from Perl var of type:".ref($m);
   }

   unless ($code) {
      croak "String Matrix is not size ${cols}x${rows}" unless
             @vals == $rows*$cols ;

      $code= "$varname=[ ...\n";
      $code.= "'$_';\n" for @vals;
      $code.= "];\n";
   }

   Inline::Octave::interpret(0, $code );

   $self->store_size();

   return $self;
}   

package Inline::Octave::Math::Complex;
use Math::Complex;

# HACK ALERT
# We can't use Math::Complex directry, because it doesn't give
# us any way to not polute our namespace, and since
# we define many of the same things, such as sqrt.
#    This seems to break the inheritance model.
# ie. If Inline::Octave::Matrix calls the sqrt function,
# wanting to overload from Inline::Octave, it instead
# gets its sqrt from Math::Complex. 
#    So the plan is to use Math::Complex from a throw
# away namespace. Then have utity functions call into
# if from our real namespace.

package Inline::Octave::ComplexMatrix;
use Carp;
@ISA= qw(Inline::Octave::Matrix Inline::Octave::Variable);

sub cplx { return Inline::Octave::Math::Complex::cplx(@_) };
sub Re   { return Inline::Octave::Math::Complex::Re  (@_) };
sub Im   { return Inline::Octave::Math::Complex::Im  (@_) };


sub write_out_matrix {
   my $self=  shift;
   my $rows=  shift;
   my $cols=  shift;
   my $vals=  shift;
   my $trans= shift;
   my $vname= shift;

   my (@real, @imag);
   for (@$vals) {
      push @real, Re( $_ );
      push @imag, Im( $_ );
   }

   my $code= "$vname=fread(stdin,[$rows,$cols],'double')$trans +".
                    "fread(stdin,[$rows,$cols],'double')$trans*I;\n".
             pack( "d".($rows*$cols*2) , ( @real, @imag)  );
   return $code;
}



#
# Inline::Octave::Matrix contains the code
# to handle octave Matrix objects
#
# called as
# new IOM( [1,2,3] ) -> ColumnVector
# new IOM( [[1,2],[2,3],[3,4]] ) -> Matrix
# new IOM( [1,2,3,4], 2, 2) -> Matrix, rows, cols
package Inline::Octave::Matrix;
use Carp;
@ISA= qw(Inline::Octave::Variable);
sub cplx { return Inline::Octave::Math::Complex::cplx(@_) };
sub Re   { return Inline::Octave::Math::Complex::Re  (@_) };
sub Im   { return Inline::Octave::Math::Complex::Im  (@_) };

$varcounter= 10000001;

sub new
{
   my $class = shift;
   my ($m, $rows, $cols) = @_;
   my $self = {};
   bless ($self, $class);

   my $varname= "mname_".$varcounter++;
   $self->{varname}= $varname;

   my @vals;
   my $do_transpose= '';
   my $code;

   my $ref_m= ref($m);

   if  ( $ref_m =~ /^Inline::Octave::/ ) {
      my $prev_varname= $m->{varname};
      $code= "$varname= $prev_varname;";
   }
   elsif ($ref_m      eq "ARRAY" and
          ref $m->[0] eq "ARRAY" ) {
      # 2 dimentional array -  ensure all rows are equal size;
      @vals= map {
                    if ($cols) {
                       croak "specified cols is length ${@$_} not $cols"
                          unless $cols== @$_;
                    } else {
                       $cols = @$_;
                    };
                    @$_
                 } @$m;
      $rows= @$m unless defined $rows;
      $do_transpose= q(');
      ($rows,$cols)= ($cols,$rows);
   }
   elsif ($ref_m eq "ARRAY" ) {
      # 1 dimentional array;
      $rows= @$m unless defined $rows;
      $cols= 1 unless defined $cols;
      @vals= @{$m};
   }
   elsif ( ($ref_m eq "") or
           ($ref_m eq "Math::Complex") ) {
          # here we have data or numbers
      $rows= 1 unless defined $rows;
      $cols= 1 unless defined $cols;
      @vals = ($m);
   } else {
      croak "Can't construct Matrix from Perl var of type:".ref($m);
   }

   # pack data into doubles and use fread to grab it from octave
   # since octave is column major and nested lists in perl are
   # row major, we need to do the transpose.
   unless ($code) {
      croak "Matrix is not size ${cols}x${rows}" unless
             @vals == $rows*$cols ;

      $code= $self->write_out_matrix( $rows,$cols,\@vals, $do_transpose, $varname );
   }
   Inline::Octave::interpret(0, $code );

   $self->store_size();

   return $self;
   tie @array, $class, $self;
   return \@array;
}

sub TIEARRAY {
    my $class = shift;
    my $self  = shift;
    return bless $self, $class;
}

# fetch index is perl style (0 based), not octave style (1 based)
sub FETCH {
    my $self = shift;
    my $index= shift() +1;
    my $size = $self->{rows} * $self->{cols};
    croak "index ($index) exceeds matrix size ($size)"
       unless $index>0 && $index<=$size;
    return $self->read_back_matrix("($index)")->[0];
}

sub FETCHSIZE {
    my $self = shift;
    return $self->{rows} * $self->{cols};
}

sub STORE {
    die "can't store";
}

sub STORESIZE {
    my $self = shift;
    croak "can't change size of ".ref($self)." variables";
}

sub EXISTS {
    my $self = shift;
    my $index= shift() +1;
    my $size = $self->{rows} * $self->{cols};
    return 1 if $index>0 && $index<=$size;
    return 0;
}

sub write_out_matrix {
   my $self=  shift;
   my $rows=  shift;
   my $cols=  shift;
   my $vals=  shift;
   my $trans= shift;
   my $vname= shift;

   my $code= "$vname=fread(stdin,[$rows,$cols],'double')$trans;\n".
             pack( "d".($rows*$cols) , @$vals );
   return $code;
}

package Inline::Octave::Variable;
use Carp;
sub cplx { return Inline::Octave::Math::Complex::cplx(@_) };
sub Re   { return Inline::Octave::Math::Complex::Re  (@_) };
sub Im   { return Inline::Octave::Math::Complex::Im  (@_) };

sub rows
{
   my $self= shift;
   return $self->{rows};
}

sub cols
{
   my $self= shift;
   return $self->{cols};
}

sub max_dim
{
   my $self= shift;
   my $rows= $self->{rows};
   my $cols= $self->{cols};

   return ( $rows > $cols ) ? $rows : $cols ;
}

sub elements
{
   my $self= shift;
   return $self->{cols} * $self->{rows};
}

sub store_size
{
   my $self = shift;
   my $varname= $self->name;
   my $code = "disp([size($varname), iscomplex($varname), ischar($varname)] )";
   my $size=  Inline::Octave::interpret(0, $code );
   croak "Problem constructing Matrix" unless
       $size =~ /^ +(\d+) +(\d+) +([01]) +([01])/;
   $self->{rows}= $1;
   $self->{cols}= $2;
   $self->{complex}= $3;
   $self->{string}= $4;
}             

sub read_back_matrix {
   my $self   = shift;
   my $extra  = shift || "";
   my $varname= $self->name;
   my @list;
   if ( $self->{complex} ) {
      my $code = "fwrite(stdout, real( $varname$extra ),'double');".
                 "fwrite(stdout, imag( $varname$extra ),'double');";
      my $retval= Inline::Octave::interpret(0, $code );
      my $half  = length( $retval ) /2;
      my $size= $self->elements();
      my @real= unpack "d$size", substr( $retval,     0, $half);
      my @imag= unpack "d$size", substr( $retval, $half, $half);
      for (my $i=0; $i< $size ; $i++ ) {
         if ($imag[$i] == 0 ) {
            push @list, $real[$i];
         } else {
            push @list, cplx( $real[$i], $imag[$i] );
         }
      }
   } else { # not complex
      my $code = "fwrite(stdout, $varname$extra,'double');";
      my $retval= Inline::Octave::interpret(0, $code );
      my $size= $self->elements();
      @list= unpack "d$size", $retval;
   };
   return \@list;
}

sub as_list
{
   my $self = shift;
   my $list = $self->read_back_matrix();
   return @$list;
}

# convert list to matrix: $list, $cols, $rows
sub list_to_matrix
{
    my $list= shift;
    my @idx = @_;
    if    ( @idx==1 || $idx[0]==1 || $idx[1]==1 ){
        return $list;
    }
    elsif ( @idx==2 ){
       my @m;
       for (0..$idx[1]-1) {
          my @index= $_*$idx[0] .. ($_+1)*$idx[0]-1;
          push @m, [ @$list[@index] ];
       }
       return \@m;
    }
    else {
        die "can't handle more than 2D matrices"
    }
}

sub as_matrix
{
   my $self = shift;
   return list_to_matrix(
       $self->read_back_matrix("'"),
       $self->cols(),
       $self->rows() );
}

# $oct_var->sub_matrix( $row_spec, $col_spec )
sub idx { return sub_matrix( @_ ) }
sub sub_matrix
{
   my $self = shift;

   my @specv; my @specn;
   for ( @_ ) {
       my $specv = new Inline::Octave( $_ );
       my $specn = $specv->name;
       push @specv, $specv;
       push @specn, $specn;
   }

   my $spec= "(". join(",",@specn). ")'";
   my @list= @{ $self->read_back_matrix( $spec ) };
   my @m;
   my $cols= $specv[0]->max_dim();
   my $rows= $specv[1]->max_dim();
   for (0..$cols-1) {
      push @m, [ (@list)[$_*$rows .. ($_+1)*$rows-1] ];
   }
   return \@m;
   return list_to_matrix(
       $self->read_back_matrix("'"),
       map { $_->max_dim() } @specv );
}


sub as_scalar
{
   my $self = shift;
   croak "requested as_scalar for non scalar value:".
           $self->cols()."x".$self->rows()
           unless $self->cols() == 1 && $self->rows() == 1;
   my $list = $self->read_back_matrix();
   return $list->[0];
}   

sub DESTROY
{
   my $self = shift;
#  use Data::Dumper; print "DESTROYing ". Dumper($self)."\n";
   my $varname= $self->name;
   my $code = "clear $varname;";
   Inline::Octave::interpret(0, $code );
}   

sub disp
{
   my $self = shift;
   my $varname= $self->name;
   my $code = "disp( $varname );";
   my $retval= Inline::Octave::interpret(0, $code );
   chomp ($retval);
   return $retval;
}   

sub name
{
   my $self = shift;
   return $self->{varname};
}   


#
# Define arithmetic on IOMs 
#
use overload 
    '+' => sub { oct_matrix_arithmetic( @_, '+',  ) },
    '-' => sub { oct_matrix_arithmetic( @_, '-',  ) },
    '*' => sub { oct_matrix_arithmetic( @_, '.*', ) },
    '/' => sub { oct_matrix_arithmetic( @_, './', ) },
    'x' => sub { oct_matrix_arithmetic( @_, '*',  ) };

sub oct_matrix_arithmetic
{
   my $a= Inline::Octave->new( shift );
   my $b= Inline::Octave->new( shift );
   ($b,$a)= ($a,$b) if shift;
   my $op= shift;

   my $v= Inline::Octave->new( $retcode_value );

   my $code= $v->name."=". $a->name ." $op ". $b->name .';';
   Inline::Octave::run_math_code( $code, $v);
   return Inline::Octave->new($v);
}   

# usage
# $a= new Inline::Octave ( ...)
# $b= $a->transpose();
sub transpose
{
   my $a= new Inline::Octave( shift );
   my $v= new Inline::Octave( $retcode_value );
   my $code= $v->name."=". $a->name.".';";
   Inline::Octave::run_math_code( $code, $v);
   return $v;
}  

# usage
# $a = Inline::Octave::zeros(4);
# $a->replace_rows( [1,3], [ [1,2,3,4],[5,6,7,8] ] );
sub replace_rows
{
   my $a= shift;
   my $b= new Inline::Octave( shift );
   my $c= new Inline::Octave( shift );
   my $code= $a->name."(". $b->name.",:)= ".$c->name.";";
   Inline::Octave::run_math_code( $code );
   return;
}

# usage
# $a = Inline::Octave::zeros(4);
# $a->replace_cols( [2,4], [ [2,4],[2,4],[2,4],[2,4] ] );
sub replace_cols
{
   my $a= shift;
   my $b= new Inline::Octave( shift );
   my $c= new Inline::Octave( shift );
   my $code= $a->name."(:,". $b->name.")= ".$c->name.";";
   Inline::Octave::run_math_code( $code );
   return;
}

# usage
# $a = Inline::Octave::zeros(4);
# $a->replace_matrix( [1,4], [1,4], [ [8,7],[6,5] ] );
sub replace_matrix
{
   my $a= shift;
   my $b= new Inline::Octave( shift );
   my $c= new Inline::Octave( shift );
   my $d= new Inline::Octave( shift );
   my $code= $a->name."(". $b->name." , ".$c->name.")= ".$d->name.";";
   Inline::Octave::run_math_code( $code );
   return;
}

#
# create methods for the various math functions
#

# include guard
BEGIN{$Inline::Octave::methods_defined=0;}
unless ($Inline::Octave::methods_defined) {
   $Inline::Octave::methods_defined=1;

   my %methods= (
      abs           => 1, acos          => 1, acosh         => 1,
      all           => 1, angle         => 1, any           => 1,
      asin          => 1, asinh         => 1, atan          => 1,
      atan2         => 1, atanh         => 1, ceil          => 1,
      conj          => 1, cos           => 1, cosh          => 1,
      cumprod       => 1, cumsum        => 1, diag          => 1,
      erf           => 1, erfc          => 1, exp           => 1,
      eye           => 1, finite        => 1, fix           => 1,
      floor         => 1, gamma         => 1, gammaln       => 1,
      imag          => 1, islogical     => 1, iscomplex     => 1,
      isglobal      => 1, islist        => 1, ismatrix      => 1,
                        , isstruct      => 1, isalnum       => 1,
      isalpha       => 1, isascii       => 1, iscell        => 1,
      iscntrl       => 1, isdigit       => 1, isempty       => 1,
      isfinite      => 1, isieee        => 1, isinf         => 1,
      islogical     => 1, isnan         => 1, isnumeric     => 1,
      isreal        => 1, length        => 1, lgamma        => 1,
      linspace      => 1, log           => 1, log10         => 1,
      logspace      => 1, ones          => 1, prod          => 1,
      rand          => 1, randn         => 1, real          => 1,
      round         => 1, sign          => 1, sin           => 1,
      sinh          => 1, size          => 2, sqrt          => 1,
      sum           => 1, sumsq         => 1, tan           => 1,
      tanh          => 1, zeros         => 1,
   );

   # methods to export to Inline::Octave namespace
   my %export_methods= (
    "eye"      =>1, "linspace" =>1, "logspace" =>1,
    "ones"     =>1, "rand"     =>1, "randn"    =>1,
    "zeros"    =>1, );

   for my $meth ( sort keys %methods ) {
      no strict 'refs';
      no warnings 'redefine';
      my $nargout= $methods{$meth};
      *$meth = sub {
         my $code= "[";

         my @v;
         foreach (1..$nargout) {
            my $v= new Inline::Octave( $retcode_value );
            $code.= $v->name.",";
            push @v,$v;
         }
         chop ($code); #remove last ','
         $code.= "]= $meth (";

         my @a;
         foreach (@_) {
            my $a= new Inline::Octave( $_ );
            $code.= $a->name.",";
            push @a, $a;
         }
         chop ($code); #remove last ','
         $code.= ");";

         Inline::Octave::run_math_code( $code, @v);
         return @v if wantarray();
         return $v[0];
      };
      
      my $IOmeth= "Inline::Octave::$meth";
      *$IOmeth = *$meth if $export_methods{$meth};
   }
}

1;


__END__

TODO LIST:

   1. Add import for functions
   2. control matrix size inputs
   3. add destructor for Octave::Matrix
       - done
   4. control waiting in the interpret loop
       - seems ok, except sysread reads small buffers
   5. support for complex variables
       - done
   6. octave gets wierd when you CTRL-C out of a 
       running program
       - seems ok
   7. Use parse-recdecent to parse octave code
   8. Come up with an OO way to avoid
       Inline::Octave::interpret(0, $code );
   9. Add support for passing Strings to Octave
        - done
  10. Errors in Octave should die in perl
       - this involves a tricky Open3 read of stderr.
  11. Refactor out the common code in Inline::Octave::Matrix
       into an Inline::Octave::Variable class
       - done

$Log: Octave.pm,v $
Revision 1.29  2005/03/07 21:45:15  aadler
fixes for versions

Revision 1.28  2005/03/07 20:20:45  aadler
version accepts \d.\d\.cvs

Revision 1.27  2004/10/11 13:15:48  aadler
warning in $input testing

Revision 1.26  2004/04/15 22:06:27  aadler
*** empty log message ***

Revision 1.25  2004/04/12 17:11:17  aadler
added wnohang signalling

Revision 1.24  2004/04/12 16:12:07  aadler
set SIGnals only when doing a read

Revision 1.23  2003/12/04 19:22:27  aadler
working errors and warnings

Revision 1.22  2003/12/04 18:20:07  aadler
does warnings right

Revision 1.21  2003/12/03 16:46:31  aadler
move to IO::Variable class

Revision 1.20  2003/12/01 03:46:21  aadler
tried to tie to an array ref. Didn't work

Revision 1.19  2003/11/30 14:33:02  aadler
cleanups of OO interface

Revision 1.18  2003/03/20 03:40:26  aadler
fix whos handling

Revision 1.17  2003/01/07 02:47:49  aadler
mods to remove warnings from tests

Revision 1.16  2002/10/29 03:59:29  aadler
improved complex code

Revision 1.15  2002/05/01 02:19:40  aadler
Initial work to add Inline::Octave::ComplexMatrix

Revision 1.14  2002/03/08 21:15:34  aadler
Mods to add sub_matrix, and OO type cleanups

Revision 1.13  2002/01/19 01:08:35  aadler
new docs and new matrix methods

Revision 1.12  2002/01/17 01:28:33  aadler
added Inline::Octave::String

Revision 1.11  2001/11/21 03:20:54  aadler
fixed make bug, added method support for IOMs

Revision 1.10  2001/11/20 02:38:05  aadler
fix for select octave path in Makefile.PL

Revision 1.8  2001/11/18 03:29:06  aadler
bug in fread fix - add \n

Revision 1.7  2001/11/18 03:22:42  aadler
multisections now ok, cleaned up singleton object,
octave no longer freaks out on ctrl-c

Revision 1.6  2001/11/17 02:15:21  aadler
changed docs, new options for Makefile.PL

Revision 1.5  2001/11/11 03:36:31  aadler
mod to work with octave-2.0 as well as 2.1

Revision 1.4  2001/11/11 03:00:54  aadler
added makefile and tests
added as_scalar method


=head1 NAME

Inline::Octave - Inline octave code into your perl


=head1 SYNOPSIS

   use Inline Octave => DATA;
   
   $f = jnk1(3);
   print "jnk1=",$f->disp(),"\n";

   $c= new Inline::Octave([ [1.5,2,3],[4.5,1,-1] ]);
   
   ($b, $t)= jnk2( $c, [4,4],[5,6] );
   print "t=",$t->as_list(),"\n";
   use Data::Dumper; print Dumper( $b->as_matrix() );
   
   print oct_sum( [1,2,3] )->disp();

   oct_plot( [0..4], [3,2,1,2,3] );
   sleep(2);

   my $d= (2*$c) x $c->transpose;
   print $d->disp;
   
   
   __DATA__
   
   __Octave__
   function x=jnk1(u); x=u+1; endfunction
   
   function [b,t]=jnk2(x,a,b);
      b=x+1+a'*b;
      t=6;
   endfunction
   
   ## Inline::Octave::oct_sum (nargout=1)  => sum
   ## Inline::Octave::oct_plot (nargout=0)  => plot

=head1   WARNING

THIS IS ALPHA SOFTWARE. It is incomplete and possibly unreliable.  It is
also possible that some elements of the interface (API) will change in
future releases. 

=head1 DESCRIPTION

Inline::Octave gives you the power of the octave programming language from
within your Perl programs.

Basically, I create an octave process with controlled stdin and stdout.
Commands send by stdin. Data is send by stdin and read with
fread(stdin, [dimx dimy], "double"), and read similarly.
                   
Inline::Octave variables in perl are tied to the octave
variable. When a destructor is called, it sends a "clear varname"
command to octave.

Additionally, there are Inline::Octave::ComplexMatrix and 
Inline::Octave::String types for the corresponding variables.
                   
I initially tried to bind the C++ and liboctave to perl, but
it started to get really hard - so I took this route.
I'm planning to get back to that eventually ...

=head1 INSTALLATION

=head2 Requirements

  perl 5.005  or newer
  Inline-0.40 or newer
  octave 3.2  or newer

=head2 Platforms

  I've succeded in getting this to work on win2k (activeperl), 
  win2k cygwin (but Inline-0.43 can't install Inline::C)
  and linux (Mandrake 8.0, Redhat 6.2, Debian 2.0).

  Note that Inline-0.43 can't handle spaces in your path -
  this is a big pain for windows users.
  
  Please send me tales of success or failure on other platforms

=head2 Install Proceedure  

You need to install the Inline module from CPAN. This provides
the infrastructure to support all the Inline::* modules.

Then:
   
   perl Makefile.PL
   make 
   make test
   make install

This will search for an octave interpreter and give you
the choice of giving the path to GNU Octave.

If you don't want this interactivity, then specify

   perl Makefile.PL OCTAVE=/path/to/octave
      or
   perl Makefile.PL OCTAVE='/path/to/octave -my -special -switches'

The path to the octave interpreter can be set in the following
ways:

   - set OCTAVE_BIN option in the use line

      use Inline Octave => DATA => OCTAVE_BIN => /path/to/octave

   - set the PERL_INLINE_OCTAVE_BIN environment variable
 
=head1 Why would I use Inline::Octave

If you can't figure out a reason, don't!

I use it to grind through long logfiles (using perl),
and then calculate mathematical results (using octave).

Why not use PDL?

   1) Because there's lots of existing code in Octave/Matlab.
   2) Because there's functionality in Octave that's not in PDL.
   3) Because there's more than one way to do it.

=head1 Using Inline::Octave

The most basic form for using Inline is:
  
   use Inline Octave => "octave source code";
             
The source code can be specified using any of the following syntaxes:

   use Inline Octave => 'DATA';
   ...perl...                                                                    
   __DATA__
   __Octave__
   ...octave...

or,

   use Inline Octave => <<'ENDOCTAVE';
   ...octave...
   ENDOCTAVE
   ...perl...

or,

   use Inline Octave => q{
   ...octave...
   };
   ...perl...

=head2 Defining Functions

Inline::Octave lets you:

1) Talk to octave functions using the syntax

   ## Inline::Octave::oct_plot (nargout=0)  => plot

Here oct_plot in perl is bound to plot in octave.
It is necessary to specify the nargouts required
because we can't get this information from perl.
(although it's promised in perl6)

If you need to use various nargouts for a function,
then bind different functions to it:

   ## Inline::Octave::eig1 (nargout=1)  => eig
   ## Inline::Octave::eig2 (nargout=2)  => eig

2) Write new octave functions,    

      function s=add(a,b);
         s=a+b;
      endfunction

will create a new function add in perl bound
to this new function in octave.

=head2 Calling Functions

A function is called using

   (list of Inline::Octave::Matrix) =
      function_name (list of Inline::Octave::Matrix)

Parameters which are not Inline::Octave::Matrix 
variables will be cast (if possible).

Values returned will need to be converted
into perl values if they need to be used within the
perl code. This can be accomplished using:

1. $oct_var->disp()

Returns a string of the disp output from octave
This provides a formatted representation, and should mostly
be useful for debugging.

2. $oct_var->as_list()

Returns a perl list, corresponding to the
ColumnVector for octave "oct_var(:)"

3. $oct_var->as_matrix()

Returns a perl list of list, of the
form

   $var= [ [1,2,3],[4,5,6],[7,8,9] ];


4. $oct_var->as_scalar()

Returns a perl scalar if $oct_var
is a 1x1 matrix, dies with an error otherwise

5. $oct_var->sub_matrix( $row_spec, $col_spec )
Returns the sub matrix specified

    $x= Inline::Octave->new([1,2,3,4]);
    $y=$x x $x->transpose();
    $y->sub_matrix( [2,4], [2,3] )'

    gives:  [ [4,6],[8,9] ]

=head1 Using Inline::Octave variables

Inline::Octave::Matrix is the matrix class that "ties"
matrices held by octave to perl variables.

Values can be created explicitly, using the syntax:

   $var= new Inline::Octave([ [1.5,2,3],[4.5,1,-1] ]);

or 

   $var= Inline::Octave->new([ [1.5,2,3],[4.5,1,-1] ]);

or values will be automatically created by 
calling octave functions.

If your code only uses matrixes, and does not need to define
any octave functions, then the following initialization
syntax may be useful:

    use Inline Octave =>" ";

=head1 Operations on Inline::Octave::Matrix -es

Many math operations have been overloaded to
work directly on Inline::Octave::Matrix values;

For example, given $var above, we can calculate:

   $v1= ( $var x $var->transpose );
   $v2=  2*$var + 1
   $v3=  $var x [ [1],[2] ];

The relation between Perl and Octave operators is:   

      '+' => '+',
      '-' => '-',
      '*' => '.*',
      '/' => './',
      'x' => '*',

=head1 Methods on Inline::Octave::Matrix -es

Methods can be called on Inline::Octave::Matrix
variables, and the underlying octave function is called.

for example:

   my $b= new Inline::Octave( 1 );
   $s= 4 * ($b->atan());
   my $pi=  $s->as_scalar;

Is a labourious way to calculate PI.

Additionally, it is possible to call these as functions
instead of methods

for example:

   $c= Inline::Octave::rand(2,3);
   print $c->disp();

gives:

  0.23229  0.50674  0.25243
  0.96019  0.17037  0.39687


The following methods are available, the corresponding
number is the output args available (nargout).

      abs         => 1   acos        => 1   acosh       => 1  
      all         => 1   angle       => 1   any         => 1  
      asin        => 1   asinh       => 1   atan        => 1  
      atan2       => 1   atanh       => 1   ceil        => 1  
      conj        => 1   cos         => 1   cosh        => 1  
      cumprod     => 1   cumsum      => 1   diag        => 1  
      erf         => 1   erfc        => 1   exp         => 1  
      eye         => 1   finite      => 1   fix         => 1  
      floor       => 1   gamma       => 1   gammaln     => 1  
      imag        => 1   is_bool     => 1   is_complex  => 1  
      is_global   => 1   is_list     => 1   is_matrix   => 1  
      is_stream   => 1   is_struct   => 1   isalnum     => 1  
      isalpha     => 1   isascii     => 1   iscell      => 1  
      iscntrl     => 1   isdigit     => 1   isempty     => 1  
      isfinite    => 1   isieee      => 1   isinf       => 1  
      islogical   => 1   isnan       => 1   isnumeric   => 1  
      isreal      => 1   length      => 1   lgamma      => 1  
      linspace    => 1   log         => 1   log10       => 1  
      logspace    => 1   ones        => 1   prod        => 1  
      rand        => 1   randn       => 1   real        => 1  
      round       => 1   sign        => 1   sin         => 1  
      sinh        => 1   size        => 2   sqrt        => 1  
      sum         => 1   sumsq       => 1   tan         => 1  
      tanh        => 1   zeros       => 1  

=head2 Manipulating Inline::Octave::Matrix -es

If you would like to do the octave equivalent of

   a=zeros(4);
   a( [1,3] , :)= [ 1,2,3,4 ; 5,6,7,8 ];
   a( : , [2,4])= [ 2,4; 2,4; 2,4; 2,4 ];
   a( [1,4],[1,4])= [8,7;6,5];

Then these methods will make life more convenient.

   $a = Inline::Octave::zeros(4);
   $a->replace_rows( [1,3], [ [1,2,3,4],[5,6,7,8] ] );
   $a->replace_cols( [2,4], [ [2,4],[2,4],[2,4],[2,4] ] );
   $a->replace_matrix( [1,4], [1,4], [ [8,7],[6,5] ] );

=head1 Using Inline::Octave::ComplexMatrix

Inline::Octave::ComplexMatrix should work very similarly
to Inline::Octave::Matrix's.  The perl Math::Complex type
is used to map octave complex numbers.

Note, however, that the Math::Complex type in perl is heavy
- it takes lots of memory and time compared to the native
implementation in Octave.

   use Math::Complex;
   my $x= Inline::Octave::ComplexMatrix->new([1,1,2,3 + 6*i,4]);
   print $x->disp();

=head1 Using Inline::Octave::String

Inline::Octave::String is a subclass of Inline::Octave::Matrix
used for octave strings.  It is required because there is
no way to explicity create a string from Inline::Octave::Matrix.

Example:

   use Inline Octave => q{
      function out = countstr( str )
         out= "";
         for i=1:size(str,1)
            out= [out,sprintf("idx=%d row=(%s)\n",i, str(i,:) )];
         end
      endfunction
   };

   $str= new Inline::Octave::String([ "asdf","b","4523","end" ] );
   $x=   countstr( $str );
   print $x->disp();

=head1 PERFORMANCE

Performance should be almost as good as octave alone.
The only slowdown is passing large variables across the
pipe between perl and octave - but this should be much
faster than any actual computations.

By using the strengths of both languages, it should be
possible to run faster than in each. (ie using octave
for matrix operations, and running loops and text
stuff in perl)

One performance issue is Complex matrix math in perl. 
The perl Math::Complex type is quite heavy, and for 
large matrices this work is done for each element.
You should try to do the complex stuff in octave,
and only pull back small matrices into perl.


=head1 AUTHOR

Andy Adler   adler at site dot uottawa dot ca


=head1 COPYRIGHT

(c) 2003-2011, Andy Adler
with help from Andreas Krause

All Rights Reserved. This module is free software. It may be used,
redistributed and/or modified under the same terms as Perl itself.



