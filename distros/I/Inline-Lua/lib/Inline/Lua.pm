package Inline::Lua;

# ABSTRACT: Embed Lua and Fennel code in your Perl scripts

use strict;
use warnings;
use JSON::MaybeXS;
use Cpanel::JSON::XS;
use FFI::Platypus 2.00;

our $VERSION = '1.0.0';

BEGIN {
    # This context hash will hold our FFI object and functions.
    my %context;

    # Create the FFI object INSIDE the BEGIN block so it's in the correct scope.
    my $ffi = FFI::Platypus->new(
        api  => 2,
        lang => 'Rust',
    );
    # This command tells Platypus to find the compiled Rust library
    # that FFI::Build::MM has placed in the blib/ directory.
    $ffi->bundle;

    $context{ffi} = $ffi;

    # The rest of the setup is the same as before.
    $context{ffi}->type('uint64' => 'uintptr_t');
    $context{ffi}->type('opaque' => 'LuaRuntime');

    $context{new}         = $context{ffi}->function('inline_lua_new'         => ['string'] => 'opaque');
    $context{destroy}     = $context{ffi}->function('inline_lua_destroy'     => ['LuaRuntime'] => 'void');
    $context{eval}        = $context{ffi}->function('inline_lua_eval'        => ['LuaRuntime', 'string'] => 'opaque');
    $context{eval_fennel} = $context{ffi}->function('inline_lua_eval_fennel' => ['LuaRuntime', 'string'] => 'opaque');
    $context{free_string} = $context{ffi}->function('inline_lua_free_string' => ['opaque'] => 'void');
    
    $context{json} = JSON::MaybeXS->new(utf8 => 1, allow_nonref => 1);

    *new = sub {
        my ($class, %args) = @_;
        
        my $options = {
            enable_fennel => defined $args{enable_fennel} ? ($args{enable_fennel} ? Cpanel::JSON::XS::true() : Cpanel::JSON::XS::false()) : Cpanel::JSON::XS::true(),
            sandboxed     => defined $args{sandboxed}     ? ($args{sandboxed}     ? Cpanel::JSON::XS::true() : Cpanel::JSON::XS::false()) : Cpanel::JSON::XS::true(),
            cache_fennel  => defined $args{cache_fennel}  ? ($args{cache_fennel}  ? Cpanel::JSON::XS::true() : Cpanel::JSON::XS::false()) : Cpanel::JSON::XS::true(),
        };
        
        my $json_options = $context{json}->encode($options);
        
        my $result_ptr = $context{new}->call($json_options);
        
        my $runtime_address = $class->_process_result($result_ptr);

        my $runtime_ptr = $context{ffi}->cast('uintptr_t' => 'LuaRuntime', $runtime_address);

        my $self = bless { runtime => $runtime_ptr, context => \%context }, $class;
        return $self;
    };

    *eval = sub {
        my ($self, $code) = @_;
        my $result_ptr = $self->{context}->{eval}->call($self->{runtime}, $code);
        return $self->_process_result($result_ptr);
    };
    
    *eval_fennel = sub {
        my ($self, $code) = @_;
        my $result_ptr = $self->{context}->{eval_fennel}->call($self->{runtime}, $code);
        return $self->_process_result($result_ptr);
    };

    *_process_result = sub {
        my ($self_or_class, $ptr) = @_;
        my $context = ref($self_or_class) ? $self_or_class->{context} : \%context;

        die "FATAL: Rust function returned a null pointer. This indicates a panic." unless $ptr;

        my $json_string = $context{ffi}->cast('opaque' => 'string', $ptr);
        $context{free_string}->call($ptr);

        my $data;
        eval {
            $data = $context{json}->decode($json_string);
            1;
        } or do {
            my $eval_error = $@ || 'Unknown JSON decoding error';
            die "Failed to decode JSON response from Rust: $eval_error\nReceived: $json_string";
        };

        if (exists $data->{error} && defined $data->{error}) {
            die "Error from Rust backend: " . $data->{error};
        }

        return $data->{ok};
    };

    *DESTROY = sub {
        my ($self) = @_;
        if (ref($self) && $self->{runtime}) {
            $self->{context}->{destroy}->call($self->{runtime});
            $self->{runtime} = undef;
        }
    };
}

1;
