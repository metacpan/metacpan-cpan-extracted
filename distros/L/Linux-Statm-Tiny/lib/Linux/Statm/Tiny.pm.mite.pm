{
package Linux::Statm::Tiny;
use strict;
use warnings;
no warnings qw( once void );

our $USES_MITE = "Mite::Class";
our $MITE_SHIM = "Linux::Statm::Tiny::Mite";
our $MITE_VERSION = "0.013000";
# Mite keywords
BEGIN {
    my ( $SHIM, $CALLER ) = ( "Linux::Statm::Tiny::Mite", "Linux::Statm::Tiny" );
    ( *after, *around, *before, *extends, *has, *signature_for, *with ) = do {
        package Linux::Statm::Tiny::Mite;
        no warnings 'redefine';
        (
            sub { $SHIM->HANDLE_after( $CALLER, "class", @_ ) },
            sub { $SHIM->HANDLE_around( $CALLER, "class", @_ ) },
            sub { $SHIM->HANDLE_before( $CALLER, "class", @_ ) },
            sub {},
            sub { $SHIM->HANDLE_has( $CALLER, has => @_ ) },
            sub { $SHIM->HANDLE_signature_for( $CALLER, "class", @_ ) },
            sub { $SHIM->HANDLE_with( $CALLER, @_ ) },
        );
    };
};

# Gather metadata for constructor and destructor
sub __META__ {
    no strict 'refs';
    my $class      = shift; $class = ref($class) || $class;
    my $linear_isa = mro::get_linear_isa( $class );
    return {
        BUILD => [
            map { ( *{$_}{CODE} ) ? ( *{$_}{CODE} ) : () }
            map { "$_\::BUILD" } reverse @$linear_isa
        ],
        DEMOLISH => [
            map { ( *{$_}{CODE} ) ? ( *{$_}{CODE} ) : () }
            map { "$_\::DEMOLISH" } @$linear_isa
        ],
        HAS_BUILDARGS => $class->can('BUILDARGS'),
        HAS_FOREIGNBUILDARGS => $class->can('FOREIGNBUILDARGS'),
    };
}


# Standard Moose/Moo-style constructor
sub new {
    my $class = ref($_[0]) ? ref(shift) : shift;
    my $meta  = ( $Mite::META{$class} ||= $class->__META__ );
    my $self  = bless {}, $class;
    my $args  = $meta->{HAS_BUILDARGS} ? $class->BUILDARGS( @_ ) : { ( @_ == 1 ) ? %{$_[0]} : @_ };
    my $no_build = delete $args->{__no_BUILD__};

    # Attribute pid (type: Int)
    # has declaration, file lib/Linux/Statm/Tiny.pm, line 42
    if ( exists $args->{"pid"} ) { (do { my $tmp = $args->{"pid"}; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or Linux::Statm::Tiny::Mite::croak "Type check failed in constructor: %s should be %s", "pid", "Int"; $self->{"pid"} = $args->{"pid"}; } ;


    # Call BUILD methods
    $self->BUILDALL( $args ) if ( ! $no_build and @{ $meta->{BUILD} || [] } );

    # Unrecognized parameters
    my @unknown = grep not( /\A(?:d(?:ata_pages|t_pages)|lib_pages|pid|r(?:esident_pages|ss(?:_(?:bytes|kb|mb|pages))?)|s(?:hare_pages|ize_pages)|text_pages|vsz(?:_(?:bytes|kb|mb|pages))?)\z/ ), keys %{$args}; @unknown and Linux::Statm::Tiny::Mite::croak( "Unexpected keys in constructor: " . join( q[, ], sort @unknown ) );

    return $self;
}

# Used by constructor to call BUILD methods
sub BUILDALL {
    my $class = ref( $_[0] );
    my $meta  = ( $Mite::META{$class} ||= $class->__META__ );
    $_->( @_ ) for @{ $meta->{BUILD} || [] };
}

# Destructor should call DEMOLISH methods
sub DESTROY {
    my $self  = shift;
    my $class = ref( $self ) || $self;
    my $meta  = ( $Mite::META{$class} ||= $class->__META__ );
    my $in_global_destruction = defined ${^GLOBAL_PHASE}
        ? ${^GLOBAL_PHASE} eq 'DESTRUCT'
        : Devel::GlobalDestruction::in_global_destruction();
    for my $demolisher ( @{ $meta->{DEMOLISH} || [] } ) {
        my $e = do {
            local ( $?, $@ );
            eval { $demolisher->( $self, $in_global_destruction ) };
            $@;
        };
        no warnings 'misc'; # avoid (in cleanup) warnings
        die $e if $e;       # rethrow
    }
    return;
}

my $__XS = !$ENV{PERL_ONLY} && eval { require Class::XSAccessor; Class::XSAccessor->VERSION("1.19") };

# Accessors for data
# has declaration, file lib/Linux/Statm/Tiny.pm, line 142
sub _refresh_data { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Clearer "_refresh_data" usage: $self->_refresh_data()' ); delete $_[0]{"data"}; $_[0]; }
sub data { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Reader "data" usage: $self->data()' ); ( exists($_[0]{"data"}) ? $_[0]{"data"} : ( $_[0]{"data"} = do { my $default_value = $Linux::Statm::Tiny::__data_DEFAULT__->( $_[0] ); (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or Linux::Statm::Tiny::Mite::croak( "Type check failed in default: %s should be %s", "data", "Int" ); $default_value } ) ) }

# Aliases for data
# has declaration, file lib/Linux/Statm/Tiny.pm, line 142
sub data_pages { shift->data( @_ ) }

# Accessors for data_bytes
# has declaration, file lib/Linux/Statm/Tiny.pm, line 158
sub _refresh_data_bytes { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Clearer "_refresh_data_bytes" usage: $self->_refresh_data_bytes()' ); delete $_[0]{"data_bytes"}; $_[0]; }
sub data_bytes { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Reader "data_bytes" usage: $self->data_bytes()' ); ( exists($_[0]{"data_bytes"}) ? $_[0]{"data_bytes"} : ( $_[0]{"data_bytes"} = do { my $default_value = $Linux::Statm::Tiny::__data_bytes_DEFAULT__->( $_[0] ); (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or Linux::Statm::Tiny::Mite::croak( "Type check failed in default: %s should be %s", "data_bytes", "Int" ); $default_value } ) ) }

# Accessors for data_kb
# has declaration, file lib/Linux/Statm/Tiny.pm, line 158
sub _refresh_data_kb { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Clearer "_refresh_data_kb" usage: $self->_refresh_data_kb()' ); delete $_[0]{"data_kb"}; $_[0]; }
sub data_kb { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Reader "data_kb" usage: $self->data_kb()' ); ( exists($_[0]{"data_kb"}) ? $_[0]{"data_kb"} : ( $_[0]{"data_kb"} = do { my $default_value = $Linux::Statm::Tiny::__data_kb_DEFAULT__->( $_[0] ); (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or Linux::Statm::Tiny::Mite::croak( "Type check failed in default: %s should be %s", "data_kb", "Int" ); $default_value } ) ) }

# Accessors for data_mb
# has declaration, file lib/Linux/Statm/Tiny.pm, line 158
sub _refresh_data_mb { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Clearer "_refresh_data_mb" usage: $self->_refresh_data_mb()' ); delete $_[0]{"data_mb"}; $_[0]; }
sub data_mb { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Reader "data_mb" usage: $self->data_mb()' ); ( exists($_[0]{"data_mb"}) ? $_[0]{"data_mb"} : ( $_[0]{"data_mb"} = do { my $default_value = $Linux::Statm::Tiny::__data_mb_DEFAULT__->( $_[0] ); (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or Linux::Statm::Tiny::Mite::croak( "Type check failed in default: %s should be %s", "data_mb", "Int" ); $default_value } ) ) }

# Accessors for dt
# has declaration, file lib/Linux/Statm/Tiny.pm, line 142
sub _refresh_dt { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Clearer "_refresh_dt" usage: $self->_refresh_dt()' ); delete $_[0]{"dt"}; $_[0]; }
sub dt { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Reader "dt" usage: $self->dt()' ); ( exists($_[0]{"dt"}) ? $_[0]{"dt"} : ( $_[0]{"dt"} = do { my $default_value = $Linux::Statm::Tiny::__dt_DEFAULT__->( $_[0] ); (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or Linux::Statm::Tiny::Mite::croak( "Type check failed in default: %s should be %s", "dt", "Int" ); $default_value } ) ) }

# Aliases for dt
# has declaration, file lib/Linux/Statm/Tiny.pm, line 142
sub dt_pages { shift->dt( @_ ) }

# Accessors for dt_bytes
# has declaration, file lib/Linux/Statm/Tiny.pm, line 158
sub _refresh_dt_bytes { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Clearer "_refresh_dt_bytes" usage: $self->_refresh_dt_bytes()' ); delete $_[0]{"dt_bytes"}; $_[0]; }
sub dt_bytes { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Reader "dt_bytes" usage: $self->dt_bytes()' ); ( exists($_[0]{"dt_bytes"}) ? $_[0]{"dt_bytes"} : ( $_[0]{"dt_bytes"} = do { my $default_value = $Linux::Statm::Tiny::__dt_bytes_DEFAULT__->( $_[0] ); (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or Linux::Statm::Tiny::Mite::croak( "Type check failed in default: %s should be %s", "dt_bytes", "Int" ); $default_value } ) ) }

# Accessors for dt_kb
# has declaration, file lib/Linux/Statm/Tiny.pm, line 158
sub _refresh_dt_kb { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Clearer "_refresh_dt_kb" usage: $self->_refresh_dt_kb()' ); delete $_[0]{"dt_kb"}; $_[0]; }
sub dt_kb { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Reader "dt_kb" usage: $self->dt_kb()' ); ( exists($_[0]{"dt_kb"}) ? $_[0]{"dt_kb"} : ( $_[0]{"dt_kb"} = do { my $default_value = $Linux::Statm::Tiny::__dt_kb_DEFAULT__->( $_[0] ); (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or Linux::Statm::Tiny::Mite::croak( "Type check failed in default: %s should be %s", "dt_kb", "Int" ); $default_value } ) ) }

# Accessors for dt_mb
# has declaration, file lib/Linux/Statm/Tiny.pm, line 158
sub _refresh_dt_mb { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Clearer "_refresh_dt_mb" usage: $self->_refresh_dt_mb()' ); delete $_[0]{"dt_mb"}; $_[0]; }
sub dt_mb { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Reader "dt_mb" usage: $self->dt_mb()' ); ( exists($_[0]{"dt_mb"}) ? $_[0]{"dt_mb"} : ( $_[0]{"dt_mb"} = do { my $default_value = $Linux::Statm::Tiny::__dt_mb_DEFAULT__->( $_[0] ); (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or Linux::Statm::Tiny::Mite::croak( "Type check failed in default: %s should be %s", "dt_mb", "Int" ); $default_value } ) ) }

# Accessors for lib
# has declaration, file lib/Linux/Statm/Tiny.pm, line 142
sub _refresh_lib { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Clearer "_refresh_lib" usage: $self->_refresh_lib()' ); delete $_[0]{"lib"}; $_[0]; }
sub lib { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Reader "lib" usage: $self->lib()' ); ( exists($_[0]{"lib"}) ? $_[0]{"lib"} : ( $_[0]{"lib"} = do { my $default_value = $Linux::Statm::Tiny::__lib_DEFAULT__->( $_[0] ); (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or Linux::Statm::Tiny::Mite::croak( "Type check failed in default: %s should be %s", "lib", "Int" ); $default_value } ) ) }

# Aliases for lib
# has declaration, file lib/Linux/Statm/Tiny.pm, line 142
sub lib_pages { shift->lib( @_ ) }

# Accessors for lib_bytes
# has declaration, file lib/Linux/Statm/Tiny.pm, line 158
sub _refresh_lib_bytes { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Clearer "_refresh_lib_bytes" usage: $self->_refresh_lib_bytes()' ); delete $_[0]{"lib_bytes"}; $_[0]; }
sub lib_bytes { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Reader "lib_bytes" usage: $self->lib_bytes()' ); ( exists($_[0]{"lib_bytes"}) ? $_[0]{"lib_bytes"} : ( $_[0]{"lib_bytes"} = do { my $default_value = $Linux::Statm::Tiny::__lib_bytes_DEFAULT__->( $_[0] ); (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or Linux::Statm::Tiny::Mite::croak( "Type check failed in default: %s should be %s", "lib_bytes", "Int" ); $default_value } ) ) }

# Accessors for lib_kb
# has declaration, file lib/Linux/Statm/Tiny.pm, line 158
sub _refresh_lib_kb { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Clearer "_refresh_lib_kb" usage: $self->_refresh_lib_kb()' ); delete $_[0]{"lib_kb"}; $_[0]; }
sub lib_kb { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Reader "lib_kb" usage: $self->lib_kb()' ); ( exists($_[0]{"lib_kb"}) ? $_[0]{"lib_kb"} : ( $_[0]{"lib_kb"} = do { my $default_value = $Linux::Statm::Tiny::__lib_kb_DEFAULT__->( $_[0] ); (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or Linux::Statm::Tiny::Mite::croak( "Type check failed in default: %s should be %s", "lib_kb", "Int" ); $default_value } ) ) }

# Accessors for lib_mb
# has declaration, file lib/Linux/Statm/Tiny.pm, line 158
sub _refresh_lib_mb { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Clearer "_refresh_lib_mb" usage: $self->_refresh_lib_mb()' ); delete $_[0]{"lib_mb"}; $_[0]; }
sub lib_mb { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Reader "lib_mb" usage: $self->lib_mb()' ); ( exists($_[0]{"lib_mb"}) ? $_[0]{"lib_mb"} : ( $_[0]{"lib_mb"} = do { my $default_value = $Linux::Statm::Tiny::__lib_mb_DEFAULT__->( $_[0] ); (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or Linux::Statm::Tiny::Mite::croak( "Type check failed in default: %s should be %s", "lib_mb", "Int" ); $default_value } ) ) }

# Accessors for pid
# has declaration, file lib/Linux/Statm/Tiny.pm, line 42
sub pid { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Reader "pid" usage: $self->pid()' ); ( exists($_[0]{"pid"}) ? $_[0]{"pid"} : ( $_[0]{"pid"} = do { my $default_value = $Linux::Statm::Tiny::__pid_DEFAULT__->( $_[0] ); (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or Linux::Statm::Tiny::Mite::croak( "Type check failed in default: %s should be %s", "pid", "Int" ); $default_value } ) ) }

# Accessors for resident
# has declaration, file lib/Linux/Statm/Tiny.pm, line 142
sub _refresh_resident { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Clearer "_refresh_resident" usage: $self->_refresh_resident()' ); delete $_[0]{"resident"}; $_[0]; }
sub resident { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Reader "resident" usage: $self->resident()' ); ( exists($_[0]{"resident"}) ? $_[0]{"resident"} : ( $_[0]{"resident"} = do { my $default_value = $Linux::Statm::Tiny::__resident_DEFAULT__->( $_[0] ); (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or Linux::Statm::Tiny::Mite::croak( "Type check failed in default: %s should be %s", "resident", "Int" ); $default_value } ) ) }

# Aliases for resident
# has declaration, file lib/Linux/Statm/Tiny.pm, line 142
sub resident_pages { shift->resident( @_ ) }
sub rss { shift->resident( @_ ) }
sub rss_pages { shift->resident( @_ ) }

# Accessors for resident_bytes
# has declaration, file lib/Linux/Statm/Tiny.pm, line 158
sub _refresh_resident_bytes { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Clearer "_refresh_resident_bytes" usage: $self->_refresh_resident_bytes()' ); delete $_[0]{"resident_bytes"}; $_[0]; }
sub resident_bytes { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Reader "resident_bytes" usage: $self->resident_bytes()' ); ( exists($_[0]{"resident_bytes"}) ? $_[0]{"resident_bytes"} : ( $_[0]{"resident_bytes"} = do { my $default_value = $Linux::Statm::Tiny::__resident_bytes_DEFAULT__->( $_[0] ); (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or Linux::Statm::Tiny::Mite::croak( "Type check failed in default: %s should be %s", "resident_bytes", "Int" ); $default_value } ) ) }

# Aliases for resident_bytes
# has declaration, file lib/Linux/Statm/Tiny.pm, line 158
sub rss_bytes { shift->resident_bytes( @_ ) }

# Accessors for resident_kb
# has declaration, file lib/Linux/Statm/Tiny.pm, line 158
sub _refresh_resident_kb { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Clearer "_refresh_resident_kb" usage: $self->_refresh_resident_kb()' ); delete $_[0]{"resident_kb"}; $_[0]; }
sub resident_kb { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Reader "resident_kb" usage: $self->resident_kb()' ); ( exists($_[0]{"resident_kb"}) ? $_[0]{"resident_kb"} : ( $_[0]{"resident_kb"} = do { my $default_value = $Linux::Statm::Tiny::__resident_kb_DEFAULT__->( $_[0] ); (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or Linux::Statm::Tiny::Mite::croak( "Type check failed in default: %s should be %s", "resident_kb", "Int" ); $default_value } ) ) }

# Aliases for resident_kb
# has declaration, file lib/Linux/Statm/Tiny.pm, line 158
sub rss_kb { shift->resident_kb( @_ ) }

# Accessors for resident_mb
# has declaration, file lib/Linux/Statm/Tiny.pm, line 158
sub _refresh_resident_mb { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Clearer "_refresh_resident_mb" usage: $self->_refresh_resident_mb()' ); delete $_[0]{"resident_mb"}; $_[0]; }
sub resident_mb { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Reader "resident_mb" usage: $self->resident_mb()' ); ( exists($_[0]{"resident_mb"}) ? $_[0]{"resident_mb"} : ( $_[0]{"resident_mb"} = do { my $default_value = $Linux::Statm::Tiny::__resident_mb_DEFAULT__->( $_[0] ); (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or Linux::Statm::Tiny::Mite::croak( "Type check failed in default: %s should be %s", "resident_mb", "Int" ); $default_value } ) ) }

# Aliases for resident_mb
# has declaration, file lib/Linux/Statm/Tiny.pm, line 158
sub rss_mb { shift->resident_mb( @_ ) }

# Accessors for share
# has declaration, file lib/Linux/Statm/Tiny.pm, line 142
sub _refresh_share { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Clearer "_refresh_share" usage: $self->_refresh_share()' ); delete $_[0]{"share"}; $_[0]; }
sub share { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Reader "share" usage: $self->share()' ); ( exists($_[0]{"share"}) ? $_[0]{"share"} : ( $_[0]{"share"} = do { my $default_value = $Linux::Statm::Tiny::__share_DEFAULT__->( $_[0] ); (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or Linux::Statm::Tiny::Mite::croak( "Type check failed in default: %s should be %s", "share", "Int" ); $default_value } ) ) }

# Aliases for share
# has declaration, file lib/Linux/Statm/Tiny.pm, line 142
sub share_pages { shift->share( @_ ) }

# Accessors for share_bytes
# has declaration, file lib/Linux/Statm/Tiny.pm, line 158
sub _refresh_share_bytes { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Clearer "_refresh_share_bytes" usage: $self->_refresh_share_bytes()' ); delete $_[0]{"share_bytes"}; $_[0]; }
sub share_bytes { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Reader "share_bytes" usage: $self->share_bytes()' ); ( exists($_[0]{"share_bytes"}) ? $_[0]{"share_bytes"} : ( $_[0]{"share_bytes"} = do { my $default_value = $Linux::Statm::Tiny::__share_bytes_DEFAULT__->( $_[0] ); (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or Linux::Statm::Tiny::Mite::croak( "Type check failed in default: %s should be %s", "share_bytes", "Int" ); $default_value } ) ) }

# Accessors for share_kb
# has declaration, file lib/Linux/Statm/Tiny.pm, line 158
sub _refresh_share_kb { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Clearer "_refresh_share_kb" usage: $self->_refresh_share_kb()' ); delete $_[0]{"share_kb"}; $_[0]; }
sub share_kb { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Reader "share_kb" usage: $self->share_kb()' ); ( exists($_[0]{"share_kb"}) ? $_[0]{"share_kb"} : ( $_[0]{"share_kb"} = do { my $default_value = $Linux::Statm::Tiny::__share_kb_DEFAULT__->( $_[0] ); (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or Linux::Statm::Tiny::Mite::croak( "Type check failed in default: %s should be %s", "share_kb", "Int" ); $default_value } ) ) }

# Accessors for share_mb
# has declaration, file lib/Linux/Statm/Tiny.pm, line 158
sub _refresh_share_mb { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Clearer "_refresh_share_mb" usage: $self->_refresh_share_mb()' ); delete $_[0]{"share_mb"}; $_[0]; }
sub share_mb { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Reader "share_mb" usage: $self->share_mb()' ); ( exists($_[0]{"share_mb"}) ? $_[0]{"share_mb"} : ( $_[0]{"share_mb"} = do { my $default_value = $Linux::Statm::Tiny::__share_mb_DEFAULT__->( $_[0] ); (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or Linux::Statm::Tiny::Mite::croak( "Type check failed in default: %s should be %s", "share_mb", "Int" ); $default_value } ) ) }

# Accessors for size
# has declaration, file lib/Linux/Statm/Tiny.pm, line 142
sub _refresh_size { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Clearer "_refresh_size" usage: $self->_refresh_size()' ); delete $_[0]{"size"}; $_[0]; }
sub size { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Reader "size" usage: $self->size()' ); ( exists($_[0]{"size"}) ? $_[0]{"size"} : ( $_[0]{"size"} = do { my $default_value = $Linux::Statm::Tiny::__size_DEFAULT__->( $_[0] ); (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or Linux::Statm::Tiny::Mite::croak( "Type check failed in default: %s should be %s", "size", "Int" ); $default_value } ) ) }

# Aliases for size
# has declaration, file lib/Linux/Statm/Tiny.pm, line 142
sub size_pages { shift->size( @_ ) }
sub vsz { shift->size( @_ ) }
sub vsz_pages { shift->size( @_ ) }

# Accessors for size_bytes
# has declaration, file lib/Linux/Statm/Tiny.pm, line 158
sub _refresh_size_bytes { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Clearer "_refresh_size_bytes" usage: $self->_refresh_size_bytes()' ); delete $_[0]{"size_bytes"}; $_[0]; }
sub size_bytes { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Reader "size_bytes" usage: $self->size_bytes()' ); ( exists($_[0]{"size_bytes"}) ? $_[0]{"size_bytes"} : ( $_[0]{"size_bytes"} = do { my $default_value = $Linux::Statm::Tiny::__size_bytes_DEFAULT__->( $_[0] ); (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or Linux::Statm::Tiny::Mite::croak( "Type check failed in default: %s should be %s", "size_bytes", "Int" ); $default_value } ) ) }

# Aliases for size_bytes
# has declaration, file lib/Linux/Statm/Tiny.pm, line 158
sub vsz_bytes { shift->size_bytes( @_ ) }

# Accessors for size_kb
# has declaration, file lib/Linux/Statm/Tiny.pm, line 158
sub _refresh_size_kb { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Clearer "_refresh_size_kb" usage: $self->_refresh_size_kb()' ); delete $_[0]{"size_kb"}; $_[0]; }
sub size_kb { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Reader "size_kb" usage: $self->size_kb()' ); ( exists($_[0]{"size_kb"}) ? $_[0]{"size_kb"} : ( $_[0]{"size_kb"} = do { my $default_value = $Linux::Statm::Tiny::__size_kb_DEFAULT__->( $_[0] ); (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or Linux::Statm::Tiny::Mite::croak( "Type check failed in default: %s should be %s", "size_kb", "Int" ); $default_value } ) ) }

# Aliases for size_kb
# has declaration, file lib/Linux/Statm/Tiny.pm, line 158
sub vsz_kb { shift->size_kb( @_ ) }

# Accessors for size_mb
# has declaration, file lib/Linux/Statm/Tiny.pm, line 158
sub _refresh_size_mb { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Clearer "_refresh_size_mb" usage: $self->_refresh_size_mb()' ); delete $_[0]{"size_mb"}; $_[0]; }
sub size_mb { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Reader "size_mb" usage: $self->size_mb()' ); ( exists($_[0]{"size_mb"}) ? $_[0]{"size_mb"} : ( $_[0]{"size_mb"} = do { my $default_value = $Linux::Statm::Tiny::__size_mb_DEFAULT__->( $_[0] ); (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or Linux::Statm::Tiny::Mite::croak( "Type check failed in default: %s should be %s", "size_mb", "Int" ); $default_value } ) ) }

# Aliases for size_mb
# has declaration, file lib/Linux/Statm/Tiny.pm, line 158
sub vsz_mb { shift->size_mb( @_ ) }

# Accessors for statm
# has declaration, file lib/Linux/Statm/Tiny.pm, line 54
sub statm { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Reader "statm" usage: $self->statm()' ); ( exists($_[0]{"statm"}) ? $_[0]{"statm"} : ( $_[0]{"statm"} = do { my $default_value = $_[0]->_build_statm; do { package Linux::Statm::Tiny::Mite; (ref($default_value) eq 'ARRAY') and do { my $ok = 1; for my $i (@{$default_value}) { ($ok = 0, last) unless (do { my $tmp = $i; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) }; $ok } } or Linux::Statm::Tiny::Mite::croak( "Type check failed in default: %s should be %s", "statm", "ArrayRef[Int]" ); $default_value } ) ) }
sub refresh { @_ == 2 or Linux::Statm::Tiny::Mite::croak( 'Writer "refresh" usage: $self->refresh( $newvalue )' ); do { package Linux::Statm::Tiny::Mite; (ref($_[1]) eq 'ARRAY') and do { my $ok = 1; for my $i (@{$_[1]}) { ($ok = 0, last) unless (do { my $tmp = $i; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) }; $ok } } or Linux::Statm::Tiny::Mite::croak( "Type check failed in %s: value should be %s", "writer", "ArrayRef[Int]" ); $_[0]{"statm"} = $_[1]; $_[0]; }

# Accessors for text
# has declaration, file lib/Linux/Statm/Tiny.pm, line 142
sub _refresh_text { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Clearer "_refresh_text" usage: $self->_refresh_text()' ); delete $_[0]{"text"}; $_[0]; }
sub text { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Reader "text" usage: $self->text()' ); ( exists($_[0]{"text"}) ? $_[0]{"text"} : ( $_[0]{"text"} = do { my $default_value = $Linux::Statm::Tiny::__text_DEFAULT__->( $_[0] ); (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or Linux::Statm::Tiny::Mite::croak( "Type check failed in default: %s should be %s", "text", "Int" ); $default_value } ) ) }

# Aliases for text
# has declaration, file lib/Linux/Statm/Tiny.pm, line 142
sub text_pages { shift->text( @_ ) }

# Accessors for text_bytes
# has declaration, file lib/Linux/Statm/Tiny.pm, line 158
sub _refresh_text_bytes { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Clearer "_refresh_text_bytes" usage: $self->_refresh_text_bytes()' ); delete $_[0]{"text_bytes"}; $_[0]; }
sub text_bytes { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Reader "text_bytes" usage: $self->text_bytes()' ); ( exists($_[0]{"text_bytes"}) ? $_[0]{"text_bytes"} : ( $_[0]{"text_bytes"} = do { my $default_value = $Linux::Statm::Tiny::__text_bytes_DEFAULT__->( $_[0] ); (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or Linux::Statm::Tiny::Mite::croak( "Type check failed in default: %s should be %s", "text_bytes", "Int" ); $default_value } ) ) }

# Accessors for text_kb
# has declaration, file lib/Linux/Statm/Tiny.pm, line 158
sub _refresh_text_kb { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Clearer "_refresh_text_kb" usage: $self->_refresh_text_kb()' ); delete $_[0]{"text_kb"}; $_[0]; }
sub text_kb { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Reader "text_kb" usage: $self->text_kb()' ); ( exists($_[0]{"text_kb"}) ? $_[0]{"text_kb"} : ( $_[0]{"text_kb"} = do { my $default_value = $Linux::Statm::Tiny::__text_kb_DEFAULT__->( $_[0] ); (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or Linux::Statm::Tiny::Mite::croak( "Type check failed in default: %s should be %s", "text_kb", "Int" ); $default_value } ) ) }

# Accessors for text_mb
# has declaration, file lib/Linux/Statm/Tiny.pm, line 158
sub _refresh_text_mb { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Clearer "_refresh_text_mb" usage: $self->_refresh_text_mb()' ); delete $_[0]{"text_mb"}; $_[0]; }
sub text_mb { @_ == 1 or Linux::Statm::Tiny::Mite::croak( 'Reader "text_mb" usage: $self->text_mb()' ); ( exists($_[0]{"text_mb"}) ? $_[0]{"text_mb"} : ( $_[0]{"text_mb"} = do { my $default_value = $Linux::Statm::Tiny::__text_mb_DEFAULT__->( $_[0] ); (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or Linux::Statm::Tiny::Mite::croak( "Type check failed in default: %s should be %s", "text_mb", "Int" ); $default_value } ) ) }


# See UNIVERSAL
sub DOES {
    my ( $self, $role ) = @_;
    our %DOES;
    return $DOES{$role} if exists $DOES{$role};
    return 1 if $role eq __PACKAGE__;
    if ( $INC{'Moose/Util.pm'} and my $meta = Moose::Util::find_meta( ref $self or $self ) ) {
        $meta->can( 'does_role' ) and $meta->does_role( $role ) and return 1;
    }
    return $self->SUPER::DOES( $role );
}

# Alias for Moose/Moo-compatibility
sub does {
    shift->DOES( @_ );
}

1;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Linux::Statm::Tiny

=head1 VERSION

version 0.0701

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Linux-Statm-Tiny>
and may be cloned from L<git://github.com/robrwo/Linux-Statm-Tiny.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/Linux-Statm-Tiny/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015-2022 by Thermeon Worldwide, PLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
