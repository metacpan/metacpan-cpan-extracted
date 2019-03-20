package Function::Interface::Info;

use v5.14.0;
use warnings;

our $VERSION = "0.04";

sub new {
    my ($class, %args) = @_;
    bless {
        package => $args{package},
        functions => $args{functions},
    } => $class;
}

sub package() { $_[0]->{package} }
sub functions() { $_[0]->{functions} }

1;
__END__

=encoding utf-8

=head1 NAME

Function::Interface::Info - information about interface package

=head1 SYNOPSIS

    package IFoo {
        use Function::Interface;

        fun hello(Str $msg) :Return(Str);
    }

    my $info = Function::Interface::info 'IFoo';
    $info->package;   # IFoo
    $info->functions; # [ Function::Interface::Info::Function ]

    for my $finfo (@{$info->functions}) {
        $finfo->subname; # hello
        $finfo->keyword; # fun
        $finfo->params;  # [ Function::Interface::Info::Function::Param ]
        $finfo->return;  # [ Function::Interface::Info::Function::ReturnParam ]

        for my $pinfo (@{$finfo->params}) {
            $pinfo->type;     # Str
            $pinfo->name;     # $msg
            $pinfo->named;    # false
            $pinfo->optional; # false
        }

        for my $rinfo (@{$rinfo->return}) {
            $rinfo->type; # Str
        }
    }

=head1 DESCRIPTION

Function::Interface::info returns objects of this class to describe interface package.

=head1 METHODS

=head2 new

Constructor of Function::Interface::Info. This is usually called at Function::Interface::info.

=head2 $info->package

Returns interface package name

=head2 $info->functions

Returns a list of L<Function::Interface::Info::Function>

=head1 SEE ALSO

L<Function::Interface>

