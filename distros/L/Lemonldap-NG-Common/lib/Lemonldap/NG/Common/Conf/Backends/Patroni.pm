package Lemonldap::NG::Common::Conf::Backends::Patroni;

use strict;
use Lemonldap::NG::Common::Conf::Backends::_DBI;
use Lemonldap::NG::Common::Conf::Backends::CDBI;
our @ISA = ('Lemonldap::NG::Common::Conf::Backends::CDBI');

*store = \&Lemonldap::NG::Common::Conf::Backends::CDBI::store;
*load = \&Lemonldap::NG::Common::Conf::Backends::CDBI::load;

sub beforeRetry {
    my ($self) = @_;
    require Lemonldap::NG::Common::UserAgent;
    require JSON;
    my $ua = Lemonldap::NG::Common::UserAgent->new($self);
    $ua->timeout(3);
    my $res = 0;
    foreach my $patroniUrl ( split /,\s*/, $self->{patroniUrl} ) {
        my $resp = $ua->get($patroniUrl);
        if ( $resp->is_success ) {
            my $c = eval { JSON::from_json( $resp->decoded_content ) };
            if ( $@ or !$c->{members} or ref( $c->{members} ) ne 'ARRAY' ) {
                print STDERR "Bad response from $self->{patroniUrl}\n"
                  . $resp->decoded_content;
                next;
            }
            my ($leader) =
              grep { $_->{role} eq 'leader' } @{ $c->{members} };
            unless ($leader) {
                print STDERR "No leader found from $self->{patroniUrl}\n"
                  . $resp->decoded_content;
                next;
            }
            delete $self->{_dbh};
            $self->{dbiChain} =~ s/(?:port|host)=[^;]+;*//g;
            $self->{dbiChain} =~ s/;$//;
            $self->{dbiChain} .= ( $self->{dbiChain} =~ /:$/ ? '' : ';' )
              . "host=$leader->{host};port=$leader->{port}";
            $res = 1;
            last;
        }
    }
    return $res;
}

push @Lemonldap::NG::Common::Conf::Backends::_DBI::confDbiHooks, \&checkPatroni;

1;
