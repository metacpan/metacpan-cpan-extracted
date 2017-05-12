# $Id: Domain.pm 291 2009-11-15 22:05:38Z jabra $
package Fierce::Parser::Domain;
{
    our $VERSION = '0.01';
    $VERSION = eval $VERSION;

    use Object::InsideOut;
    use Fierce::Parser::Domain::NameServers;
    use Fierce::Parser::Domain::ZoneTransfers;
    use Fierce::Parser::Domain::BruteForce;
    use Fierce::Parser::Domain::Vhost;
    use Fierce::Parser::Domain::SubdomainBruteForce;
    use Fierce::Parser::Domain::ExtBruteForce;
    use Fierce::Parser::Domain::FindMX;
    use Fierce::Parser::Domain::WildCard;
    use Fierce::Parser::Domain::WhoisLookup;
    use Fierce::Parser::Domain::ReverseLookups;
    use Fierce::Parser::Domain::FindNearby;
    use Fierce::Parser::Domain::ARIN;

    my @domain : Field : Arg(domain) : Get(domain);
    my @startscan : Field : Arg(startscan) : Get(startscan);
    my @startscanstr : Field : Arg(startscanstr) : Get(startscanstr);
    my @endscan : Field : Arg(endscan) : Get(endscan);
    my @endscanstr : Field : Arg(endscanstr) : Get(endscanstr);

    my @name_servers : Field : Arg(name_servers) : Get(name_servers) :
        Type(Fierce::Parser::Domain::NameServers);
    my @arin_lookup : Field : Arg(arin_lookup) : Get(arin_lookup) :
        Type(Fierce::Parser::Domain::ARIN);
    my @zone_transfers : Field : Arg(zone_transfers) : Get(zone_transfers) :
        Type(Fierce::Parser::Domain::ZoneTransfers);
    my @bruteforce : Field : Arg(bruteforce) : Get(bruteforce) :
        Type(Fierce::Parser::Domain::BruteForce);
    my @vhost : Field : Arg(vhost) : Get(vhost) :
        Type(Fierce::Parser::Domain::Vhost);
    my @subdomain_bruteforce : Field : Arg(subdomain_bruteforce) :
        Get(subdomain_bruteforce) :
        Type(Fierce::Parser::Domain::SubdomainBruteForce);
    my @ext_bruteforce : Field : Arg(ext_bruteforce) : Get(ext_bruteforce) :
        Type(Fierce::Parser::Domain::ExtBruteForce);
    my @reverse_lookups : Field : Arg(reverse_lookups) : Get(reverse_lookups)
        : Type(Fierce::Parser::Domain::ReverseLookups);
    my @wildcard : Field : Arg(wildcard) : Get(wildcard) :
        Type(Fierce::Parser::Domain::WildCard);
    my @findmx : Field : Arg(findmx) : Get(findmx) :
        Type(Fierce::Parser::Domain::FindMX);
    my @whois_lookup : Field : Arg(whois_lookup) : Get(whois_lookup) :
        Type(Fierce::Parser::Domain::WhoisLookup);
    my @find_nearby : Field : Arg(find_nearby) : Get(find_nearby) :
        Type(Fierce::Parser::Domain::FindNearby);
}
1;
