#!/usr/bin/perl -w
package Mail::Miner::Recogniser::Entity;

eval "use Lingua::EN::NamedEntity";
unless ($@) {

$Mail::Miner::recognisers{"".__PACKAGE__} =
    {
     title    => "Named entities",
    };
}

sub process {
    my ($class, %hash) = @_;

    return map {{ asset   => $_->{entity},
                  creator => __PACKAGE__."::".$_->{class}
               }}
      Lingua::EN::NamedEntity::extract_entities($hash{getbody}->())
}

1;
