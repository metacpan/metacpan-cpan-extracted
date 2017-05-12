#!perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Data::Dumper;

BEGIN {
    use_ok('Method::Traits');
    # load from t/lib
    use_ok('Getopt::Trait::Provider');
    use_ok('Getopt::Trait::Handler');
    use_ok('Accessor::Trait::Provider');
}

=pod


=cut

BEGIN {
    package MyApp;

    use strict;
    use warnings;

    use Method::Traits qw[
        Getopt::Trait::Provider
        Accessor::Trait::Provider
    ];

    our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') }
    our %HAS; BEGIN {
        %HAS = (
            name    => sub { __PACKAGE__ },
            verbose => sub { 0 },
            debug   => sub { 0 },
        )
    }

    sub app_name   : Opt('name=s')    Accessor(ro, 'name');
    sub is_verbose : Opt('v|verbose') Accessor(ro, 'verbose');
    sub is_debug   : Opt('d|debug')   Accessor(ro, 'debug');

    sub new_from_options {
        my $class = shift;
        my %args  = Getopt::Trait::Handler::get_options( $class );

        #use Data::Dumper;
        #warn Dumper \%args;

        return $class->new( %args, @_ );
    }

}

{
    @ARGV = ();

    my $app = MyApp->new_from_options;
    isa_ok($app, 'MyApp');

    #use Data::Dumper;
    #warn Dumper $app;

    ok(!$app->is_verbose, '... got the right setting for verbose');
    ok(!$app->is_debug, '... got the right setting for debug');

    is($app->app_name, 'MyApp', '... got the expected app-name');
}

{
    @ARGV = ('--verbose', '--name', 'FooBarBaz');

    my $app = MyApp->new_from_options;
    isa_ok($app, 'MyApp');

    #use Data::Dumper;
    #warn Dumper $app;

    ok($app->is_verbose, '... got the right setting for verbose');
    ok(!$app->is_debug, '... got the right setting for debug');

    is($app->app_name, 'FooBarBaz', '... got the expected app-name');
}

{
    @ARGV = ('--verbose', '-d');

    my $app = MyApp->new_from_options;
    isa_ok($app, 'MyApp');

    #use Data::Dumper;
    #warn Dumper $app;

    ok($app->is_verbose, '... got the right setting for verbose');
    ok($app->is_debug, '... got the right setting for debug');

    is($app->app_name, 'MyApp', '... got the expected app-name');
}



done_testing;

