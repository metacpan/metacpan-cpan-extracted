package GTop;

use strict;

use DynaLoader ();

{
    no strict;
    $VERSION = '0.18';

    *dl_load_flags = DynaLoader->can('dl_load_flags');
    do {
	__PACKAGE__->can('bootstrap') || \&DynaLoader::bootstrap;
    }->(__PACKAGE__, $VERSION);
}

use constant DEBUG    => 0;
use constant THREADED => eval { my $ver = $threads::VERSION };

require Scalar::Util if THREADED;

use subs qw(debug CLONE);

my %objects = ();

if (DEBUG) {
    *debug = sub { warn __PACKAGE__ . ": " . sprintf shift, @_ };
}
else {
    *debug = sub { };
}

sub new {
    my $self = shift->_new(@_);

    debug " new object IV: 0x%x\n", $$self;

    return $self unless THREADED;

    # make a weak copy, to allow CLONE to affect objects in the user space
    # key = object's stringified IV (pointer to the C struct)
    $objects{"$$self"} = $self;
    Scalar::Util::weaken($objects{"$$self"});

    return $self;
}

if (THREADED) {
    *CLONE = sub {
        for my $key ( keys %objects) {
            my $self = delete $objects{$key};

            # replace the guts of the object with new $data
            # this affects the object in the user program as well
            debug "    possess IV: 0x%x\n", $$self;
            $self->_possess();
            debug "   new guts IV: 0x%x\n", $$self;

            # store the updated object, in case a cloned perl will be used
            # to clone another perl interpreter
            # key = object's stringified IV (pointer to the C struct)
            $objects{"$$self"} = $self;
        }
    };
}

sub DESTROY {
    my $self = shift;

    delete $objects{"$$self"} if THREADED;

    debug "DESTROY obj IV: 0x%x\n", $$self;
    $self->_destroy;
}

1;
__END__
