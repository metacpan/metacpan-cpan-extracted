package Maypole::Model::CDBI;
use strict;

=head1 NAME

Maypole::Model::CDBI - Model class based on Class::DBI

=head1 DESCRIPTION

This is a master model class which uses L<Class::DBI> to do all the hard
work of fetching rows and representing them as objects. It is a good
model to copy if you're replacing it with other database abstraction
modules.

It implements a base set of methods required for a Maypole Data Model.

It inherits accessor and helper methods from L<Maypole::Model::Base>.

When specified as the application model, it will use Class::DBI::Loader
to generate the model classes from the provided database. If you do not
wish to use this functionality, use L<Maypole::Model::CDBI::Plain> which
will instead use Class::DBI classes provided.

=cut

use base qw(Maypole::Model::CDBI::Base);
use Data::Dumper;
use Class::DBI::Loader;
use attributes ();

use Maypole::Model::CDBI::AsForm;
use Maypole::Model::CDBI::FromCGI;
use CGI::Untaint::Maypole;

=head2 Untainter

Set the class you use to untaint and validate form data
Note it must be of type CGI::Untaint::Maypole (takes $r arg) or CGI::Untaint

=cut

sub Untainter { 'CGI::Untaint::Maypole' };

=head2 add_model_superclass

Adds model as superclass to model classes (if necessary)

Inherited from Maypole::Model::CDBI::Base

=head1 Action Methods

Action methods are methods that are accessed through web (or other public) interface.

Inherited from L<Maypole::Model::CDBI::Base>

=head2 do_edit

If there is an object in C<$r-E<gt>objects>, then it should be edited
with the parameters in C<$r-E<gt>params>; otherwise, a new object should
be created with those parameters, and put back into C<$r-E<gt>objects>.
The template should be changed to C<view>, or C<edit> if there were any
errors. A hash of errors will be passed to the template.

=head2 do_delete

Inherited from Maypole::Model::CDBI::Base.

This action deletes records

=head2 do_search

Inherited from Maypole::Model::CDBI::Base.

This action method searches for database records.

=head2 list

Inherited from Maypole::Model::CDBI::Base.

The C<list> method fills C<$r-E<gt>objects> with all of the
objects in the class. The results are paged using a pager.

=head1 Helper Methods

=head2 setup

  This method is inherited from Maypole::Model::Base and calls setup_database,
  which uses Class::DBI::Loader to create and load Class::DBI classes from
  the given database schema.

=cut

=head2 setup_database

The $opts argument is a hashref of options.  The "options" key is a hashref of
Database connection options . Other keys may be various Loader arguments or
flags.  It has this form:
 {
   # DB connection options
   options { AutoCommit => 1 , ... },
   # Loader args
   relationships => 1,
   ...
 }

=cut

sub setup_database {
    my ( $class, $config, $namespace, $dsn, $u, $p, $opts ) = @_;
    $dsn  ||= $config->dsn;
    $u    ||= $config->user;
    $p    ||= $config->pass;
    $opts ||= $config->opts;
    $config->dsn($dsn);
    warn "No DSN set in config" unless $dsn;
    $config->loader || $config->loader(
        Class::DBI::Loader->new(
            namespace => $namespace,
            dsn       => $dsn,
            user      => $u,
            password  => $p,
	    %$opts,
        )
    );
    $config->{classes} = [ $config->{loader}->classes ];
    $config->{tables}  = [ $config->{loader}->tables ];

    my @table_class = map { $_ . " => " . $config->{loader}->_table2class($_) } @{ $config->{tables} };
    warn( 'Loaded tables to classes: ' . join ', ', @table_class )
      if $namespace->debug;
}

=head2 class_of

  returns class for given table

=cut

sub class_of {
    my ( $self, $r, $table ) = @_;
    return $r->config->loader->_table2class($table); # why not find_class ?
}


=head1 SEE ALSO

L<Maypole>, L<Maypole::Model::CDBI::Base>.

=head1 AUTHOR

Maypole is currently maintained by Aaron Trevena.

=head1 AUTHOR EMERITUS

Simon Cozens, C<simon#cpan.org>

Simon Flack maintained Maypole from 2.05 to 2.09

Sebastian Riedel, C<sri#oook.de> maintained Maypole from 1.99_01 to 2.04

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut

1;
