package ExtUtils::XSpp::Plugin::TestNewNodesPlugin;

use strict;
use warnings;

sub new { return bless { directives => [] }, $_[0] }

sub register_plugin {
    my( $class, $parser ) = @_;
    my $inst = $class->new;

    $parser->add_function_tag_plugin( plugin => $inst, tag => 'MyComment' );
    $parser->add_class_tag_plugin( plugin => $inst, tag => 'MyComment' );
    $parser->add_method_tag_plugin( plugin => $inst, tag => 'MyComment' );
    $parser->add_toplevel_tag_plugin( plugin => $inst, tag => 'MyComment' );
}

sub handle_method_tag {
    my( $self, $method, $any_tag, %args ) = @_;

    ( 1, ExtUtils::XSpp::Node::Raw->new
             ( rows => [ '// method ' . $method->class->cpp_name .
                                        '::' . $method->cpp_name ] ) );
}

sub handle_function_tag {
    my( $self, $function, $any_tag, %args ) = @_;

    ( 1, ExtUtils::XSpp::Node::Raw->new
             ( rows => [ '// function ' . $function->cpp_name ] ) );
}

sub handle_class_tag {
    my( $self, $class, $any_tag, %args ) = @_;

    ( 1, ExtUtils::XSpp::Node::Raw->new
             ( rows => [ '// class ' . $class->cpp_name ] ) );
}

sub handle_toplevel_tag {
    my( $self, undef, $any_tag, %args ) = @_;

    ( 1, ExtUtils::XSpp::Node::Raw->new
             ( rows => [ '// directive ' . $any_tag ] ) );
}

1;
