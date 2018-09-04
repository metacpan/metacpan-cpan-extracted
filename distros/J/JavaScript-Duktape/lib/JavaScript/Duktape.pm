package JavaScript::Duktape;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Scalar::Util qw( weaken );
our $VERSION = '2.5.0';

my $GlobalRef = {};

my $THIS;
my $DUKTAPE;
my $isNew  = bless [], "NEW";
my $HEAP   = bless [], "HEAP";
my $DUK    = bless [], "DUK";
my $NOARGS = bless [], "NOARGS";

use base qw/Exporter/;
our @EXPORT = qw (
  DUK_TYPE_NONE
  DUK_TYPE_UNDEFINED
  DUK_TYPE_NULL
  DUK_TYPE_BOOLEAN
  DUK_TYPE_NUMBER
  DUK_TYPE_STRING
  DUK_TYPE_OBJECT
  DUK_TYPE_BUFFER
  DUK_TYPE_POINTER
  DUK_TYPE_LIGHTFUNC
  DUK_ENUM_INCLUDE_NONENUMERABLE
  DUK_ENUM_INCLUDE_HIDDEN
  DUK_ENUM_INCLUDE_SYMBOLS
  DUK_ENUM_EXCLUDE_STRINGS
  DUK_ENUM_INCLUDE_INTERNAL
  DUK_ENUM_OWN_PROPERTIES_ONLY
  DUK_ENUM_ARRAY_INDICES_ONLY
  DUK_ENUM_SORT_ARRAY_INDICES
  DUK_ENUM_NO_PROXY_BEHAVIOR
  DUK_TYPE_MASK_NONE
  DUK_TYPE_MASK_UNDEFINED
  DUK_TYPE_MASK_NULL
  DUK_TYPE_MASK_BOOLEAN
  DUK_TYPE_MASK_NUMBER
  DUK_TYPE_MASK_STRING
  DUK_TYPE_MASK_OBJECT
  DUK_TYPE_MASK_BUFFER
  DUK_TYPE_MASK_POINTER
  DUK_TYPE_MASK_LIGHTFUNC
  DUK_TYPE_MASK_THROW
  DUK_COMPILE_EVAL
  DUK_COMPILE_FUNCTION
  DUK_COMPILE_STRICT
  DUK_COMPILE_SAFE
  DUK_COMPILE_NORESULT
  DUK_COMPILE_NOSOURCE
  DUK_COMPILE_STRLEN
  DUK_DEFPROP_WRITABLE
  DUK_DEFPROP_ENUMERABLE
  DUK_DEFPROP_CONFIGURABLE
  DUK_DEFPROP_HAVE_WRITABLE
  DUK_DEFPROP_HAVE_ENUMERABLE
  DUK_DEFPROP_HAVE_CONFIGURABLE
  DUK_DEFPROP_HAVE_VALUE
  DUK_DEFPROP_HAVE_GETTER
  DUK_DEFPROP_HAVE_SETTER
  DUK_DEFPROP_FORCE
  DUK_VARARGS
  null
  true
  false
  _
  this
);

##constants
use constant {
    DUK_TYPE_NONE      => 0,
    DUK_TYPE_UNDEFINED => 1,
    DUK_TYPE_NULL      => 2,
    DUK_TYPE_BOOLEAN   => 3,
    DUK_TYPE_NUMBER    => 4,
    DUK_TYPE_STRING    => 5,
    DUK_TYPE_OBJECT    => 6,
    DUK_TYPE_BUFFER    => 7,
    DUK_TYPE_POINTER   => 8,
    DUK_TYPE_LIGHTFUNC => 9,

    DUK_TYPE_MASK_NONE      => ( 1 << 0 ),
    DUK_TYPE_MASK_UNDEFINED => ( 1 << 1 ),
    DUK_TYPE_MASK_NULL      => ( 1 << 2 ),
    DUK_TYPE_MASK_BOOLEAN   => ( 1 << 3 ),
    DUK_TYPE_MASK_NUMBER    => ( 1 << 4 ),
    DUK_TYPE_MASK_STRING    => ( 1 << 5 ),
    DUK_TYPE_MASK_OBJECT    => ( 1 << 6 ),
    DUK_TYPE_MASK_BUFFER    => ( 1 << 7 ),
    DUK_TYPE_MASK_POINTER   => ( 1 << 8 ),
    DUK_TYPE_MASK_LIGHTFUNC => ( 1 << 9 ),
    DUK_TYPE_MASK_THROW     => ( 1 << 10 ),

    # Enumeration flags for duk_enum()
    DUK_ENUM_INCLUDE_NONENUMERABLE => ( 1 << 0 ),
    DUK_ENUM_INCLUDE_HIDDEN        => ( 1 << 1 ),
    DUK_ENUM_INCLUDE_SYMBOLS       => ( 1 << 2 ),
    DUK_ENUM_EXCLUDE_STRINGS       => ( 1 << 3 ),
    DUK_ENUM_OWN_PROPERTIES_ONLY   => ( 1 << 4 ),
    DUK_ENUM_ARRAY_INDICES_ONLY    => ( 1 << 5 ),
    DUK_ENUM_SORT_ARRAY_INDICES    => ( 1 << 6 ),
    DUK_ENUM_NO_PROXY_BEHAVIOR     => ( 1 << 7 ),

    DUK_COMPILE_EVAL     => ( 1 << 3 ),
    DUK_COMPILE_FUNCTION => ( 1 << 4 ),
    DUK_COMPILE_STRICT   => ( 1 << 5 ),
    DUK_COMPILE_SAFE     => ( 1 << 6 ),
    DUK_COMPILE_NORESULT => ( 1 << 7 ),
    DUK_COMPILE_NOSOURCE => ( 1 << 8 ),
    DUK_COMPILE_STRLEN   => ( 1 << 9 ),

    #Flags for duk_def_prop() and its variants
    DUK_DEFPROP_WRITABLE          => ( 1 << 0 ),
    DUK_DEFPROP_ENUMERABLE        => ( 1 << 1 ),
    DUK_DEFPROP_CONFIGURABLE      => ( 1 << 2 ),
    DUK_DEFPROP_HAVE_WRITABLE     => ( 1 << 3 ),
    DUK_DEFPROP_HAVE_ENUMERABLE   => ( 1 << 4 ),
    DUK_DEFPROP_HAVE_CONFIGURABLE => ( 1 << 5 ),
    DUK_DEFPROP_HAVE_VALUE        => ( 1 << 6 ),
    DUK_DEFPROP_HAVE_GETTER       => ( 1 << 7 ),
    DUK_DEFPROP_HAVE_SETTER       => ( 1 << 8 ),
    DUK_DEFPROP_FORCE             => ( 1 << 9 ),
    DUK_VARARGS                   => -1
};

sub new {
    my $class = shift;
    my %options = @_;

    my $max_memory = $options{max_memory} || 0;
    my $timeout    = $options{timeout} || 0;

    if ($timeout){
        croak "timeout option must be a number" if !JavaScript::Duktape::Vm::duk_sv_is_number( $timeout );
    }

    if ( $max_memory ){
        croak "max_memory option must be a number" if !JavaScript::Duktape::Vm::duk_sv_is_number( $max_memory );
        croak "max_memory must be at least 256k (256 * 1024)" if $max_memory < 256 * 1024;
    }

    my $self  = bless {}, $class;

    my $duk   = $self->{duk} = JavaScript::Duktape::Vm->perl_duk_new( $max_memory, $timeout );

    $self->{pid} = $$;
    $self->{max_memory} = $max_memory;

    # Initialize global stash 'PerlGlobalStash'
    # this will be used to store some perl refs
    $duk->push_global_stash();
    $duk->push_object();
    $duk->put_prop_string( -2, "PerlGlobalStash" );
    $duk->pop();

    $THIS = bless { duk => $duk, heapptr => 0 }, "JavaScript::Duktape::Object";

    ##finalizer method
    $self->{finalizer} = sub {
        my $ref = $duk->get_string(0);
        delete $GlobalRef->{$ref};
        return 1;
    };

    weaken $GlobalRef;

    $duk->perl_push_function( $self->{finalizer}, 1 );
    $duk->put_global_string('perlFinalizer');

    return $self;
}

sub null                   { $JavaScript::Duktape::NULL::null; }
sub true                   { $JavaScript::Duktape::Bool::true; }
sub false                  { $JavaScript::Duktape::Bool::false }
sub JavaScript::Duktape::_ { $NOARGS }
sub this                   { $THIS }

sub set {
    my $self = shift;
    my $name = shift;
    my $val  = shift;
    my $duk  = $self->vm;

    if ( $name =~ /\./ ) {

        my @props  = split /\./, $name;
        my $last   = pop @props;
        my $others = join '.', @props;

        if ( $duk->peval_string($others) != 0 ) {
            croak $others . " is not a javascript object ";
        }

        my $type = $duk->get_type(-1);
        if ( $type != DUK_TYPE_OBJECT ) {
            croak $others . " isn't an object";
        }

        $duk->push_string($last);
        $duk->push_perl($val);
        $duk->put_prop(-3);
        $duk->pop();
        return 1;
    }

    $duk->push_perl($val);
    $duk->put_global_string($name);
    return 1;
}

sub get {
    my $self = shift;
    my $name = shift;
    my $duk  = $self->vm;
    $duk->push_string($name);
    if ( $duk->peval() != 0 ) {
        croak $duk->last_error_string();
    }
    my $ret = $duk->to_perl(-1);
    $duk->pop();
    return $ret;
}

sub get_object {
    my $self = shift;
    my $name = shift;
    my $duk  = $self->vm;
    $duk->push_string($name);
    if ( $duk->peval() != 0 ) {
        croak $duk->last_error_string();
    }
    my $ret = $duk->to_perl_object(-1);
    $duk->pop();
    return $ret;
}

##FIXME : should pop here?
sub eval {
    my $self   = shift;
    my $string = shift;
    my $duk    = $self->duk;

    if ( $duk->peval_string($string) != 0 ) {
        croak $duk->last_error_string();
    }

    return $duk->to_perl(-1);
}

sub vm  { shift->{duk}; }
sub duk { shift->{duk}; }

sub set_timeout {
    my $self = shift;
    $self->duk->set_timeout( shift );
}

sub resize_memory {
    my $self = shift;
    $self->duk->resize_memory( shift );
}

sub destroy {
    local $@;
    my $self = shift;
    my $duk  = delete $self->{duk};
    return if !$duk;
    $duk->free_perl_duk();
    $duk->destroy_heap();
}

sub DESTROY {
    my $self = shift;
    if ( $self->{pid} && $self->{pid} == $$ ) {
        $self->destroy();
    }
}

package JavaScript::Duktape::Vm;
use strict;
use warnings;
no warnings 'redefine';
use Data::Dumper;
use Config qw( %Config );
use JavaScript::Duktape::C::libPath;
use Carp;

my $Duklib;

my $BOOL_PACKAGES = {
    'JavaScript::Duktape::Bool'  => 1,
    'boolean'                    => 1,
    'JSON::PP::Boolean'          => 1,
    'JSON::Tiny::_Bool'          => 1,
    'Data::MessagePack::Boolean' => 1
};

BEGIN {
    my $FunctionsMap = _get_path("FunctionsMap.pl");
    require $FunctionsMap;

    sub _get_path { &JavaScript::Duktape::C::libPath::getPath }

    $Duklib =
      $^O eq 'MSWin32'
      ? _get_path('duktape.dll')
      : _get_path('duktape.so');
}

use Inline C => config =>
    typemaps => _get_path('typemap'),
    INC      => '-I' . _get_path('../C') . ' -I' .  _get_path('../C/lib');
    # myextlib => $Duklib,
    # LIBS     => '-L'. _get_path('../C/lib') . ' -lduktape';

use Inline C => _get_path('duk_perl.c');

use Inline C => q{
    void poke_buffer(IV to, IV from, IV sz) {
        memcpy( to, from, sz );
    }
};

my $ptr_format = do {
    my $ptr_size = $Config{ptrsize};
        $ptr_size == 4 ? "L"
      : $ptr_size == 8 ? "Q"
      :                  die("Unrecognized pointer size");
};

sub peek { unpack 'P' . $_[1], pack $ptr_format, $_[0] }
sub pv_address { unpack( $ptr_format, pack( "p", $_[0] ) ) }

sub push_perl {
    my $self  = shift;
    my $val   = shift;
    my $stash = shift || {};

    if ( my $ref = ref $val ) {
        if ( $ref eq 'JavaScript::Duktape::NULL' ) {
            $self->push_null();
        }

        elsif ( $BOOL_PACKAGES->{$ref} ) {
            if ($val) {
                $self->push_true();
            }
            else {
                $self->push_false();
            }
        }

        elsif ( $ref eq 'ARRAY' ) {
            my $arr_idx = $self->push_array();
            $stash->{$val} = $self->get_heapptr(-1);
            my $len = scalar @{$val};
            for ( my $idx = 0 ; $idx < $len ; $idx++ ) {
                if ( $stash->{ $val->[$idx] } ) {
                    $self->push_heapptr( $stash->{ $val->[$idx] } );
                }
                else {
                    $self->push_perl( $val->[$idx], $stash );
                }
                $self->put_prop_index( $arr_idx, $idx );
            }
        }

        elsif ( $ref eq 'HASH' ) {
            $self->push_object();
            $stash->{$val} = $self->get_heapptr(-1);
            while ( my ( $k, $v ) = each %{$val} ) {
                $self->push_string($k);
                if ( $v && $stash->{$v} ) {
                    $self->push_heapptr( $stash->{$v} );
                }
                else {
                    $self->push_perl( $v, $stash );
                }
                $self->put_prop(-3);
            }
        }

        elsif ( $ref eq 'CODE' ) {
            $self->push_function($val);
        }

        elsif ( $ref eq 'JavaScript::Duktape::Object' ) {
            $self->push_heapptr( $val->{heapptr} );
        }

        elsif ( $ref eq 'JavaScript::Duktape::Function' ) {
            $self->push_heapptr( $val->($HEAP) );
        }

        elsif ( $ref eq 'JavaScript::Duktape::Pointer' ) {
            $self->push_pointer($$val);
        }

        elsif ( $ref eq 'JavaScript::Duktape::Buffer' ) {
            my $len = defined $$val ? length($$val) : 0;
            my $ptr = $self->push_fixed_buffer($len);
            poke_buffer( $ptr, pv_address($$val), $len );
        }

        elsif ( $ref eq 'SCALAR' ) {
            $$val ? $self->push_true() : $self->push_false()
        }

        else {
            $self->push_undefined();
        }
    }
    else {
        if ( !defined $val ) {
            $self->push_undefined();
        }
        elsif ( duk_sv_is_number($val) ) {
            $self->push_number($val);
        }
        else {
            $self->push_string($val);
        }
    }
}

sub to_perl_object {
    my $self    = shift;
    my $index   = shift;
    my $heapptr = $self->get_heapptr($index);
    if ( !$heapptr ) { croak "value at stack $index is not an object" }
    return JavaScript::Duktape::Util::jsObject(
        {
            duk     => $self,
            heapptr => $heapptr
        }
    );
}

sub to_perl {
    my $self  = shift;
    my $index = shift;
    my $stash = shift || {};

    my $ret;

    my $type = $self->get_type($index);

    if ( $type == JavaScript::Duktape::DUK_TYPE_UNDEFINED ) {
        $ret = undef;
    }

    elsif ( $type == JavaScript::Duktape::DUK_TYPE_STRING ) {
        $ret = $self->get_utf8_string($index);
    }

    elsif ( $type == JavaScript::Duktape::DUK_TYPE_NUMBER ) {
        $ret = $self->get_number($index);
    }

    elsif ( $type == JavaScript::Duktape::DUK_TYPE_BUFFER ) {
        my $ptr = $self->get_buffer_data( $index, my $sz );
        $ret = peek( $ptr, $sz );
    }

    elsif ( $type == JavaScript::Duktape::DUK_TYPE_OBJECT ) {

        if ( $self->is_function($index) ) {
            my $ptr = $self->get_heapptr($index);
            return sub {
                $self->push_heapptr($ptr);
                $self->push_this();
                my $len = 0 + @_;
                for ( my $i = 0 ; $i < $len ; $i++ ) {
                    $self->push_perl( $_[$i] );
                }
                if ( $self->pcall_method($len) == 1 ) {
                    croak $self->last_error_string();
                }
                my $ret = $self->to_perl(-1);
                $self->pop();
                return $ret;
            };
        }

        my $isArray = $self->is_array($index);

        my $heapptr = $self->require_heapptr($index);
        if ( $stash->{$heapptr} ) {
            $ret = $stash->{$heapptr};
        }
        else {
            $ret = $isArray ? [] : {};
            $stash->{$heapptr} = $ret;
        }

        $self->enum( $index, JavaScript::Duktape::DUK_ENUM_OWN_PROPERTIES_ONLY );

        while ( $self->next( -1, 1 ) ) {
            my ( $key, $val );

            $key = $self->to_perl(-2);

            if ( $self->get_type(-1) == JavaScript::Duktape::DUK_TYPE_OBJECT ) {
                my $heapptr = $self->get_heapptr(-1);
                if ( $stash->{$heapptr} ) {
                    $val = $stash->{$heapptr};
                }
                else {
                    $val = $self->to_perl( -1, $stash );
                }
            }
            else {
                $val = $self->to_perl(-1);
            }

            $self->pop_n(2);

            if ($isArray) {
                $ret->[$key] = $val;
            }
            else {
                $ret->{$key} = $val;
            }
        }

        $self->pop();
    }

    elsif ( $type == JavaScript::Duktape::DUK_TYPE_BOOLEAN ) {
        my $bool = $self->get_boolean($index);
        if ( $bool == 1 ) {
            $ret = JavaScript::Duktape::Bool::true();
        }
        else {
            $ret = JavaScript::Duktape::Bool::false();
        }
    }

    elsif ( $type == JavaScript::Duktape::DUK_TYPE_NULL ) {
        $ret = JavaScript::Duktape::NULL::null();
    }

    elsif ( $type == JavaScript::Duktape::DUK_TYPE_POINTER ) {
        my $p = $self->get_pointer($index);
        $ret = bless \$p, 'JavaScript::Duktape::Pointer';
    }

    return $ret;
}

##############################################
# push functions
##############################################
sub push_function {
    my $self  = shift;
    my $sub   = shift;
    my $nargs = shift || -1;

    $self->push_c_function(
        sub {
            my @args;
            my $top = $self->get_top();
            for ( my $i = 0 ; $i < $top ; $i++ ) {
                push @args, $self->to_perl($i);
            }

            $self->push_this();
            my $heap = $self->get_heapptr(-1);
            $self->pop();

            if ( !$heap ) {
                $self->push_global_object();
                $heap = $self->get_heapptr(-1);
                $self->pop();
            }

            $THIS->{heapptr} = $heap;
            $THIS->{duk}     = $self;

            my $ret = $sub->(@args);
            $self->push_perl($ret);
            return 1;
        },
        $nargs
    );
}

#####################################################################
# safe call
#####################################################################
sub push_c_function {
    my $self  = shift;
    my $sub   = shift;
    my $nargs = shift || -1;

    $GlobalRef->{"$sub"} = sub {
        my @args = @_;
        my $top  = $self->get_top();
        my $ret  = 1;

        my $err = $self->safe_call(
            sub {
                $ret = $sub->(@args);
                return 1;
            },
            $top,
            1
        );

        if ($err) {
            croak $self->last_error_string();
        }
        return $ret;
    };

    $self->perl_push_function( $GlobalRef->{"$sub"}, $nargs );
    $self->eval_string("(function(){perlFinalizer('$sub')})");
    $self->set_finalizer(-2);
}

#####################################################################
# safe call
#####################################################################
sub safe_call {
    my $self = shift;
    my $sub  = shift;
    my $ret;
    my $safe = sub {
        local $@;
        eval { $ret = $sub->($self) };
        if ( my $error = $@ ) {
            if ( $error =~ /^Duk::Error/i ) {
                croak $self->last_error_string();
            }
            else {
                $self->eval_string('(function (e){ throw new Error(e) })');
                $self->push_string($error);
                $self->call(1);
            }
        }

        return defined $ret ? $ret : 1;
    };

    eval { $ret = $self->perl_duk_safe_call( $safe, @_ ) };
    return defined $ret ? $ret : 1;
}

sub set_timeout {
    my $self = shift;
    my $timeout = shift;

    croak "timeout must be a number" if !duk_sv_is_number($timeout);
    $self->perl_duk_set_timeout($timeout);
}

sub resize_memory {
    my $self = shift;
    my $max_memory = shift || 0;

    croak "max_memory should be a number" if !duk_sv_is_number( $max_memory );
    croak "max_memory must be at least 256k (256 * 1024)" if $max_memory < 256 * 1024;

    $self->perl_duk_resize_memory($max_memory);
}

##############################################
# custom functions
##############################################
*get_utf8_string     = \&perl_duk_get_utf8_string;
*push_perl_function  = \&push_c_function;
*push_light_function = \&perl_push_function;

##############################################
# overridden functions
##############################################
*require_context = \&perl_duk_require_context;

##############################################
# helper functions
##############################################
*reset_top = \&perl_duk_reset_top;

sub last_error_string {
    my $self = shift;
    $self->dup(-1);
    my $error_str = $self->safe_to_string(-1);
    $self->pop();
    return $error_str;
}

sub dump {
    my $self = shift;
    my $name = shift || "Duktape";
    my $fh   = shift || \*STDOUT;
    my $n    = $self->get_top();
    printf $fh "%s (top=%ld):", $name, $n;
    for ( my $i = 0 ; $i < $n ; $i++ ) {
        printf $fh " ";
        $self->dup($i);
        printf $fh "%s", $self->safe_to_string(-1);
        $self->pop();
    }
    printf $fh "\n";
}

sub DESTROY { }

package JavaScript::Duktape::Bool;
{
    use warnings;
    use strict;
    our ( $true, $false );
    use overload
      '""'   => sub { ${ $_[0] } },
      'bool' => sub { ${ $_[0] } ? 1 : 0 },
      fallback => 1;

    BEGIN {
        my $use_boolean = eval { require boolean; 1; };
        my $t = 1;
        my $f = 0;
        $true  = $use_boolean ? boolean::true() : bless \$t, 'JavaScript::Duktape::Bool';
        $false = $use_boolean ? boolean::false() : bless \$f, 'JavaScript::Duktape::Bool';
    }

    sub true  { $true }
    sub false { $false }

    sub TO_JSON { ${$_[0]} ? \1 : \0 }
}

package JavaScript::Duktape::NULL;
{
    use warnings;
    use strict;
    our ($null);
    use overload
      '""'   => sub { ${ $_[0] } },
      'bool' => sub { ${ $_[0] } ? 1 : 0 },
      fallback => 1;

    BEGIN {
        my $n = '';
        $null = bless \$n, 'JavaScript::Duktape::NULL';
    }

    sub null { $null }
}

package JavaScript::Duktape::Object;
{
    use warnings;
    use strict;
    use Carp;
    use Data::Dumper;
    my $CONSTRUCTORS = {};
    use Scalar::Util 'weaken';
    use overload '""' => sub {
        my $self = shift;
        $self->inspect();
      },
      fallback => 1;

    sub inspect {
        my $self    = shift;
        my $heapptr = $self->{heapptr};
        my $duk     = $self->{duk};
        $duk->push_heapptr($heapptr);
        my $ret = $duk->to_perl(-1);
        $duk->pop();
        return $ret;
    }

    our $AUTOLOAD;

    sub AUTOLOAD {
        my $self     = shift;
        my $heapptr  = $self->{heapptr};
        my $duk      = $self->{duk};
        my ($method) = ( $AUTOLOAD =~ /([^:']+$)/ );
        return if $method eq 'DESTROY';
        return JavaScript::Duktape::Util::autoload( $self, $method, $duk, $heapptr, @_ );
    }

    DESTROY {
        my $self = shift;
        my $duk  = $self->{duk};

        my $refcount = delete $self->{refcount};
        return if ( !$refcount );
        $duk->push_global_stash();
        $duk->get_prop_string( -1, "PerlGlobalStash" );
        $duk->push_number($refcount);
        $duk->del_prop(-2);
        $duk->pop_2();
    }
}

package JavaScript::Duktape::Function;
{
    use strict;
    use warnings;
    use Data::Dumper;

    sub new {
        my $self = shift;
        $self->( $isNew, @_ );
    }

    our $AUTOLOAD;

    sub AUTOLOAD {
        my $self    = shift;
        my $heapptr = $self->($HEAP);
        my $duk     = $self->($DUK);

        my ($method) = ( $AUTOLOAD =~ /([^:']+$)/ );
        return if $method eq 'DESTROY';
        return JavaScript::Duktape::Util::autoload( $self, $method, $duk, $heapptr, @_ );
    }

    sub DESTROY { }
};

package JavaScript::Duktape::Util;
{
    use strict;
    use warnings;
    use Data::Dumper;
    use Carp;

    sub autoload {
        my $self    = shift;
        my $method  = shift;
        my $duk     = shift;
        my $heapptr = shift;

        $duk->push_heapptr($heapptr);
        if ( $method eq 'new' ) {
            my $len = @_ + 0;
            foreach my $val (@_) {
                $duk->push_perl($val);
            }
            if ( $duk->pnew($len) != 0 ) {
                croak $duk->last_error_string();
            }
            my $val = $duk->to_perl_object(-1);
            $duk->pop();
            return $val;
        }

        my $val = undef;
        $duk->get_prop_string( -1, $method );

        my $type = $duk->get_type(-1);
        if (   $type == JavaScript::Duktape::DUK_TYPE_OBJECT
            || $type == JavaScript::Duktape::DUK_TYPE_BUFFER )
        {

            if ( $duk->is_function(-1) ) {
                my $function_heap = $duk->get_heapptr(-1);

                if (@_) {
                    #called with special no arg _
                    shift if ( ref $_[0] eq 'NOARGS' );
                    $val = jsFunction( $method, $duk, $function_heap, $heapptr, 'call', @_ );
                }
                else {
                    $val = jsFunction( $method, $duk, $function_heap, $heapptr );
                }
            }
            else {
                $val = $duk->to_perl_object(-1);
            }
        }
        else {
            $val = $duk->to_perl(-1);
        }
        $duk->pop_2();
        return $val;
    }

    sub jsFunction {
        my $methodname  = shift;
        my $duk         = shift;
        my $heapptr     = shift;
        my $constructor = shift || $heapptr;
        my $doCall      = shift;
        my $sub         = sub {

            # check first value, if it a ref of NEW
            # then this is a constructor call, other wise
            # it's just a normal call
            my $isNew;
            my $ref = ref $_[0];
            if ( $ref eq "NEW" ) {
                shift;
                $isNew = 1;
            }
            elsif ( $ref eq "HEAP" ) {
                return $heapptr;
            }
            elsif ( $ref eq "DUK" ) {
                return $duk;
            }

            my $len = @_ + 0;
            $duk->push_heapptr($heapptr);
            $duk->push_heapptr($constructor) if !$isNew;
            foreach my $val (@_) {
                if ( ref $val eq 'CODE' ) {
                    $duk->push_function($val);
                }
                else {
                    $duk->push_perl($val);
                }
            }

            if ($isNew) {
                if ( $duk->pnew($len) != 0 ) {
                    croak $duk->last_error_string();
                }
            }
            else {
                if ( $duk->pcall_method($len) != 0 ) {
                    croak $duk->last_error_string();
                }
            }

            my $ret;
            ##getting function call values
            my $type = $duk->get_type(-1);
            if (   $type == JavaScript::Duktape::DUK_TYPE_OBJECT
                || $type == JavaScript::Duktape::DUK_TYPE_BUFFER )
            {
                $ret = $duk->to_perl_object(-1);
            }
            else {
                $ret = $duk->to_perl(-1);
            }
            $duk->pop();
            return $ret;
        };

        return $sub->(@_) if $doCall;
        return bless $sub, "JavaScript::Duktape::Function";
    }

    my $REFCOUNT = 0;

    sub jsObject {
        my $options = shift;

        my $duk         = $options->{duk};
        my $heapptr     = $options->{heapptr};
        my $constructor = $options->{constructor} || $heapptr;

        #We may push same heapptr on the global stack more
        #than once, this results in segmentation fault when
        #we destroy the object and delete heapptr from the
        #global stash then trying to use it again
        #TODO : this is really a poor man solution
        #for this problem, we use a refcounter to create
        #a unique id for each heapptr, a better solution
        #would be making sure same heapptr pushed once and not to
        #be free unless all gone
        my $refcount = ( ++$REFCOUNT ) + ( rand(3) );

        $duk->push_global_stash();
        $duk->get_prop_string( -1, "PerlGlobalStash" );
        $duk->push_number($refcount);
        $duk->push_heapptr($heapptr);
        $duk->put_prop(-3);    #PerlGlobalStash[heapptr] = object
        $duk->pop_2();

        my $type = $duk->get_type(-1);

        if ( $duk->is_function(-1) ) {
            return JavaScript::Duktape::Util::jsFunction( 'anon', $duk, $heapptr, $constructor );
        }

        return bless {
            refcount => $refcount,
            duk      => $duk,
            heapptr  => $heapptr
        }, "JavaScript::Duktape::Object";
    }
}

1;

__END__
=encoding utf-8

=head1 NAME

JavaScript::Duktape - Perl interface to Duktape embeddable javascript engine

=for html
<a href="https://travis-ci.org/mamod/JavaScript-Duktape"><img src="https://travis-ci.org/mamod/JavaScript-Duktape.svg?branch=master"></a>

=head1 SYNOPSIS

    use JavaScript::Duktape;

    ## create new js context
    my $js = JavaScript::Duktape->new();

    # set function to be used from javascript land
    $js->set('write' => sub {
        print $_[0], "\n";
    });

    $js->eval(qq{
        (function(){
            for (var i = 0; i < 100; i++){
                write(i);
            }
        })();
    });

=head1 DESCRIPTION

JavaScript::Duktape implements almost all duktape javascript engine api, the c code is just
a thin layer that maps duktape api to perl, and all other functions implemented in perl
it self, so maintaing and contributing to the base code should be easy.

=head1 JavaScript::Duktape->new(%options)

initiate JavaScript::Duktape with options

=head2 options

=over 4

=item max_memory

Set maximum memory allowed for the excuted javascript code to consume, not setting
this option is the default, which means no restricts on the maximum memory that can
be consumed.

Minumum value to set for the C<max_memory> option is 256 * 1024 = (256k)
setting number below 256k will croak.

    max_memory => 256 * 1024 * 2

You can resize the memory allowed to consume on different executions by calling
C<resize_memory> method, see L</Sandboxing> section below.

=item timout

Set maximum time javascript code can run, this value represented in seconds and is not 100% guranteed
that the javascript code will fail after the exact value passed, but it will eventually fail on first tick checking.

Not setting this option is the default, which means no timeout checking at all

    timeout => 5

You can override this value later on another code evaluation by calling C<set_timeout> method

    $js->set_timeout(25);

See L</Sandboxing> section below

=back

=head1 methods

=over 4

=item set('name', data);

Creates property 'name' and sets it's value to the given perl data

    $js->set('something', {}); #set something
    $js->set('something.name', 'Joe');
    $js->set('number', 1234);
    ...

this method will die if you try to set a property on undfined base value

    $js->set('notHere.name', 'Joe'); ## will die

    ## so first set "notHere"
    $js->set('notHere', {});
    $js->set('notHere.name', 'Joe'); ## good


=item get('name');

Gets property 'name' value from javascript and return it as perl data, this method will die
if you try to get value of undefined base value

    my $print_sub = $js->get('print');

=item eval('javascript');

Evaluates javascript string and return the results or croak if error

    my $ret = $js->eval(q{
        var t = 1+2;
        t; // return value from eval
    });

    print $ret, "\n"; # 3


=item get_object('name');

Same as C<get> method but instead of returning a raw value of the property name, it will
return a C<JavaScript::Duktape::Object> this method will die if you try to get a property
that is not of type 'object'

    $js->eval(q{
        function Person (name){
            this.name = name;
        }
    });

    my $personObject = $js->get('Person');

    # $personObject is a blessed 'JavaScript::Duktape::Object' object
    # so you can call internal

    my $person = $personObject->new('Joe');
    print $person->name, "\n"; # Joe

For more on how you can use C<JavaScript::Duktape::Object> please see
examples provided with this distribution

=back

=head1 Sandboxing

As of version C<2.2.0> C<JavaScript::Duktape> integrated some of
Duktape Engine Sandboxing methods, this will allow developers to restrict
the running javascript code by restricting memory consumption and running time

C<DUK_USE_EXEC_TIMEOUT_CHECK> flag is set by default to enable
L<< Bytecode execution timeout|https://github.com/svaarala/duktape/blob/master/doc/sandboxing.rst#bytecode-execution-timeout-details >>

    # prevent javascript code to consume memory more
    # than max_memory option

    my $js = JavaScript::Duktape->new( max_memory => 256 * 1024 );

    # this will fail with "Error: alloc failed" message
    # when running, because it will consume more memory
    # than the allowed max_memory
    $js->eval(q{
        var str = '';
        while(1){ str += 'XXXX' }
    });

=head2 C<set_timout(t)>

Enable/Disable timeout checking, to disable set the value to 0
this value is in seconds

    my $js = JavaScript::Duktape->new();

    # throw 'time out' Error if executed
    # js code does not finish after 5 seconds
    $js->set_timeout(5);

    eval {
        $js->eval(q{
            while(1){}
        });
    };

    print $@, "\n"; #RangeError: execution timeout

    # disable timeout checking
    $js->set_timeout(0);

    # now will run infinitely
    $js->eval(q{
        while(1){}
    });

This method can be used with duktape VM instance too

    my $js = JavaScript::Duktape->new();
    my $duk = $js->duk();

    $duk->set_timeout(3);
    $duk->peva_stringl(q{
        while (1){}
    });

    print $duk->safe_to_string(-1); # Error: execution 'time out'

=head2 C<resize_memory(m)>

This method will have effect only if you intiated with max_memory option

    my $js = JavaScript::Duktape->new( max_memory => 1024 * 256 );


    eval {
        $js->eval(q{
            var buf = Buffer(( 1024 * 256 ) + 1000 );
            print('does not reach');
        });
    };

    print $@, "\n"; # Error: 'alloc failed'

    $js->resize_memory( 1024 * 256 * 2 );

    # now it will not throw
    $js->eval(q{
        var buf = Buffer(( 1024 * 256 ) + 1000 );
        print('ok');
    });



=head1 VM API

vm api corresponds to Duktape Engine API see L<http://duktape.org/api.html>
To access vm create new context then call C<vm>

    my $js = JavaScript::Duktape->new();
    my $duk = $js->vm;

    #now you can call Duktape API from perl

    $duk->push_string('print');
    $duk->eval();
    $duk->push_string('hi');
    $duk->call(1);
    $duk->pop();

Also you may find it useful to use C<dump> function
regularly to get a better idea where you're in the stack, the following code is the same example
above but with using C<dump> function to get a glance of stack top

    my $js = JavaScript::Duktape->new();
    my $duk = $js->duk;

    #push "print" string
    $duk->push_string('print');
    $duk->dump(); #-> [ Duktape (top=1): print ]

    #since print is a native function we need to evaluate it
    $duk->eval();
    $duk->dump(); #-> [ Duktape (top=1): function print() {/* native */} ]

    #push one argument to print function
    $duk->push_string('hi');
    $duk->dump(); #-> [ Duktape (top=2): function print() {/* native */} hi ]

    #now call print function and pass "hi" as one argument
    $duk->call(1);

    #since print function doesn't return any value, it will push undefined to the stack
    $duk->dump(); #-> [ Duktape (top=1): undefined ]

    #pop to remove undefined from stack top
    $duk->pop();

    #Bingo
    $duk->dump(); #-> [ Duktape (top=0): ]

=head1 VM methods

As a general rule all duktape api supported, but I haven't had the chance to test them all,
so please report any missing or failure api call and I'll try to fix

For the list of duktape engine API please see L<http://duktape.org/api.html>, and here is how
you can translate duktape api to perl

    my $js = JavaScript::Duktape->new();
    my $duk = $js->duk;

    # -- C example
    # duk_push_c_function(func, 2);
    # duk_push_int(ctx, 2);
    # duk_push_int(ctx, 3);
    # duk_call(ctx, 2);  /* [ ... func 2 3 ] -> [ 5 ] */
    # printf("2+3=%ld\n", (long) duk_get_int(ctx, -1));
    # duk_pop(ctx);

    #and here is how we can implement it in JavaScript::Duktape

    $duk->push_c_function(sub {
        my $num1 = $duk->get_int(0);
        my $num2 = $duk->get_int(1);

        my $total = $num1+$num2;
        $duk->push_number($total);
        return 1;
    }, 2);

    $duk->push_int(2);
    $duk->push_int(3);
    $duk->call(2);  # [ ... func 2 3 ] -> [ 5 ]
    printf("2+3=%ld\n", $duk->get_int(-1));
    $duk->pop();

As you can see all you need to do is replacing C<duk_> with C<< $duk-> >> and remove C<ctx> from the function call,
this may sounds crazy but api tests have been generated by copying duktape tests and using search and replace tool :)

Besides duktape api, C<JavaScript::Duktape::Vm> implements the following methods

=over 4

=item push_function ( code_ref );

push perl sub into duktape stack, this is the same as push_perl_function
except it will handle both passed arguments and return data for you

    $duk->push_function(sub {
        my ($arg1, $arg2, ...) = @_;
        return $something;
    });

=item push_perl_function ( code_ref, num_of_args );

an alias to push_c_function, same as push_perl_function except you will be
responsible for extracting arguments and pushing returning data

    $duk->push_perl_function(sub {
        my $arg1 = $duk->get_int(-1);
        my $somthing_to_return = "..";
        $duk->push_string($somthing_to_return);
        return 1;
    });

=item push_perl( ... );

Push given perl data into the duktape stack.

=item to_perl(index);

Get the value at index and return it as perl data

=item to_perl_object(index);

Get object at index and return it as 'JavaScript::Duktape::Object', this
function will die if javascript data at index is not of type object

=item reset_top

resets duktape stack top

=back

=head1 EXPORTS

C<JavaScript::Duktape> exports the following by default

=over 4

=item true

=item false

=item null

=item _ (underscore)

This can be used to indicate that we are calling an object function
without arguments, see L</CAVEATS>

=item this

This can be called from pushed perl sub

    $duk->push_perl_function(sub{
        my $this = this;
    });

See C<examples/this.pl>

=back

=head1 DEAFULT JAVASCRIPT FUNCTIONS

JavaScript::Duktape has C<alert> and C<print> functions available as global
functions to javascript, where C<alert> prints to STDERR and C<print> prints
to STDOUT.

=head1 CAVEATS

=head2 VM methods

C<JavaScript::Duktape> vm methods is a direct low level calls to duktape c library, so stepping
outside of the stack will result in a program termination without a useful error message, so you
need to be careful when using these methods and always check your stack with C<< $duk->dump() >> method

=head2 JavaScript::Duktape::Object

C<JavaScript::Duktape::Object> use overload and AUTOLOAD internally, so there is no way to guess if
you're trying to get a property type of function or executing it, this is the same as javascript behaviour

    # js
    $js->eval(q{
        function test () {
            return 'Hi';
        }

        print(test); // function(){ ... }
        print(test()) // Hi
    });

    ## same thing when we do it in perl
    my $test = $js->get_object('test');

    print $test, "\n"; #JavaScript::Duktape::Function=CODE(...)
    print $test->(), "\n"; #Hi

This may sound ok with simple function calls but gets ugly not perlish when you're trying
to call deep object properties

So C<JavaScript::Duktape> exports a special variable underscore '_' by default
this to indicate that we are calling the function with no arguments

    $js->eval(q{
        function Person (name){
            this.name = name;
        }

        Person.prototype.getName = function(){
            print(this.name);
        };

        var me = new Person('Joe');
        print(me.getName); // function(){ ... }
        print(me.getName()); // Joe
    });

    # Now let's do it in perl
    my $Person = $js->get_object('Person');
    my $me = $Person->new('Joe');

    print $me->getName, "\n"; #JavaScript::Duktape::Function=CODE(...)
    print $me->getName(), "\n"; #JavaScript::Duktape::Function=CODE(...)
    print $me->getName->(), "\n"; # Joe

    #however if you pass any argument with the function it will work
    print $me->getName(0), "\n"; #Joe

    # or you can use special null argument _ which we export by default
    print $me->getName(_), "\n"; #Joe


=head1 AUTHOR

Mamod Mehyar C<< <mamod.mehyar@gmail.com> >>

=head1 CONTRIBUTORS

Thanks for everyone who contributed to this module, either by code, bug reports, API design
or suggestions

=over 4

=item * Rodrigo de Oliveira L<@rodrigolive|https://github.com/rodrigolive>

=item * jomo666 L<@jomo666|https://github.com/jomo666>

=item * Viacheslav Tykhanovskyi L<@vti|https://github.com/vti>

=item * Slaven Rezić L<@eserte|https://github.com/eserte>

=item * Max Maischein L<@Corion|https://github.com/Corion>

=back

=head1 APPRECIATION

Credits should go to L<< Duktape Javascript embeddable engine|http://duktape.org >> and it's creator L<< Sami Vaarala|https://github.com/svaarala >>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
