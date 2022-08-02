{
package Linux::Statm::Tiny;
our $USES_MITE = q[Mite::Class];
use strict;
use warnings;


sub new {
    my $class = ref($_[0]) ? ref(shift) : shift;
    my $meta  = ( $Mite::META{$class} ||= $class->__META__ );
    my $self  = bless {}, $class;
    my $args  = $meta->{HAS_BUILDARGS} ? $class->BUILDARGS( @_ ) : { ( @_ == 1 ) ? %{$_[0]} : @_ };
    my $no_build = delete $args->{__no_BUILD__};

    # Initialize attributes
    if ( exists($args->{q[pid]}) ) { (do { my $tmp = $args->{q[pid]}; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or require Carp && Carp::croak(q[Type check failed in constructor: pid should be Int]); $self->{q[pid]} = $args->{q[pid]};  }

    # Enforce strict constructor
    my @unknown = grep not( do { package Linux::Statm::Tiny::Mite; (defined and !ref and m{\A(?:(?:d(?:ata_pages|t_pages)|lib_pages|pid|r(?:esident_pages|ss(?:_(?:bytes|kb|mb|pages))?)|s(?:hare_pages|ize_pages)|text_pages|vsz(?:_(?:bytes|kb|mb|pages))?))\z}) } ), keys %{$args}; @unknown and require Carp and Carp::croak("Unexpected keys in constructor: " . join(q[, ], sort @unknown));

    # Call BUILD methods
    unless ( $no_build ) { $_->($self, $args) for @{ $meta->{BUILD} || [] } };

    return $self;
}

defined ${^GLOBAL_PHASE}
    or eval { require Devel::GlobalDestruction; 1 }
    or do   { *Devel::GlobalDestruction::in_global_destruction = sub { undef; } };

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

sub __META__ {
    no strict 'refs';
    require mro;
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
    };
}

sub DOES {
    my ( $self, $role ) = @_;
    our %DOES;
    return $DOES{$role} if exists $DOES{$role};
    return 1 if $role eq __PACKAGE__;
    return $self->SUPER::DOES( $role );
}

sub does {
    shift->DOES( @_ );
}

my $__XS = !$ENV{MITE_PURE_PERL} && eval { require Class::XSAccessor; Class::XSAccessor->VERSION("1.19") };

# Accessors for data
*_refresh_data = sub { delete $_[0]->{q[data]}; $_[0]; };
*data = sub { @_ > 1 ? require Carp && Carp::croak("data is a read-only attribute of @{[ref $_[0]]}") : ( exists($_[0]{q[data]}) ? $_[0]{q[data]} : ( $_[0]{q[data]} = do { my $default_value = do { my $method = $Linux::Statm::Tiny::__data_DEFAULT__; $_[0]->$method }; (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or do { require Carp; Carp::croak(q[Type check failed in default: data should be Int]) }; $default_value } ) ) };

# Aliases for for data
sub data_pages { shift->data( @_ ) }

# Accessors for data_bytes
*_refresh_data_bytes = sub { delete $_[0]->{q[data_bytes]}; $_[0]; };
*data_bytes = sub { @_ > 1 ? require Carp && Carp::croak("data_bytes is a read-only attribute of @{[ref $_[0]]}") : ( exists($_[0]{q[data_bytes]}) ? $_[0]{q[data_bytes]} : ( $_[0]{q[data_bytes]} = do { my $default_value = do { my $method = $Linux::Statm::Tiny::__data_bytes_DEFAULT__; $_[0]->$method }; (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or do { require Carp; Carp::croak(q[Type check failed in default: data_bytes should be Int]) }; $default_value } ) ) };

# Accessors for data_kb
*_refresh_data_kb = sub { delete $_[0]->{q[data_kb]}; $_[0]; };
*data_kb = sub { @_ > 1 ? require Carp && Carp::croak("data_kb is a read-only attribute of @{[ref $_[0]]}") : ( exists($_[0]{q[data_kb]}) ? $_[0]{q[data_kb]} : ( $_[0]{q[data_kb]} = do { my $default_value = do { my $method = $Linux::Statm::Tiny::__data_kb_DEFAULT__; $_[0]->$method }; (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or do { require Carp; Carp::croak(q[Type check failed in default: data_kb should be Int]) }; $default_value } ) ) };

# Accessors for data_mb
*_refresh_data_mb = sub { delete $_[0]->{q[data_mb]}; $_[0]; };
*data_mb = sub { @_ > 1 ? require Carp && Carp::croak("data_mb is a read-only attribute of @{[ref $_[0]]}") : ( exists($_[0]{q[data_mb]}) ? $_[0]{q[data_mb]} : ( $_[0]{q[data_mb]} = do { my $default_value = do { my $method = $Linux::Statm::Tiny::__data_mb_DEFAULT__; $_[0]->$method }; (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or do { require Carp; Carp::croak(q[Type check failed in default: data_mb should be Int]) }; $default_value } ) ) };

# Accessors for dt
*_refresh_dt = sub { delete $_[0]->{q[dt]}; $_[0]; };
*dt = sub { @_ > 1 ? require Carp && Carp::croak("dt is a read-only attribute of @{[ref $_[0]]}") : ( exists($_[0]{q[dt]}) ? $_[0]{q[dt]} : ( $_[0]{q[dt]} = do { my $default_value = do { my $method = $Linux::Statm::Tiny::__dt_DEFAULT__; $_[0]->$method }; (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or do { require Carp; Carp::croak(q[Type check failed in default: dt should be Int]) }; $default_value } ) ) };

# Aliases for for dt
sub dt_pages { shift->dt( @_ ) }

# Accessors for dt_bytes
*_refresh_dt_bytes = sub { delete $_[0]->{q[dt_bytes]}; $_[0]; };
*dt_bytes = sub { @_ > 1 ? require Carp && Carp::croak("dt_bytes is a read-only attribute of @{[ref $_[0]]}") : ( exists($_[0]{q[dt_bytes]}) ? $_[0]{q[dt_bytes]} : ( $_[0]{q[dt_bytes]} = do { my $default_value = do { my $method = $Linux::Statm::Tiny::__dt_bytes_DEFAULT__; $_[0]->$method }; (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or do { require Carp; Carp::croak(q[Type check failed in default: dt_bytes should be Int]) }; $default_value } ) ) };

# Accessors for dt_kb
*_refresh_dt_kb = sub { delete $_[0]->{q[dt_kb]}; $_[0]; };
*dt_kb = sub { @_ > 1 ? require Carp && Carp::croak("dt_kb is a read-only attribute of @{[ref $_[0]]}") : ( exists($_[0]{q[dt_kb]}) ? $_[0]{q[dt_kb]} : ( $_[0]{q[dt_kb]} = do { my $default_value = do { my $method = $Linux::Statm::Tiny::__dt_kb_DEFAULT__; $_[0]->$method }; (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or do { require Carp; Carp::croak(q[Type check failed in default: dt_kb should be Int]) }; $default_value } ) ) };

# Accessors for dt_mb
*_refresh_dt_mb = sub { delete $_[0]->{q[dt_mb]}; $_[0]; };
*dt_mb = sub { @_ > 1 ? require Carp && Carp::croak("dt_mb is a read-only attribute of @{[ref $_[0]]}") : ( exists($_[0]{q[dt_mb]}) ? $_[0]{q[dt_mb]} : ( $_[0]{q[dt_mb]} = do { my $default_value = do { my $method = $Linux::Statm::Tiny::__dt_mb_DEFAULT__; $_[0]->$method }; (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or do { require Carp; Carp::croak(q[Type check failed in default: dt_mb should be Int]) }; $default_value } ) ) };

# Accessors for lib
*_refresh_lib = sub { delete $_[0]->{q[lib]}; $_[0]; };
*lib = sub { @_ > 1 ? require Carp && Carp::croak("lib is a read-only attribute of @{[ref $_[0]]}") : ( exists($_[0]{q[lib]}) ? $_[0]{q[lib]} : ( $_[0]{q[lib]} = do { my $default_value = do { my $method = $Linux::Statm::Tiny::__lib_DEFAULT__; $_[0]->$method }; (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or do { require Carp; Carp::croak(q[Type check failed in default: lib should be Int]) }; $default_value } ) ) };

# Aliases for for lib
sub lib_pages { shift->lib( @_ ) }

# Accessors for lib_bytes
*_refresh_lib_bytes = sub { delete $_[0]->{q[lib_bytes]}; $_[0]; };
*lib_bytes = sub { @_ > 1 ? require Carp && Carp::croak("lib_bytes is a read-only attribute of @{[ref $_[0]]}") : ( exists($_[0]{q[lib_bytes]}) ? $_[0]{q[lib_bytes]} : ( $_[0]{q[lib_bytes]} = do { my $default_value = do { my $method = $Linux::Statm::Tiny::__lib_bytes_DEFAULT__; $_[0]->$method }; (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or do { require Carp; Carp::croak(q[Type check failed in default: lib_bytes should be Int]) }; $default_value } ) ) };

# Accessors for lib_kb
*_refresh_lib_kb = sub { delete $_[0]->{q[lib_kb]}; $_[0]; };
*lib_kb = sub { @_ > 1 ? require Carp && Carp::croak("lib_kb is a read-only attribute of @{[ref $_[0]]}") : ( exists($_[0]{q[lib_kb]}) ? $_[0]{q[lib_kb]} : ( $_[0]{q[lib_kb]} = do { my $default_value = do { my $method = $Linux::Statm::Tiny::__lib_kb_DEFAULT__; $_[0]->$method }; (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or do { require Carp; Carp::croak(q[Type check failed in default: lib_kb should be Int]) }; $default_value } ) ) };

# Accessors for lib_mb
*_refresh_lib_mb = sub { delete $_[0]->{q[lib_mb]}; $_[0]; };
*lib_mb = sub { @_ > 1 ? require Carp && Carp::croak("lib_mb is a read-only attribute of @{[ref $_[0]]}") : ( exists($_[0]{q[lib_mb]}) ? $_[0]{q[lib_mb]} : ( $_[0]{q[lib_mb]} = do { my $default_value = do { my $method = $Linux::Statm::Tiny::__lib_mb_DEFAULT__; $_[0]->$method }; (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or do { require Carp; Carp::croak(q[Type check failed in default: lib_mb should be Int]) }; $default_value } ) ) };

# Accessors for pid
*pid = sub { @_ > 1 ? require Carp && Carp::croak("pid is a read-only attribute of @{[ref $_[0]]}") : ( exists($_[0]{q[pid]}) ? $_[0]{q[pid]} : ( $_[0]{q[pid]} = do { my $default_value = do { my $method = $Linux::Statm::Tiny::__pid_DEFAULT__; $_[0]->$method }; (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or do { require Carp; Carp::croak(q[Type check failed in default: pid should be Int]) }; $default_value } ) ) };

# Accessors for resident
*_refresh_resident = sub { delete $_[0]->{q[resident]}; $_[0]; };
*resident = sub { @_ > 1 ? require Carp && Carp::croak("resident is a read-only attribute of @{[ref $_[0]]}") : ( exists($_[0]{q[resident]}) ? $_[0]{q[resident]} : ( $_[0]{q[resident]} = do { my $default_value = do { my $method = $Linux::Statm::Tiny::__resident_DEFAULT__; $_[0]->$method }; (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or do { require Carp; Carp::croak(q[Type check failed in default: resident should be Int]) }; $default_value } ) ) };

# Aliases for for resident
sub resident_pages { shift->resident( @_ ) }
sub rss { shift->resident( @_ ) }
sub rss_pages { shift->resident( @_ ) }

# Accessors for resident_bytes
*_refresh_resident_bytes = sub { delete $_[0]->{q[resident_bytes]}; $_[0]; };
*resident_bytes = sub { @_ > 1 ? require Carp && Carp::croak("resident_bytes is a read-only attribute of @{[ref $_[0]]}") : ( exists($_[0]{q[resident_bytes]}) ? $_[0]{q[resident_bytes]} : ( $_[0]{q[resident_bytes]} = do { my $default_value = do { my $method = $Linux::Statm::Tiny::__resident_bytes_DEFAULT__; $_[0]->$method }; (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or do { require Carp; Carp::croak(q[Type check failed in default: resident_bytes should be Int]) }; $default_value } ) ) };

# Aliases for for resident_bytes
sub rss_bytes { shift->resident_bytes( @_ ) }

# Accessors for resident_kb
*_refresh_resident_kb = sub { delete $_[0]->{q[resident_kb]}; $_[0]; };
*resident_kb = sub { @_ > 1 ? require Carp && Carp::croak("resident_kb is a read-only attribute of @{[ref $_[0]]}") : ( exists($_[0]{q[resident_kb]}) ? $_[0]{q[resident_kb]} : ( $_[0]{q[resident_kb]} = do { my $default_value = do { my $method = $Linux::Statm::Tiny::__resident_kb_DEFAULT__; $_[0]->$method }; (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or do { require Carp; Carp::croak(q[Type check failed in default: resident_kb should be Int]) }; $default_value } ) ) };

# Aliases for for resident_kb
sub rss_kb { shift->resident_kb( @_ ) }

# Accessors for resident_mb
*_refresh_resident_mb = sub { delete $_[0]->{q[resident_mb]}; $_[0]; };
*resident_mb = sub { @_ > 1 ? require Carp && Carp::croak("resident_mb is a read-only attribute of @{[ref $_[0]]}") : ( exists($_[0]{q[resident_mb]}) ? $_[0]{q[resident_mb]} : ( $_[0]{q[resident_mb]} = do { my $default_value = do { my $method = $Linux::Statm::Tiny::__resident_mb_DEFAULT__; $_[0]->$method }; (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or do { require Carp; Carp::croak(q[Type check failed in default: resident_mb should be Int]) }; $default_value } ) ) };

# Aliases for for resident_mb
sub rss_mb { shift->resident_mb( @_ ) }

# Accessors for share
*_refresh_share = sub { delete $_[0]->{q[share]}; $_[0]; };
*share = sub { @_ > 1 ? require Carp && Carp::croak("share is a read-only attribute of @{[ref $_[0]]}") : ( exists($_[0]{q[share]}) ? $_[0]{q[share]} : ( $_[0]{q[share]} = do { my $default_value = do { my $method = $Linux::Statm::Tiny::__share_DEFAULT__; $_[0]->$method }; (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or do { require Carp; Carp::croak(q[Type check failed in default: share should be Int]) }; $default_value } ) ) };

# Aliases for for share
sub share_pages { shift->share( @_ ) }

# Accessors for share_bytes
*_refresh_share_bytes = sub { delete $_[0]->{q[share_bytes]}; $_[0]; };
*share_bytes = sub { @_ > 1 ? require Carp && Carp::croak("share_bytes is a read-only attribute of @{[ref $_[0]]}") : ( exists($_[0]{q[share_bytes]}) ? $_[0]{q[share_bytes]} : ( $_[0]{q[share_bytes]} = do { my $default_value = do { my $method = $Linux::Statm::Tiny::__share_bytes_DEFAULT__; $_[0]->$method }; (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or do { require Carp; Carp::croak(q[Type check failed in default: share_bytes should be Int]) }; $default_value } ) ) };

# Accessors for share_kb
*_refresh_share_kb = sub { delete $_[0]->{q[share_kb]}; $_[0]; };
*share_kb = sub { @_ > 1 ? require Carp && Carp::croak("share_kb is a read-only attribute of @{[ref $_[0]]}") : ( exists($_[0]{q[share_kb]}) ? $_[0]{q[share_kb]} : ( $_[0]{q[share_kb]} = do { my $default_value = do { my $method = $Linux::Statm::Tiny::__share_kb_DEFAULT__; $_[0]->$method }; (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or do { require Carp; Carp::croak(q[Type check failed in default: share_kb should be Int]) }; $default_value } ) ) };

# Accessors for share_mb
*_refresh_share_mb = sub { delete $_[0]->{q[share_mb]}; $_[0]; };
*share_mb = sub { @_ > 1 ? require Carp && Carp::croak("share_mb is a read-only attribute of @{[ref $_[0]]}") : ( exists($_[0]{q[share_mb]}) ? $_[0]{q[share_mb]} : ( $_[0]{q[share_mb]} = do { my $default_value = do { my $method = $Linux::Statm::Tiny::__share_mb_DEFAULT__; $_[0]->$method }; (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or do { require Carp; Carp::croak(q[Type check failed in default: share_mb should be Int]) }; $default_value } ) ) };

# Accessors for size
*_refresh_size = sub { delete $_[0]->{q[size]}; $_[0]; };
*size = sub { @_ > 1 ? require Carp && Carp::croak("size is a read-only attribute of @{[ref $_[0]]}") : ( exists($_[0]{q[size]}) ? $_[0]{q[size]} : ( $_[0]{q[size]} = do { my $default_value = do { my $method = $Linux::Statm::Tiny::__size_DEFAULT__; $_[0]->$method }; (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or do { require Carp; Carp::croak(q[Type check failed in default: size should be Int]) }; $default_value } ) ) };

# Aliases for for size
sub size_pages { shift->size( @_ ) }
sub vsz { shift->size( @_ ) }
sub vsz_pages { shift->size( @_ ) }

# Accessors for size_bytes
*_refresh_size_bytes = sub { delete $_[0]->{q[size_bytes]}; $_[0]; };
*size_bytes = sub { @_ > 1 ? require Carp && Carp::croak("size_bytes is a read-only attribute of @{[ref $_[0]]}") : ( exists($_[0]{q[size_bytes]}) ? $_[0]{q[size_bytes]} : ( $_[0]{q[size_bytes]} = do { my $default_value = do { my $method = $Linux::Statm::Tiny::__size_bytes_DEFAULT__; $_[0]->$method }; (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or do { require Carp; Carp::croak(q[Type check failed in default: size_bytes should be Int]) }; $default_value } ) ) };

# Aliases for for size_bytes
sub vsz_bytes { shift->size_bytes( @_ ) }

# Accessors for size_kb
*_refresh_size_kb = sub { delete $_[0]->{q[size_kb]}; $_[0]; };
*size_kb = sub { @_ > 1 ? require Carp && Carp::croak("size_kb is a read-only attribute of @{[ref $_[0]]}") : ( exists($_[0]{q[size_kb]}) ? $_[0]{q[size_kb]} : ( $_[0]{q[size_kb]} = do { my $default_value = do { my $method = $Linux::Statm::Tiny::__size_kb_DEFAULT__; $_[0]->$method }; (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or do { require Carp; Carp::croak(q[Type check failed in default: size_kb should be Int]) }; $default_value } ) ) };

# Aliases for for size_kb
sub vsz_kb { shift->size_kb( @_ ) }

# Accessors for size_mb
*_refresh_size_mb = sub { delete $_[0]->{q[size_mb]}; $_[0]; };
*size_mb = sub { @_ > 1 ? require Carp && Carp::croak("size_mb is a read-only attribute of @{[ref $_[0]]}") : ( exists($_[0]{q[size_mb]}) ? $_[0]{q[size_mb]} : ( $_[0]{q[size_mb]} = do { my $default_value = do { my $method = $Linux::Statm::Tiny::__size_mb_DEFAULT__; $_[0]->$method }; (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or do { require Carp; Carp::croak(q[Type check failed in default: size_mb should be Int]) }; $default_value } ) ) };

# Aliases for for size_mb
sub vsz_mb { shift->size_mb( @_ ) }

# Accessors for statm
*statm = sub { @_ > 1 ? require Carp && Carp::croak("statm is a read-only attribute of @{[ref $_[0]]}") : ( exists($_[0]{q[statm]}) ? $_[0]{q[statm]} : ( $_[0]{q[statm]} = do { my $default_value = $_[0]->_build_statm; do { package Linux::Statm::Tiny::Mite; (ref($default_value) eq 'ARRAY') and do { my $ok = 1; for my $i (@{$default_value}) { ($ok = 0, last) unless (do { my $tmp = $i; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) }; $ok } } or do { require Carp; Carp::croak(q[Type check failed in default: statm should be ArrayRef[Int]]) }; $default_value } ) ) };
*refresh = sub { do { package Linux::Statm::Tiny::Mite; (ref($_[1]) eq 'ARRAY') and do { my $ok = 1; for my $i (@{$_[1]}) { ($ok = 0, last) unless (do { my $tmp = $i; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) }; $ok } } or require Carp && Carp::croak(q[Type check failed in writer: value should be ArrayRef[Int]]); $_[0]{q[statm]} = $_[1]; $_[0]; };

# Accessors for text
*_refresh_text = sub { delete $_[0]->{q[text]}; $_[0]; };
*text = sub { @_ > 1 ? require Carp && Carp::croak("text is a read-only attribute of @{[ref $_[0]]}") : ( exists($_[0]{q[text]}) ? $_[0]{q[text]} : ( $_[0]{q[text]} = do { my $default_value = do { my $method = $Linux::Statm::Tiny::__text_DEFAULT__; $_[0]->$method }; (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or do { require Carp; Carp::croak(q[Type check failed in default: text should be Int]) }; $default_value } ) ) };

# Aliases for for text
sub text_pages { shift->text( @_ ) }

# Accessors for text_bytes
*_refresh_text_bytes = sub { delete $_[0]->{q[text_bytes]}; $_[0]; };
*text_bytes = sub { @_ > 1 ? require Carp && Carp::croak("text_bytes is a read-only attribute of @{[ref $_[0]]}") : ( exists($_[0]{q[text_bytes]}) ? $_[0]{q[text_bytes]} : ( $_[0]{q[text_bytes]} = do { my $default_value = do { my $method = $Linux::Statm::Tiny::__text_bytes_DEFAULT__; $_[0]->$method }; (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or do { require Carp; Carp::croak(q[Type check failed in default: text_bytes should be Int]) }; $default_value } ) ) };

# Accessors for text_kb
*_refresh_text_kb = sub { delete $_[0]->{q[text_kb]}; $_[0]; };
*text_kb = sub { @_ > 1 ? require Carp && Carp::croak("text_kb is a read-only attribute of @{[ref $_[0]]}") : ( exists($_[0]{q[text_kb]}) ? $_[0]{q[text_kb]} : ( $_[0]{q[text_kb]} = do { my $default_value = do { my $method = $Linux::Statm::Tiny::__text_kb_DEFAULT__; $_[0]->$method }; (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or do { require Carp; Carp::croak(q[Type check failed in default: text_kb should be Int]) }; $default_value } ) ) };

# Accessors for text_mb
*_refresh_text_mb = sub { delete $_[0]->{q[text_mb]}; $_[0]; };
*text_mb = sub { @_ > 1 ? require Carp && Carp::croak("text_mb is a read-only attribute of @{[ref $_[0]]}") : ( exists($_[0]{q[text_mb]}) ? $_[0]{q[text_mb]} : ( $_[0]{q[text_mb]} = do { my $default_value = do { my $method = $Linux::Statm::Tiny::__text_mb_DEFAULT__; $_[0]->$method }; (do { my $tmp = $default_value; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) or do { require Carp; Carp::croak(q[Type check failed in default: text_mb should be Int]) }; $default_value } ) ) };


1;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Linux::Statm::Tiny

=head1 VERSION

version 0.0700

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
