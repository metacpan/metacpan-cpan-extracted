use strict;
use warnings;
use lib './lib';
use JavaScript::Duktape;
use Data::Dumper;

my $js = JavaScript::Duktape->new();
my $duk = $js->duk;

## this is an advanced array example
## where we will be using low level duktape API
## to create & construct new javascript classes
## from perl

{
    ## set some javascript objects
    $js->eval(q{
        function Users (name, age, isAdmin){
            this.name = name;
            this.age = age;
            this.role = isAdmin;
        }

        function Roles (role){
            this.admin = role.admin;
            this.developer = role.developer;
        }
    });

    ## getting both Users & Roles objects from
    ## javascript land as perl objects
    my $users = $js->get_object('Users');
    my $role  = $js->get_object('Roles');

    ## add userList javascript array
    ## but this time from perl
    $js->set('usersList', [
        $users->new('Joe The Admin', 36, $role->new({ admin => true, developer => false })),
        $users->new('Doe The Developer', 28, $role->new({ admin => false, developer => true }))
    ]);

    ## did we get this right ?
    $js->eval(q{
        print(usersList[0].name); // => Joe
        print(usersList[1].age); // => 28
    });

    ## get userList from perl again!!
    ## not sure if you ever need to do this :)
    my $usersList = $js->get_object('usersList');

    ## set a map function, we are going to use it
    ## from javascript to map our userList
    ## and set admins
    $duk->push_perl_function( sub {

        # javascript array map prototype pass
        # three arguments, (current element, element index, whole array)
        # so getting argument at index 0 for each array element

        # we need to extract it as javascript object
        # because we need to do some stuff with it
        # so instead of using to_perl method
        # we use to_perl_object
        my $user = $duk->to_perl_object(0);

        # if his role is admin add isAdmin prop
        if ($user->role->admin){
            $duk->push_perl($user);
            $duk->push_true();
            $duk->put_prop_string(-2, "isAdmin");
            $duk->pop();
        }

        # return array element
        $duk->push_perl($user);

        # tell duktape stack that we are pushing/return something
        return 1;
    });

    ## push the above created function to duktape stack
    ## as a global function with "maps" name
    $duk->put_global_string('maps');

    ## use our maps function from javascript
    my $admins = $duk->eval_string(q{ usersList.map(maps); });

    ## get
    $admins = $duk->to_perl_object(-1);

    ## don't forget to pop eval results
    ## we already have it mapped to perl
    $duk->pop();

    ## admins should be a javascript array object
    ## let's check if forEach works
    $admins->forEach( sub {
        my $user = $duk->to_perl_object(0);
        if ($user->isAdmin) {
            print "==================================\n";
            print "found an admin\n";
            print "his name is : ";
            print $user->name, "\n";
            print "==================================\n";
        }
    });

    ## $admin is a javascript array prototype
    ## so instead of using map from javascript we can
    ## also use it from perl land too, and we will
    ## assign new created array to $dev array
    my $dev = $admins->map( sub {
        my $user = $duk->to_perl_object(0);
        if (!$user->isAdmin){
            return $user;
        }
        return false;
    });

    ## again since javascript map function
    ## creates new Array, $dev is an object to
    ## javascript Array
    $dev->forEach( sub {
        my $user = shift;
        if ($user == false){
            print "** only devs allowed\n";
        } else {
            print "welcome home ", $user->{name}, "\n";
        }
    });

    print "==================================\n";
    ## now back to perl again, let's check who's admin
    ## we can also get list as a perl array
    ## eval function will not convert results as objects
    ## it will return as perl data so ..
    $admins = $js->eval(q{ usersList.map(maps); });
    for (@{$admins}){
        if (!$_->{isAdmin}) {
            print "found a Developer\n";
            print "his name is : ";
            print $_->{name}, "\n";
        }
    }
}
