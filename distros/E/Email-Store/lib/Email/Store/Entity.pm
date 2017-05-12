package Email::Store::Entity;
use base "Email::Store::DBI";
Email::Store::Entity->table("entity");
Email::Store::Entity->columns(Primary => qw/id/);
Email::Store::Entity->columns(All => qw/id notes/); # notes is a hack.
use Email::Address; 
use Email::MIME;
use Module::Pluggable::Ordered 
    search_path => ["Email::Store::Entity::Correlator"];
Email::Store::Entity->set_sql(distinct_entity => q{
    SELECT     DISTINCT entity id
    FROM addressing
    WHERE name = ?    AND address = ?});
Email::Store::Entity->set_sql(distinct_entity_for_name => q{
    SELECT     DISTINCT entity id
    FROM addressing
    WHERE name = ?});
Email::Store::Entity->set_sql(distinct_entity_for_address => q{
    SELECT     DISTINCT entity id
    FROM addressing
    WHERE address = ?});
sub on_store_order { 1 }
sub on_store {
    my ($self, $mail) = @_;
    # This will MIME-decode the headers
    my $mime = Email::MIME->new($mail->message);
    for my $role (qw(To From Cc Bcc)) {
        my @addrs = Email::Address->parse($mime->header($role));
        for my $addr (@addrs) { 
            my $name = Email::Store::Entity::Name->find_or_create({
                name => ($addr->name || " ")
            });
            my $address = Email::Store::Entity::Address->find_or_create({
                address => $addr->address
            });
            my $person = $self->get_person($mail, $role, $name, $address);
            Email::Store::Addressing->create({
                mail => $mail->id,
                role => $role,
                name => $name->id,
                address => $address->id,
                entity => $person->id
            });
        }
    }
}

sub get_person {
    my ($self, $mail, $role, $name, $address) = @_;
    my $entity;
    $self->call_plugins("get_person", \$entity, $mail, $role, $name, $address);
    $entity || Email::Store::Entity->create({ notes => "" });
          # This bit shouldn't happen
}

package Email::Store::Addressing;
use base "Email::Store::DBI";
Email::Store::Addressing->table("addressing");
Email::Store::Addressing->columns( All => qw/ id mail role name address
entity confidence /);

# Relationships
for (qw(name address)) {
    no strict 'refs';
    my $class = "Email::Store::Entity::".ucfirst($_);
    @{$class."::ISA"} = "Email::Store::DBI";
    $class->table($_);
    $class->columns(Primary => qw/id/);
    $class->columns(All => "id", $_);
    $class->has_many("addressings" => "Email::Store::Addressing");
    Email::Store::Addressing->has_a($_ => $class);
}

Email::Store::Entity->has_many("addressings" => "Email::Store::Addressing");
Email::Store::Entity->has_many("names" => ["Email::Store::Addressing"=>"name"]);
Email::Store::Entity->has_many("addresses" => ["Email::Store::Addressing"=>"address"]);
Email::Store::Mail->has_many("addressings" => "Email::Store::Addressing");
Email::Store::Addressing->has_a("entity" => "Email::Store::Entity");
Email::Store::Addressing->has_a("mail" => "Email::Store::Mail");

package Email::Store::Entity;
1;

=head1 NAME

Email::Store::Entity - People in the address universe

=head1 SYNOPSIS

   my ($name) = Email::Store::Name->search( name => "Simon Cozens" )
   @mails_from_simon = $name->addressings( role => "From" )->mails;

=head1 DESCRIPTION

This file defines a number of concepts related to the people who send
and receive mail. 

An "entity" is a distinct "person", who may have multiple friendly names
and/or multiple email addresses.

We save distinct names and addresses; these are tied to mails by means
of "addressings". An addressing has a name, an address, a mail, a role
and an entity. The entity ID is meant to distinguish between the same
person with different email addresses or the same email address replying
on behalf of several names; see http://blog.simon-cozens.org/6744.html
for more on this theory.

=head2 Distinguishing entities

There are many heuristics to determine whether C<foo-bar@example.com (Foo Bar)>
is the same person as C<foo@example.com (Foo)>, or the same person as
C<foo-bar@anotherdomain.com (Foo Bar)>, or an entirely separate
individual. C<Email::Store> only knows one such heuristic, and it's not
a good one: it believes that a combination of email address and name
represents a distinct individual. It doesn't know that C<simon-nospam@>
and C<simon@> the same domain are the same person. This heuristic is
implemented by C<Email::Store::Entity::Correlator::Trivial>. 

However, in the same way as the rest of C<Email::Store>, you can write
your own correlators to determine how an addressing should be
allocated to an entity.

A correlator must live in the C<Email::Store::Entity::Correlator>
namespace, and implement the C<get_person_order> and C<get_person>
methods. C<get_person> is called with a reference to the
currently-selected entity and also the mail object, role name, 
and name and address objects involved. By examining the mail and the
current list of addressings, your method can choose to find or create a
more appropriate entity, and replace the reference accordingly.

=cut

__DATA__
CREATE TABLE IF NOT EXISTS entity (
    id integer auto_increment NOT NULL PRIMARY KEY,
    notes text
);

CREATE TABLE IF NOT EXISTS addressing (
    id integer auto_increment NOT NULL PRIMARY KEY,
    mail varchar(255),
    role varchar(20),
    entity integer,
    name integer,
    address integer,
    confidence integer
);

CREATE TABLE IF NOT EXISTS name (
    id integer auto_increment NOT NULL PRIMARY KEY,
    name varchar(255)
);

CREATE TABLE IF NOT EXISTS address (
    id integer auto_increment NOT NULL PRIMARY KEY,
    address varchar(255)
);
