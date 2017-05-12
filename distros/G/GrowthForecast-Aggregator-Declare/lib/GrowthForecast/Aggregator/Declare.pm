package GrowthForecast::Aggregator::Declare;
use strict;
use warnings;
use 5.008001;
our $VERSION = '0.1.1';

use parent qw(Exporter);

use GrowthForecast::Aggregator::DB;
use GrowthForecast::Aggregator::DBMulti;
use GrowthForecast::Aggregator::Callback;

our @EXPORT = qw(gf section db db_multi callback);

our $_SECTION;
our @_QUERIES;

sub gf(&) {
    local @_QUERIES;
    $_[0]->();
    return @_QUERIES;
}

sub section($&) {
    local $_SECTION = shift;
    $_[0]->();
}

sub db {
    push @_QUERIES, GrowthForecast::Aggregator::DB->new(
        section => $_SECTION,
        @_,
    );
}

sub db_multi {
    push @_QUERIES, GrowthForecast::Aggregator::DBMulti->new(
        section => $_SECTION,
        @_,
    );
}

sub callback {
    push @_QUERIES, GrowthForecast::Aggregator::Callback->new(
        section => $_SECTION,
        @_,
    );
}

1;
__END__

=encoding utf8

=head1 NAME

GrowthForecast::Aggregator::Declare - Declarative interface for GrowthForecast client

=head1 SYNOPSIS

    use GrowthForecast::Aggregator::Declare;

    my @queries = gf {
        section member => sub {
            # post to member/count
            db(
                name => 'count',
                description => 'The number of members',
                query => 'SELECT COUNT(*) FROM member',
            );
        };

        section entry => sub {
            # post to entry/count, entry/count_unique
            db_multi(
                names        => ['count',                'count_unique'],
                descriptions => ['Total count of posts', 'Posted bloggers'],
                query => 'SELECT COUNT(*), COUNT(DISTINCT member_id) FROM entry',
            );
        };
    };
    for my $query (@queries) {
        $query->run(
            dbh => $dbh,
            ua  => $ua,
            service => 'blog_service',
            endpoint => 'http://exapmle.com/api/',
        );
    }

=head1 DESCRIPTION

GrowthForecast::Aggregator::Declare is a declarative client library for L<GrowthForecast>

=head1 DSL

=over 4

=item gf { ... }

This makes a scope to declare GrowthForecast metrics.

This function returns list of Aggregators.

=item section $name:Str, \&block

    section 'member' => sub { ... };

This function defines section. Under this function, db() and db_multi() function use the section name automatically.

=item db(%args)

Create L<GrowthForecast::Aggregator::DB> object using C<< %args >>.

=item db_multi(%args)

Create L<GrowthForecast::Aggregator::DBMulti> object using C<< %args >>.

=item callback(%args)

Create L<GrowthForecast::Aggregator::Callback> object using C<< %args >>.

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 SEE ALSO

This library is client for L<GrowthForecast>.

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
