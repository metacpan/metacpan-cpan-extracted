use strict;
use warnings;
use Test::More;

{
    package HackException;
    use parent 'Exception::Tiny';
    use Class::Accessor::Lite (
        ro => [qw/ time pid uid euid gid egid /],
    );

    sub new {
        my($class, %args) = @_;
        %args = (
            %args,
            time => CORE::time,
            pid  => $$,
            uid  => $<,
            euid => $>,
            gid  => $(,
            egid => $),
        );
        $class->SUPER::new(%args);
    }
}

eval {
    HackException->throw;
};

my $e = $@;
like $e->time, qr/\A\d+\z/;
is $e->pid, $$;
is $e->uid, $<;
is $e->euid, $>;
is $e->gid, $(;
is $e->egid, $);

done_testing;
