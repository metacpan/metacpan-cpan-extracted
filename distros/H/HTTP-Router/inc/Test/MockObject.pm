#line 1
package Test::MockObject;

use strict;
use warnings;

use vars qw( $VERSION $AUTOLOAD );
$VERSION = '1.09';

use Scalar::Util qw( blessed refaddr reftype weaken );
use UNIVERSAL::isa;
use UNIVERSAL::can;

use Test::Builder;

my $Test = Test::Builder->new();
my (%calls, %subs);

sub new
{
    my ($class, $type) = @_;
    $type ||= {};
    bless $type, $class;
}

sub mock
{
    my ($self, $name, $sub) = @_;
    $sub ||= sub {};

    # leading dash means unlog, otherwise do log
    _set_log( $self, $name, ( $name =~ s/^-// ? 0 : 1 ) );
    _subs( $self )->{$name} = $sub;

    $self;
}

sub set_isa
{
    my ($self, @supers) = @_;
    my $supers          = _isas( $self );
    $supers->{$_}       = 1 for @supers;
}

sub set_always
{
    my ($self, $name, $value) = @_;
    $self->mock( $name, sub { $value } );
}

sub set_true
{
    my $self = shift;

    for my $name ( @_ )
    {
        $self->mock( $name, sub { 1 } );
    }

    return $self;
}

sub set_false
{
    my $self = shift;

    for my $name ( @_ )
    {
        $self->mock( $name, sub {} );
    }

    return $self;
}

sub set_list
{
    my ($self, $name, @list) = @_;
    $self->mock( $name, sub { @{[ @list ]} } );
}

sub set_series
{
    my ($self, $name, @list) = @_;
    $self->mock( $name, sub { return unless @list; shift @list } );
}

sub set_bound
{
    my ($self, $name, $ref) = @_;

    my %bindings =
    (
        SCALAR => sub { $$ref },
        ARRAY  => sub { @$ref },
        HASH   => sub { %$ref },
    );

    return unless exists $bindings{reftype( $ref )};
    $self->mock( $name,  $bindings{reftype( $ref )} );
}

# hack around debugging mode being too smart for my sub names
my $old_p;
BEGIN
{
    $old_p  = $^P;
    $^P    &= ~0x200;
}

BEGIN
{
    for my $universal
    ( { sub => \&_subs, name => 'can' }, { sub => \&_isas, name => 'isa' } )
    {
        my $sub = sub
        {
            my ($self, $sub) = @_;
            local *__ANON__  = $universal->{name};

            # mockmethods are special cases, class methods are handled directly
            my $lookup = $universal->{sub}->( $self );
            return $lookup->{$sub} if blessed $self and exists $lookup->{$sub};
            my $parent = 'SUPER::' . $universal->{name};
            return $self->$parent( $sub );
        };

        no strict 'refs';
        *{ $universal->{name} } = $sub;
    }

    $^P = $old_p;
}

sub remove
{
    my ($self, $sub) = @_;
    delete _subs( $self )->{$sub};
    $self;
}

sub called
{
    my ($self, $sub) = @_;

    for my $called (reverse @{ _calls( $self ) })
    {
        return 1 if $called->[0] eq $sub;
    }

    return 0;
}

sub clear
{
    my $self             = shift;
    @{ _calls( $self ) } = ();
    $self;
}

sub call_pos
{
    $_[0]->_call($_[1], 0);
}

sub call_args
{
    return @{ $_[0]->_call($_[1], 1) };
}

sub _call
{
    my ($self, $pos, $type) = @_;
    my $calls               = _calls( $self );
    return if abs($pos) > @$calls;
    $pos-- if $pos > 0;
    return $calls->[$pos][$type];
}

sub call_args_string
{
    my $args = $_[0]->_call( $_[1], 1 ) or return;
    return join($_[2] || '', @$args);
}

sub call_args_pos
{
    my ($self, $subpos, $argpos) = @_;
    my $args = $self->_call( $subpos, 1 ) or return;
    $argpos-- if $argpos > 0;
    return $args->[$argpos];
}

sub next_call
{
    my ($self, $num)  = @_;
    $num            ||= 1;

    my $calls = _calls( $self );
    return unless @$calls >= $num;

    my ($call) = (splice(@$calls, 0, $num))[-1];
    return wantarray() ? @$call : $call->[0];
}

sub AUTOLOAD
{
    my $self = shift;
    my $sub;
    {
        local $1;
        ($sub) = $AUTOLOAD =~ /::(\w+)\z/;
    }
    return if $sub eq 'DESTROY';

    $self->dispatch_mocked_method( $sub, @_ );
}

sub dispatch_mocked_method
{
    my $self = $_[0];
    my $sub  = splice( @_, 1, 1 );

    my $subs = _subs( $self );
    if (exists $subs->{$sub})
    {
        $self->log_call( $sub, @_ );
        goto &{ $subs->{$sub} };
    }
    else
    {
        require Carp;
        Carp::carp("Un-mocked method '$sub()' called");
    }

    return;
}

sub log_call
{
    my ($self, $sub, @call_args) = @_;
    return unless _logs( $self, $sub );

    # prevent circular references with weaken
    for my $arg ( @call_args )
    {
        next unless ref $arg;
        weaken( $arg ) if refaddr( $arg ) eq refaddr( $self );
    }

    push @{ _calls( $self ) }, [ $sub, \@call_args ];
}

sub called_ok
{
    my ($self, $sub, $name) = @_;
    $name ||= "object called '$sub'";
    $Test->ok( $self->called($sub), $name );
}

sub called_pos_ok
{
    my ($self, $pos, $sub, $name) = @_;
    $name ||= "object called '$sub' at position $pos";
    my $called = $self->call_pos($pos, $sub);
    unless ($Test->ok( (defined $called and $called eq $sub), $name ))
    {
        $called = 'undef' unless defined $called;
        $Test->diag("Got:\n\t'$called'\nExpected:\n\t'$sub'\n");
    }
}

sub called_args_string_is
{
    my ($self, $pos, $sep, $expected, $name) = @_;
    $name ||= "object sent expected args to sub at position $pos";
    $Test->is_eq( $self->call_args_string( $pos, $sep ), $expected, $name );
}

sub called_args_pos_is
{
    my ($self, $pos, $argpos, $arg, $name) = @_;
    $name ||= "object sent expected arg '$arg' to sub at position $pos";
    $Test->is_eq( $self->call_args_pos( $pos, $argpos ), $arg, $name );
}

sub fake_module
{
    my ($class, $modname, %subs) = @_;

    if ($class->check_class_loaded( $modname ) and ! keys %subs)
    {
        require Carp;
        Carp::croak( "No mocked subs for loaded module '$modname'" );
    }

    $modname =~ s!::!/!g;
    $INC{ $modname . '.pm' } = 1;

    no warnings 'redefine';
    {
        no strict 'refs';
        ${ $modname . '::' }{VERSION} ||= -1;
    }

    for my $sub (keys %subs)
    {
        my $type = reftype( $subs{ $sub } ) || '';
        unless ( $type eq 'CODE' )
        {
            require Carp;
            Carp::carp("'$sub' is not a code reference" );
            next;
        }
        no strict 'refs';
        *{ $_[1] . '::' . $sub } = $subs{ $sub };
    }
}

sub check_class_loaded
{
    my ($self, $class, $load_flag) = @_;

    (my $path    = $class) =~ s{::}{/}g;
    return 1 if exists $INC{ $path . '.pm' };

    my $symtable = \%main::;
    my $found    = 1;

    for my $symbol ( split( '::', $class ))
    {
        unless (exists $symtable->{ $symbol . '::' })
        {
            $found = 0;
            last;
        }

        $symtable = $symtable->{ $symbol . '::' };
    }

    return $found;
}

sub fake_new
{
    my ($self, $class) = @_;
    $self->fake_module( $class, new => sub { $self } );
}

sub DESTROY
{
    my $self = shift;
    $self->_clear_calls();
    $self->_clear_subs();
    $self->_clear_logs();
    $self->_clear_isas();
}

sub _get_key
{
    my $invocant = shift;
    return blessed( $invocant ) ? refaddr( $invocant ) : $invocant;
}

{
    my %calls;

    sub _calls
    {
        $calls{ _get_key( shift ) } ||= [];
    }

    sub _clear_calls
    {
        delete $calls{ _get_key( shift ) };
    }
}

{
    my %subs;

    sub _subs
    {
        $subs{ _get_key( shift ) } ||= {};
    }

    sub _clear_subs
    {
        delete $subs{ _get_key( shift ) };
    }
}

{
    my %logs;

    sub _set_log
    {
        my $key          = _get_key( shift );
        my ($name, $log) = @_;

        $logs{$key} ||= {};

        if ($log)
        {
            $logs{$key}{$name} = 1;
        }
        else
        {
            delete $logs{$key}{$name};
        }
    }

    sub _logs
    {
        my $key    = _get_key( shift );
        my ($name) = @_;
        return exists $logs{$key}{$name};
    }

    sub _clear_logs
    {
        delete $logs{ _get_key( shift ) };
    }
}

{
    my %isas;

    sub _isas
    {
        $isas{ _get_key( shift ) } ||= {};
    }

    sub _clear_isas
    {
        delete $isas{ _get_key( shift ) };
    }
}

1;

__END__

#line 883
