use strict;
use 5.010;

package FusqlFS::Backend::PgSQL;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;
use parent 'FusqlFS::Backend::Base';

=begin testing

#!class FusqlFS::Backend::PgSQL::Test
#!noinst

my $fusqlh = FusqlFS::Backend::PgSQL->new(
    host     => '',
    port     => '',
    database => 'fusqlfs_test',
    user     => 'postgres',
    password => ''
);

isa_ok $fusqlh, 'FusqlFS::Backend::PgSQL', 'PgSQL backend initialization';

my $new_fusqlh = FusqlFS::Backend::PgSQL->new();
is $new_fusqlh, $fusqlh, 'PgSQL backend is singleton';

=end testing
=cut
sub init
{
    $_[0]->autopackages(
        'tables',
        'views',
        'sequences',
        'roles',
        'queries',
        'functions',
        'languages');
}

sub dsn
{
    my $self = shift;
    return 'Pg:'.$self->SUPER::dsn(@_);
}

1;

