package Email::Store::Plucene;
use 5.006;
use strict;
use warnings;
our $VERSION = '0.02';
use Plucene::Simple; # For now
our $index_path ||= "./emailstore-index";
use Module::Pluggable::Ordered search_path => ["Email::Store"];

sub on_store_order { 99 }
sub on_store {
    my ($self, $mail) = @_;
    my $hash = {};
    $self->call_plugins("on_gather_plucene_fields", $mail, $hash);
    my $plucy = Plucene::Simple->open($index_path);
    $plucy->add($mail->id, $hash);
}

sub optimize {
    my $plucy = Plucene::Simple->open($index_path);
    $plucy->optimize;
}
    
sub on_gather_plucene_fields_order { 1 } # I really am the king of this
sub on_gather_plucene_fields {
    my ($self, $mail, $hash) = @_;
    $hash->{list} = join " ", map {$_->name} $mail->lists;
    # At some point we might want to be able to search for "from_id",
    # mail from a specific entity, but that would require us to use
    # tokenizers which understood numbers, so we'll leave it for a later
    # release.
    for (qw(From Cc To)) {
        $hash->{lc $_} = join " ", map {$_->name->name} 
                                       $mail->addressings(role => $_);
    }
    $hash->{text} = $mail->simple->body;
}

package Email::Store::Mail;
sub plucene_search {
    my ($class, $terms) = @_;
    my $plucy = Plucene::Simple->open($index_path);
    return $class->_ids_to_objects([map {{ message_id => $_ }} $plucy->search($terms)]);
}

sub plucene_search_during {
    my ($class, @terms) = @_;
    my $plucy = Plucene::Simple->open($index_path);
    return $class->_ids_to_objects([map {{ message_id => $_ }} $plucy->search_during(@terms)]);
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Email::Store::Plucene - Search your Email::Store with Plucene

=head1 SYNOPSIS

  use Email::Store;
  $Email::Store::Plucene::index_path = "/var/db/mailstore_index";
  Email::Store::Mail->store($_) for @mails;
  Email::Store::Plucene->optimize;

  @some_mails = 
    Email::Store::Mail->plucene_search("from:dan list:perl6-internals");
  
  @may_mails = Email::Store::Mail->plucene_search_during
            ("from:dan list:perl6-internals", "2004-05-01", "2004-05-31");

=head1 DESCRIPTION

This module adds Plucene indexing to Email::Store's indexing. Whenever a
mail is indexed, an entry will be added in the Plucene index which is
located at C<$Email::Store::Plucene::index_path>. If you don't change
this variable, you'll end up with an index called F<emailstore-index> in
the current directory.

=head1 METHODS

The module hooks into the C<store> method in the usual way, and provides
two new search methods:

=over 3

=item C<plucene_search>

This takes a query and returns a list of mails matching that query. The
query terms are by default joined together with the C<OR> operator.

=item C<plucene_search_during>

As above, but also takes two ISO format dates, returning only mails in 
that period.

=back

=head1 NOTES FOR PLUG-IN WRITERS

This module provides a hook called C<on_gather_plucene_fields>. You
should provide methods called C<on_gather_plucene_fields_order> (a
numeric ordering) and C<on_gather_plucene_fields>. This last should
expect a C<Email::Store::Mail> object and a hash reference. Write into
this hash reference any fields you want to be searchable:

    package Email::Store::Annotations;
    sub on_gather_plucene_fields_order { 10 }
    sub on_gather_plucene_fields {
        my ($self, $mail, $hash);
        $hash->{notes} = join " ", $mail->annotations;
    }

Now you should be able to use C<notes:foo> to search for mails with
"foo" in their annotations.

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Simon Cozens

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
