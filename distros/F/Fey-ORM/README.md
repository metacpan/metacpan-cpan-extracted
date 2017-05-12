NAME

    Fey::ORM - A Fey-based ORM (If you like SQL, you might like Fey::ORM)

VERSION

    version 0.47

SYNOPSIS

    A "table-based" class for the User table:

      package MyApp::Model::User;
    
      use MyApp::Model::Schema;
    
      use Fey::ORM::Table;
    
      my $schema = MyApp::Model::Schema->Schema();
    
      has_table $schema->table('User');
    
      has_one $schema->table('Group');
    
      has_many 'messages' => ( table => $schema->table('Messages') );

    MyApp::Model::Schema might look like this:

      package MyApp::Model::Schema;
    
      use Fey::DBIManager::Source;
      use Fey::Loader;
    
      use Fey::ORM::Schema;
    
      my $source = Fey::DBIManager::Source->new(
          dsn  => 'dbi:Pg:dbname=MyApp',
          user => 'myapp',
      );
    
      my $schema = Fey::Loader->new( dbh => $source->dbh() )->make_schema();
    
      has_schema $schema;

    __PACKAGE__->DBIManager()->add_source($source);

    Then in your application:

      use MyApp::Model::User;
    
      my $user = MyApp::Model::User->new( user_id => 1 );
    
      print $user->username();
    
      $user->update( username => 'bob' );

DESCRIPTION

    Fey::ORM builds on top of other Fey project libraries to create an ORM
    focused on easy SQL generation. This is an ORM for people who are
    comfortable with SQL and want to be able to use it with their objects,
    rather than people who like OO and don't want to think about the DBMS.

    Fey::ORM also draws inspiration from Moose and tries to provide as much
    functionality as it can via a simple declarative interface. Of course,
    it uses Moose under the hood for its implementation.

EARLY VERSION WARNING

    This is still very new software, and APIs may change in future releases
    without notice. You have been warned.

    Moreover, this software is still missing a number of features which
    will be needed to make it more easily usable and competitive with other
    ORM packages.

GETTING STARTED

    You should start by reading Fey::ORM::Manual::Intro. This will walk you
    through creating a set of classes based on a schema. Then look at
    Fey::ORM::Manual for a list of additional documentation.

BUGS

    Please report any bugs or feature requests to bug-fey-orm@rt.cpan.org,
    or through the web interface at http://rt.cpan.org. I will be notified,
    and then you'll automatically be notified of progress on your bug as I
    make changes.

AUTHOR

    Dave Rolsky <autarch@urth.org>

COPYRIGHT AND LICENSE

    This software is copyright (c) 2011 - 2015 by Dave Rolsky.

    This is free software; you can redistribute it and/or modify it under
    the same terms as the Perl 5 programming language system itself.

