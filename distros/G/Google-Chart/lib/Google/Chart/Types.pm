# $Id$

package Google::Chart::Types;
use strict;
use warnings;
use Carp ();
use Moose::Util::TypeConstraints;
use Sub::Exporter -setup => {
    exports => [ qw(hash_coercion) ]
};

sub hash_coercion {
    my (%args) = @_;

    my $default = $args{default};
    my $prefix  = $args{prefix};

    return sub {
        my $h = $_;
        my $module = $h->{module} || $default ||
            Carp::confess("No module name provided for coercion");
        if ($module !~ s/^\+//) {
            $module = join('::', $prefix, $module);
        }
        Class::MOP::load_class( $module );
        return $module->new(%{ $h->{args} });
    }
}

{
    role_type 'Google::Chart::Type';
    coerce 'Google::Chart::Type'
        => from 'Str'
        => via {
            my $class = sprintf( 'Google::Chart::Type::%s', ucfirst $_ );
            Class::MOP::load_class($class);

            return $class->new();
        }
    ;
    coerce 'Google::Chart::Type'
        => from 'HashRef'
        => hash_coercion(prefix => "Google::Chart::Type")
    ;
}

{
    role_type 'Google::Chart::Fill';
    coerce 'Google::Chart::Fill'
        => from 'Str'
        => via {
            my $class = sprintf( 'Google::Chart::Fill::%s', ucfirst $_ );
            Class::MOP::load_class($class);

            return $class->new();
        }
    ;
    coerce 'Google::Chart::Fill'
        => from 'HashRef'
        => hash_coercion(prefix => "Google::Chart::Fill")
    ;
}

{
    role_type 'Google::Chart::Data';
    coerce 'Google::Chart::Data'
        => from 'ArrayRef'
        => via {
            my $class = 'Google::Chart::Data::Text';
            Class::MOP::load_class($class);
            $class->new(dataset => $_);
        }
    ;
    coerce 'Google::Chart::Data'
        => from 'HashRef'
        => via {
            my $class = $_->{module};
            if ($class !~ s/^\+//) {
                $class = "Google::Chart::Data::$class";
            }
            Class::MOP::load_class($class);

            $class->new(%{$_->{args}});
        }
    ;
}

no Moose::Util::TypeConstraints;

1;

__END__

=head1 NAME

Google::Chart::Types - Google::Chart Miscellaneous Types

=head1 FUNCTIONS

=head2 hash_coercion

=cut
