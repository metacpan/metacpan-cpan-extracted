package Kwiki::DB::ClassDBI;
use Kwiki::DB -Base;

our $VERSION = '0.03';

const class_id    => 'cdbi';
const class_title => 'Kwiki ClassDBI';

field '_base';
field entities => {};

sub base {
    return $self->_base unless @_;
    my $class = shift;
    eval "require $class";
    die $@ if $@;
    $self->_base($class);
}

sub entity {
    my ($entity,$class) = @_;
    my $object = Kwiki::DB::ClassDBI->new(base => $class);
    $object->init;
    $self->entities->{$entity} = $object;
}

sub AUTOLOAD {
    my ($p,$func) = $Kwiki::DB::ClassDBI::AUTOLOAD =~ m/(.*)::(.*?)$/;
    for(keys %{$self->entities}) {
        if ($_ eq $func) {
            return $self->entities->{$_};
        }
    }
    if(my $base = $self->base) {
        $base->$func(@_);
    }
}

__END__


=head1 NAME

  Kwiki::DB::ClassDBI - A Class::DBI wrapper for Kwiki

=head1 SYNOPSIS

  package Kwiki::MyPlugin;
  use Kwiki::Plugin -Base;

  # setup Music::Artist and Music::CD as in Class::DBI pod.
  sub init {
      super;
      $self->hub->config->add_field("db_class" => 'Kwiki::DB::DBI');
      field db => -init => "\$self->hub->load_class('db')";

      $self->db->entity( artist => 'Music::Artist' );
      $self->db->entity(     cd => 'Music::CD'     );
      $self->connection("dbi:SQLite:dbfile.sqlt");
  }

  sub my_action {
      $self->cdb->artist->create(...)
  }

=head1 DESCRIPTION

This module privdes a bridge between L<Class::DBI> and L<Kwiki> programming
environment. After adding C<Kwiki::DB::ClassDBI> into your C<plugins> file,
there will be a convienent $self->hub->cdbi reference to an instantiated object
which acts as the door to all your C<Class::DBI> based classes.

Instead of using class name to access data, this module requires you give
several "entity" names in the init phrase. Each entity has a short name, and a
corresponding C<Class::DBI> based class name. Writing

    $self->hub->cdbi->entity( artist => 'Music::Artist' );

would create a object held in $self->db->artist, and delegates all methods
to C<Music::Artist>. So these two lines are doing the same work:

    $self->hub->cdbi->artist->create({ artistid => 1, name => 'U2' });
    Music::Artist->create({ artistid => 1, name => 'U2' });

They return the same type of value, because $self->db->artist only
delegates the C<create> method to C<Music::Artist>.

People could even directly use the $hub->db to access database in their
kwiki template like this:

    The band is [% hub.db.artist.retrieve(1).name %].

Also, you may want to read the test C<t/02.classdbi-sqlite.t> and
C<t/lib/Kwiki/DB/Music*> as a live example for how to use this bridge.

=head1 SEE ALSO

L<Class::DBI>, L<Kwiki::DB::DBI>

=head1 COPYRIGHT

Copyright 2005 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut
