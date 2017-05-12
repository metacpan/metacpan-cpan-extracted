package ExtUtils::XSpp::Plugin::TestParserPlugin;

use strict;
use warnings;

sub new { return bless { directives => [] }, $_[0] }

sub register_plugin {
    my( $class, $parser ) = @_;
    my $inst = $class->new;

    $parser->add_function_tag_plugin( plugin => $inst, tag => 'MyFuncRename' );
    $parser->add_class_tag_plugin( plugin => $inst, tag => 'MyClassRename' );
    $parser->add_method_tag_plugin( plugin => $inst, tag => 'MyMethodRename' );

    $parser->add_toplevel_tag_plugin( plugin => $inst, tag => 'MyDirective' );
    $parser->add_post_process_plugin( plugin => $inst );
}

sub handle_method_tag {
    my( $self, $method, $any_tag, %args ) = @_;
    my $name = $args{positional}[0];

    $method->set_perl_name( $name );

    1;
}

sub handle_function_tag {
    my( $self, $function, $any_tag, %args ) = @_;
    my $name = $args{positional}[0];

    $function->set_perl_name( $name );

    return 1;
}

sub handle_class_tag {
    my( $self, $class, $any_tag, %args ) = @_;
    my $name = $args{positional}[0];

    $class->set_perl_name( $name );

    return 1;
}

sub handle_toplevel_tag {
    my( $self, undef, $any_tag, %args ) = @_;
    my $name = $args{positional}[0];

    push @{$self->{directives}}, $name;

    return 1;
}

sub post_process {
    my( $self, $nodes ) = @_;

    foreach my $name ( @{$self->{directives}} ) {
        push @$nodes, ExtUtils::XSpp::Node::Raw->new( rows => [ "// $name" ] );
    }
}

1;
