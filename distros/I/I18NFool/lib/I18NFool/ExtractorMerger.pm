package I18NFool::ExtractorMerger;
use warnings;
use strict;


sub process
{
    my $class  = shift;
    my $result = {};
    foreach my $domain_hash (@_)
    {
        foreach my $domain_key (keys %{$domain_hash})
        {
            my $domain_lexicon = $domain_hash->{$domain_key};
            foreach my $key ( keys %{$domain_lexicon} )
            {
                my $po_entry = $domain_lexicon->{$key};
                $result->{$domain_key} ||= {};
                $result->{$domain_key}->{$key} = $po_entry;
            }
        }
    }

    return $result;
}


1;


__END__
