use strict;
use 5.010;

package FusqlFS::Backend;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;

=head1 NAME

FusqlFS::Backend - FusqlFS database backend abstract factory

=head1 SYNOPSIS

    use FusqlFS::Backend;

    my $fs = FusqlFS::Backend->new(engine => 'PgSQL', database => 'dbname', user => 'postgres', password => 'pa$$w0rd');

=head1 DESCRIPTION

This class is a factory for the family of L<FusqlFS::Backend::Base> subclasses.
Its C<new()> method initializes and returns some kind of real backend class
instance (L<FusqlFS::Backend::PgSQL> or L<FusqlFS::Backend::MySQL> for now)
depending on `engine' option passed to it. If engine is not given or not
recognized, it falls back to `PgSQL' backend with a debug message.

You better look at one of underlying classes for detailed description.

=cut

use Carp;

our %Engines = (
    pgsql  => '::PgSQL',
    mysql  => '::MySQL',
    sqlite => '::SQLite',
);

sub new
{
    my $class = shift;
    my %options = @_;
    my $engine = $options{engine};

    my $subclass = $Engines{lc $engine} || '';
    if (!$subclass)
    {
        carp "Unknown engine `$engine', falling back to default `PgSQL' engine";
        $subclass = '::PgSQL';
    }

    $class .= $subclass;
    eval "require $class";
    $class->new(@_);
}

1;
