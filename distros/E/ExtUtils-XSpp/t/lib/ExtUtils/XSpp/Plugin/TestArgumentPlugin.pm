package ExtUtils::XSpp::Plugin::TestArgumentPlugin;

use strict;
use warnings;

sub new { return bless { directives => [] }, $_[0] }

sub register_plugin {
    my( $class, $parser ) = @_;
    my $inst = $class->new;

    $parser->add_method_tag_plugin( plugin => $inst, tag => 'MyWrap' );
    $parser->add_argument_tag_plugin( plugin => $inst, tag => 'MyWrap' );
}

sub handle_method_tag {
    my( $self, $method, $any_tag, %args ) = @_;

    $method->set_ret_typemap( _wrap_typemap( $method->ret_typemap, 'ret' ) );

    return 1;
}

sub handle_argument_tag {
    my( $self, $argument, $any_tag, %args ) = @_;
    my $function = $argument->function;

    $function->set_arg_typemap
        ( $argument->index, _wrap_typemap( $function->arg_typemap( $argument->index ), $argument->index ) );

    return 1;
}

sub _wrap_typemap {
    my( $typemap, $description ) = @_;

    return ExtUtils::XSpp::Plugin::TestArgumentPlugin::Wrapper->new
               ( typemap => $typemap, description => $description );
}

package ExtUtils::XSpp::Plugin::TestArgumentPlugin::Wrapper;

use strict;
use warnings;
use base 'ExtUtils::XSpp::Typemap::wrapper';

sub init {
    my( $self, %args ) = @_;
    $self->SUPER::init( %args );

    $self->{DESCRIPTION} = $args{description};
}

sub precall_code {
    my( $self, $pvar, $cvar ) = @_;
    my $code = $self->typemap->precall_code( $pvar, $cvar );
    my $add = '// wrapped typemap ' . $self->{DESCRIPTION};

    return $code ? "$code\n$add" : $add;
}

sub cleanup_code {
    my( $self, $pvar, $cvar ) = @_;
    my $code = $self->typemap->cleanup_code( $pvar, $cvar );
    my $add = '// wrapped typemap ' . $self->{DESCRIPTION};

    return $code ? "$code\n$add" : $add;
}

1;
