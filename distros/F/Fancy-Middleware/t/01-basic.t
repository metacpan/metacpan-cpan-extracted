use Test::More;
use MooseX::Declare;

class PreInvokeMiddleware
{
    with 'Fancy::Middleware' => { -excludes => 'preinvoke' };

    method preinvoke()
    {
        $self->env->{'pre.invoke.middleware'} = 'foo';
    }
}

class InvokeMiddleware
{
    with 'Fancy::Middleware';

    around invoke
    {
        $self->set_response(['500', [ 'Content-Type:', 'text/plain' ], ['Server Error']]);
    }
}

class PostInvokeMiddleware
{
    with 'Fancy::Middleware' => { -excludes => 'postinvoke' };

    method postinvoke()
    {
        push(@{$self->response->[2]}, 'Yeehaw!');
    }
}

my $app = sub
{
    my ($env) = @_;
    ok(exists $env->{'pre.invoke.middleware'} && $env->{'pre.invoke.middleware'} eq 'foo', 'preinvoke successful');

    return [ 200, ['Content-Type', 'text/plain'], ['Awesomesauce']];
};

my $preapp = PreInvokeMiddleware->wrap($app);
$preapp->({});

my $invapp = InvokeMiddleware->wrap($preapp);
my $first_result = $invapp->({});
is_deeply($first_result, [ 500, [ 'Content-Type:', 'text/plain' ], ['Server Error']], 'Compare app results with InvokeMiddleware applied');

my $postapp = PostInvokeMiddleware->wrap($invapp);
my $second_result = $postapp->({});
is_deeply($second_result, [ 500, [ 'Content-Type:', 'text/plain' ], ['Server Error', 'Yeehaw!']], 'Compare app results with PostInvokeMiddleware applied');

done_testing();
