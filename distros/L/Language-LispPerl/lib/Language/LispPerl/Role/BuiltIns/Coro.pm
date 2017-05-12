package Language::LispPerl::Role::BuiltIns::Coro;
$Language::LispPerl::Role::BuiltIns::Coro::VERSION = '0.007';
use Moose::Role;

use Coro;

use Language::LispPerl::Atom;
use Language::LispPerl::Seq;

=head1 NAME

Language::LispPerl::Role::BuiltIns::Coro - A role with coro primitives for the BuiltIns objects.

=head1 SYNOPSIS

   my $lisp = Language::LispPerl::Evaler->new();

   $lisp->builtins()->apply_role('Language::LispPerl::Role::BuiltIns::Coro');

   .. lisp now implements the coro functions.

=head2 FUNCTIONS

To be documented. Look at the source code for now..

=cut

my $_CORO_FUNCTIONS = {

    # Coro stuff
    "coro"         => \&_impl_coro,
    "coro-suspend" => \&_impl_coro_suspend,
    "coro-sleep"   => \&_impl_coro_sleep,
    "coro-yield"   => \&_impl_coro_yield,
    "coro-resume"  => \&_impl_coro_resume,
    "coro-wake"    => \&_impl_coro_wake,
    "coro-join"    => \&_impl_coro_join,
    "coro-current" => \&_impl_coro_current,
    "coro-main"    => \&_impl_coro_main,
};

around 'has_function' => sub {
    my ( $orig, $self, $fname, @rest ) = @_;

    if ( my $f = $_CORO_FUNCTIONS->{$fname} ) {
        return $f;
    }
    return $self->$orig( $fname, @rest );
};

sub _impl_coro {
    my ( $self, $ast, $symbol ) = @_;
    $ast->error("coro expects 1 argument") if $ast->size() != 2;
    my $b = $self->evaler()->_eval( $ast->second() );
    $ast->error( "core expects a function as argument but got " . $b->type() )
      if $b->type() ne "function";
    my $coro = new Coro sub {
        my $evaler = $self->evaler()->new_instance();
        my $fc     = Language::LispPerl::Seq->new({ type => "list" });
        $fc->append($b);
        $evaler->_eval($fc);
    };
    $coro->ready();
    return Language::LispPerl::Atom->new({type =>  "coroutine", value =>  $coro });
}

sub _impl_coro_suspend {
    my ( $self, $ast, $symbol ) = @_;
    $ast->error("coro-suspend expects 1 argument") if $ast->size() != 2;
    my $coro = $self->evaler()->_eval( $ast->second() );
    $ast->error( "coro-suspend expects a coroutine as argument but got "
          . $coro->type() )
      if $coro->type() ne "coroutine";
    $coro->value()->suspend();
    return $coro;
}

sub _impl_coro_sleep {
    my ( $self, $ast ) = @_;
    $ast->error("coro-sleep expects 0 argument") if $ast->size != 1;
    $Coro::current->suspend();
    cede();
    return Language::LispPerl::Atom->new({ type => "coroutine", value => $Coro::current });
}

sub _impl_coro_yield {
    my ( $self, $ast ) = @_;
    $ast->error("coro-yield expects 0 argument") if $ast->size() != 1;
    cede;
    return Language::LispPerl::Atom->new({ type => "coroutine", value => $Coro::current });
}

sub _impl_coro_resume {
    my ( $self, $ast ) = @_;
    $ast->error("coro-resume expects 1 argument") if $ast->size() != 2;
    my $coro = $self->evaler()->_eval( $ast->second() );
    $ast->error(
        "coro-resume expects a coroutine as argument but got " . $coro->type() )
      if $coro->type() ne "coroutine";
    $coro->value()->resume();
    $coro->value()->cede_to();
    return $coro;
}

sub _impl_coro_wake {
    my ( $self, $ast ) = @_;
    $ast->error("coro-wake expects 1 argument") if $ast->size() != 2;
    my $coro = $self->evaler()->_eval( $ast->second() );
    $ast->error(
        "coro-wake expects a coroutine as argument but got " . $coro->type() )
      if $coro->type() ne "coroutine";
    $coro->value()->resume();
    return $coro;
}

sub _impl_coro_join {
    my ( $self, $ast ) = @_;
    $ast->error("join-coro expects 1 argument") if $ast->size() != 2;
    my $coro = $self->evaler()->_eval( $ast->second() );
    $ast->error(
        "join-coro expects a coroutine as argument but got " . $coro->type() )
      if $coro->type() ne "coroutine";
    $coro->value()->join();
    return $coro;
}

sub _impl_coro_current {
    my ( $self, $ast ) = @_;
    $ast->error("coro-current expects 0 argument") if $ast->size() != 1;
    return Language::LispPerl::Atom->new({ type => "coroutine", value => $Coro::current });
}

sub _impl_coro_main {
    my ( $self, $ast ) = @_;
    $ast->error("coro-main expects 0 argument") if $ast->size() != 1;
    return Language::LispPerl::Atom->new({ type => "coroutine", value => $Coro::main });
}

1;
