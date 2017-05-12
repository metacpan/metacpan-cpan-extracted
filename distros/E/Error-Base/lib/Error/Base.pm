package Error::Base;
#=========# MODULE USAGE
#~ use Error::Base;                # Simple structured errors with full backtrace
#~ 

#=========# PACKAGE BLOCK
{   #=====# Entire package inside bare block, not indented....

use 5.008008;
use strict;
use warnings;
use version; our $VERSION = qv('v1.0.2');

# Core modules
use overload                    # Overload Perl operations
    '""'    => \&_stringify,
    ;
use Scalar::Util;               # General-utility scalar subroutines

# CPAN modules

# Alternate uses
#~ use Devel::Comments '###', ({ -file => 'debug.log' });                   #~

## use
#============================================================================#

# Pseudo-globals

# Compiled regexes
our $QRFALSE            = qr/\A0?\z/            ;
our $QRTRUE             = qr/\A(?!$QRFALSE)/    ;

our $BASETOP            = 2;    # number of stack frames generated internally
# see also global defaults set in accessors

#----------------------------------------------------------------------------#

#=========# OPERATOR OVERLOADING
#
#   _stringify();     # short
#       
# Purpose   : Overloads stringification.
# Parms     : ____
# Reads     : ____
# Returns   : ____
# Writes    : ____
# Throws    : ____
# See also  : ____
# 
# ____
# 
sub _stringify {
#   my ($self, $other, $swap) = @_;
    my ($self, undef,  undef) = @_;
    
    no warnings 'uninitialized';
    if ( defined $self->{-lines} ) {
        return join qq{\n}, @{ $self->{-lines} }, q{};
    }
    else {
        return 'Error::Base internal error: stringifying unthrown object';
    };
        
}; ## _stringify

#=========# INTERNAL ROUTINE
#
#    @lines      = $self->_trace(               # dump full backtrace
#                    -top      => 2,            # starting stack frame
#                );
#       
# Purpose   : Full backtrace dump.
# Parms     : -top  : integer   : usually set at init-time
# Returns   : ____
# Writes    : $self->{-frames}  : unformatted backtrace
# Throws    : 'excessive backtrace'
# See also  : _fuss(), _paired()
# 
# ____
# 
sub _trace {
    my $self        = shift;
    my %args        = _paired(@_);
    my $i           = defined $args{-top} ? $args{-top} : 1;
    
    my $bottomed    ;
    my @maxlen      = ( 1, 1, 1 );  # starting length of each field
    my @f           = (             # order in which keys will be dumped
        '-sub',
        '-line',
        '-file',
    );
    my $pad         = q{ };         # padding for better formatting
    my $in          ;               # usually 'in '
    
    my @frames      ;               # unformatted AoH
    my @lines       ;               # formatted array of strings
    
    # Get each stack frame.
    while ( not $bottomed ) {
        my $frame           ;
        
        # Get info for current frame.
        ( 
            $frame->{-package}, 
            $frame->{-file}, 
            $frame->{-line}, 
            undef, 
            undef, 
            undef, 
            $frame->{-eval} 
        )                   = caller( $i );
        
        # caller returns this from the "wrong" viewpoint
        ( 
            undef, 
            undef, 
            undef, 
            $frame->{-sub}, 
            undef, 
            undef, 
            undef, 
        )                   = caller( $i + 1 );
        
        # Normal exit from while loop.
        if ( not $frame->{-package} ) {
            $bottomed++;
            last;
        };
        
        # Clean up bottom frame.
        if ( not $frame->{-sub} ) {
            $frame->{-sub}      = q{};
            $frame->{-bottom}   = 1;
        };
        
        # Get maximum length of each field.
        for my $fc ( 0..$#f ) {
            $maxlen[$fc]    = $maxlen[$fc] > length $frame->{$f[$fc]}
                            ? $maxlen[$fc]
                            : length $frame->{$f[$fc]}
                            ;
        };
        
        # Clean up any eval text.
        if ($frame->{-eval}) {
            # fake newlines for hard newlines
            $frame->{-eval}     =~ s/\n/\\n/g;
        };
        push @frames, $frame;
        
        # Safety exit from while loop.
        $i++;
        die 'Error::Base internal error: excessive backtrace'
            if $i > 99;
#~ last if $i > 9;                                             # DEBUG ONLY #~
        
    }; ## while not bottomed
    
    # Stash unformatted stack frames.
    $self->{-frames}    = \@frames;
    
    # Format each stack frame. 
    for my $frame (@frames) {
        
        # Pad each field to maximum length (found in while)
        for my $fc ( 0..$#f ) {
            my $diff            = $maxlen[$fc] - length $frame->{$f[$fc]};
            $frame->{$f[$fc]}   = $frame->{$f[$fc]} . ($pad x $diff);
        };
        
        # Fix up bottom.
        if ( $frame->{-bottom} ) {
            $frame->{-sub} =~ s/ /_/g;      # all underbars
            $in         = q{___};           # *THREE* underbars
        }
        else {
            $in         = q{in };           # a three-char string
        };
        
        # Format printable line.
        my $line    = qq*$in$frame->{-sub} at line $frame->{-line}*
                    . qq*    [$frame->{-file}]*
                    ;
        
        # Append any eval text.
        if ($frame->{-eval}) {
            # hard newlines so number of frames doesn't change
            $line           = $line
                            . qq{\n}
                            . qq*    string eval: "$frame->{-eval}"*
                            . qq{\n}
                            ;
        };
        
        push @lines, $line;
    }; ## for each frame
    
    return @lines;
}; ## _trace

#=========# CLASS OR OBJECT METHOD
#
#    Error::Base->crash( $text );    # class method; error text required
#    $err->crash;                    # object method
#    $err->crash( $text );           # object method; error text optional
#    $err->crash( -base => $base );  # named argument okay
#    $err->crash( -foo  => 'bar' );  # set Error::Base options now
#    $err->crash( mybit => 'baz' );  # set your private stuff now
#
# Purpose   : Fatal out of your program's errors
# Parms     : $text     : string    : final   part of error message [odd arg]
#           : -type     : string    : middle  part of error message
#           : -base     : string    : initial part of error message
#           : -top      : integer   : starting backtrace frame
#           : -quiet    : boolean   : TRUE for no backtrace at all
# Returns   : never
# Throws    : $self     : die will stringify
# See also  : _fuss(), crank(), cuss(), init()
# 
# The first arg is tested to see if it's a class or object reference.
# Then the next test is to see if an odd number of args remain.
#   If so, then the next arg is shifted off and considered -base.
# All remaining args are considered key/value pairs and passed to new().
#   
sub crash{
    my $self    = _fuss(@_);
    
    die $self;
}; ## crash

#=========# INTERNAL FUNCTION
#
# This does all the work for crash(), crank(), and cuss().
# See crash() for more info.
#
sub _fuss {
    my $self        = shift;
    if ( Scalar::Util::blessed $self ) {        # called on existing object
        $self->init(@_);                        # initialize or overwrite
    } 
    else {                                      # called as class method
        $self       = $self->new(@_);
    };
    
    my $max         = 78;                       # maximum line length
    my $message     ;                           # user-defined error message
    my @lines       ;                           # to stringify $self
    
    # Deal with array values.
    $self->{-mesg}  = _expand_ref( $self->{-mesg} );
    
    # Collect all the texts into one message.
    $message        = _join_local(
                        $self->{-base},
                        $self->{-type},
                        $self->{-mesg},
                    );
#~     ### $self
    
    # Late interpolate.    
    $message        = $self->_late( $message );
    
    # If still no text in there, finally default.
    if    ( not $message ) {
        $message        = 'Undefined error.';
    }; 
    $self->{-all}   = $message;                 # keep for possible inspection

    # Accumulate.
    @lines          = ( $message );
        
    # Stack backtrace by default.
    if ( not $self->{-quiet} ) {
        my @trace       = $self->_trace( -top => $self->{-top} );
        push @lines, @trace;
    };
    
    # Optionally prepend some stuff.
    if ( defined $self->{-prepend} ) {          # prepended to first line
        @{ $self->{-lines} } 
            = _join_local( $self->{-prepend}, shift @lines );
    }
    else {
        @{ $self->{-lines} }                = shift @lines;
    };
    if ( defined $self->{-indent} ) {           # prepended to all others
        push @{ $self->{-lines} }, 
            map { _join_local( $self->{-indent}, $_ ) } @lines;
    }
    else {
        push @{ $self->{-lines} },                      @lines;
    };
    
    ### @lines
    return $self;
    
#~     # Do something to control line length and deal with multi-line $all.
#~     my @temp        = split /\n/, $all;         # in case it's multi-line
#~     my $limit       = $max - length $prepend;
#~        @temp        = map { s//\n/ if length > $limit } 
#~                         @temp; # avoid excessive line length
#~     my $infix       = qq{\n} . $indent;
#~        $all         = join $infix, @temp;
    
}; ## _fuss

#=========# CLASS OR OBJECT METHOD
#
# Just like crash() except it warn()-s and does not die().
# See crash() for more info.
sub crank{
    my $self    = _fuss(@_);
    
    warn $self;
}; ## crank

#=========# CLASS OR OBJECT METHOD
#
# Just like crash() except it just returns $self (after expansion).
# See crash() for more info.
sub cuss{
    my $self    = _fuss(@_);
    
    return $self;
}; ## crank

#=========# INTERNAL FUNCTION
#
#   $string =_expand_ref( $var );     # expand reference if any
#       
# Purpose   : ____
# Parms     : ____
# Reads     : ____
# Returns   : ____
# Invokes   : ____
# Writes    : ____
# Throws    : ____
# See also  : ____
# 
# ____
#   
sub _expand_ref {
    my $in          = shift;
    my $rt          = Scalar::Util::reftype $in;    # returns no class
        
    if    ( not $rt ) {                             # simple scalar...
        # ... don't deref
        return $in                                  # unchanged
    }
    elsif ( $rt eq 'SCALAR' ) {                     # scalar ref
        return $$in                                 # dereference
    } 
    elsif ( $rt eq 'ARRAY'  ) {                     # array ref
        return _join_local(@$in);                   # deref and join
    } 
#~     elsif ( $rt eq 'HASH'   ) {                     # hash ref
#~     my @sorted  = map { $_, $in->{$_} } sort keys %$in;
#~         return _join_local(@sorted);                # deref, sort, and join
#~     } 
    else {
        die 'Error::Base internal error: bad reftype in _expand_ref';
    };
    
}; ## _expand_ref

#=========# INTERNAL FUNCTION
#
#   $string = _join_local(@_);     # short
#       
# Purpose   : Like builtin join() but with local list separator.
# Parms     : @_        : strings to join
# Returns   : $string   : joined strings
# Throws    : ____
# See also  : init()
# 
# Buitin join() does not take $" (or anything else) by default.
# We splice out empty strings to avoid useless runs of spaces.  
# 
sub _join_local {
    my @parts       = @_;
    
    # Splice out empty strings. 
   @parts       = grep { $_ ne q** } @parts;
    
    return join $", @parts;
}; ## _join_local

#=========# INTERNAL FUNCTION
#
#   my %args    = _paired(@_);     # check for unpaired arguments
#       
# Purpose   : ____
# Parms     : ____
# Reads     : ____
# Returns   : ____
# Writes    : ____
# Throws    : ____
# See also  : ____
# 
# ____
#   
sub _paired {
    if ( scalar @_ % 2 ) {  # an odd number modulo 2 is one: true
        die 'Error::Base internal error: unpaired args';
    };
    return @_;
}; ## _paired

#=========# CLASS METHOD
#
#   my $obj     = $class->new();
#   my $obj     = $class->new({ -a  => 'x' });
#       
# Purpose   : Object constructor
# Parms     : $class    : Any subclass of this class
#             anything else will be passed to init()
# Returns   : $self
# Invokes   : init()
# 
# Good old-fashioned hashref-based object constructor. 
# 
sub new {
    my $class   = shift;
    my $self    = {};           # always hashref
    
    bless ($self => $class);
    $self->init(@_);            # init remaining args
    
    return $self;
}; ## new

#=========# OBJECT METHOD
#
#   $err->init(        k => 'v', f => $b );
#   $err->init( $text, k => 'v', f => $b );
#
# An object can be init()-ed more than once; all new values overwrite the old.
# This non-standard init() allows an unnamed initial arg. 
#
# See: crash()
#
sub init {
    my $self        = shift;
    if ( scalar @_ % 2 ) {              # an odd number modulo 2 is one: true
        $self->{-mesg}  = shift;        # and now it's even
    };
    
    # Merge all values. Newer values always overwrite. 
    %{$self}        = ( %{$self}, @_ );
    
    # Set some default values, mostly to avoid 'uninitialized' warnings.
    $self->put_base(  $self->{-base}  );
    $self->put_type(  $self->{-type}  );
    $self->put_mesg(  $self->{-mesg}  );
    $self->put_quiet( $self->{-quiet} );
    $self->put_nest(  $self->{-nest}  );
    $self->_fix_pre_ind();
    
    return $self;
}; ## init

#----------------------------------------------------------------------------#
# ACCSESSORS

my $Default = {
    -base           =>  q{},
    -type           =>  q{},
    -mesg           =>  q{},
    -quiet          =>  0,
    -nest           =>  0,
    -prepend        =>  undef,
    -indent         =>  undef,
};



# put
sub put_base {
    my $self            = shift;
    $self->{-base}      = shift;
    if    ( not defined $self->{-base}  ) {
        $self->{-base}  = $Default->{-base};
    };
    return $self;
};
sub put_type {
    my $self            = shift;
    $self->{-type}      = shift;
    if    ( not defined $self->{-type}  ) {
        $self->{-type}  = $Default->{-type};
    };
    return $self;
};
sub put_mesg {
    my $self            = shift;
    $self->{-mesg}      = shift;
    if    ( not defined $self->{-mesg}  ) {
        $self->{-mesg}  = $Default->{-mesg};
    };
    return $self;
};
sub put_quiet {
    my $self            = shift;
    $self->{-quiet}     = shift;
    if    ( not defined $self->{-quiet}  ) {
        $self->{-quiet} = $Default->{-quiet};
    };
    return $self;
};
sub put_nest {
    my $self            = shift;
    $self->{-nest}      = shift;
    if    ( not defined $self->{-nest}  ) {
        $self->{-nest}  = $Default->{-nest};
    };
    # -top is now deprecated from the API
    $self->{-top}       = $self->{-nest} + $BASETOP;
    return $self;
};
sub put_prepend {
    my $self            = shift;
    $self->{-prepend}   = shift;
    $self->_fix_pre_ind();
    return $self;
};
sub put_indent {
    my $self            = shift;
    $self->{-indent}    = shift;
    $self->_fix_pre_ind();
    return $self;
};
# For internal use only
sub _fix_pre_ind {
    my $self            = shift;
    my $indent          ;
    my $case            ;
    
    $case   = $case . ( defined $self->{-prepend} ? 'P' : '-' );
    $case   = $case . ( defined $self->{-indent}  ? 'I' : '-' );
    
    # four cases cover all needs
    if    ( $case eq '--' ) {
        $self->{-prepend}   =   $Default->{-prepend};
        $self->{-indent}    =   $Default->{-indent};
    }
    elsif ( $case eq '-I' ) {
        $self->{-prepend}   =   $self->{-indent};
    }
    elsif ( $case eq 'P-' ) {
        my $prepend         = $self->{-prepend};
        $self->{-indent}    = ( substr $prepend, 0, 1           )
                            . ( q{ } x ((length $prepend) - 1)  )
                            ;
    }
    else {
        # ( $case eq 'PI' )     # do nothing
    };
    
    return $self;
};

# get
sub get_base {
    my $self    = shift;
    return $self->{-base};
};
sub get_type {
    my $self    = shift;
    return $self->{-type};
};
sub get_mesg {
    my $self    = shift;
    return $self->{-mesg};
};
sub get_quiet {
    my $self    = shift;
    return $self->{-quiet};
};
sub get_nest {
    my $self    = shift;
    return $self->{-nest};
};
sub get_prepend {
    my $self    = shift;
    return $self->{-prepend};
};
sub get_indent {
    my $self    = shift;
    return $self->{-indent};
};
sub get_all {
    my $self    = shift;
    return $self->{-all};
};
sub get_lines {
    my $self    = shift;
    return $self->{-lines};
};
sub get_frames {
    my $self    = shift;
    return $self->{-frames};
};

## accessors
#----------------------------------------------------------------------------#

#=========# INTERNAL OBJECT METHOD
#
#   $out    = $self->_late( $in );     # late interpolate
#
# Wrapper method; see Error::Base::Late::_late().
sub _late { return Error::Base::Late::_late(@_) };
##

}   #=====# ... Entire package inside bare block, not indented.
#=========# END PACKAGE BLOCK

package Error::Base::Late;   # switch package to avoid pseudo-global lexicals
{

#=========# INTERNAL FUNCTION IN FOREIGN PACKAGE
#
#   $out    = _late( $self, $in );     # late interpolate
#       
# Purpose   : ____
# Parms     : $in       : scalar string
# Reads     : every key in $self starting with a $, @, or % sigil
#           : $self     : available as '$self'
# Returns   : $out      : scalar string
# Writes    : ____
# Throws    : ____
# See also  : ____
# 
# I hope this is the worst possible implementation of late(). 
# Late interpolation is accomplished by multiple immediate interpolations, 
#   inside and outside of a string eval. 
# Non-core PadWalker is not used to derive interpolation context; 
#   caller is required to pass context inside the $self object. 
# To avoid collision and unintended interpolation, I make housekeeping 
#   variables internal to this routine, package variables. 
#   These are fully qualified to a "foreign" package; caller cannot 
#   accidentally access them (although I cannot stop you from doing stupid).
# Some work is done in a bare "setup" block with lexical variables. 
#   But package variables are used to pass values within the routine, 
#   from block to block, inside to outside, within and without the eval. 
# Quoting is a major concern. Heredocs are used in three places for 
#   double-quoted interpolation; they may not conflict with each other 
#   or with any string that may exist within any of: 
#       - the string to be interpolated, $in
#       - values passed in $self against @keys (keys with leading sigils)
#   Rather than attempt to exclude all of these from a generic q//, 
#       I chose heredocs and three long, arbitrary strings. 
# 
sub _late {
    use strict;
    use warnings;
    no warnings 'uninitialized';          # too many to count
#~ ##### CASE:
#~ ##### @_    
    # No lexical variables loose in the outer block of the subroutine.
    $Error::Base::Late::self    = shift;
    if ( not ref $Error::Base::Late::self ) {
        die 'Error::Base internal error: no $self';
    };
    $Error::Base::Late::in      = shift || undef;
    return $Error::Base::Late::in 
        unless $Error::Base::Late::in =~ /[\$\@%]/; # no sigil, don't bother
    
    # Y0uMaYFiReWHeNReaDYGRiDLeY          # quite unlikely to collide
    
    @Error::Base::Late::code    = undef;  # to be eval-ed
    $Error::Base::Late::out     = undef;  # interpolated
    
    #--------------------------------------------------------------------#
    { # setup block
        
        # Some preamble.
        push @Error::Base::Late::code, 
            q**,
            q*#--------------------------------------------------------#*,
            q*# START EVAL                                              *,
            q**,
            q*my $self  = $Error::Base::Late::self;*,
            q**,
        ;
        
        # Unpack all appropriate k/v pairs into their own lexical variables... 
        
        # Each key includes leading sigil.
        my @keys    = grep { /^[\$\@%]/ } keys %$Error::Base::Late::self;
        return $Error::Base::Late::in   # abort if not interpolating today
#~             unless ( @keys or $Error::Base::Late::in =~ /\$self/ );
            unless ( @keys );
        my $key     ;  # placeholder includes sigil!
        my $val     ;  # value to be interpolated
        my $rt      ;  # builtin 'ref' returns (unwanted) class of blessed ref
        
        #            my $key = $sigil?$Error::Base::Late::self->{'$key'}?;
        my $ch1  = q*my *                                                   ;
        my $ch2  =        q* = *                                            ;
        my $ch3  =                  q*Error::Base::Late::self->{'*          ;
        my $ch4  =                                                q*'}*     ;
        my $ch5  =                                                  q*;*    ;
        
        for my $key (@keys) {
            $val            = $Error::Base::Late::self->{$key};
            $rt             = Scalar::Util::reftype $val;   # returns no class
            
            my $sigil   ;           # sigil (if any) to deref
            my $lbc     = q*{$*;    # left  brace if sigil . '$' for $self
            my $rbc     = q*}*;     # right brace if sigil
            
            if    ( not $rt ) {                             # simple scalar...
                # ... don't deref
                $lbc    = q{$};     # only '$' for $self
                $rbc    = q{};
            }
            elsif ( $rt eq 'SCALAR' ) {                     # scalar ref
                $sigil      = q{$};
            } 
            elsif ( $rt eq 'ARRAY'  ) {                     # array ref
                $sigil      = q{@};
            } 
            elsif ( $rt eq 'HASH'   ) {                     # hash ref
                $sigil      = q{%};
            } 
            else {
                die 'Error::Base internal error: bad reftype in _late';
            };
            
            #        my $key = $sigil?$Error::Base::Late::self->{'$key'}?;
            push @Error::Base::Late::code, 
                ( join q{}, 
                    $ch1, $key, $ch2, 
                    $sigil, $lbc, $ch3, $key, $ch4, $rbc, $ch5,
                );
            
        }; ## for keys
    # ... done unpacking.
    
    # Do the late interpolation phase. 
    push @Error::Base::Late::code, 
        q**,
        q*<<Heredoc01_Y0uMaYFiReWHeNReaDYGRiDLeY;*,
<<Heredoc02_Y0uMaYFiReWHeNReaDYGRiDLeY,
$Error::Base::Late::in
Heredoc02_Y0uMaYFiReWHeNReaDYGRiDLeY
        q*Heredoc01_Y0uMaYFiReWHeNReaDYGRiDLeY*,
        q*#--------------------------------------------------------#*,
        q**,
    ;
    
    # Code is now fully assembled.
    $Error::Base::Late::eval_code   = 
        join qq{\n}, @Error::Base::Late::code;
    
    } ## setup
    #--------------------------------------------------------------------#
    { # eval string
        
$Error::Base::Late::out     = eval 
<<Heredoc03_Y0uMaYFiReWHeNReaDYGRiDLeY;
$Error::Base::Late::eval_code
Heredoc03_Y0uMaYFiReWHeNReaDYGRiDLeY
        
        if ($@) {
            warn "Error::Base internal warning: in _late eval: $@";
            return $Error::Base::Late::in;           # best we can do
        };
        
#~         ##### CASE
#~         ##### $Error::Base::Late::self
#~         ##### $Error::Base::Late::in
#~         ##### @Error::Base::Late::code
#~         ##### $Error::Base::Late::eval_code
#~         ##### $@
    
    } ## eval string
    #--------------------------------------------------------------------#
    
    # Heredocs add spurious newlines.
    chomp  $Error::Base::Late::out;
    chomp  $Error::Base::Late::out;
#~ my $out =  $Error::Base::Late::out;
#~ ##### $out;
    return $Error::Base::Late::out;
}; ## _late

} ## package Error::Base::Late

## END MODULE
1;
#============================================================================#
__END__

=head1 NAME

Error::Base - Simple structured errors with full backtrace

=head1 VERSION

This document describes Error::Base version v1.0.2

=head1 WHAT'S NEW

=over

=item *

You may now pass an array reference to L<-mesg|Error::Base/-mesg>. 

=item *

You now have get and put L<accessors|Error::Base/ACCESSORS>. 

=item *

Some elements of the API have changed. 
C<-top> and C<-prepend_all> have been deprecated. 

=back

=head1 SYNOPSIS

    use Error::Base;
    Error::Base->crash('Sanity check failed');  # die() with backtrace
    
    my $err     = Error::Base->new('Foo');      # construct object first
        yourcodehere(...);                  # ... do other stuff
    $err->crash;                                # as object method
    
    my $err     = Error::Base->new(
                        'Foo error',            # odd arg is error text
                    -quiet    => 1,             # no backtrace
                    grink     => 'grunt',       # store somethings
                    puppy     => 'dog',         # your keys, no leading dash 
                );
    $err->crash;
    
    $err->crank;                    # get cranky: warn() but don't die()
    my $err = Error::Base->crank('Me!');        # also a constructor
    
    eval{ Error::Base->crash( 'car', -foo => 'bar' ) }; 
    my $err     = $@ if $@;         # catch and examine the full object
    
    # late interpolation
    my $err     = Error::Base->new(
                    -base       => 'File handler error:',
                    _openerr    => 'Could not open $file for $op',
                );
    {
        my $file = 'z00bie.xxx';    # uh-oh, variable out of scope for new()
        open my $fh, '<', $file
            or $err->crash(
                -type       => $err->{_openerr},
                '$file'     => $file,
                '$op'       => 'reading',
            );                      # late interpolation to the rescue
    }

=head1 DESCRIPTION

=over

I<J'avais cru plus difficile de mourir.> 
-- Louis XIV

=back

Die early, die often. Make frequent sanity checks and die when a check fails. 
See neat dumps of the caller stack with each error. Construct a group of 
error messages in one object or write error text I<ad hoc>. Trap an error 
object and examine the contents; or let it tell its sad tale and end it. 

Error::Base usage can be simple or complex. For quick sanity checks, 
construct and throw a simple fatal error in one line. At the other extreme, 
you can override methods in your own error subclasses. 

Error::Base is lightweight. It defines no global variables, uses no non-core 
modules (and few of those), exports no symbols, and is purely object-oriented.
I hope you will be able to use it commonly instead of a simple C<die()>. 
You are not required to subclass it. 

See the L<Error::Base::Cookbook|Error::Base::Cookbook> for examples. 

=head1 METHODS 

=head2 new()

    my $err     = Error::Base->new;             # constructor
    my $err     = Error::Base->new(
                        'bartender',            # lone string first okay
                    -base       => 'Bar error:',
                    -type       => 'last call',
                    -quiet      => 1,
                    -nest       => 1,
                    -prepend    => '@! Black Tie Lunch:',
                    -indent     => '@!                 ',
                    _beer   => 'out of beer',   # your private attribute(s)
                );
    my $err     = Error::Base->new(
                    -base       => 'First',
                    -type       => 'Second',
                    -mesg       => 'Third',
                );

The constructor must be called as a class method; there is no mutator 
returning a new object based on an old one. You do have some freedom in how 
you call, though. 

Called with an even number of args, they are all considered key/value pairs. 
Keys with leading dash (C<'-'>) are reserved for use by Error::Base;
keys led by a Perlish sigil (C<=~ /^[\$\@%]/>) trigger 
L<late interpolation|/LATE INTERPOLATION>;
all other keys are free to use as you see fit. 
Error message text is constructed as a single string.

Called with an odd number of args, the first arg is shifted off and appended
to the error message text. This shorthand may be offensive to some; in which 
case, don't do that. 
Instead, pass C<< -base >>, C<< -type >>, and/or C<< -mesg >>. 

You may stash any arbitrary data inside the returned object (during 
construction or later) and do whatever you like with it. You might choose to 
supply additional optional texts for later access. 

Stringification is overridden on objects of this class. So, if you attempt to 
print the object, or perform an operation that causes perl to want to treat 
it as a string, you will get the printable error message. If you prefer to 
examine the object internally, access its hash values; or dump it using 
L<Data::Dumper|Data::Dumper>, L<Devel::Comments|Devel::Comments>, or 
L<Test::More|Test::More>::explain().

See L</PARAMETERS>.

=head2 crash()

    Error::Base->crash('Sanity check failed');  # as class method
    $err->crash;                                # as object method
        # all the same args are okay in crash() as in new()
    eval{ $err->crash };                        # trap...
    print STDERR $@ if $@;                      # ... and examine the object

C<crash()> and other public methods may be called as class or object methods. 
If called as a class method, then C<new()> is called internally. Call C<new()>
first if you want to call C<crash()> as an object method. 

C<crash()> is a very thin wrapper, easy to subclass. It differs from similar 
methods in that instead of returning its object, it C<die()>-s with it. 
If uncaught, the error will stringify; if caught, the entire object is yours. 

=head2 crank()

    $err->crank( -type => 'Excessive boxes' ) if $box > $max;


This is exactly like C<crash()> except that it C<warn()>s instead of 
C<die()>-ing. Therefore you may easily recover the object for later use. 

=head2 cuss()

    my $err = Error::Base->cuss('x%@#*!');      # also a constructor

Again, exactly like C<crash()> or C<crank()> except that it neither 
C<die()>-s nor C<warn()>s; it I<only> returns the object. 

The difference between C<new()> and the other methods is that C<new()> returns 
the constructed object containing only what was passed in as arguments. 
C<crash()>, C<crank()>, and C<cuss()> perform a full stack backtrace 
(if not passed -quiet) and format the result for stringified display.

You may find C<cuss()> useful in testing your subclass or to see how your 
error will be thrown without the bother of actually catching C<crash()>.

=head2 init()

    $err->init(@args);

The calling conventions are exactly the same as for the other public methods. 

C<init()> is called on a newly constructed object, as is conventional. 
If you call it a second time on an existing object, new C<@args> will 
overwrite previous values. Internally, when called on an existing object,
C<crash()>, C<crank()>, and C<cuss()> each call C<init()>. When these are 
called as class methods, they call C<new()>, which calls C<init()>.

Therefore, the chief distinction between calling as class or object method is 
that if you call new() first then you can separate the definition of your 
error text from the actual throw. 

=head1 PARAMETERS

All public methods accept the same arguments, with the same conventions. 
Parameter names begin with a leading dash (C<'-'>); please choose other 
names for your private keys. 

If the same parameter is set multiple times, the most recent argument 
completely overwrites the previous value. 

You are cautioned that deleting keys may be unwise. 

=head2 -base

I<scalar string>

The value of C<< -base >> is printed in the first line of the stringified 
error object after a call to C<crash()>, C<crank()>, or C<cuss()>. 

=head2 -type

I<scalar string>

This parameter is provided as a way to express a subtype of error. 
It is appended to C<< -base >>. 

=head2 -mesg

I<scalar string> or I<array reference>

    $err->crash( 'Pronto!' );           # emits 'Pronto!'
    $err->crash(
            -mesg => 'Pronto!',
    );                                  # same thing
    my $foo     = 'bar';
    $err->crash(
            -mesg => [ 'Cannot find', $foo, q{.} ],
    );                                  # emits 'Cannot find bar .'

As a convenience, if the number of arguments passed in is odd, then the first 
arg is shifted off and appended to the error message 
after C<< -base >> and C<< -type >>. 
This is done to simplify writing one-off, one-line sanity checks:

    open( my $in_fh, '<', $filename )
        or Error::Base->crash("Couldn't open $filename for reading.");

You may pass into C<-mesg> a reference to an array of simple scalars; 
these will all be joined together and appened to the error message. 
If you need 
to pass a multi-line string then please embed escaped newlines (C<'\n'>). 

=head2 -quiet

I<scalar boolean> default: undef

    $err->crash( -quiet         => 1, );        # no backtrace

By default, you get a full stack backtrace. If you want none, set this 
parameter. Only error text will be emitted. 

=head2 -top

Deprecated as a public parameter; now internal only to Error::Base. 

=head2 -nest

I<scalar signed integer> default: 0

By default, stack frames internal to Error::Base are not traced. 
Set this parameter to adjust how many additional frames to discard.
Negative values display internal frames.  

=head2 -prepend

I<scalar string> default: undef

=head2 -indent

I<scalar string> default: first char of -prepend, padded with spaces to length

The value of C<< -prepend >> is prepended to the first line of error text; 
C<< -indent >> to all others. 
If only C<< -indent >> is given, it is prepended to all lines. 
If only C<< -prepend >> is given, C<< -indent >> is generated from its first 
character and padded to the same length. 
Override either of these default actions by passing the empty string. 

This is a highly useful feature that improves readability in the middle of a 
dense dump. So in future releases, the default may be changed to form 
C<< -prepend >> in some way for you if not defined. If you are certain you 
want no prepending or indentation, pass the empty string, C<q{}>.

=head1 LATE INTERPOLATION

It is possible to interpolate a variable that is I<not in scope> 
into error message text. This is triggered by passing the value against a 
key whose leading character is a Perlish sigil, one of C<$@%>. 
Enclose the text (including placeholders) in single quotes. 
For a detailed explanation, 
see the L<Cookbook|Error::Base::Cookbook/Late Interpolation>.

=head1 RESULTS

=head2 -all

I<scalar string> default: 'Undefined error.'

The error message, expanded, without C<< -prepend >> or backtrace. 
An empty message is not allowed; if none is provided by any means, 
'Undefined error.' emits. 

=head2 -lines

I<array of strings>

The formatted error message, fully expanded, including backtrace. 

=head2 -frames

I<array of hashrefs>

The raw stack frames used to compose the backtrace. 

=head1 ACCSESSORS

Object-oriented accessor methods are provided for each parameter and result. 
They all do just what you'd expect. 

    $self               = $self->put_base($string);
    $self               = $self->put_type($string);
    $self               = $self->put_mesg($string);
    $self               = $self->put_quiet($string_or_aryref);
    $self               = $self->put_nest($signed_int);
    $self               = $self->put_prepend($string);
    $self               = $self->put_indent($string);
    $string             = $self->get_base();
    $string             = $self->get_type();
    $string_or_aryref   = $self->get_mesg();
    $boolean            = $self->get_quiet();
    $signed_int         = $self->get_nest();
    $string             = $self->get_prepend();
    $string             = $self->get_indent();
    $string             = $self->get_all();
    @array_of_strings   = $self->get_lines();
    @array of hashrefs  = $self->get_frames();

=head1 SUBCLASSING

    use base 'Error::Base';
    sub init{
        my $self    = shift;
        _munge_my_args(@_);
        $self->SUPER::init(@_);
        return $self;
    };

While useful standing alone, L<Error::Base> is written to be subclassed, 
if you so desire. Perhaps the most useful method to subclass may be C<init()>.
You might also subclass C<crash()>, C<crank()>, or C<cuss()> if you want to 
do something first: 

    use base 'Error::Base';
    sub crash{
        my $self    = _fuss(@_);
        $self->a_kiss_before_dying();
        die $self;
    };

The author hopes that most users will not be driven to subclassing but if you
do so, successfully or not, please be so kind as to notify. 

=head1 SEE ALSO

L<Error::Base::Cookbook|Error::Base::Cookbook>

Many error-related modules are available on CPAN. Some do bizarre things. 

L<Exception::Class|Exception::Class>, L<Error|Error>, L<Exception|Exception>, L<Carp|Carp>, L<Test::Trap|Test::Trap>.

=head1 INSTALLATION

This module is installed using L<Module::Build|Module::Build>. 

=head1 DIAGNOSTICS

This module emits error messages I<for> you; it is hoped you won't encounter 
any from within itself. If you do see one of these errors, kindly report to RT 
so maintainer can take action. Thank you for helping. 

All errors internal to this module are prefixed C<< Error::Base internal... >>

=over

=item C<< excessive backtrace >>

Attempted to capture too many frames of backtrace. 
You probably mis-set C<< -nest >>, reasonable values of which are perhaps 
C<-2..3>.

=item C<< unpaired args: >>

You do I<not> have to pass paired arguments to most public methods. 
Perhaps you passed an odd number of args to a private method. 

=item C<< bad reftype in _late >>

Perhaps you attempted to late-interpolate a reference other than to 
a scalar, array, or hash. 
Don't pass such references as values to any key with the wrong sigil. 

=item C<< bad reftype in _expand_ref >>

You passed a hashref or coderef to C<-mesg>. Pass a simple string or arrayref. 

=item C<< no $self >>

Called a method without class or object. Did you call as function?

=item C<< stringifying unthrown object >>

An object of this class will stringify to its printable error message 
(including backtrace if any) when thrown. There is nothing to see (yet) if 
you try to print an object that has been constructed but not (yet) thrown. 
This error is not fatal; it is returned as the stringification. 

=item C<< in _late eval: >>

Attempted to late-interpolate badly. Check your code. The interpolation 
failed so you cannot expect to see the correct error message text. 
On the offchance that you would like to see the stack backtrace anyway, 
this error is not fatal. 

=back

=head1 CONFIGURATION AND ENVIRONMENT

Error::Base requires no configuration files or environment variables.

=head1 DEPENDENCIES

There are no non-core dependencies. 

=over

=item 

L<version|version> 0.99    E<nbsp>E<nbsp>E<nbsp>E<nbsp> # Perl extension for Version Objects

=item 

L<overload|overload>    E<nbsp>E<nbsp>E<nbsp>E<nbsp> # Overload Perl operations

=item 

L<Scalar::Util|Scalar::Util>    E<nbsp>E<nbsp>E<nbsp>E<nbsp> # General-utility scalar subroutines

=back

This module should work with any version of perl 5.8.8 and up. 
However, you may need to upgrade some core modules. 

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

This is an early release. Reports and suggestions will be warmly welcomed. 

Please report any bugs or feature requests to
C<bug-error-base@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 DEVELOPMENT

This project is hosted on GitHub at: L<https://github.com/Xiong/error-base>. 

=head1 THANKS

Grateful acknowledgement deserved by AMBRUS for coherent API suggestions. 
Any failure to grasp them is mine. 

=head1 AUTHOR

Xiong Changnian  C<< <xiong@cpan.org> >>

=head1 LICENCE

Copyright (C) 2011, 2013 Xiong Changnian C<< <xiong@cpan.org> >>

This library and its contents are released under Artistic License 2.0:

L<http://www.opensource.org/licenses/artistic-license-2.0.php>

=begin fool_pod_coverage

No, I'm not just lazy. I think it's counterproductive to give each accessor 
its very own section. Sorry if you disagree. 

=head2 put_base

=head2 put_type

=head2 put_mesg

=head2 put_quiet

=head2 put_nest

=head2 put_prepend

=head2 put_indent

=head2 get_base

=head2 get_type

=head2 get_mesg

=head2 get_quiet

=head2 get_nest;

=head2 get_prepend

=head2 get_indent

=head2 get_all

=head2 get_lines

=head2 get_frames

=end   fool_pod_coverage

=cut
