    #!/usr/bin/perl

    use strict;
    use warnings;
    use Metaweb;
    use Data::Dumper;

    my $mw = Metaweb->new();
    my $result = $mw->query({
        name => 'ships',
        query => [{
            type => "/user/skud/default_domain/tall_ship",
            rig  => 'barque',
            name => undef,
        }],
    });

    foreach my $r (@{$result->{content}}) {
        print $r->{name}, "\n";
    }


