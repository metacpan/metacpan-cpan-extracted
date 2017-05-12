package Jorge;

use warnings;
use strict;

=head1 NAME

Jorge - ORM Made simple.

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

Not ready for Class::DBI or DBIx::Class? Dissapointed by Tangram? Still
writting your own SQL?

Then, you may benefit from Jorge.

Jorge is a simple ORM (Object Relational Mapper) that will let you
quick and easily interface your perl objects with a MySQL database
(Suppport for PostgreSQL may arrive some day)

Usual operations are covered (insert, update, select, delete, count) but
if you need JOINS or other type of queries, you should be looking for
other library (DBIx::Class or Rose::DB::Object)

Jorge won't solve all your problems and may not be what you need, but if
it covers your needs, you'll find it ultra easy to use, intuitive and 
will get used to it sooner that you may think.


=head1 USAGE

=head2 Defining your new Jorge based class

=head3 Start with: YourClass.pm

    package YourClass
    use base Jorge::DBEntity;

    sub _fields {

        my $table_name = 'YourClass';

        my @fields = qw(
            Id
            Password
            Email
            Date
            Md5
        );

        my %fields = (
            Id => { pk => 1, read_only => 1 },
            Date => { datetime => 1},
        );

        return [ \@fields, \%fields, $table_name ];
    }
    ;1




That is enough to get you started with Jorge.
Now, you need to provide Jorge with a config file containing
the database info (this is likely to change in future and add options,
like passing the config info as parameters)

create a config/jorge.yml file (in your current working dir, relative
to the path the instance script will be working)

=head3 Configuration. config/jorge.yml

    database:
        host: DB_HOST
        db: DB_NAME
        user: DB_USER
        password: USER_PASSWORD
config
This is what the config file should have. Plain simple. Since it's YAML,
you will want to double check the syntax looking for tabs/spaces.


Now, you can create a instance script and try the next.

=head3 Creating a new Object.

YourInstanceScript.pl

    #!/usr/bin/perl
    use User;

    my $user = User->new(Email => 'jorge@foo.com', Password => 'sshhhhh');

    #or

    my $another_user = User->new();
    $another_user->Email('jorge@foo.com');
    $another_user->Password('sshhhhh');

If the database info you provided in the config file was accurate and you
already created the database (Jorge will not create your database, at least, 
not now, but likely to change in next versions) You should be able now to
start interacting with it.

Try now something like this, later on your instance script:

    $user->insert;
    print $user->Id; #if the insert was successful, you $user->Id should
    #return the inserted id. 

Ideally, that should have worked fine and now you can start using Jorge.

Available method for Jorge::DBEntity based classes are:

=over 2

=item insert

=item update

=item delete

=item get_by

All those methods are pretty self explanatory, but this should guide you
through the basic operations

=back

=head3 Creating a new object, insert, delete and get from/to the Database.

YourInstanceScript.pl

    #!/usr/bin/perl
    use User;

    my $user = User->new(Email => 'jorge@foo.com', Password => 'sshhhhh');
    $user->insert;
    #now $user->Id returns the inserted id from the database
    $user->Email('updated_mail@bar.com');
    $user->update;
    #same $user->Id, but $user->Email was updated in the database
    $user->delete
    #now, even while the $user exists in memory, is not present anymore on
    the database

    #now, let's try something more complex
    my $user2 = User->new(Email => 'coco@foo.com', Password => 'secret');
    $user2->get_by(qw[Email Password]);
    print $user2->Id;
    # Now, if there is a User in with Email = 'coco@foo.com' AND a Password
    # = 'secret' then $user2->Id will be a positive integer. Otherwhise, it
    # will return undef

    $user2->get_by('Email'); #will look only for the Email field.


As you can see, you should ALLWAYS check your object to confirm that it 
found at match before using it.

I'm considering implementing some error checking method, but since I got
used to check for Id's on my objects.

If you have a proposal to solve this, feel free to email or open a 
request ticket on CPAN Request Tracker at:
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Jorge>
    
Another thing to consider is that, even if the get_by() method finds more 
than one match, it will allways use the first one.

If you need to retrieve more than 1 element at a time, then you need 
Jorge::ObjectCollection

=head2 Defining Your new Jorge based Object Collection

=head3 Collections: YourClassCollection.pm

    package YourClassCollection;
    use base 'Jorge::ObjectCollection';

    use YourClass;

    use strict;

    sub create_object {
	    return new YourClass;
    }

    ;1

And that's it. Instant gratification.

Now you can create a new YourClassCollection object and get multiple 
objects from the database.

How? simple. Just pass the parameters to get the matching objects from the
database.

=head3 Using Collections: YourInstanceScript.pl

    
    #!/usr/bin/perl
    use Users;  # (note the convention. for DBEntity based packages we used
                # singular form of the name and the plural form form
                # for ObjectCollection based objects, similar as Rail's 
                # Active::Record does.

    my $users = Users->new();
    my %params = (Email => 'coco@foo.com');
    $users->get_all(%params);
    while (my $user = $users->get_next){
        print $user->Id;
    }

Available method for Jorge::ObjectCollection based classes are:

=over 2

=item get_all

=item get_count

=item get_next


Again, all those methods are pretty self explanatory.

get_all and get_count can receive parameters (as a hash). If they dont,
both will retrive all the rows from the database to provide a result.

=back

=head2 Params Syntax for ObjectCollection based objects

Simplest case: Name equals some value.

    my %params = (Name => 'Jorge');

Moving on...

    my %params = (Name => ['!=', 'Jorge']);

Let's continue

    my %params = (Price => ['>', 12]);

    my %params = (Price => ['>', 12], Id => ['<', 30]); #That's a AND.
    
    my %params = (Price => 'is null');
    
    #OR support. Yeah!
    my %params = (Name => [ 'or',[ ['=','Bill'],['=','Steve'],['=','Linus']);
    
    #IN
    my %params = (Id => [ 'in', [1,2,3,5,7,11] ]);
    
    #BETWEEN
    #NOTE: Allways provide min and max values
    my %params = (Id => ['between',(1,100)]);
    
    #Use a object as a parameter
    my %params = (User => $user);


=head2 get_all, get_next: Iterating.

Once you invoke the method get_all (hint. if you invoke it without params)
it will do a SELECT * FROM __table__, retrieving all the elements of that
table/class.

In fact, no query will retrieve all the objects, but only their Id's (or 
primary keys.)

After you retrieve all the matching objects, you can start iterating pulling
elements from the array of matching elements invoking the method get_next

    my $elements = Elements->new;
    my %params = (Field => 'Value');
    $elements->get_all(%params);
    while (my $element = $elements->get_next){
        #We're Iterating!
        print $element->Id;
    }

=head1 Setup

=head2 Config File

Jorge expects a YAML config file under a certain directory/filename.
Default value is config/jorge.yml relative to the working dir path
If you need to override or change the location of the config file, you can
modify the config_file variable in Jorge::Config file

    Jorge::Config::$CONFIG_FILE = 'path to your config';

In your instance script / Main package.

=head1 Plugins

You can create plugins for Jorge. Plugin support right now it's very raw,
but has a lot of potential. Included in the distro you will find Jorge::Plugin::Md5
which imports a subroutine into the Jorge::DBEntity based objects named
encodeMd5.
You can read the code to get an idea of how you can write your own Jorge
plugins and how to extend your Jorge based objects. Feedback will be appreciated.


=head2 Jorge::Plugin::Md5

    package Jorge::Plugin::Md5;
    use Digest::MD5;
    use vars qw($VERSION @EXPORT);
    use warnings;
    use strict;

    @EXPORT = qw(
      encodeMd5
    );
    our $VERSION = '0.01';
    sub import {
        my $pkg     = shift;
        my $callpkg = caller;
        no strict 'refs';
        foreach my $sym (@EXPORT) {
            *{"${callpkg}::$sym"} = \&{$sym};
        }
    }
    sub encodeMd5 {
        my $self   = shift;
        my @params = @_;

        my $md5 = Digest::MD5->new;

        foreach my $key (@params) {
            my $k = $self->{$key};
            $md5->add($k);
        }
        return substr( $md5->hexdigest, 0, 8 );
    }

To enable Jorge::Plugin::Md5 in your Jorge::DBEntity based objects, just
use it in your package and the encodeMd5 subroutine will be available in
your objects.

=head3 Using Plugins: YourClass.pm

    package User;

    use base 'Jorge::DBEntity';
    use Jorge::Plugin::Md5;


    sub _fields {
	
	    my $table_name = 'User';
	
	    my @fields = qw(
		    Id
		    Password
		    Date
		    Md5
		    Email
	    );

	    my %fields = (
		    Id => { pk => 1, read_only => 1 },
		    Date => { datetime => 1},
	    );

	    return [ \@fields, \%fields, $table_name ];
    }
    ;1

=head3 Using Plugins: YourInstanceScript.pl


    #!/usr/bin/perl

    use User;
    my $user = User->new(Email => 'jorge@foo.com', Password => 'sshhhhh');
    print $user->encodeMd5(qw[Email Password]); #will print a Md5 hash


=head1 AUTHORS

Joaquin Perez, C<< <mondongo at gmail.com> >> had the original idea after
 being frustrated by Catalyst and Tangram.

Julian Porta, C<< <julian.porta at gmail.com> >> took the code and tried 
to make it harder, better, faster, stronger. And packaged it.

=head1 BUGS

Please report any bugs or feature requests to C<bug-jorge at rt.cpan.org>,
or through the web interface at 
 L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Jorge>.  
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Jorge


You can also look for information at:

=over 4

=item * Github Project Page

L<http://github.com/Porta/Jorge/tree/master>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Jorge>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Jorge>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Jorge>

=item * Search CPAN

L<http://search.cpan.org/dist/Jorge/>

=back


=head1 ACKNOWLEDGEMENTS

Joaquin Perez C<< <mondongo at gmail.com> >> For starting this.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Julian Porta, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;    # End of Jorge

