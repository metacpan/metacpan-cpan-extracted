package Email::Store::Entity::Correlator::List;

# People sometimes reply to lists with the 'name' as the person they're
# responding to. Hence, if we detect that the address belongs to a
# list's posting address, then we ignore the name.

sub get_person_order { 1 }
sub get_person {
    my ($self, $person_r, $mail, $role, $name, $address) = @_;
    my ($list) = Email::Store::List->search(
            posting_address => $address->address
    );
    return unless $list;
    my %seen;
    my @candidates = 
        Email::Store::Entity->search_distinct_entity_for_address( $address->id);
    if (@candidates == 1) { $$person_r = $candidates[0]; }
}

1;
