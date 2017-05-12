package Meta::Builder;
use strict;
use warnings;

use Carp qw/croak/;
use Meta::Builder::Util;
use Meta::Builder::Base;

our $VERSION = "0.003";

our @SUGAR = qw/metric action hash_metric lists_metric/;
our @HOOKS = qw/before after/;
our @METHODS = (( map { "add_$_"  } @SUGAR ),
               ( map { "hook_$_" } @HOOKS ));
our @EXPORT = ( @SUGAR, @HOOKS, qw/make_immutable accessor/ );
our @REMOVABLE = ( @EXPORT, @METHODS );

for my $item ( @SUGAR ) {
    my $wraps = "add_$item";
    inject( __PACKAGE__, $item, sub {
        caller->$wraps(@_)
    });
}

for my $item ( @HOOKS ) {
    my $wraps = "hook_$item";
    inject( __PACKAGE__, $item, sub {
        caller->$wraps(@_)
    });
}

sub import {
    my $class = shift;
    my $caller = caller;

    inject( $caller, $_, $class->can( $_ )) for @EXPORT;
    no strict 'refs';
    push @{"$caller\::ISA"} => 'Meta::Builder::Base';
}

sub make_immutable {
    my $class = shift || caller;
    for my $sub ( @REMOVABLE ) {
        inject( $class, $sub, sub {
            croak "$class has been made immutable, cannot call '$sub'"
        }, 1 );
    }
}

sub accessor {
    my $class = caller;
    $class->set_accessor( @_ );
}

1;

__END__

=head1 NAME

Meta::Builder - Tools for creating Meta objects to track custom metrics.

=head1 DESCRIPTION

Meta programming is becomming more and more popular. The popularity of Meta
programming comes from the fact that many problems are made significantly
easier. There are a few specialized Meta tools out there, for instance
L<Class:MOP> which is used by L<Moose> to track class metadata.

Meta::Builder is designed to be a generic tool for writing Meta objects. Unlike
specialized tools, Meta::Builder makes no assumptions about what metrics you
will care about. Meta::Builder also mkaes it simple for others to extend your
meta-object based tools by providing hooks for other packages to add metrics to
your meta object.

If a specialized Meta object tool is available ot meet your needs please use
it. However if you need a simple Meta object to track a couple metrics, use
Meta::Builder.

Meta::Builder is also low-sugar and low-dep. In most cases you will not want a
class that needs a meta object to use your meta-object class directly. Rather
you will usually want to create a sugar class that exports enhanced API
functions that manipulate the meta object.

=head1 SYNOPSIS

My/Meta.pm:

    package My::Meta;
    use strict;
    use warnings;

    use Meta::Builder;

    # Name the accessor that will be defined in the class that uses the meta object
    # It is used to retrieve the classes meta object.
    accessor "mymeta";

    # Add a metric with two actions
    metric mymetric => sub { [] },
           pop => sub {
               my $self = shift;
               my ( $data ) = @_;
               pop @$data;
           },
           push => sub {
               my $self = shift;
               my ( $data, $metric, $action, @args ) = @_;
               push @$data => @args;
           };

    # Add an additional action to the metric
    action mymetric => ( get_ref => sub { shift });

    # Add some predefined metric types + actions
    hash_metric 'my_hashmetric';
    lists_metric 'my_listsmetric';

My.pm:

    package My;
    use strict;
    use warnings;

    use My::Meta;

    My::Meta->new( __PACKAGE__ );

    # My::Meta defines mymeta() as the accessor we use to get our meta object.
    # this is the ONLY way to get the meta object for this class.

    mymeta()->mymetric_push( "some data" );
    mymeta()->my_hashmetric_add( key => 'value' );
    mymeta()->my_listsmetric_push( list => qw/valueA valueB/ );

    # It works fine as an object/class method as well.
    __PACKAGE__->mymeta->do_thing(...);

    ...;

=head1 USING

When you use Meta::Builder your class is automatically turned into a subclass
of L<Meta::Builder::Base>. In addition several "sugar" functions are exported
into your namespace. To avoid the "sugar" functions you can simply sublass
L<Meta::Builder::Base> directly.

=head1 EXPORTS

=over 4

=item metric( $name, \&generator, %actions )

Wraper around C<caller->add_metric()>. See L<Meta::Builder::Base>.

=item action( $metric, $name, $code )

Wraper around C<caller->add_action()>. See L<Meta::Builder::Base>.

=item hash_metric( $name, %additional_actions )

Wraper around C<caller->add_hash_metric()>. See L<Meta::Builder::Base>.

=item lists_metric( $name, %additional_actions )

Wraper around C<caller->add_lists_metric()>. See L<Meta::Builder::Base>.

=item before( $metric, $action, $code )

Wraper around C<caller->hook_before()>. See L<Meta::Builder::Base>.

=item after( $metric, $action, $code )

Wraper around C<caller->hook_after()>. See L<Meta::Builder::Base>.

=item accessor( $name )

Wraper around C<caller->set_accessor()>. See L<Meta::Builder::Base>.

=item make_immutable()

Overrides all functions/methods that alter the meta objects meta-data. This in
effect prevents anything from adding new metrics, actions, or hooks without
directly editing the metadata.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Meta-Builder is free software; Standard perl licence.

Meta-Builder is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
